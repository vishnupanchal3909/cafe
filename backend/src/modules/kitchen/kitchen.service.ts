import { Injectable } from '@nestjs/common';
import { principal, tenantId } from '../../common/context';
import { conflict, notFound } from '../../common/errors';
import { ulid } from '../../common/ids';
import { assertBranchAllowed, currentBranch, idOf } from '../../common/lookup';
import { audit, Db, emit, rooms, staffRooms, Tx } from '../../infra/db/db.service';
import { OrderingService } from '../ordering/ordering.service';

const TICKET_FLOW: Record<string, string[]> = { new: ['accepted', 'cancelled'], accepted: ['preparing', 'ready', 'cancelled'], preparing: ['ready', 'cancelled'], ready: ['completed'], completed: [], cancelled: [] };

@Injectable()
export class KitchenService {
  constructor(private readonly db: Db, private readonly ordering: OrderingService) {}

  // Kitchen staff need to pick their branch, but hold no cafe-profile permission.
  async branches() {
    let q = this.db.q.selectFrom('cafe_branches').select(['public_id', 'name']).where('cafe_id', '=', tenantId()).where('deleted_at', 'is', null).where('status', '=', 'active');
    const allowed = principal().branchIds;
    if (allowed) q = q.where('id', 'in', allowed.length ? allowed : [0]);
    return q.orderBy('is_main', 'desc').execute();
  }

  async stations() {
    return this.db.q.selectFrom('kitchen_stations').select(['public_id', 'name', 'delay_threshold_minutes', 'is_active']).where('cafe_id', '=', tenantId()).where('branch_id', '=', currentBranch()).orderBy('name').execute();
  }
  async createStation(d: { name: string; delayThresholdMinutes?: number }) {
    const publicId = ulid();
    await this.db.q.insertInto('kitchen_stations').values({ public_id: publicId, cafe_id: tenantId(), branch_id: currentBranch(), name: d.name, delay_threshold_minutes: d.delayThresholdMinutes }).execute();
    return { publicId };
  }
  async updateStation(publicId: string, d: { name?: string; delayThresholdMinutes?: number; isActive?: boolean }) {
    const r = await this.db.q.updateTable('kitchen_stations').set({ name: d.name, delay_threshold_minutes: d.delayThresholdMinutes, is_active: d.isActive === undefined ? undefined : d.isActive ? 1 : 0 }).where('cafe_id', '=', tenantId()).where('public_id', '=', publicId).executeTakeFirst();
    if (!r.numUpdatedRows) throw notFound();
    return { ok: true };
  }
  async routeProduct(productPublicId: string, stationPublicId: string | null) {
    const branch = currentBranch();
    const product = await idOf(this.db.q, 'products', productPublicId);
    if (!stationPublicId) {
      await this.db.q.deleteFrom('product_station_routes').where('cafe_id', '=', tenantId()).where('branch_id', '=', branch).where('product_id', '=', product).execute();
      return { ok: true };
    }
    const station = await idOf(this.db.q, 'kitchen_stations', stationPublicId);
    await this.db.q.insertInto('product_station_routes').values({ cafe_id: tenantId(), branch_id: branch, product_id: product, station_id: station }).onDuplicateKeyUpdate({ station_id: station }).execute();
    return { ok: true };
  }

  async tickets(query: { status?: string; station?: string }) {
    const branch = currentBranch();
    const statuses = (query.status ?? 'new,accepted,preparing,ready').split(',') as Array<'new'>;
    let q = this.db.q.selectFrom('kitchen_orders as k').innerJoin('orders as o', 'o.id', 'k.order_id').leftJoin('cafe_tables as t', 't.id', 'o.table_id').leftJoin('kitchen_stations as s', 's.id', 'k.station_id')
      .select(['k.id', 'k.public_id', 'k.status', 'k.priority', 'k.created_at', 'k.accepted_at', 'k.started_at', 'k.ready_at', 'o.public_id as order_id', 'o.order_number', 'o.order_type', 'o.customer_notes', 'o.language_code', 't.table_number', 's.public_id as station_id', 's.name as station_name', 's.delay_threshold_minutes'])
      .where('k.cafe_id', '=', tenantId()).where('k.branch_id', '=', branch).where('k.status', 'in', statuses);
    if (query.station) q = q.where('s.public_id', '=', query.station);
    const tickets = await q.orderBy('k.priority', 'desc').orderBy('k.created_at').limit(200).execute();
    if (!tickets.length) return [];
    const items = await this.db.q.selectFrom('kitchen_order_items as ki').innerJoin('order_items as i', 'i.id', 'ki.order_item_id')
      .select(['ki.id', 'ki.kitchen_order_id', 'ki.status', 'i.id as order_item_id', 'i.name_snapshot', 'i.variant_name_snapshot', 'i.quantity', 'i.notes']).where('ki.cafe_id', '=', tenantId()).where('ki.kitchen_order_id', 'in', tickets.map((t) => t.id)).where('ki.status', '!=', 'cancelled').execute();
    const addons = items.length ? await this.db.q.selectFrom('order_item_addons').select(['order_item_id', 'name_snapshot', 'quantity']).where('cafe_id', '=', tenantId()).where('order_item_id', 'in', items.map((i) => i.order_item_id)).execute() : [];
    const now = Date.now();
    return tickets.map(({ id, delay_threshold_minutes, ...t }) => {
      const elapsedMinutes = Math.floor((now - t.created_at.getTime()) / 60000);
      return {
        ...t, elapsedMinutes, isDelayed: !['ready', 'completed'].includes(t.status) && elapsedMinutes >= (delay_threshold_minutes ?? 15),
        items: items.filter((i) => i.kitchen_order_id === id).map((i) => ({ id: i.id, status: i.status, name: i.name_snapshot, variant: i.variant_name_snapshot, quantity: i.quantity, notes: i.notes, addons: addons.filter((a) => a.order_item_id === i.order_item_id).map((a) => ({ name: a.name_snapshot, quantity: a.quantity })) })),
      };
    });
  }

