import { type Tx, emit, staffRooms } from '../../infra/db/db.service';
import { loadSettings } from '../tenancy/settings';

/** Orders at this table that still owe money. A table is never freed while any exist. */
export async function unpaidOrderAtTable(tx: Tx, cafeId: number, tableId: number, sessionId: number | null) {
  let q = tx.selectFrom('orders').select('id').where('cafe_id', '=', cafeId).where('status', '!=', 'cancelled').where('payment_status', 'in', ['unpaid', 'partially_paid']);
  q = sessionId ? q.where('session_id', '=', sessionId) : q.where('table_id', '=', tableId);
  return q.executeTakeFirst();
}

/**
 * Marks the table available once nothing on it is owed. The paying guests' session stays open for the cafe's chosen
 * number of minutes so they can follow their order; the next scan of the QR starts a fresh session for the next party.
 */
export async function releaseTableIfSettled(tx: Tx, cafeId: number, branchId: number, tableId: number | null, sessionId: number | null) {
  if (!tableId) return false;
  if (await unpaidOrderAtTable(tx, cafeId, tableId, sessionId)) return false;
  const t = await tx.selectFrom('cafe_tables').select(['public_id', 'status']).where('cafe_id', '=', cafeId).where('id', '=', tableId).forUpdate().executeTakeFirst();
  if (!t || t.status !== 'occupied') return false;
  await tx.updateTable('cafe_tables').set({ status: 'available' }).where('cafe_id', '=', cafeId).where('id', '=', tableId).execute();
  // The guests who paid keep their session a little while to follow their order, then it ends, so they cannot order from elsewhere.
  if (sessionId) {
    const end = new Date(Date.now() + (await loadSettings(tx)).sessionEndAfterPaymentMinutes * 60_000);
    await tx.updateTable('table_sessions').set({ expires_at: end }).where('cafe_id', '=', cafeId).where('id', '=', sessionId).where('expires_at', '>', end).execute();
  }
  await emit(tx, { cafeId, branchId, type: 'table.status_changed', rooms: staffRooms(cafeId, branchId), payload: { tableId: t.public_id, status: 'available' } });
  return true;
}
