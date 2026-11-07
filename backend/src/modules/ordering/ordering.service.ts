import { Injectable } from '@nestjs/common';
import { createHash } from 'node:crypto';
import { sql } from 'kysely';
import { actorUserId, currentLang, requiredUserId, store, tenantId, unscoped } from '../../common/context';
import { AppError, badRequest, conflict, forbidden, notFound } from '../../common/errors';
import { paged, requirePage } from '../../common/http';
import { ulid } from '../../common/ids';
import { assertBranchAllowed, currentBranch, idOf } from '../../common/lookup';
import { D, Decimal, dbMoney, money, ZERO } from '../../common/money';
import { audit, Db, emit, rooms, staffRooms, Tx } from '../../infra/db/db.service';
import { InventoryService } from '../inventory/inventory.service';
import { loadSettings, pickTranslation } from '../tenancy/settings';
import { EntitlementService } from '../subscriptions/entitlement.service';
import { validPinProof } from '../tables/pin';
import { businessDate, LineInput, localClock, priceOrder } from './pricing';

export interface OrderItemInput { productId: string; variantId?: string; quantity: number; addons?: Array<{ addonId: string; quantity?: number }>; notes?: string }
export interface PlaceOrderInput { items: OrderItemInput[]; notes?: string; couponCode?: string; language?: string; orderType?: 'dine_in' | 'takeaway' | 'delivery'; tableId?: string; redeemPoints?: number; deliveryAddress?: Record<string, unknown> }

export type OrderStatus = 'pending_payment' | 'placed' | 'accepted' | 'preparing' | 'ready' | 'served' | 'completed' | 'cancelled';
const TRANSITIONS: Record<OrderStatus, OrderStatus[]> = {
  pending_payment: ['placed', 'cancelled'], placed: ['accepted', 'cancelled'], accepted: ['preparing', 'ready', 'cancelled'], preparing: ['ready', 'cancelled'],
  ready: ['served', 'completed', 'cancelled'], served: ['completed'], completed: [], cancelled: [],
};

@Injectable()
export class OrderingService {
  constructor(private readonly db: Db, private readonly inventory: InventoryService, private readonly entitlements: EntitlementService) {}

  async withIdempotency<T>(tx: Tx, key: string | undefined, body: unknown, fn: () => Promise<T>): Promise<T> {
    if (!key) return fn();
    const s = store()!;
    const scope = s.principal?.type === 'user' ? `u:${s.principal.id}` : s.principal?.tableSessionId ? `ts:${s.principal.tableSessionId}` : `c:${s.principal?.id}`;
    const hash = createHash('sha256').update(JSON.stringify(body)).digest('hex');
    const inserted = await tx.insertInto('idempotency_keys').ignore().values({ cafe_id: s.cafeId ?? null, principal: scope, idempotency_key: key, request_hash: hash, expires_at: new Date(Date.now() + 86400_000) }).executeTakeFirst();
    if (!Number(inserted.numInsertedOrUpdatedRows)) {
      const prior = await tx.selectFrom('idempotency_keys').select(['request_hash', 'response_body']).where('principal', '=', scope).where('idempotency_key', '=', key).executeTakeFirstOrThrow();
      if (prior.request_hash !== hash) throw conflict('IDEMPOTENCY_KEY_REUSED');
      if (prior.response_body === null) throw conflict('REQUEST_IN_PROGRESS');
      return prior.response_body as T;
    }
    const result = await fn();
    await tx.updateTable('idempotency_keys').set({ response_body: JSON.stringify(result), response_status: 201 }).where('principal', '=', scope).where('idempotency_key', '=', key).execute();
    return result;
  }

