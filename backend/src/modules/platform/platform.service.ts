import { Injectable } from '@nestjs/common';
import { sql } from 'kysely';
import { actorUserId, asTenant, requiredUserId, tenantId, unscoped } from '../../common/context';
import { config } from '../../common/config';
import { conflict, forbidden, notFound } from '../../common/errors';
import { paged, requirePage } from '../../common/http';
import { ulid } from '../../common/ids';
import { audit, Db, emit, rooms } from '../../infra/db/db.service';
import Redis from 'ioredis';

// Every read across cafes and every action goes through unscoped(reason) and is written to the audit log.
@Injectable()
export class PlatformService {
  constructor(private readonly db: Db) {}

  async listCafes(query: { status?: string; search?: string; page?: string; limit?: string }) {
    const { page, limit, offset } = requirePage(query);
    return unscoped('platform cafe list', async () => {
      let q = this.db.q.selectFrom('cafes as c').innerJoin('users as u', 'u.id', 'c.owner_user_id');
      if (query.status) q = q.where('c.status', '=', query.status as 'active');
      if (query.search) q = q.where((eb) => eb.or([eb('c.display_name', 'like', `%${query.search}%`), eb('c.slug', 'like', `%${query.search}%`)]));
      const [rows, count] = await Promise.all([
        q.select(['c.public_id', 'c.slug', 'c.display_name', 'c.status', 'c.country_code', 'c.currency_code', 'c.created_at', 'c.approved_at', 'u.full_name as owner_name', 'u.email as owner_email']).orderBy('c.id', 'desc').limit(limit).offset(offset).execute(),
        q.select((eb) => eb.fn.countAll<number>().as('n')).executeTakeFirstOrThrow(),
      ]);
      return paged(rows, page, limit, Number(count.n));
    });
  }

  private async cafeId(publicId: string) {
    const c = await unscoped('platform cafe lookup', () => this.db.q.selectFrom('cafes').select(['id', 'status']).where('public_id', '=', publicId).executeTakeFirst());
    if (!c) throw notFound('CAFE_NOT_FOUND');
    return c;
  }

  async cafeDetail(publicId: string, reason?: string) {
    const { id } = await this.cafeId(publicId);
    return asTenant(id, async () => {
      const c = await this.db.q.selectFrom('cafes').select(['public_id', 'slug', 'display_name', 'legal_name', 'status', 'status_reason', 'country_code', 'currency_code', 'timezone', 'contact_email', 'contact_phone', 'business_registration_number', 'created_at', 'approved_at', 'suspended_at']).where('id', '=', id).executeTakeFirstOrThrow();
      const [branches, staff, orders, sub] = await Promise.all([
        this.db.q.selectFrom('cafe_branches').select(['public_id', 'name', 'city', 'status']).where('cafe_id', '=', id).where('deleted_at', 'is', null).execute(),
        this.db.q.selectFrom('cafe_staff').select((eb) => eb.fn.countAll<number>().as('n')).where('cafe_id', '=', id).executeTakeFirstOrThrow(),
        this.db.q.selectFrom('orders').select((eb) => [eb.fn.countAll<number>().as('n'), eb.fn.coalesce(eb.fn.sum<string>('total_amount'), sql<string>`0`).as('gross')]).where('cafe_id', '=', id).where('status', '!=', 'cancelled').executeTakeFirstOrThrow(),
        this.db.q.selectFrom('cafe_subscriptions as s').innerJoin('subscription_plans as p', 'p.id', 's.plan_id').select(['p.name', 's.status', 's.current_period_end']).where('s.cafe_id', '=', id).orderBy('s.id', 'desc').executeTakeFirst(),
      ]);
      await audit(this.db.q, { action: 'platform.cafe_read', entityType: 'cafe', entityId: publicId, reason, cafeId: id });
      return { ...c, branches, staffCount: Number(staff.n), orderCount: Number(orders.n), grossSales: orders.gross, subscription: sub ?? null };
    });
  }

