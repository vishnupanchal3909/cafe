import { Injectable } from '@nestjs/common';
import { asTenant, tenantId, unscoped } from '../../common/context';
import { badRequest, conflict, notFound } from '../../common/errors';
import { ulid } from '../../common/ids';
import { dbMoney, money } from '../../common/money';
import { audit, Db, Tx } from '../../infra/db/db.service';

const addPeriod = (d: Date, interval: 'monthly' | 'yearly') => { const n = new Date(d); if (interval === 'monthly') n.setUTCMonth(n.getUTCMonth() + 1); else n.setUTCFullYear(n.getUTCFullYear() + 1); return n; };

@Injectable()
export class SubscriptionsService {
  constructor(private readonly db: Db) {}

  // Cafe side
  async availablePlans() {
    return unscoped('plans are global', async () => {
      const plans = await this.db.q.selectFrom('subscription_plans').selectAll().where('is_active', '=', 1).where('is_public', '=', 1).orderBy('sort_order').execute();
      if (!plans.length) return [];
      const [prices, ents] = await Promise.all([
        this.db.q.selectFrom('plan_prices').selectAll().where('plan_id', 'in', plans.map((p) => p.id)).execute(),
        this.db.q.selectFrom('plan_entitlements').selectAll().where('plan_id', 'in', plans.map((p) => p.id)).execute(),
      ]);
      return plans.map((p) => ({ code: p.code, name: p.name, description: p.description, trialDays: p.trial_days, prices: prices.filter((x) => x.plan_id === p.id).map((x) => ({ interval: x.billing_interval, ...money(x.amount, x.currency_code) })), entitlements: ents.filter((x) => x.plan_id === p.id).map((x) => ({ feature: x.feature_key, enabled: !!x.is_enabled, limit: x.limit_value })) }));
    });
  }
  async current() {
    const s = await this.db.q.selectFrom('cafe_subscriptions as s').innerJoin('subscription_plans as p', 'p.id', 's.plan_id').select(['s.public_id', 's.status', 's.billing_interval', 's.currency_code', 's.price_amount', 's.trial_ends_at', 's.current_period_start', 's.current_period_end', 's.grace_ends_at', 's.cancel_at_period_end', 'p.code as plan_code', 'p.name as plan_name']).where('s.cafe_id', '=', tenantId()).orderBy('s.id', 'desc').executeTakeFirst();
    return s ?? null;
  }
  async invoices() {
    return this.db.q.selectFrom('subscription_invoices').select(['public_id', 'invoice_number', 'status', 'currency_code', 'total_amount', 'period_start', 'period_end', 'due_at', 'paid_at']).where('cafe_id', '=', tenantId()).orderBy('id', 'desc').limit(100).execute();
  }

  private async activeRow(tx: Tx) {
    return tx.selectFrom('cafe_subscriptions').selectAll().where('cafe_id', '=', tenantId()).where('status', 'in', ['trialing', 'active', 'past_due', 'grace']).forUpdate().executeTakeFirst();
  }
  private async planPrice(tx: Tx, code: string, interval: 'monthly' | 'yearly', currency: string) {
    const plan = await tx.selectFrom('subscription_plans').selectAll().where('code', '=', code).where('is_active', '=', 1).executeTakeFirst();
    if (!plan) throw notFound('PLAN_NOT_FOUND');
    const price = await tx.selectFrom('plan_prices').select('amount').where('plan_id', '=', plan.id).where('currency_code', '=', currency).where('billing_interval', '=', interval).executeTakeFirst();
    if (!price) throw badRequest('PLAN_PRICE_UNAVAILABLE', { currency, interval });
    return { plan, amount: price.amount };
  }

  async subscribe(d: { planCode: string; interval: 'monthly' | 'yearly' }) {
    return this.db.tx(async (tx) => {
      if (await this.activeRow(tx)) throw conflict('SUBSCRIPTION_EXISTS');
      const cafe = await tx.selectFrom('cafes').select('currency_code').where('id', '=', tenantId()).executeTakeFirstOrThrow();
      const { plan, amount } = await this.planPrice(tx, d.planCode, d.interval, cafe.currency_code);
      const now = new Date();
      const trialEnd = plan.trial_days ? new Date(now.getTime() + plan.trial_days * 86400_000) : null;
      const publicId = ulid();
      await tx.insertInto('cafe_subscriptions').values({ public_id: publicId, cafe_id: tenantId(), plan_id: plan.id, status: trialEnd ? 'trialing' : 'active', billing_interval: d.interval, currency_code: cafe.currency_code, price_amount: amount, trial_ends_at: trialEnd, current_period_start: now, current_period_end: trialEnd ?? addPeriod(now, d.interval) }).execute();
      await audit(tx, { action: 'subscription.started', entityType: 'subscription', entityId: publicId, after: d });
      return { publicId, status: trialEnd ? 'trialing' : 'active' };
    });
  }