  async place(input: PlaceOrderInput, idempotencyKey?: string, pinProof?: string) {
    if (!input.items.length) throw badRequest('ORDER_EMPTY');
    const s = store()!;
    const p = s.principal!;
    const isGuestPath = p.type === 'table_session';
    return this.db.tx((tx) => this.withIdempotency(tx, idempotencyKey, input, async () => {
      const cafeId = tenantId();
      const cafe = await tx.selectFrom('cafes as c').innerJoin('currencies as m', 'm.code', 'c.currency_code').select(['c.status', 'c.timezone', 'c.currency_code', 'c.default_language_code', 'm.minor_unit']).where('c.id', '=', cafeId).executeTakeFirstOrThrow();
      if (cafe.status !== 'active') throw new AppError(403, 'CAFE_UNAVAILABLE');
      await this.entitlements.assertWithinLimit(tx, 'monthly_orders', 1);

      let branchId: number;
      let tableId: number | null = null;
      let sessionId: number | null = null;
      if (isGuestPath) {
        const sess = await tx.selectFrom('table_sessions').select(['id', 'public_id', 'branch_id', 'table_id', 'status', 'pin_ciphertext']).where('cafe_id', '=', cafeId).where('id', '=', p.tableSessionId!).forUpdate().executeTakeFirstOrThrow();
        if (sess.status !== 'open') throw new AppError(410, 'TABLE_SESSION_ENDED');
        // A photo of the QR is not enough when the cafe asks for the table PIN.
        if (sess.pin_ciphertext && (await loadSettings(tx)).tablePinRequired && !validPinProof(sess.public_id, pinProof)) throw new AppError(403, 'TABLE_PIN_REQUIRED');
        ({ branch_id: branchId, table_id: tableId, id: sessionId } = sess);
      } else {
        branchId = currentBranch();
        if (input.tableId) {
          const t = await tx.selectFrom('cafe_tables').select(['id', 'branch_id']).where('cafe_id', '=', cafeId).where('public_id', '=', input.tableId).where('deleted_at', 'is', null).executeTakeFirst();
          if (!t || t.branch_id !== branchId) throw notFound('TABLE_NOT_FOUND');
          tableId = t.id;
          const open = await tx.selectFrom('table_sessions').select('id').where('cafe_id', '=', cafeId).where('table_id', '=', t.id).where('status', '!=', 'closed').executeTakeFirst();
          sessionId = open?.id ?? null;
        }
      }
      // A new order on a table freed after payment, e.g. the same guests ordering dessert, takes it again.
      if (tableId) {
        const back = await tx.updateTable('cafe_tables').set({ status: 'occupied' }).where('cafe_id', '=', cafeId).where('id', '=', tableId).where('status', '=', 'available').executeTakeFirst();
        if (Number(back.numUpdatedRows)) {
          await emit(tx, { cafeId, branchId, type: 'table.status_changed', rooms: staffRooms(cafeId, branchId), payload: { status: 'occupied' } });
          // Their session was set to end soon after paying; ordering again gives it the cafe's full length back.
          if (sessionId) await tx.updateTable('table_sessions').set({ expires_at: new Date(Date.now() + (await loadSettings(tx)).sessionHours * 3600_000) }).where('cafe_id', '=', cafeId).where('id', '=', sessionId).execute();
        }
      }
      const branch = await tx.selectFrom('cafe_branches').select(['timezone', 'business_day_cutoff', 'status', 'code', 'state_code']).where('cafe_id', '=', cafeId).where('id', '=', branchId).executeTakeFirstOrThrow();
      if (branch.status !== 'active') throw new AppError(403, 'BRANCH_UNAVAILABLE');
      const timezone = branch.timezone ?? cafe.timezone;
      const now = new Date();
      const date = businessDate(now, timezone, branch.business_day_cutoff);
      const clock = localClock(now, timezone);
      const settings = await loadSettings(tx);
      const destination = input.orderType === 'delivery' ? (input.deliveryAddress?.stateCode as string | undefined) : undefined;
      const interRegion = !!destination && !!branch.state_code && destination !== branch.state_code;

      // Everything priced below is read from the database, inside this transaction.
      const productIds = [...new Set(input.items.map((i) => i.productId))];
      const products = await tx.selectFrom('products').selectAll().where('cafe_id', '=', cafeId).where('public_id', 'in', productIds).where('deleted_at', 'is', null).execute();
      if (products.length !== productIds.length) throw notFound('PRODUCT_NOT_FOUND');
      const dbIds = products.map((x) => x.id);
      const [translations, variants, variantTr, overrides, schedules, links, addonRows, addonGroups, addonTr, rates, promos, promoTargets] = await Promise.all([
        tx.selectFrom('product_translations').selectAll().where('cafe_id', '=', cafeId).where('product_id', 'in', dbIds).execute(),
        tx.selectFrom('product_variants').selectAll().where('cafe_id', '=', cafeId).where('product_id', 'in', dbIds).where('deleted_at', 'is', null).where('is_active', '=', 1).execute(),
        tx.selectFrom('product_variant_translations as t').innerJoin('product_variants as v', 'v.id', 't.variant_id').select(['t.variant_id', 't.language_code', 't.name']).where('t.cafe_id', '=', cafeId).where('v.product_id', 'in', dbIds).execute(),
        tx.selectFrom('branch_product_overrides').selectAll().where('cafe_id', '=', cafeId).where('branch_id', '=', branchId).where('product_id', 'in', dbIds).execute(),
        tx.selectFrom('product_availability_schedules').selectAll().where('cafe_id', '=', cafeId).where('product_id', 'in', dbIds).execute(),
        tx.selectFrom('product_addon_groups').selectAll().where('cafe_id', '=', cafeId).where('product_id', 'in', dbIds).execute(),
        tx.selectFrom('product_addons').selectAll().where('cafe_id', '=', cafeId).where('deleted_at', 'is', null).where('is_active', '=', 1).execute(),
        tx.selectFrom('addon_groups').selectAll().where('cafe_id', '=', cafeId).where('deleted_at', 'is', null).execute(),
        tx.selectFrom('product_addon_translations').selectAll().where('cafe_id', '=', cafeId).execute(),
        tx.selectFrom('tax_rates').selectAll().where('cafe_id', '=', cafeId).where('valid_from', '<=', new Date(date)).where((eb) => eb.or([eb('valid_to', 'is', null), eb('valid_to', '>', new Date(date))])).where('applies_to', 'in', interRegion ? ['always', 'inter_region'] : ['always', 'intra_region']).execute(),
        tx.selectFrom('promotions').selectAll().where('cafe_id', '=', cafeId).where('is_active', '=', 1).where('deleted_at', 'is', null).where((eb) => eb.or([eb('starts_at', 'is', null), eb('starts_at', '<=', now)])).where((eb) => eb.or([eb('ends_at', 'is', null), eb('ends_at', '>=', now)])).orderBy('priority', 'desc').execute(),
        tx.selectFrom('promotion_targets').selectAll().where('cafe_id', '=', cafeId).execute(),
      ]);
      const lang = input.language ?? currentLang();
      const fallback = cafe.default_language_code;

      const built = input.items.map((item) => {
        if (!Number.isInteger(item.quantity) || item.quantity < 1 || item.quantity > 999) throw badRequest('QUANTITY_INVALID');
        const prod = products.find((x) => x.public_id === item.productId)!;
        const override = overrides.find((o) => o.product_id === prod.id && o.variant_id === null);
        if (!prod.is_active || prod.is_out_of_stock || override?.is_available === 0) throw conflict('PRODUCT_UNAVAILABLE', { productId: item.productId });
        const windows = schedules.filter((w) => w.product_id === prod.id);
        if (windows.length && !windows.some((w) => (w.weekday === null || w.weekday === clock.weekday) && w.starts_at <= clock.time && clock.time <= w.ends_at)) throw conflict('PRODUCT_NOT_AVAILABLE_NOW', { productId: item.productId });

        const productVariants = variants.filter((v) => v.product_id === prod.id);
        const variant = item.variantId ? productVariants.find((v) => v.public_id === item.variantId) : undefined;
        if (item.variantId && !variant) throw notFound('VARIANT_NOT_FOUND');
        if (!item.variantId && productVariants.length) throw badRequest('VARIANT_REQUIRED', { productId: item.productId });
        const unitPrice = variant ? (overrides.find((o) => o.variant_id === variant.id)?.price_override ?? variant.price) : (override?.price_override ?? prod.base_price);

        const myGroups = links.filter((l) => l.product_id === prod.id).map((l) => addonGroups.find((g) => g.id === l.addon_group_id)!).filter(Boolean);
        const chosen = (item.addons ?? []).map((a) => {
          const row = addonRows.find((r) => r.public_id === a.addonId && myGroups.some((g) => g.id === r.addon_group_id));
          if (!row) throw notFound('ADDON_NOT_FOUND', );
          return { row, quantity: a.quantity ?? 1 };
        });
        for (const g of myGroups) {
          const n = chosen.filter((c) => c.row.addon_group_id === g.id).reduce((acc, c) => acc + c.quantity, 0);
          if (n < g.min_select || (g.max_select !== null && n > g.max_select)) throw badRequest('ADDON_SELECTION_INVALID', { group: g.public_id, min: g.min_select, max: g.max_select });
        }
        const addonsPerUnit = chosen.reduce((acc, c) => acc.plus(D(c.row.price).times(c.quantity)), ZERO);

        const promo = promos.find((pr) => promoTargets.some((t) => t.promotion_id === pr.id && (t.product_id === prod.id || t.category_id === prod.category_id)));
        const unit = D(unitPrice).plus(addonsPerUnit);
        const lineDiscount = !promo ? ZERO : promo.discount_type === 'percent' ? unit.times(item.quantity).times(promo.percent_value!).div(100).toDecimalPlaces(cafe.minor_unit) : Decimal.min(D(promo.fixed_amount!).times(item.quantity), unit.times(item.quantity));

        const productRates = prod.tax_category_id ? rates.filter((r) => r.tax_category_id === prod.tax_category_id) : [];
        return {
          item, prod, variant, chosen, unitPrice,
          line: { unitPrice, addonsPerUnit: addonsPerUnit.toString(), quantity: item.quantity, lineDiscount: lineDiscount.toString(), taxes: productRates.map((r) => ({ code: r.component_code, name: r.display_name, ratePercent: r.rate_percent })) } as LineInput,
        };
      });

      const customerId = p.type === 'customer' || (isGuestPath && p.id) ? p.id : null;
      if (customerId) await tx.insertInto('cafe_customers').values({ public_id: ulid(), cafe_id: cafeId, customer_id: customerId, first_order_at: now }).onDuplicateKeyUpdate({ customer_id: customerId }).execute();

      // Coupon: the row lock makes the redemption limit safe under concurrency.
      const provisional = priceOrder(built.map((b) => b.line), { minorUnit: cafe.minor_unit, pricesIncludeTax: !!settings.pricesIncludeTax, taxRounding: settings.taxRounding });
      let orderDiscount = ZERO;
      let couponId: number | null = null;
      const base = provisional.subtotal.minus(provisional.discount);
      if (input.couponCode) {
        const c = await tx.selectFrom('coupons').selectAll().where('cafe_id', '=', cafeId).where('code', '=', input.couponCode).where('deleted_at', 'is', null).where('is_active', '=', 1).forUpdate().executeTakeFirst();
        if (!c || (c.starts_at && c.starts_at > now) || (c.ends_at && c.ends_at < now)) throw badRequest('COUPON_INVALID');
        if (c.max_redemptions !== null && c.redemption_count >= c.max_redemptions) throw conflict('COUPON_EXHAUSTED');
        if (base.lt(c.min_order_amount)) throw badRequest('COUPON_MIN_ORDER', { minOrder: c.min_order_amount });
        if (c.max_per_customer !== null) {
          if (!customerId) throw badRequest('COUPON_REQUIRES_LOGIN');
          const used = await tx.selectFrom('coupon_redemptions').select((eb) => eb.fn.countAll<number>().as('n')).where('cafe_id', '=', cafeId).where('coupon_id', '=', c.id).where('customer_id', '=', customerId).executeTakeFirstOrThrow();
          if (Number(used.n) >= c.max_per_customer) throw conflict('COUPON_ALREADY_USED');
        }
        orderDiscount = c.discount_type === 'percent' ? base.times(c.percent_value!).div(100) : D(c.fixed_amount!);
        if (c.max_discount_amount) orderDiscount = Decimal.min(orderDiscount, c.max_discount_amount);
        orderDiscount = Decimal.min(orderDiscount, base);
        couponId = c.id;
      }

      let pointsUsed = 0;
      if (input.redeemPoints) {
        if (!customerId) throw badRequest('LOYALTY_REQUIRES_LOGIN');
        const program = await tx.selectFrom('loyalty_programs').selectAll().where('cafe_id', '=', cafeId).where('is_active', '=', 1).executeTakeFirst();
        if (!program) throw badRequest('LOYALTY_NOT_ACTIVE');
        const acct = await tx.selectFrom('customer_loyalty_points').selectAll().where('cafe_id', '=', cafeId).where('customer_id', '=', customerId).forUpdate().executeTakeFirst();
        if (!acct || acct.balance_points < input.redeemPoints || input.redeemPoints < program.min_redeem_points) throw badRequest('LOYALTY_INSUFFICIENT_POINTS');
        orderDiscount = Decimal.min(orderDiscount.plus(D(program.currency_value_per_point).times(input.redeemPoints)), base);
        pointsUsed = input.redeemPoints;
      }

      const priced = priceOrder(built.map((b) => b.line), {
        minorUnit: cafe.minor_unit, pricesIncludeTax: !!settings.pricesIncludeTax, taxRounding: settings.taxRounding, orderDiscount, serviceChargePercent: settings.serviceChargePercent,
      });

      await tx.insertInto('order_sequences').values({ cafe_id: cafeId, branch_id: branchId, business_date: new Date(date), last_number: 0 }).onDuplicateKeyUpdate({ cafe_id: cafeId }).execute();
      const seq = await tx.selectFrom('order_sequences').select('last_number').where('cafe_id', '=', cafeId).where('branch_id', '=', branchId).where('business_date', '=', new Date(date)).forUpdate().executeTakeFirstOrThrow();
      const orderNumber = seq.last_number + 1;
      await tx.updateTable('order_sequences').set({ last_number: orderNumber }).where('cafe_id', '=', cafeId).where('branch_id', '=', branchId).where('business_date', '=', new Date(date)).execute();

      const prepay = isGuestPath && settings.paymentPolicy === 'prepay';
      const status: OrderStatus = prepay ? 'pending_payment' : 'placed';
      const publicId = ulid();
      const orderId = Number((await tx.insertInto('orders').values({
        public_id: publicId, cafe_id: cafeId, branch_id: branchId, order_number: orderNumber, business_date: new Date(date), order_source: isGuestPath ? 'qr' : p.type === 'customer' ? 'customer_app' : 'staff',
        order_type: input.orderType ?? 'dine_in', table_id: tableId, session_id: sessionId, customer_id: customerId, placed_by_user_id: actorUserId(), status, language_code: lang, currency_code: cafe.currency_code,
        prices_include_tax: settings.pricesIncludeTax ? 1 : 0, subtotal_amount: dbMoney(priced.subtotal), discount_amount: dbMoney(priced.discount), tax_amount: dbMoney(priced.tax), service_charge_amount: dbMoney(priced.serviceCharge), total_amount: dbMoney(priced.total),
        customer_notes: input.notes ?? null, delivery_address_snapshot: input.deliveryAddress ? JSON.stringify(input.deliveryAddress) : null, placed_at: now,
      }).executeTakeFirstOrThrow()).insertId);

      for (const [i, b] of built.entries()) {
        const pl = priced.lines[i]!;
        const trs = translations.filter((t) => t.product_id === b.prod.id);
        const shown = pickTranslation(trs, lang, fallback);
        const vTrs = b.variant ? variantTr.filter((t) => t.variant_id === b.variant!.id) : [];
        const itemId = Number((await tx.insertInto('order_items').values({
          cafe_id: cafeId, order_id: orderId, product_id: b.prod.id, variant_id: b.variant?.id ?? null, tax_category_id: b.prod.tax_category_id, name_snapshot: shown?.name ?? '', variant_name_snapshot: pickTranslation(vTrs, lang, fallback)?.name ?? null,
          name_translations: JSON.stringify(Object.fromEntries(trs.map((t) => [t.language_code, t.name]))), quantity: b.item.quantity, unit_price: dbMoney(b.unitPrice), addons_amount: dbMoney(D(b.line.addonsPerUnit).times(b.item.quantity)),
          discount_amount: dbMoney(pl.discount), tax_amount: dbMoney(pl.tax), line_total_amount: dbMoney(pl.total), notes: b.item.notes ?? null,
        }).executeTakeFirstOrThrow()).insertId);
        for (const c of b.chosen) {
          const aTrs = addonTr.filter((t) => t.addon_id === c.row.id);
          await tx.insertInto('order_item_addons').values({ cafe_id: cafeId, order_item_id: itemId, addon_id: c.row.id, name_snapshot: pickTranslation(aTrs, lang, fallback)?.name ?? '', name_translations: JSON.stringify(Object.fromEntries(aTrs.map((t) => [t.language_code, t.name]))), quantity: c.quantity, unit_price: dbMoney(c.row.price) }).execute();
        }
        for (const t of pl.taxes) await tx.insertInto('order_item_taxes').values({ cafe_id: cafeId, order_item_id: itemId, component_code: t.code, display_name: t.name, rate_percent: t.ratePercent, taxable_amount: dbMoney(t.taxable), tax_amount: dbMoney(t.amount) }).execute();
      }

      if (couponId) {
        await tx.updateTable('coupons').set((eb) => ({ redemption_count: eb('redemption_count', '+', 1) })).where('cafe_id', '=', cafeId).where('id', '=', couponId).execute();
        await tx.insertInto('coupon_redemptions').values({ cafe_id: cafeId, coupon_id: couponId, order_id: orderId, customer_id: customerId, currency_code: cafe.currency_code, discount_amount: dbMoney(orderDiscount) }).execute();
      }
      if (pointsUsed && customerId) {
        await tx.updateTable('customer_loyalty_points').set((eb) => ({ balance_points: eb('balance_points', '-', pointsUsed) })).where('cafe_id', '=', cafeId).where('customer_id', '=', customerId).execute();
        await tx.insertInto('loyalty_ledger').values({ cafe_id: cafeId, customer_id: customerId, entry_type: 'redeem', points: -pointsUsed, order_id: orderId }).execute();
      }
      if (customerId) await tx.updateTable('cafe_customers').set((eb) => ({ total_orders: eb('total_orders', '+', 1), last_order_at: now })).where('cafe_id', '=', cafeId).where('customer_id', '=', customerId).execute();

      await tx.insertInto('order_status_history').values({ cafe_id: cafeId, order_id: orderId, to_status: status, changed_by_user_id: actorUserId() }).execute();
      await this.entitlements.incrementUsage(tx, 'monthly_orders');
      if (status === 'placed') await this.dispatchToKitchen(tx, orderId, publicId, branchId, orderNumber);
      await audit(tx, { action: 'order.placed', entityType: 'order', entityId: publicId, branchId, after: { total: dbMoney(priced.total), source: isGuestPath ? 'qr' : 'staff' } });
      return this.summary(tx, orderId);
    }));
  }