  async cafeOrders(publicId: string, query: { page?: string; limit?: string }, reason?: string) {
    const { id } = await this.cafeId(publicId);
    const { page, limit, offset } = requirePage(query);
    return asTenant(id, async () => {
      const [rows, count] = await Promise.all([
        // Order lines and customer identity are deliberately absent from this platform view.
        this.db.q.selectFrom('orders').select(['public_id', 'order_number', 'status', 'payment_status', 'currency_code', 'total_amount', 'placed_at']).where('cafe_id', '=', id).orderBy('id', 'desc').limit(limit).offset(offset).execute(),
        this.db.q.selectFrom('orders').select((eb) => eb.fn.countAll<number>().as('n')).where('cafe_id', '=', id).executeTakeFirstOrThrow(),
      ]);
      await audit(this.db.q, { action: 'platform.cafe_orders_read', entityType: 'cafe', entityId: publicId, reason, cafeId: id });
      return paged(rows, page, limit, Number(count.n));
    });
  }

  async cafeFinance(publicId: string, reason?: string) {
    const { id } = await this.cafeId(publicId);
    return asTenant(id, async () => {
      const rows = await sql<Record<string, string>>`SELECT currency_code, COUNT(*) AS orders, SUM(subtotal_amount) AS gross, SUM(discount_amount) AS discounts, SUM(tax_amount) AS tax, SUM(refunded_amount) AS refunds, SUM(paid_amount) AS collected FROM orders WHERE cafe_id = ${tenantId()} AND status <> 'cancelled' GROUP BY currency_code`.execute(this.db.q);
      await audit(this.db.q, { action: 'platform.cafe_finance_read', entityType: 'cafe', entityId: publicId, reason, cafeId: id });
      return rows.rows;
    });
  }

  async setStatus(publicId: string, status: 'active' | 'suspended' | 'rejected' | 'closed', reason: string) {
    const c = await this.cafeId(publicId);
    const allowed: Record<string, string[]> = { pending_approval: ['active', 'rejected'], active: ['suspended', 'closed'], suspended: ['active', 'closed'], rejected: ['active'], closed: [] };
    if (!allowed[c.status]!.includes(status)) throw conflict('CAFE_ILLEGAL_TRANSITION', { from: c.status, to: status });
    await unscoped('platform cafe governance', () => this.db.tx(async (tx) => {
      await tx.updateTable('cafes').set({
        status, status_reason: reason, approved_by_user_id: status === 'active' ? requiredUserId() : undefined, approved_at: status === 'active' ? new Date() : undefined, suspended_at: status === 'suspended' ? new Date() : status === 'active' ? null : undefined,
      }).where('id', '=', c.id).execute();
      if (status !== 'active') {
        // Suspension takes effect immediately: staff sessions end, while all data is preserved.
        await tx.updateTable('login_sessions').set({ revoked_at: new Date(), revoke_reason: `cafe_${status}` }).where('cafe_id', '=', c.id).where('revoked_at', 'is', null).execute();
      }
      await audit(tx, { action: `platform.cafe_${status}`, entityType: 'cafe', entityId: publicId, reason, cafeId: c.id });
      await emit(tx, { type: 'cafe.status_changed', rooms: [rooms.platform(), rooms.owner(c.id)], payload: { cafeId: publicId, status } });
    }));
    return { ok: true };
  }

