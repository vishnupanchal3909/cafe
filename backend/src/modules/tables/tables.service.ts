import { Injectable } from '@nestjs/common';
import { createHmac } from 'node:crypto';
import QRCode from 'qrcode';
import { actorUserId, asTenant, currentLang, requiredUserId, store, tenantId, unscoped } from '../../common/context';
import { config } from '../../common/config';
import { AppError, badRequest, conflict, notFound } from '../../common/errors';
import { decrypt, encrypt, randomToken, sha256, ulid } from '../../common/ids';
import { assertBranchAllowed, currentBranch, idOf } from '../../common/lookup';
import { audit, Db, emit, Q, rooms, staffRooms } from '../../infra/db/db.service';
import { loadSettings } from '../tenancy/settings';
import { TenancyService } from '../tenancy/tenancy.service';

// Session tokens are derived, so a second diner scanning the same QR joins the same session
// while the database only ever stores the token's hash.
const sessionToken = (publicId: string) => createHmac('sha256', config.encryptionKey).update(`table-session:${publicId}`).digest('base64url');

@Injectable()
export class TablesService {
  constructor(private readonly db: Db, private readonly tenancy: TenancyService) {}

  private async issueQr(tx: Q, tableId: number) {
    const token = randomToken();
    await tx.insertInto('table_qr_codes').values({ cafe_id: tenantId(), table_id: tableId, token_hash: sha256(token), token_ciphertext: encrypt(token), encryption_key_id: config.encryptionKeyId, created_by_user_id: actorUserId() }).execute();
    return token;
  }

  async list() {
    let q = this.db.q.selectFrom('cafe_tables as t').innerJoin('cafe_branches as b', 'b.id', 't.branch_id')
      .select(['t.public_id', 't.table_number', 't.area_name', 't.capacity', 't.status', 'b.public_id as branch_id'])
      .where('t.cafe_id', '=', tenantId()).where('t.deleted_at', 'is', null);
    const branch = store()?.branchId;
    const allowed = store()?.principal?.branchIds;
    if (branch) q = q.where('t.branch_id', '=', branch);
    else if (allowed) q = q.where('t.branch_id', 'in', allowed);
    return q.orderBy('t.table_number').execute();
  }

  async create(d: { tableNumber: string; capacity?: number; areaName?: string }) {
    const branch = currentBranch();
    return this.db.tx(async (tx) => {
      const publicId = ulid();
      const id = Number((await tx.insertInto('cafe_tables').values({ public_id: publicId, cafe_id: tenantId(), branch_id: branch, table_number: d.tableNumber, capacity: d.capacity, area_name: d.areaName ?? null }).executeTakeFirstOrThrow()).insertId);
      await this.issueQr(tx, id);
      await audit(tx, { action: 'table.created', entityType: 'table', entityId: publicId });
      return { publicId };
    });
  }

  private async table(q: Q, publicId: string) {
    const t = await q.selectFrom('cafe_tables').select(['id', 'branch_id', 'status', 'table_number']).where('cafe_id', '=', tenantId()).where('public_id', '=', publicId).where('deleted_at', 'is', null).executeTakeFirst();
    if (!t) throw notFound('TABLE_NOT_FOUND');
    assertBranchAllowed(t.branch_id);
    return t;
  }

  async update(publicId: string, d: { tableNumber?: string; capacity?: number; areaName?: string; status?: 'available' | 'occupied' | 'reserved' | 'cleaning' | 'inactive' }) {
    await this.db.tx(async (tx) => {
      const t = await this.table(tx, publicId);
      await tx.updateTable('cafe_tables').set({ table_number: d.tableNumber, capacity: d.capacity, area_name: d.areaName, status: d.status }).where('cafe_id', '=', tenantId()).where('id', '=', t.id).execute();
      await audit(tx, { action: 'table.updated', entityType: 'table', entityId: publicId, after: d });
      if (d.status) await emit(tx, { cafeId: tenantId(), branchId: t.branch_id, type: 'table.status_changed', rooms: staffRooms(tenantId(), t.branch_id), payload: { tableId: publicId, status: d.status } });
    });
    return { ok: true };
  }