  // Creates one ticket per station. Items with no station route go on an unassigned ticket.
  async dispatchToKitchen(tx: Tx, orderId: number, orderPublicId: string, branchId: number, orderNumber: number) {
    const cafeId = tenantId();
    const items = await tx.selectFrom('order_items').select(['id', 'product_id']).where('cafe_id', '=', cafeId).where('order_id', '=', orderId).where('status', '=', 'active').execute();
    const routes = await tx.selectFrom('product_station_routes').select(['product_id', 'station_id']).where('cafe_id', '=', cafeId).where('branch_id', '=', branchId).execute();
    const byStation = new Map<number | null, number[]>();
    for (const i of items) {
      const station = routes.find((r) => r.product_id === i.product_id)?.station_id ?? null;
      byStation.set(station, [...(byStation.get(station) ?? []), i.id]);
    }
    for (const [station, itemIds] of byStation) {
      const ticketId = Number((await tx.insertInto('kitchen_orders').values({ public_id: ulid(), cafe_id: cafeId, branch_id: branchId, order_id: orderId, station_id: station }).executeTakeFirstOrThrow()).insertId);
      await tx.insertInto('kitchen_order_items').values(itemIds.map((order_item_id) => ({ cafe_id: cafeId, kitchen_order_id: ticketId, order_item_id }))).execute();
    }
    await emit(tx, { cafeId, branchId, type: 'order.placed', rooms: [rooms.branch(cafeId, branchId, 'kitchen'), ...staffRooms(cafeId, branchId)], payload: { orderId: orderPublicId, orderNumber } });
  }