  async users(query: { search?: string; page?: string; limit?: string }) {
    const { page, limit, offset } = requirePage(query);
    return unscoped('platform user management', async () => {
      let q = this.db.q.selectFrom('users').where('deleted_at', 'is', null);
      if (query.search) q = q.where((eb) => eb.or([eb('email', 'like', `%${query.search}%`), eb('full_name', 'like', `%${query.search}%`)]));
      const [rows, count] = await Promise.all([
        q.select(['public_id', 'email', 'full_name', 'status', 'is_platform_user', 'last_login_at', 'created_at']).orderBy('id', 'desc').limit(limit).offset(offset).execute(),
        q.select((eb) => eb.fn.countAll<number>().as('n')).executeTakeFirstOrThrow(),
      ]);
      await audit(this.db.q, { action: 'platform.users_read', cafeId: null });
      return paged(rows, page, limit, Number(count.n));
    });
  }
  async setUserStatus(publicId: string, status: 'active' | 'disabled', reason: string) {
    await unscoped('platform user management', () => this.db.tx(async (tx) => {
      const u = await tx.selectFrom('users').select('id').where('public_id', '=', publicId).executeTakeFirst();
      if (!u) throw notFound();
      if (u.id === actorUserId()) throw forbidden('CANNOT_CHANGE_SELF');
      await tx.updateTable('users').set({ status }).where('id', '=', u.id).execute();
      if (status === 'disabled') await tx.updateTable('login_sessions').set({ revoked_at: new Date(), revoke_reason: 'user_disabled' }).where('user_id', '=', u.id).where('revoked_at', 'is', null).execute();
      await audit(tx, { action: `platform.user_${status}`, entityType: 'user', entityId: publicId, reason, cafeId: null });
    }));
    return { ok: true };
  }

  // Reference data
  private async adminWrite<T>(action: string, entity: string, fn: (tx: Parameters<Parameters<Db['tx']>[0]>[0]) => Promise<T>, after?: unknown) {
    return unscoped(action, () => this.db.tx(async (tx) => {
      const r = await fn(tx);
      await audit(tx, { action, entityType: entity, cafeId: null, after });
      return r;
    }));
  }
  languages() { return unscoped('reference', () => this.db.q.selectFrom('languages').selectAll().orderBy('sort_order').execute()); }
  saveLanguage(d: { code: string; name: string; nativeName: string; direction: 'ltr' | 'rtl'; isActive?: boolean }) {
    const v = { name: d.name, native_name: d.nativeName, direction: d.direction, is_active: d.isActive === false ? 0 : 1 };
    return this.adminWrite('platform.language_saved', 'language', (tx) => tx.insertInto('languages').values({ code: d.code, ...v }).onDuplicateKeyUpdate(v).execute().then(() => ({ ok: true })), d);
  }
  currencies() { return unscoped('reference', () => this.db.q.selectFrom('currencies').selectAll().orderBy('code').execute()); }
  saveCurrency(d: { code: string; numericCode: string; name: string; symbol: string; minorUnit: number; isActive?: boolean }) {
    const v = { numeric_code: d.numericCode, name: d.name, symbol: d.symbol, minor_unit: d.minorUnit, is_active: d.isActive === false ? 0 : 1 };
    return this.adminWrite('platform.currency_saved', 'currency', (tx) => tx.insertInto('currencies').values({ code: d.code, ...v }).onDuplicateKeyUpdate(v).execute().then(() => ({ ok: true })), d);
  }
  countries() { return unscoped('reference', () => this.db.q.selectFrom('countries').selectAll().orderBy('name').execute()); }
  saveCountry(d: { code: string; name: string; defaultCurrency: string; defaultLanguage: string; defaultTimezone: string; fiscalYearStartMonth?: number; isActive?: boolean }) {
    const v = { name: d.name, default_currency_code: d.defaultCurrency, default_language_code: d.defaultLanguage, default_timezone: d.defaultTimezone, fiscal_year_start_month: d.fiscalYearStartMonth ?? 1, is_active: d.isActive === false ? 0 : 1 };
    return this.adminWrite('platform.country_saved', 'country', (tx) => tx.insertInto('countries').values({ code: d.code, ...v }).onDuplicateKeyUpdate(v).execute().then(() => ({ ok: true })), d);
  }
  exchangeRates(base?: string) {
    return unscoped('reference', () => {
      let q = this.db.q.selectFrom('exchange_rates').selectAll();
      if (base) q = q.where('base_currency_code', '=', base);
      return q.orderBy('effective_at', 'desc').limit(200).execute();
    });
  }
  addExchangeRate(d: { base: string; quote: string; rate: string; provider: string; effectiveAt: string }) {
    return this.adminWrite('platform.exchange_rate_added', 'exchange_rate', (tx) => tx.insertInto('exchange_rates').values({ base_currency_code: d.base, quote_currency_code: d.quote, rate: d.rate, provider: d.provider, effective_at: new Date(d.effectiveAt), created_by_user_id: actorUserId() }).execute().then(() => ({ ok: true })), d);
  }
  translations(namespace?: string, language?: string) {
    return unscoped('reference', () => {
      let q = this.db.q.selectFrom('translations').selectAll();
      if (namespace) q = q.where('namespace', '=', namespace);
      if (language) q = q.where('language_code', '=', language);
      return q.orderBy('translation_key').limit(1000).execute();
    });
  }
  saveTranslation(d: { namespace: string; key: string; language: string; value: string; isReviewed?: boolean }) {
    const v = { value: d.value, is_reviewed: d.isReviewed ? 1 : 0 };
    return this.adminWrite('platform.translation_saved', 'translation', (tx) => tx.insertInto('translations').values({ namespace: d.namespace, translation_key: d.key, language_code: d.language, ...v }).onDuplicateKeyUpdate(v).execute().then(() => ({ ok: true })), { key: d.key, language: d.language });
  }
  settings() { return unscoped('reference', () => this.db.q.selectFrom('platform_settings').selectAll().execute()); }
  saveSetting(key: string, value: unknown, description?: string) {
    const v = { value: JSON.stringify(value), description: description ?? null, updated_by_user_id: actorUserId() };
    return this.adminWrite('platform.setting_saved', 'setting', (tx) => tx.insertInto('platform_settings').values({ setting_key: key, ...v }).onDuplicateKeyUpdate(v).execute().then(() => ({ ok: true })), { key });
  }
  commissions() { return unscoped('platform commissions', () => this.db.q.selectFrom('commission_configs as c').leftJoin('cafes as f', 'f.id', 'c.cafe_id').select(['c.id', 'c.rate_percent', 'c.valid_from', 'c.valid_to', 'f.public_id as cafe_id', 'f.display_name']).orderBy('c.id', 'desc').execute()); }
  async addCommission(d: { cafeId?: string; ratePercent: string; validFrom: string }) {
    const cafe = d.cafeId ? (await this.cafeId(d.cafeId)).id : null;
    return this.adminWrite('platform.commission_added', 'commission', (tx) => tx.insertInto('commission_configs').values({ cafe_id: cafe, rate_percent: d.ratePercent, valid_from: new Date(d.validFrom), created_by_user_id: actorUserId() }).execute().then(() => ({ ok: true })), d);
  }