  async remove(publicId: string) {
    await this.db.tx(async (tx) => {
      const t = await this.table(tx, publicId);
      if (await tx.selectFrom('table_sessions').select('id').where('cafe_id', '=', tenantId()).where('table_id', '=', t.id).where('status', '!=', 'closed').executeTakeFirst()) throw conflict('TABLE_HAS_OPEN_SESSION');
      await tx.updateTable('cafe_tables').set({ deleted_at: new Date(), status: 'inactive' }).where('cafe_id', '=', tenantId()).where('id', '=', t.id).execute();
      await tx.updateTable('table_qr_codes').set({ revoked_at: new Date(), revoked_by_user_id: actorUserId() }).where('cafe_id', '=', tenantId()).where('table_id', '=', t.id).where('revoked_at', 'is', null).execute();
      await audit(tx, { action: 'table.deleted', entityType: 'table', entityId: publicId });
    });
    return { ok: true };
  }

  private qrUrl(token: string) { return `${config.publicAppUrl}/t/${token}`; }

  async qr(publicId: string) {
    const t = await this.table(this.db.q, publicId);
    const row = await this.db.q.selectFrom('table_qr_codes').select(['token_ciphertext']).where('cafe_id', '=', tenantId()).where('table_id', '=', t.id).where('revoked_at', 'is', null).executeTakeFirst();
    if (!row) throw notFound('QR_NOT_FOUND');
    const url = this.qrUrl(decrypt(Buffer.from(row.token_ciphertext)));
    return { url, tableNumber: t.table_number, png: await QRCode.toDataURL(url, { errorCorrectionLevel: 'M', margin: 2, width: 600 }) };
  }

  async regenerateQr(publicId: string) {
    await this.db.tx(async (tx) => {
      const t = await this.table(tx, publicId);
      await tx.updateTable('table_qr_codes').set({ revoked_at: new Date(), revoked_by_user_id: actorUserId() }).where('cafe_id', '=', tenantId()).where('table_id', '=', t.id).where('revoked_at', 'is', null).execute();
      await this.issueQr(tx, t.id);
      await audit(tx, { action: 'table.qr_regenerated', entityType: 'table', entityId: publicId });
    });
    return this.qr(publicId);
  }

  // The tenant is derived from the token alone. No client-supplied cafe or branch is read.
  async resolveQr(token: string, lang?: string) {
    const row = await unscoped('token precedes tenant resolution', () =>
      this.db.q.selectFrom('table_qr_codes as q').innerJoin('cafe_tables as t', 't.id', 'q.table_id').innerJoin('cafes as c', 'c.id', 'q.cafe_id').innerJoin('cafe_branches as b', 'b.id', 't.branch_id')
        .select(['q.cafe_id', 'q.revoked_at', 't.id as table_id', 't.public_id as table_public_id', 't.table_number', 't.branch_id', 't.status as table_status', 'c.status as cafe_status', 'b.status as branch_status', 'b.public_id as branch_public_id', 'c.slug'])
        .where('q.token_hash', '=', sha256(token)).where('t.deleted_at', 'is', null).executeTakeFirst());
    if (!row || row.revoked_at) throw notFound('QR_INVALID');
    if (row.cafe_status !== 'active' || row.branch_status !== 'active' || row.table_status === 'inactive') throw new AppError(403, 'CAFE_UNAVAILABLE');

    return asTenant(row.cafe_id, async () => {
      const s = store()!;
      s.branchId = row.branch_id;
      const settings = await loadSettings(this.db.q);
      if (!settings.guestOrderingEnabled) throw new AppError(403, 'QR_ORDERING_DISABLED');
      const session = await this.db.tx(async (tx) => {
        const existing = await tx.selectFrom('table_sessions').select(['id', 'public_id', 'expires_at']).where('cafe_id', '=', row.cafe_id).where('table_id', '=', row.table_id).where('status', '!=', 'closed').forUpdate().executeTakeFirst();
        if (existing && existing.expires_at > new Date()) return { publicId: existing.public_id, token: sessionToken(existing.public_id) };
        if (existing) await tx.updateTable('table_sessions').set({ status: 'closed', closed_at: new Date() }).where('cafe_id', '=', row.cafe_id).where('id', '=', existing.id).execute();
        const publicId = ulid();
        const token = sessionToken(publicId);
        await tx.insertInto('table_sessions').values({ public_id: publicId, cafe_id: row.cafe_id, branch_id: row.branch_id, table_id: row.table_id, token_hash: sha256(token), expires_at: new Date(Date.now() + settings.sessionHours * 3600_000) }).execute();
        await tx.updateTable('cafe_tables').set({ status: 'occupied' }).where('cafe_id', '=', row.cafe_id).where('id', '=', row.table_id).execute();
        await emit(tx, { cafeId: row.cafe_id, branchId: row.branch_id, type: 'table.status_changed', rooms: staffRooms(row.cafe_id, row.branch_id), payload: { tableId: row.table_public_id, status: 'occupied' } });
        return { publicId, token };
      });
      return {
        table: { publicId: row.table_public_id, number: row.table_number }, branchId: row.branch_public_id, slug: row.slug,
        session: { publicId: session.publicId, token: session.token }, config: await this.tenancy.configFor(row.cafe_id, lang ?? currentLang()),
      };
    });
  }