  async transition(tx: Tx, orderId: number, to: OrderStatus, reason?: string) {
    const cafeId = tenantId();
    const o = await tx.selectFrom('orders').selectAll().where('cafe_id', '=', cafeId).where('id', '=', orderId).forUpdate().executeTakeFirst();
    if (!o) throw notFound('ORDER_NOT_FOUND');
    if (o.status === to) return o;
    if (!TRANSITIONS[o.status].includes(to)) throw conflict('ORDER_ILLEGAL_TRANSITION', { from: o.status, to });
    if (to === 'completed' && o.payment_status !== 'paid' && o.payment_status !== 'partially_refunded' && o.payment_status !== 'refunded') throw conflict('ORDER_NOT_PAID');
    const now = new Date();
    await tx.updateTable('orders').set({
      status: to, accepted_at: to === 'accepted' ? now : undefined, ready_at: to === 'ready' ? now : undefined, completed_at: to === 'completed' ? now : undefined,
      cancelled_at: to === 'cancelled' ? now : undefined, cancel_reason: to === 'cancelled' ? reason ?? null : undefined,
    }).where('cafe_id', '=', cafeId).where('id', '=', orderId).execute();
    await tx.insertInto('order_status_history').values({ cafe_id: cafeId, order_id: orderId, from_status: o.status, to_status: to, changed_by_user_id: actorUserId(), reason: reason ?? null }).execute();

    const date = o.business_date.toISOString().slice(0, 10);
    const settings = await loadSettings(tx);
    if (to === 'accepted' && settings.stockDeductionEnabled) await this.inventory.consumeForOrder(tx, orderId, o.branch_id, date);
    if (to === 'cancelled') {
      if (['accepted', 'placed', 'pending_payment'].includes(o.status)) await this.inventory.reverseForOrder(tx, orderId, o.branch_id);
      await tx.updateTable('kitchen_orders').set({ status: 'cancelled' }).where('cafe_id', '=', cafeId).where('order_id', '=', orderId).where('status', '!=', 'completed').execute();
      await this.reverseRedemptions(tx, o);
    }

    const session = o.session_id ? await tx.selectFrom('table_sessions').select('public_id').where('cafe_id', '=', cafeId).where('id', '=', o.session_id).executeTakeFirst() : undefined;
    await emit(tx, {
      cafeId, branchId: o.branch_id, type: `order.${to}`,
      rooms: [rooms.branch(cafeId, o.branch_id, 'kitchen'), ...staffRooms(cafeId, o.branch_id), ...(session ? [rooms.session(session.public_id)] : []), ...(o.customer_id ? [rooms.customer(o.customer_id)] : [])],
      payload: { orderId: o.public_id, orderNumber: o.order_number, status: to },
    });
    if (to === 'ready' && o.customer_id) {
      // Rendered in the language of the order. Push delivery is pending configuration; this is the in-app copy.
      const tpl = await tx.selectFrom('notification_templates as t').innerJoin('notification_template_translations as x', 'x.template_id', 't.id').select(['x.language_code', 'x.title', 'x.body']).where('t.template_key', '=', 'order_ready').where('t.channel', '=', 'in_app').where('x.language_code', 'in', [o.language_code, 'en']).execute();
      const text = tpl.find((x) => x.language_code === o.language_code) ?? tpl[0];
      if (text) await tx.insertInto('notifications').values({ public_id: ulid(), cafe_id: cafeId, customer_id: o.customer_id, template_key: 'order_ready', language_code: o.language_code, title: text.title, body: text.body.replace('{number}', String(o.order_number)), data: JSON.stringify({ orderId: o.public_id }) }).execute();
    }
    return o;
  }