  // Upgrades apply immediately. A downgrade over the new plan's limits is refused rather than silently breaking the cafe.
  async changePlan(d: { planCode: string; interval?: 'monthly' | 'yearly' }) {
    return this.db.tx(async (tx) => {
      const s = await this.activeRow(tx);
      if (!s) throw notFound('SUBSCRIPTION_NOT_FOUND');
      const interval = d.interval ?? s.billing_interval;
      const { plan, amount } = await this.planPrice(tx, d.planCode, interval, s.currency_code);
      const branchLimit = await tx.selectFrom('plan_entitlements').select('limit_value').where('plan_id', '=', plan.id).where('feature_key', '=', 'branches').executeTakeFirst();
      if (branchLimit?.limit_value != null) {
        const n = await tx.selectFrom('cafe_branches').select((eb) => eb.fn.countAll<number>().as('n')).where('cafe_id', '=', tenantId()).where('deleted_at', 'is', null).executeTakeFirstOrThrow();
        if (Number(n.n) > Number(branchLimit.limit_value)) throw conflict('DOWNGRADE_EXCEEDS_LIMIT', { feature: 'branches', limit: Number(branchLimit.limit_value) });
      }
      const staffLimit = await tx.selectFrom('plan_entitlements').select('limit_value').where('plan_id', '=', plan.id).where('feature_key', '=', 'employees').executeTakeFirst();
      if (staffLimit?.limit_value != null) {
        const n = await tx.selectFrom('cafe_staff').select((eb) => eb.fn.countAll<number>().as('n')).where('cafe_id', '=', tenantId()).where('status', '!=', 'inactive').executeTakeFirstOrThrow();
        if (Number(n.n) > Number(staffLimit.limit_value)) throw conflict('DOWNGRADE_EXCEEDS_LIMIT', { feature: 'employees', limit: Number(staffLimit.limit_value) });
      }
      await tx.updateTable('cafe_subscriptions').set({ plan_id: plan.id, billing_interval: interval, price_amount: amount, cancel_at_period_end: 0 }).where('cafe_id', '=', tenantId()).where('id', '=', s.id).execute();
      await audit(tx, { action: 'subscription.plan_changed', entityType: 'subscription', entityId: s.public_id, after: d });
      return { ok: true };
    });
  }

  async cancel() {
    return this.db.tx(async (tx) => {
      const s = await this.activeRow(tx);
      if (!s) throw notFound('SUBSCRIPTION_NOT_FOUND');
      await tx.updateTable('cafe_subscriptions').set({ cancel_at_period_end: 1 }).where('cafe_id', '=', tenantId()).where('id', '=', s.id).execute();
      await audit(tx, { action: 'subscription.cancel_requested', entityType: 'subscription', entityId: s.public_id });
      return { cancelAt: s.current_period_end };
    });
  }