  async closeSession(publicId: string) {
    await this.db.tx(async (tx) => {
      const s = await tx.selectFrom('table_sessions').select(['id', 'table_id', 'branch_id', 'status']).where('cafe_id', '=', tenantId()).where('public_id', '=', publicId).forUpdate().executeTakeFirst();
      if (!s) throw notFound();
      assertBranchAllowed(s.branch_id);
      const open = await tx.selectFrom('orders').select('id').where('cafe_id', '=', tenantId()).where('session_id', '=', s.id).where('status', '!=', 'cancelled').where('payment_status', 'in', ['unpaid', 'partially_paid']).executeTakeFirst();
      if (open) throw conflict('SESSION_HAS_UNPAID_ORDERS');
      await tx.updateTable('table_sessions').set({ status: 'closed', closed_at: new Date(), closed_by_user_id: requiredUserId() }).where('cafe_id', '=', tenantId()).where('id', '=', s.id).execute();
      await tx.updateTable('cafe_tables').set({ status: 'available' }).where('cafe_id', '=', tenantId()).where('id', '=', s.table_id).execute();
      await audit(tx, { action: 'table_session.closed', entityType: 'table_session', entityId: publicId });
      await emit(tx, { cafeId: tenantId(), branchId: s.branch_id, type: 'table.status_changed', rooms: staffRooms(tenantId(), s.branch_id), payload: { sessionId: publicId, status: 'available' } });
      await emit(tx, { cafeId: tenantId(), branchId: s.branch_id, type: 'session.closed', rooms: [rooms.session(publicId)], payload: { sessionId: publicId } });
    });
    return { ok: true };
  }

  async activeSessions() {
    let q = this.db.q.selectFrom('table_sessions as s').innerJoin('cafe_tables as t', 't.id', 's.table_id').select(['s.public_id', 's.status', 's.opened_at', 't.table_number', 't.public_id as table_id']).where('s.cafe_id', '=', tenantId()).where('s.status', '!=', 'closed');
    const allowed = store()?.principal?.branchIds;
    if (store()?.branchId) q = q.where('s.branch_id', '=', store()!.branchId!);
    else if (allowed) q = q.where('s.branch_id', 'in', allowed);
    return q.orderBy('t.table_number').execute();
  }