  private async reverseRedemptions(tx: Tx, o: { id: number; customer_id: number | null }) {
    const cafeId = tenantId();
    const red = await tx.selectFrom('coupon_redemptions').select(['id', 'coupon_id']).where('cafe_id', '=', cafeId).where('order_id', '=', o.id).execute();
    for (const r of red) {
      await tx.updateTable('coupons').set((eb) => ({ redemption_count: eb('redemption_count', '-', 1) })).where('cafe_id', '=', cafeId).where('id', '=', r.coupon_id).execute();
      await tx.deleteFrom('coupon_redemptions').where('cafe_id', '=', cafeId).where('id', '=', r.id).execute();
    }
    if (!o.customer_id) return;
    const ledger = await tx.selectFrom('loyalty_ledger').select(['entry_type', 'points']).where('cafe_id', '=', cafeId).where('order_id', '=', o.id).execute();
    const redeemed = ledger.filter((l) => l.entry_type === 'redeem').reduce((a, l) => a + Math.abs(l.points), 0);
    if (redeemed && !ledger.some((l) => l.entry_type === 'reverse')) {
      await tx.updateTable('customer_loyalty_points').set((eb) => ({ balance_points: eb('balance_points', '+', redeemed) })).where('cafe_id', '=', cafeId).where('customer_id', '=', o.customer_id).execute();
      await tx.insertInto('loyalty_ledger').values({ cafe_id: cafeId, customer_id: o.customer_id, entry_type: 'reverse', points: redeemed, order_id: o.id, reason: 'order cancelled' }).execute();
    }
  }