  private async loadTicket(tx: Tx, publicId: string) {
    const t = await tx.selectFrom('kitchen_orders').selectAll().where('cafe_id', '=', tenantId()).where('public_id', '=', publicId).forUpdate().executeTakeFirst();
    if (!t) throw notFound('TICKET_NOT_FOUND');
    assertBranchAllowed(t.branch_id);
    return t;
  }

  // The order's status is rolled up from its tickets: first accept, first start, and all ready.
  async setStatus(publicId: string, to: 'accepted' | 'preparing' | 'ready' | 'completed') {
    await this.db.tx(async (tx) => {
      const t = await this.loadTicket(tx, publicId);
      if (t.status === to) return;
      if (!TICKET_FLOW[t.status]!.includes(to)) throw conflict('TICKET_ILLEGAL_TRANSITION', { from: t.status, to });
      const now = new Date();
      await tx.updateTable('kitchen_orders').set({
        status: to, accepted_at: to === 'accepted' ? now : t.accepted_at, started_at: to === 'preparing' ? now : t.started_at, ready_at: to === 'ready' ? now : t.ready_at, completed_at: to === 'completed' ? now : t.completed_at,
      }).where('cafe_id', '=', tenantId()).where('id', '=', t.id).execute();
      if (to === 'ready') await tx.updateTable('kitchen_order_items').set({ status: 'ready', ready_at: now }).where('cafe_id', '=', tenantId()).where('kitchen_order_id', '=', t.id).where('status', '!=', 'cancelled').execute();
      if (to === 'preparing') await tx.updateTable('kitchen_order_items').set({ status: 'preparing' }).where('cafe_id', '=', tenantId()).where('kitchen_order_id', '=', t.id).where('status', '=', 'new').execute();

      const order = await tx.selectFrom('orders').select(['id', 'status', 'public_id']).where('cafe_id', '=', tenantId()).where('id', '=', t.order_id).executeTakeFirstOrThrow();
      if (to === 'accepted' && order.status === 'placed') await this.ordering.transition(tx, order.id, 'accepted');
      if (to === 'preparing') {
        if (order.status === 'placed') await this.ordering.transition(tx, order.id, 'accepted');
        if (['placed', 'accepted'].includes(order.status)) await this.ordering.transition(tx, order.id, 'preparing');
      }
      if (to === 'ready') {
        const others = await tx.selectFrom('kitchen_orders').select('status').where('cafe_id', '=', tenantId()).where('order_id', '=', order.id).where('status', '!=', 'cancelled').execute();
        if (others.every((o) => ['ready', 'completed'].includes(o.status))) {
          if (order.status === 'placed') await this.ordering.transition(tx, order.id, 'accepted');
          await this.ordering.transition(tx, order.id, 'ready');
        }
      }
      await emit(tx, { cafeId: tenantId(), branchId: t.branch_id, type: 'kitchen.ticket_updated', rooms: [rooms.branch(tenantId(), t.branch_id, 'kitchen'), ...staffRooms(tenantId(), t.branch_id)], payload: { ticketId: publicId, status: to, orderId: order.public_id } });
      await audit(tx, { action: `kitchen.${to}`, entityType: 'kitchen_order', entityId: publicId, branchId: t.branch_id });
    });
    return { ok: true };
  }

  async prioritize(publicId: string, priority: number) {
    await this.db.tx(async (tx) => {
      const t = await this.loadTicket(tx, publicId);
      await tx.updateTable('kitchen_orders').set({ priority }).where('cafe_id', '=', tenantId()).where('id', '=', t.id).execute();
      await emit(tx, { cafeId: tenantId(), branchId: t.branch_id, type: 'kitchen.ticket_updated', rooms: [rooms.branch(tenantId(), t.branch_id, 'kitchen')], payload: { ticketId: publicId, priority } });
    });
    return { ok: true };
  }

}