  // Merge another table into a session: its diners share one bill.
  async merge(sessionPublicId: string, tablePublicId: string) {
    await this.db.tx(async (tx) => {
      const s = await tx.selectFrom('table_sessions').select(['id', 'branch_id', 'table_id']).where('cafe_id', '=', tenantId()).where('public_id', '=', sessionPublicId).where('status', '!=', 'closed').forUpdate().executeTakeFirst();
      if (!s) throw notFound();
      const t = await this.table(tx, tablePublicId);
      if (t.branch_id !== s.branch_id) throw badRequest('TABLE_IN_OTHER_BRANCH');
      if (t.id === s.table_id) throw badRequest('TABLE_ALREADY_PRIMARY');
      await tx.insertInto('table_session_tables').values({ cafe_id: tenantId(), session_id: s.id, table_id: t.id, merged_by_user_id: requiredUserId() }).execute();
      await tx.updateTable('cafe_tables').set({ status: 'occupied' }).where('cafe_id', '=', tenantId()).where('id', '=', t.id).execute();
      await audit(tx, { action: 'table_session.merged', entityType: 'table_session', entityId: sessionPublicId, after: { table: tablePublicId } });
    });
    return { ok: true };
  }

  async transferOrder(orderPublicId: string, tablePublicId: string, reason: string) {
    await this.db.tx(async (tx) => {
      const o = await tx.selectFrom('orders').select(['id', 'branch_id', 'table_id', 'session_id', 'status']).where('cafe_id', '=', tenantId()).where('public_id', '=', orderPublicId).forUpdate().executeTakeFirst();
      if (!o) throw notFound('ORDER_NOT_FOUND');
      if (['completed', 'cancelled'].includes(o.status)) throw conflict('ORDER_NOT_EDITABLE');
      const t = await this.table(tx, tablePublicId);
      if (t.branch_id !== o.branch_id) throw badRequest('TABLE_IN_OTHER_BRANCH');
      let session = await tx.selectFrom('table_sessions').select('id').where('cafe_id', '=', tenantId()).where('table_id', '=', t.id).where('status', '!=', 'closed').executeTakeFirst();
      if (!session) {
        const pid = ulid();
        const id = Number((await tx.insertInto('table_sessions').values({ public_id: pid, cafe_id: tenantId(), branch_id: t.branch_id, table_id: t.id, token_hash: sha256(sessionToken(pid)), expires_at: new Date(Date.now() + 6 * 3600_000), opened_by_user_id: actorUserId() }).executeTakeFirstOrThrow()).insertId);
        session = { id };
        await tx.updateTable('cafe_tables').set({ status: 'occupied' }).where('cafe_id', '=', tenantId()).where('id', '=', t.id).execute();
      }
      await tx.updateTable('orders').set({ table_id: t.id, session_id: session.id }).where('cafe_id', '=', tenantId()).where('id', '=', o.id).execute();
      await tx.insertInto('order_modifications').values({
        cafe_id: tenantId(), order_id: o.id, modification_type: 'table_transferred', before_state: JSON.stringify({ tableId: o.table_id, sessionId: o.session_id }), after_state: JSON.stringify({ tableId: t.id, sessionId: session.id }), reason, modified_by_user_id: requiredUserId(), authorized_by_user_id: requiredUserId(),
      }).execute();
      await audit(tx, { action: 'order.table_transferred', entityType: 'order', entityId: orderPublicId, reason, after: { table: tablePublicId } });
    });
    return { ok: true };
  }

  // Service requests
  async createServiceRequest(type: 'waiter' | 'bill' | 'staff') {
    const s = store()!;
    const p = s.principal!;
    return this.db.tx(async (tx) => {
      const sess = await tx.selectFrom('table_sessions as ts').innerJoin('cafe_tables as t', 't.id', 'ts.table_id').select(['ts.id', 'ts.table_id', 'ts.branch_id', 't.table_number']).where('ts.cafe_id', '=', tenantId()).where('ts.id', '=', p.tableSessionId!).executeTakeFirstOrThrow();
      const open = await tx.selectFrom('service_requests').select('public_id').where('cafe_id', '=', tenantId()).where('session_id', '=', sess.id).where('request_type', '=', type).where('status', '=', 'open').executeTakeFirst();
      if (open) return { publicId: open.public_id, deduplicated: true };
      const publicId = ulid();
      await tx.insertInto('service_requests').values({ public_id: publicId, cafe_id: tenantId(), branch_id: sess.branch_id, table_id: sess.table_id, session_id: sess.id, request_type: type }).execute();
      await emit(tx, { cafeId: tenantId(), branchId: sess.branch_id, type: 'service_request.created', rooms: staffRooms(tenantId(), sess.branch_id), payload: { requestId: publicId, type, table: sess.table_number } });
      return { publicId, deduplicated: false };
    });
  }