  async staffTransition(publicId: string, to: OrderStatus, reason?: string) {
    if (to === 'cancelled' && !store()!.principal!.permissions.has('orders.cancel')) throw forbidden();
    await this.db.tx(async (tx) => {
      const o = await tx.selectFrom('orders').select(['id', 'branch_id', 'status', 'paid_amount', 'refunded_amount']).where('cafe_id', '=', tenantId()).where('public_id', '=', publicId).executeTakeFirst();
      if (!o) throw notFound('ORDER_NOT_FOUND');
      assertBranchAllowed(o.branch_id);
      if (to === 'cancelled' && !reason) throw badRequest('REASON_REQUIRED');
      await this.transition(tx, o.id, to, reason);
      await tx.updateTable('kitchen_orders').set(to === 'ready' ? { status: 'ready', ready_at: new Date() } : to === 'completed' || to === 'served' ? { status: 'completed', completed_at: new Date() } : {}).where('cafe_id', '=', tenantId()).where('order_id', '=', o.id).where('status', 'not in', ['cancelled', 'completed']).execute().catch(() => undefined);
      await audit(tx, { action: `order.${to}`, entityType: 'order', entityId: publicId, reason });
    });
    return this.getStaff(publicId);
  }

  // Quantity or item changes are allowed only before the kitchen starts, and only while unpaid.
  async modifyItem(orderPublicId: string, itemId: number, d: { quantity?: number; cancel?: boolean; reason: string }) {
    await this.db.tx(async (tx) => {
      const cafeId = tenantId();
      const o = await tx.selectFrom('orders').selectAll().where('cafe_id', '=', cafeId).where('public_id', '=', orderPublicId).forUpdate().executeTakeFirst();
      if (!o) throw notFound('ORDER_NOT_FOUND');
      assertBranchAllowed(o.branch_id);
      if (!['pending_payment', 'placed'].includes(o.status) || D(o.paid_amount).gt(0)) throw conflict('ORDER_NOT_EDITABLE');
      const item = await tx.selectFrom('order_items').selectAll().where('cafe_id', '=', cafeId).where('order_id', '=', o.id).where('id', '=', itemId).where('status', '=', 'active').executeTakeFirst();
      if (!item) throw notFound('ORDER_ITEM_NOT_FOUND');
      const qty = d.cancel ? 0 : d.quantity ?? item.quantity;
      if (qty === item.quantity) return;
      if (qty < 0) throw badRequest('QUANTITY_INVALID');
      if (qty === 0) {
        await tx.updateTable('order_items').set({ status: 'cancelled' }).where('cafe_id', '=', cafeId).where('id', '=', item.id).execute();
        await tx.updateTable('kitchen_order_items').set({ status: 'cancelled' }).where('cafe_id', '=', cafeId).where('order_item_id', '=', item.id).execute();
      } else {
        const ratio = D(qty).div(item.quantity);
        const { minor_unit } = await tx.selectFrom('currencies').select('minor_unit').where('code', '=', o.currency_code).executeTakeFirstOrThrow();
        const scale = (v: string) => dbMoney(D(v).times(ratio).toDecimalPlaces(minor_unit));
        await tx.updateTable('order_items').set({ quantity: qty, addons_amount: scale(item.addons_amount), discount_amount: scale(item.discount_amount), tax_amount: scale(item.tax_amount), line_total_amount: scale(item.line_total_amount) }).where('cafe_id', '=', cafeId).where('id', '=', item.id).execute();
        const taxes = await tx.selectFrom('order_item_taxes').selectAll().where('cafe_id', '=', cafeId).where('order_item_id', '=', item.id).execute();
        for (const t of taxes) await tx.updateTable('order_item_taxes').set({ taxable_amount: scale(t.taxable_amount), tax_amount: scale(t.tax_amount) }).where('cafe_id', '=', cafeId).where('id', '=', t.id).execute();
      }
      const totals = await tx.selectFrom('order_items').select((eb) => [
        sql<string>`COALESCE(SUM(unit_price * quantity + addons_amount), 0)`.as('subtotal'), eb.fn.coalesce(eb.fn.sum<string>('discount_amount'), sql<string>`0`).as('discount'), eb.fn.coalesce(eb.fn.sum<string>('tax_amount'), sql<string>`0`).as('tax'), eb.fn.coalesce(eb.fn.sum<string>('line_total_amount'), sql<string>`0`).as('total'),
      ]).where('cafe_id', '=', cafeId).where('order_id', '=', o.id).where('status', '=', 'active').executeTakeFirstOrThrow();
      await tx.updateTable('orders').set({ subtotal_amount: dbMoney(totals.subtotal), discount_amount: dbMoney(totals.discount), tax_amount: dbMoney(totals.tax), total_amount: dbMoney(D(totals.total).plus(o.service_charge_amount).plus(o.delivery_fee_amount)) }).where('cafe_id', '=', cafeId).where('id', '=', o.id).execute();
      await tx.insertInto('order_modifications').values({
        cafe_id: cafeId, order_id: o.id, modification_type: qty === 0 ? 'item_cancelled' : 'quantity_changed', before_state: JSON.stringify({ itemId: item.id, quantity: item.quantity, total: o.total_amount }), after_state: JSON.stringify({ itemId: item.id, quantity: qty, total: totals.total }), reason: d.reason, modified_by_user_id: requiredUserId(),
      }).execute();
      await audit(tx, { action: 'order.modified', entityType: 'order', entityId: orderPublicId, reason: d.reason });
    });
    return this.getStaff(orderPublicId);
  }