  announcements() {
    return unscoped('platform announcements', async () => {
      const rows = await this.db.q.selectFrom('announcements').selectAll().orderBy('id', 'desc').limit(100).execute();
      const tr = rows.length ? await this.db.q.selectFrom('announcement_translations').selectAll().where('announcement_id', 'in', rows.map((r) => r.id)).execute() : [];
      return rows.map(({ id, ...r }) => ({ ...r, translations: tr.filter((t) => t.announcement_id === id).map((t) => ({ language: t.language_code, title: t.title, body: t.body })) }));
    });
  }
  async createAnnouncement(d: { audience: 'all_cafes' | 'owners' | 'customers'; startsAt: string; endsAt?: string; translations: Array<{ language: string; title: string; body: string }> }) {
    return this.adminWrite('platform.announcement_created', 'announcement', async (tx) => {
      const publicId = ulid();
      const id = Number((await tx.insertInto('announcements').values({ public_id: publicId, audience: d.audience, starts_at: new Date(d.startsAt), ends_at: d.endsAt ? new Date(d.endsAt) : null, created_by_user_id: requiredUserId() }).executeTakeFirstOrThrow()).insertId);
      await tx.insertInto('announcement_translations').values(d.translations.map((t) => ({ announcement_id: id, language_code: t.language, title: t.title, body: t.body }))).execute();
      return { publicId };
    });
  }
  activeAnnouncements(lang: string) {
    return unscoped('announcements are global', async () => {
      const now = new Date();
      const rows = await this.db.q.selectFrom('announcements as a').innerJoin('announcement_translations as t', 't.announcement_id', 'a.id').select(['a.public_id', 'a.audience', 't.language_code', 't.title', 't.body']).where('a.is_active', '=', 1).where('a.starts_at', '<=', now).where((eb) => eb.or([eb('a.ends_at', 'is', null), eb('a.ends_at', '>=', now)])).where('a.audience', 'in', ['all_cafes', 'owners']).execute();
      const out = new Map<string, (typeof rows)[number]>();
      for (const r of rows) if (!out.has(r.public_id) || r.language_code === lang) out.set(r.public_id, r);
      return [...out.values()];
    });
  }