  // Platform side
  async adminPlans() {
    const [plans, prices, ents] = await Promise.all([
      this.db.q.selectFrom('subscription_plans').selectAll().orderBy('sort_order').execute(), this.db.q.selectFrom('plan_prices').selectAll().execute(), this.db.q.selectFrom('plan_entitlements').selectAll().execute(),
    ]);
    return plans.map((p) => ({ ...p, prices: prices.filter((x) => x.plan_id === p.id), entitlements: ents.filter((x) => x.plan_id === p.id) }));
  }
  async adminSavePlan(code: string, d: { name?: string; description?: string; isActive?: boolean; isPublic?: boolean; trialDays?: number; graceDays?: number; prices?: Array<{ currency: string; interval: 'monthly' | 'yearly'; amount: string }>; entitlements?: Array<{ feature: string; enabled: boolean; limit?: number | null }> }) {
    return this.db.tx(async (tx) => {
      await tx.insertInto('subscription_plans').values({ code, name: d.name ?? code }).ignore().execute();
      const plan = await tx.selectFrom('subscription_plans').select('id').where('code', '=', code).executeTakeFirstOrThrow();
      await tx.updateTable('subscription_plans').set({ name: d.name, description: d.description, is_active: d.isActive === undefined ? undefined : d.isActive ? 1 : 0, is_public: d.isPublic === undefined ? undefined : d.isPublic ? 1 : 0, trial_days: d.trialDays, grace_days: d.graceDays }).where('id', '=', plan.id).execute();
      for (const p of d.prices ?? []) await tx.insertInto('plan_prices').values({ plan_id: plan.id, currency_code: p.currency, billing_interval: p.interval, amount: dbMoney(p.amount) }).onDuplicateKeyUpdate({ amount: dbMoney(p.amount) }).execute();
      for (const e of d.entitlements ?? []) await tx.insertInto('plan_entitlements').values({ plan_id: plan.id, feature_key: e.feature, is_enabled: e.enabled ? 1 : 0, limit_value: e.limit ?? null }).onDuplicateKeyUpdate({ is_enabled: e.enabled ? 1 : 0, limit_value: e.limit ?? null }).execute();
      await audit(tx, { action: 'platform.plan_saved', entityType: 'plan', entityId: code, after: d, cafeId: null });
      return { ok: true };
    });
  }
  async adminMarkInvoicePaid(publicId: string, reference: string) {
    return unscoped('platform billing', () => this.db.tx(async (tx) => {
      const inv = await tx.selectFrom('subscription_invoices').selectAll().where('public_id', '=', publicId).forUpdate().executeTakeFirst();
      if (!inv) throw notFound();
      if (inv.status === 'paid') return { ok: true };
      await tx.updateTable('subscription_invoices').set({ status: 'paid', paid_at: new Date(), provider_payment_ref: reference }).where('id', '=', inv.id).execute();
      await tx.insertInto('platform_transactions').values({ public_id: ulid(), cafe_id: inv.cafe_id, transaction_type: 'subscription', direction: 'credit', currency_code: inv.currency_code, amount: inv.total_amount, source_type: 'subscription_invoice', source_id: inv.id, occurred_at: new Date() }).execute();
      await tx.updateTable('cafe_subscriptions').set({ status: 'active', grace_ends_at: null }).where('id', '=', inv.subscription_id).where('status', 'in', ['past_due', 'grace']).execute();
      await audit(tx, { action: 'platform.subscription_invoice_paid', entityType: 'subscription_invoice', entityId: publicId, reason: reference, cafeId: inv.cafe_id });
      return { ok: true };
    }));
  }

  // Lifecycle job: renewals invoice, unpaid goes past_due, then grace, then expired.
  async runLifecycle(now = new Date()) {
    const due = await unscoped('worker sweep across cafes', () => this.db.q.selectFrom('cafe_subscriptions as s').innerJoin('subscription_plans as p', 'p.id', 's.plan_id').select(['s.id', 's.cafe_id', 's.public_id', 's.status', 's.billing_interval', 's.currency_code', 's.price_amount', 's.current_period_end', 's.cancel_at_period_end', 's.grace_ends_at', 'p.grace_days']).where('s.status', 'in', ['trialing', 'active', 'past_due', 'grace']).where('s.current_period_end', '<=', now).limit(200).execute());
    for (const s of due) {
      await asTenant(s.cafe_id, () => this.db.tx(async (tx) => {
        const set = (patch: Record<string, unknown>) => tx.updateTable('cafe_subscriptions').set(patch as never).where('cafe_id', '=', s.cafe_id).where('id', '=', s.id).execute();
        if (s.cancel_at_period_end) { await set({ status: 'cancelled', cancelled_at: now }); return; }
        if (s.status === 'active' || s.status === 'trialing') {
          const start = s.current_period_end;
          const end = addPeriod(start, s.billing_interval);
          await tx.insertInto('subscription_invoices').values({ public_id: ulid(), cafe_id: s.cafe_id, subscription_id: s.id, invoice_number: `SUB-${ulid().slice(-12)}`, currency_code: s.currency_code, subtotal_amount: s.price_amount, total_amount: s.price_amount, period_start: start, period_end: end, due_at: start }).execute();
          await set({ status: 'past_due', current_period_start: start, current_period_end: end, grace_ends_at: new Date(now.getTime() + s.grace_days * 86400_000) });
        }
      }));
    }
    await unscoped('worker sweep across cafes', async () => {
      await this.db.q.updateTable('cafe_subscriptions').set({ status: 'grace' }).where('status', '=', 'past_due').execute();
      await this.db.q.updateTable('cafe_subscriptions').set({ status: 'expired' }).where('status', '=', 'grace').where('grace_ends_at', '<=', now).execute();
    });
    return { processed: due.length };
  }
}