  async summary(q: Tx | Db['q'], orderId: number) {
    const cafeId = tenantId();
    const o = await q.selectFrom('orders as o').leftJoin('cafe_tables as t', 't.id', 'o.table_id').selectAll('o').select('t.table_number').where('o.cafe_id', '=', cafeId).where('o.id', '=', orderId).executeTakeFirstOrThrow();
    const items = await q.selectFrom('order_items').selectAll().where('cafe_id', '=', cafeId).where('order_id', '=', orderId).execute();
    const ids = items.map((i) => i.id);
    const [addons, taxes] = ids.length ? await Promise.all([
      q.selectFrom('order_item_addons').selectAll().where('cafe_id', '=', cafeId).where('order_item_id', 'in', ids).execute(),
      q.selectFrom('order_item_taxes').selectAll().where('cafe_id', '=', cafeId).where('order_item_id', 'in', ids).execute(),
    ]) : [[], []];
    const c = o.currency_code;
    return {
      publicId: o.public_id, orderNumber: o.order_number, businessDate: o.business_date.toISOString().slice(0, 10), status: o.status, paymentStatus: o.payment_status, orderType: o.order_type, source: o.order_source, tableNumber: o.table_number, language: o.language_code, notes: o.customer_notes,
      placedAt: o.placed_at, readyAt: o.ready_at, completedAt: o.completed_at, cancelReason: o.cancel_reason, pricesIncludeTax: !!o.prices_include_tax,
      subtotal: money(o.subtotal_amount, c), discount: money(o.discount_amount, c), tax: money(o.tax_amount, c), serviceCharge: money(o.service_charge_amount, c), deliveryFee: money(o.delivery_fee_amount, c), total: money(o.total_amount, c), paid: money(o.paid_amount, c), refunded: money(o.refunded_amount, c),
      items: items.map((i) => ({
        id: i.id, name: (i.name_translations as Record<string, string> | null)?.[o.language_code] ?? i.name_snapshot, nameTranslations: i.name_translations, variant: i.variant_name_snapshot, quantity: i.quantity, unitPrice: money(i.unit_price, c), status: i.status, notes: i.notes, lineTotal: money(i.line_total_amount, c), tax: money(i.tax_amount, c),
        addons: addons.filter((a) => a.order_item_id === i.id).map((a) => ({ name: a.name_snapshot, quantity: a.quantity, unitPrice: money(a.unit_price, c) })),
        taxes: taxes.filter((t) => t.order_item_id === i.id).map((t) => ({ code: t.component_code, name: t.display_name, ratePercent: t.rate_percent, amount: money(t.tax_amount, c) })),
      })),
    };
  }