  // Support tickets: cafes raise them, the platform answers.
  async tickets(query: { status?: string; page?: string; limit?: string }) {
    const { page, limit, offset } = requirePage(query);
    return unscoped('platform support queue', async () => {
      let q = this.db.q.selectFrom('support_tickets as t').innerJoin('cafes as c', 'c.id', 't.cafe_id');
      if (query.status) q = q.where('t.status', '=', query.status as 'open');
      const rows = await q.select(['t.public_id', 't.subject', 't.status', 't.priority', 't.created_at', 'c.display_name as cafe']).orderBy('t.id', 'desc').limit(limit).offset(offset).execute();
      return paged(rows, page, limit, rows.length);
    });
  }
  async ticket(publicId: string) {
    return unscoped('platform support queue', async () => {
      const t = await this.db.q.selectFrom('support_tickets').selectAll().where('public_id', '=', publicId).executeTakeFirst();
      if (!t) throw notFound();
      const messages = await this.db.q.selectFrom('support_ticket_messages as m').innerJoin('users as u', 'u.id', 'm.author_user_id').select(['m.body', 'm.is_internal_note', 'm.created_at', 'u.full_name']).where('m.ticket_id', '=', t.id).orderBy('m.id').execute();
      return { publicId: t.public_id, subject: t.subject, status: t.status, priority: t.priority, messages };
    });
  }
  async replyTicket(publicId: string, d: { body: string; internal?: boolean; status?: 'open' | 'in_progress' | 'waiting_on_cafe' | 'resolved' | 'closed' }) {
    return unscoped('platform support queue', () => this.db.tx(async (tx) => {
      const t = await tx.selectFrom('support_tickets').select(['id', 'cafe_id']).where('public_id', '=', publicId).executeTakeFirst();
      if (!t) throw notFound();
      await tx.insertInto('support_ticket_messages').values({ cafe_id: t.cafe_id, ticket_id: t.id, author_user_id: requiredUserId(), body: d.body, is_internal_note: d.internal ? 1 : 0 }).execute();
      await tx.updateTable('support_tickets').set({ status: d.status, assigned_to_user_id: requiredUserId() }).where('id', '=', t.id).execute();
      await audit(tx, { action: 'platform.ticket_replied', entityType: 'support_ticket', entityId: publicId, cafeId: t.cafe_id });
      return { ok: true };
    }));
  }
  async cafeTickets() {
    return this.db.q.selectFrom('support_tickets').select(['public_id', 'subject', 'status', 'priority', 'created_at']).where('cafe_id', '=', tenantId()).orderBy('id', 'desc').limit(100).execute();
  }
  async cafeCreateTicket(d: { subject: string; body: string; priority?: 'low' | 'normal' | 'high' | 'urgent' }) {
    return this.db.tx(async (tx) => {
      const publicId = ulid();
      const id = Number((await tx.insertInto('support_tickets').values({ public_id: publicId, cafe_id: tenantId(), subject: d.subject, priority: d.priority, opened_by_user_id: requiredUserId() }).executeTakeFirstOrThrow()).insertId);
      await tx.insertInto('support_ticket_messages').values({ cafe_id: tenantId(), ticket_id: id, author_user_id: requiredUserId(), body: d.body }).execute();
      await emit(tx, { type: 'support.ticket_created', rooms: [rooms.platform()], payload: { ticketId: publicId, subject: d.subject } });
      return { publicId };
    });
  }
  async cafeTicket(publicId: string) {
    const t = await this.db.q.selectFrom('support_tickets').selectAll().where('cafe_id', '=', tenantId()).where('public_id', '=', publicId).executeTakeFirst();
    if (!t) throw notFound();
    // Internal platform notes are never shown to the cafe.
    const messages = await this.db.q.selectFrom('support_ticket_messages as m').innerJoin('users as u', 'u.id', 'm.author_user_id').select(['m.body', 'm.created_at', 'u.full_name']).where('m.cafe_id', '=', tenantId()).where('m.ticket_id', '=', t.id).where('m.is_internal_note', '=', 0).orderBy('m.id').execute();
    return { publicId, subject: t.subject, status: t.status, messages };
  }
  async cafeReplyTicket(publicId: string, body: string) {
    const t = await this.db.q.selectFrom('support_tickets').select('id').where('cafe_id', '=', tenantId()).where('public_id', '=', publicId).executeTakeFirst();
    if (!t) throw notFound();
    await this.db.q.insertInto('support_ticket_messages').values({ cafe_id: tenantId(), ticket_id: t.id, author_user_id: requiredUserId(), body }).execute();
    return { ok: true };
  }