  async listServiceRequests() {
    let q = this.db.q.selectFrom('service_requests as r').innerJoin('cafe_tables as t', 't.id', 'r.table_id').select(['r.public_id', 'r.request_type', 'r.status', 'r.created_at', 't.table_number']).where('r.cafe_id', '=', tenantId()).where('r.status', '!=', 'resolved');
    const allowed = store()?.principal?.branchIds;
    if (store()?.branchId) q = q.where('r.branch_id', '=', store()!.branchId!);
    else if (allowed) q = q.where('r.branch_id', 'in', allowed);
    return q.orderBy('r.created_at').execute();
  }

  async updateServiceRequest(publicId: string, status: 'acknowledged' | 'resolved') {
    const r = await this.db.q.updateTable('service_requests').set(status === 'acknowledged' ? { status, acknowledged_by_user_id: actorUserId(), acknowledged_at: new Date() } : { status, resolved_at: new Date() }).where('cafe_id', '=', tenantId()).where('public_id', '=', publicId).executeTakeFirst();
    if (!r.numUpdatedRows) throw notFound();
    return { ok: true };
  }

  // Reservations
  async listReservations(from?: string) {
    let q = this.db.q.selectFrom('reservations as r').leftJoin('cafe_tables as t', 't.id', 'r.table_id').select(['r.public_id', 'r.guest_name', 'r.guest_phone', 'r.party_size', 'r.starts_at', 'r.ends_at', 'r.status', 'r.notes', 't.table_number']).where('r.cafe_id', '=', tenantId());
    if (store()?.branchId) q = q.where('r.branch_id', '=', store()!.branchId!);
    if (from) q = q.where('r.starts_at', '>=', new Date(from));
    return q.orderBy('r.starts_at').limit(200).execute();
  }

  async createReservation(d: { guestName?: string; guestPhone?: string; partySize: number; startsAt: string; endsAt: string; notes?: string; tableId?: string }, branchId?: number, customerId?: number) {
    const branch = branchId ?? currentBranch();
    return this.db.tx(async (tx) => {
      const tableId = d.tableId ? (await this.table(tx, d.tableId)).id : null;
      if (tableId) {
        const clash = await tx.selectFrom('reservations').select('id').where('cafe_id', '=', tenantId()).where('table_id', '=', tableId).where('status', 'in', ['requested', 'confirmed', 'seated'])
          .where('starts_at', '<', new Date(d.endsAt)).where('ends_at', '>', new Date(d.startsAt)).executeTakeFirst();
        if (clash) throw conflict('TABLE_ALREADY_RESERVED');
      }
      if (customerId) await tx.insertInto('cafe_customers').values({ public_id: ulid(), cafe_id: tenantId(), customer_id: customerId }).onDuplicateKeyUpdate({ customer_id: customerId }).execute();
      const publicId = ulid();
      await tx.insertInto('reservations').values({ public_id: publicId, cafe_id: tenantId(), branch_id: branch, table_id: tableId, customer_id: customerId ?? null, guest_name: d.guestName ?? null, guest_phone: d.guestPhone ?? null, party_size: d.partySize, starts_at: new Date(d.startsAt), ends_at: new Date(d.endsAt), notes: d.notes ?? null, created_by_user_id: actorUserId() }).execute();
      await emit(tx, { cafeId: tenantId(), branchId: branch, type: 'reservation.created', rooms: staffRooms(tenantId(), branch), payload: { reservationId: publicId, startsAt: d.startsAt, partySize: d.partySize } });
      return { publicId };
    });
  }

  async updateReservation(publicId: string, status: 'confirmed' | 'seated' | 'completed' | 'cancelled' | 'no_show') {
    const r = await this.db.q.updateTable('reservations').set({ status }).where('cafe_id', '=', tenantId()).where('public_id', '=', publicId).executeTakeFirst();
    if (!r.numUpdatedRows) throw notFound();
    return { ok: true };
  }
}