  async getStaff(publicId: string) {
    const id = await idOf(this.db.q, 'orders', publicId, 'ORDER_NOT_FOUND');
    const b = await this.db.q.selectFrom('orders').select('branch_id').where('cafe_id', '=', tenantId()).where('id', '=', id).executeTakeFirstOrThrow();
    assertBranchAllowed(b.branch_id);
    const [order, history, modifications] = await Promise.all([
      this.summary(this.db.q, id),
      this.db.q.selectFrom('order_status_history').select(['from_status', 'to_status', 'reason', 'occurred_at']).where('cafe_id', '=', tenantId()).where('order_id', '=', id).orderBy('id').execute(),
      this.db.q.selectFrom('order_modifications').select(['modification_type', 'before_state', 'after_state', 'reason', 'occurred_at']).where('cafe_id', '=', tenantId()).where('order_id', '=', id).orderBy('id').execute(),
    ]);
    return { ...order, history, modifications };
  }

  async list(query: { status?: string; paymentStatus?: string; date?: string; page?: string; limit?: string }) {
    const { page, limit, offset } = requirePage(query);
    let q = this.db.q.selectFrom('orders as o').leftJoin('cafe_tables as t', 't.id', 'o.table_id').where('o.cafe_id', '=', tenantId());
    const allowed = store()?.principal?.branchIds;
    if (store()?.branchId) q = q.where('o.branch_id', '=', store()!.branchId!);
    else if (allowed) q = q.where('o.branch_id', 'in', allowed);
    if (query.status) q = q.where('o.status', 'in', query.status.split(',') as OrderStatus[]);
    if (query.paymentStatus) q = q.where('o.payment_status', '=', query.paymentStatus as 'paid');
    if (query.date) q = q.where('o.business_date', '=', new Date(query.date));
    const [rows, count] = await Promise.all([
      q.select(['o.public_id', 'o.order_number', 'o.status', 'o.payment_status', 'o.order_type', 'o.order_source', 'o.currency_code', 'o.total_amount', 'o.paid_amount', 'o.placed_at', 'o.business_date', 't.table_number']).orderBy('o.id', 'desc').limit(limit).offset(offset).execute(),
      q.select((eb) => eb.fn.countAll<number>().as('n')).executeTakeFirstOrThrow(),
    ]);
    return paged(rows, page, limit, Number(count.n));
  }

  // A guest only ever sees orders of their own table session.
  async getForSession(publicId: string) {
    const p = store()!.principal!;
    const o = await this.db.q.selectFrom('orders').select('id').where('cafe_id', '=', tenantId()).where('public_id', '=', publicId).where('session_id', '=', p.tableSessionId!).executeTakeFirst();
    if (!o) throw notFound('ORDER_NOT_FOUND');
    return this.summary(this.db.q, o.id);
  }
  async listForSession() {
    const p = store()!.principal!;
    const rows = await this.db.q.selectFrom('orders').select('id').where('cafe_id', '=', tenantId()).where('session_id', '=', p.tableSessionId!).orderBy('id', 'desc').execute();
    return Promise.all(rows.map((r) => this.summary(this.db.q, r.id)));
  }

  async customerHistory(customerId: number, query: { page?: string; limit?: string }) {
    const { page, limit, offset } = requirePage(query);
    return unscoped('a customer reading their own orders across cafes', async () => {
      const rows = await this.db.q.selectFrom('orders as o').innerJoin('cafes as c', 'c.id', 'o.cafe_id').select(['o.public_id', 'o.order_number', 'o.status', 'o.payment_status', 'o.currency_code', 'o.total_amount', 'o.placed_at', 'c.display_name as cafe', 'c.slug']).where('o.customer_id', '=', customerId).orderBy('o.id', 'desc').limit(limit).offset(offset).execute();
      const count = await this.db.q.selectFrom('orders').select((eb) => eb.fn.countAll<number>().as('n')).where('customer_id', '=', customerId).executeTakeFirstOrThrow();
      return paged(rows, page, limit, Number(count.n));
    });
  }

  async recentlyOrdered(customerId: number) {
    return this.db.q.selectFrom('order_items as i').innerJoin('orders as o', 'o.id', 'i.order_id').innerJoin('products as p', 'p.id', 'i.product_id')
      .select(['p.public_id', 'i.name_snapshot']).select((eb) => eb.fn.max('o.placed_at').as('last')).where('i.cafe_id', '=', tenantId()).where('o.customer_id', '=', customerId).groupBy(['p.public_id', 'i.name_snapshot']).orderBy('last', 'desc').limit(20).execute();
  }

  // Pricing preview. Identical code path to placement, and nothing is written.
  async validateCoupon(code: string, subtotal: string) {
    const now = new Date();
    const c = await this.db.q.selectFrom('coupons').selectAll().where('cafe_id', '=', tenantId()).where('code', '=', code).where('is_active', '=', 1).where('deleted_at', 'is', null).executeTakeFirst();
    if (!c || (c.starts_at && c.starts_at > now) || (c.ends_at && c.ends_at < now) || (c.max_redemptions !== null && c.redemption_count >= c.max_redemptions)) return { valid: false };
    if (D(subtotal).lt(c.min_order_amount)) return { valid: false, reason: 'COUPON_MIN_ORDER', minOrder: c.min_order_amount };
    return { valid: true, discountType: c.discount_type, percent: c.percent_value, fixedAmount: c.fixed_amount };
  }
}