  auditLogs(query: { cafeId?: string; action?: string; page?: string; limit?: string }) {
    const { page, limit, offset } = requirePage(query);
    return unscoped('platform audit read', async () => {
      let q = this.db.q.selectFrom('audit_logs as a').leftJoin('cafes as c', 'c.id', 'a.cafe_id');
      if (query.cafeId) q = q.where('c.public_id', '=', query.cafeId);
      if (query.action) q = q.where('a.action', 'like', `${query.action}%`);
      const rows = await q.select(['a.id', 'a.actor_type', 'a.actor_id', 'a.action', 'a.entity_type', 'a.entity_id', 'a.reason', 'a.occurred_at', 'a.ip_address', 'c.display_name as cafe']).orderBy('a.id', 'desc').limit(limit).offset(offset).execute();
      return paged(rows, page, limit, rows.length);
    });
  }

  async platformFinance() {
    return unscoped('platform finance', async () => {
      const rows = await sql<Record<string, string>>`SELECT currency_code, transaction_type, direction, COUNT(*) AS n, SUM(amount) AS total FROM platform_transactions GROUP BY currency_code, transaction_type, direction ORDER BY currency_code`.execute(this.db.q);
      await audit(this.db.q, { action: 'platform.finance_read', cafeId: null });
      return rows.rows;
    });
  }

  async health() {
    return unscoped('health', async () => {
      const started = Date.now();
      let database = 'ok';
      let outboxLag: number | null = null;
      let failedWebhooks: number | null = null;
      try {
        const o = await this.db.q.selectFrom('outbox_events').select((eb) => eb.fn.countAll<number>().as('n')).where('dispatched_at', 'is', null).executeTakeFirstOrThrow();
        outboxLag = Number(o.n);
        const w = await this.db.q.selectFrom('payment_webhooks').select((eb) => eb.fn.countAll<number>().as('n')).where('status', '=', 'failed').executeTakeFirstOrThrow();
        failedWebhooks = Number(w.n);
      } catch { database = 'down'; }
      let redis = config.redisUrl ? 'down' : 'not_configured';
      if (config.redisUrl) {
        const c = new Redis(config.redisUrl, { lazyConnect: true, maxRetriesPerRequest: 0, connectTimeout: 1000, retryStrategy: () => null });
        c.on('error', () => undefined);
        try { await c.connect(); if ((await c.ping()) === 'PONG') redis = 'ok'; } catch { /* reported as down */ } finally { c.disconnect(); }
      }
      return { status: database === 'ok' ? 'ok' : 'degraded', database, redis, outboxLag, failedWebhooks, dbLatencyMs: Date.now() - started, uptimeSeconds: Math.floor(process.uptime()) };
    });
  }

  ping() { return { status: 'ok' }; }
}
