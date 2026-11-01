import { Injectable } from '@nestjs/common';
import { sql } from 'kysely';
import { actorUserId, requiredUserId, tenantId } from '../../common/context';
import { badRequest, conflict, notFound } from '../../common/errors';
import { ulid } from '../../common/ids';
import { assertBranchAllowed, currentBranch, idOf } from '../../common/lookup';
import { assertPrecision, D, Decimal, dbMoney, ZERO } from '../../common/money';
import { audit, Db, emit, rooms, staffRooms, Tx } from '../../infra/db/db.service';
import { AccountingService } from '../accounting/accounting.service';

@Injectable()
export class InventoryService {
  constructor(private readonly db: Db, private readonly accounting: AccountingService) {}

  private async currency(tx: Tx) {
    return (await tx.selectFrom('cafes').select('currency_code').where('id', '=', tenantId()).executeTakeFirstOrThrow()).currency_code;
  }
  private today() { return new Date().toISOString().slice(0, 10); }

  async listIngredients() {
    return this.db.q.selectFrom('ingredients').select(['public_id', 'name', 'sku', 'unit_code', 'is_perishable']).where('cafe_id', '=', tenantId()).where('deleted_at', 'is', null).orderBy('name').execute();
  }
  async createIngredient(d: { name: string; unitCode: string; sku?: string; isPerishable?: boolean }) {
    const publicId = ulid();
    await this.db.q.insertInto('ingredients').values({ public_id: publicId, cafe_id: tenantId(), name: d.name, unit_code: d.unitCode, sku: d.sku ?? null, is_perishable: d.isPerishable ? 1 : 0 }).execute();
    return { publicId };
  }
  async deleteIngredient(publicId: string) {
    const r = await this.db.q.updateTable('ingredients').set({ deleted_at: new Date() }).where('cafe_id', '=', tenantId()).where('public_id', '=', publicId).executeTakeFirst();
    if (!r.numUpdatedRows) throw notFound();
    return { ok: true };
  }

  async setRecipe(productPublicId: string, variantPublicId: string | undefined, items: Array<{ ingredientId: string; quantity: string; wastePercent?: string }>) {
    await this.db.tx(async (tx) => {
      const pid = await idOf(tx, 'products', productPublicId);
      const vid = variantPublicId ? await idOf(tx, 'product_variants', variantPublicId) : null;
      let del = tx.deleteFrom('product_recipes').where('cafe_id', '=', tenantId()).where('product_id', '=', pid);
      del = vid ? del.where('variant_id', '=', vid) : del.where('variant_id', 'is', null);
      await del.execute();
      for (const i of items) await tx.insertInto('product_recipes').values({ cafe_id: tenantId(), product_id: pid, variant_id: vid, ingredient_id: await idOf(tx, 'ingredients', i.ingredientId), quantity: i.quantity, waste_percent: i.wastePercent ?? '0' }).execute();
      await audit(tx, { action: 'recipe.updated', entityType: 'product', entityId: productPublicId });
    });
    return { ok: true };
  }
  async getRecipe(productPublicId: string) {
    const pid = await idOf(this.db.q, 'products', productPublicId);
    return this.db.q.selectFrom('product_recipes as r').innerJoin('ingredients as i', 'i.id', 'r.ingredient_id').leftJoin('product_variants as v', 'v.id', 'r.variant_id').select(['i.public_id as ingredient_id', 'i.name', 'i.unit_code', 'r.quantity', 'r.waste_percent', 'v.public_id as variant_id']).where('r.cafe_id', '=', tenantId()).where('r.product_id', '=', pid).execute();
  }

  private async item(tx: Tx, branchId: number, ingredientId: number) {
    await tx.insertInto('inventory_items').values({ cafe_id: tenantId(), branch_id: branchId, ingredient_id: ingredientId }).onDuplicateKeyUpdate({ ingredient_id: ingredientId }).execute();
    return tx.selectFrom('inventory_items').selectAll().where('cafe_id', '=', tenantId()).where('branch_id', '=', branchId).where('ingredient_id', '=', ingredientId).forUpdate().executeTakeFirstOrThrow();
  }

  // The single writer of stock. Holds the row lock, updates moving average cost, appends the movement.
  async move(tx: Tx, m: { branchId: number; ingredientId: number; type: 'stock_in' | 'stock_out' | 'adjustment' | 'sale_consumption' | 'sale_reversal' | 'wastage' | 'purchase_receipt'; quantity: Decimal; unitCost?: string; sourceType?: string; sourceId?: number; reason?: string; batchId?: number }) {
    const item = await this.item(tx, m.branchId, m.ingredientId);
    const onHand = D(item.on_hand_quantity);
    const avg = D(item.average_unit_cost);
    const cost = m.quantity.gt(0) && m.unitCost !== undefined ? D(m.unitCost) : avg;
    const after = onHand.plus(m.quantity);
    let newAvg = avg;
    if (m.quantity.gt(0) && after.gt(0)) newAvg = Decimal.max(onHand, 0).times(avg).plus(m.quantity.times(cost)).div(Decimal.max(onHand, 0).plus(m.quantity));
    await tx.updateTable('inventory_items').set({ on_hand_quantity: after.toFixed(4), average_unit_cost: newAvg.toFixed(6) }).where('cafe_id', '=', tenantId()).where('id', '=', item.id).execute();
    await tx.insertInto('stock_movements').values({
      cafe_id: tenantId(), branch_id: m.branchId, ingredient_id: m.ingredientId, batch_id: m.batchId ?? null, movement_type: m.type, quantity: m.quantity.toFixed(4), unit_cost: cost.toFixed(6), currency_code: await this.currency(tx),
      source_type: m.sourceType ?? null, source_id: m.sourceId ?? null, reason: m.reason ?? null, created_by_user_id: actorUserId(),
    }).execute();
    if (m.quantity.lt(0)) await this.drawBatches(tx, m.branchId, m.ingredientId, m.quantity.abs());
    if (item.reorder_level !== null && after.lte(item.reorder_level) && onHand.gt(item.reorder_level)) {
      const ing = await tx.selectFrom('ingredients').select(['public_id', 'name']).where('cafe_id', '=', tenantId()).where('id', '=', m.ingredientId).executeTakeFirstOrThrow();
      await tx.updateTable('inventory_items').set({ low_stock_notified_at: new Date() }).where('cafe_id', '=', tenantId()).where('id', '=', item.id).execute();
      await emit(tx, { cafeId: tenantId(), branchId: m.branchId, type: 'stock.low', rooms: [rooms.branch(tenantId(), m.branchId, 'manager'), rooms.owner(tenantId())], payload: { ingredientId: ing.public_id, name: ing.name, onHand: after.toString(), reorderLevel: item.reorder_level } });
    }
    return { cost, after };
  }

  // Earliest expiry first, so perishable stock is used before it spoils.
  private async drawBatches(tx: Tx, branchId: number, ingredientId: number, quantity: Decimal) {
    let left = quantity;
    const batches = await tx.selectFrom('stock_batches').select(['id', 'remaining_quantity']).where('cafe_id', '=', tenantId()).where('branch_id', '=', branchId).where('ingredient_id', '=', ingredientId).where('remaining_quantity', '>', '0')
      .orderBy(sql`expires_on IS NULL`).orderBy('expires_on').orderBy('received_at').forUpdate().execute();
    for (const b of batches) {
      if (left.lte(0)) break;
      const take = Decimal.min(left, b.remaining_quantity);
      await tx.updateTable('stock_batches').set({ remaining_quantity: D(b.remaining_quantity).minus(take).toFixed(4) }).where('cafe_id', '=', tenantId()).where('id', '=', b.id).execute();
      left = left.minus(take);
    }
  }

  // Recipe rules at order acceptance (assumption A-9). A short stock level does not block a sale already accepted.
  async consumeForOrder(tx: Tx, orderId: number, branchId: number, date: string) {
    const already = await tx.selectFrom('stock_movements').select('id').where('cafe_id', '=', tenantId()).where('source_type', '=', 'order').where('source_id', '=', orderId).where('movement_type', '=', 'sale_consumption').limit(1).executeTakeFirst();
    if (already) return;
    const items = await tx.selectFrom('order_items').select(['product_id', 'variant_id', 'quantity']).where('cafe_id', '=', tenantId()).where('order_id', '=', orderId).where('status', '=', 'active').execute();
    if (!items.length) return;

    const combos = await tx.selectFrom('combo_items').selectAll().where('cafe_id', '=', tenantId()).where('combo_product_id', 'in', items.map((i) => i.product_id)).execute();
    const expanded: Array<{ product_id: number; variant_id: number | null; quantity: number }> = [];
    for (const i of items) {
      const parts = combos.filter((c) => c.combo_product_id === i.product_id);
      if (parts.length) parts.forEach((p) => expanded.push({ product_id: p.item_product_id, variant_id: p.item_variant_id, quantity: p.quantity * i.quantity }));
      else expanded.push(i);
    }
    const recipes = await tx.selectFrom('product_recipes').selectAll().where('cafe_id', '=', tenantId()).where('product_id', 'in', expanded.map((e) => e.product_id)).execute();
    const need = new Map<number, Decimal>();
    for (const e of expanded) {
      const own = recipes.filter((r) => r.product_id === e.product_id && r.variant_id === e.variant_id);
      const rows = own.length ? own : recipes.filter((r) => r.product_id === e.product_id && r.variant_id === null);
      for (const r of rows) {
        const qty = D(r.quantity).times(D(1).plus(D(r.waste_percent).div(100))).times(e.quantity);
        need.set(r.ingredient_id, (need.get(r.ingredient_id) ?? ZERO).plus(qty));
      }
    }
    let cogs = ZERO;
    for (const ingredientId of [...need.keys()].sort((a, b) => a - b)) {
      const qty = need.get(ingredientId)!;
      const { cost } = await this.move(tx, { branchId, ingredientId, type: 'sale_consumption', quantity: qty.neg(), sourceType: 'order', sourceId: orderId });
      cogs = cogs.plus(qty.times(cost));
    }
    await this.accounting.post(tx, { sourceType: 'order', sourceId: orderId, kind: 'cogs', date, branchId, memo: 'Cost of goods sold', lines: [{ key: 'cogs', debit: cogs.toFixed(4) }, { key: 'inventory', credit: cogs.toFixed(4) }] });
  }

  // Only before preparation started. Food already cooked is real consumption and stays deducted.
  async reverseForOrder(tx: Tx, orderId: number, branchId: number) {
    const moved = await tx.selectFrom('stock_movements').select(['ingredient_id', 'quantity', 'unit_cost', 'movement_type']).where('cafe_id', '=', tenantId()).where('source_type', '=', 'order').where('source_id', '=', orderId).execute();
    if (!moved.length || moved.some((m) => m.movement_type === 'sale_reversal')) return;
    for (const m of moved) await this.move(tx, { branchId, ingredientId: m.ingredient_id, type: 'sale_reversal', quantity: D(m.quantity).abs(), unitCost: m.unit_cost, sourceType: 'order', sourceId: orderId, reason: 'order cancelled' });
    const entry = await tx.selectFrom('journal_entries').select('id').where('cafe_id', '=', tenantId()).where('source_type', '=', 'order').where('source_id', '=', orderId).where('entry_kind', '=', 'cogs').executeTakeFirst();
    if (entry) await this.accounting.reverseIn(tx, entry.id, 'order cancelled');
  }

  async stock() {
    const branch = currentBranch();
    return this.db.q.selectFrom('ingredients as i').leftJoin('inventory_items as s', (j) => j.onRef('s.ingredient_id', '=', 'i.id').on('s.branch_id', '=', branch))
      .select(['i.public_id', 'i.name', 'i.unit_code', 's.on_hand_quantity', 's.average_unit_cost', 's.reorder_level']).where('i.cafe_id', '=', tenantId()).where('i.deleted_at', 'is', null).orderBy('i.name').execute();
  }
  async setReorderLevel(ingredientPublicId: string, level: string | null) {
    const branch = currentBranch();
    await this.db.tx(async (tx) => {
      const item = await this.item(tx, branch, await idOf(tx, 'ingredients', ingredientPublicId));
      await tx.updateTable('inventory_items').set({ reorder_level: level }).where('cafe_id', '=', tenantId()).where('id', '=', item.id).execute();
    });
    return { ok: true };
  }

  async record(d: { ingredientId: string; type: 'stock_in' | 'stock_out' | 'adjustment' | 'wastage'; quantity: string; unitCost?: string; reason?: string; expiresOn?: string; batchCode?: string }) {
    const branch = currentBranch();
    return this.db.tx(async (tx) => {
      const ingredientId = await idOf(tx, 'ingredients', d.ingredientId);
      const raw = D(d.quantity);
      if (raw.isZero()) throw badRequest('QUANTITY_ZERO');
      if (d.type === 'stock_in' && d.unitCost === undefined) throw badRequest('UNIT_COST_REQUIRED');
      if (d.type !== 'adjustment' && raw.lt(0)) throw badRequest('QUANTITY_NEGATIVE');
      if (['stock_out', 'wastage', 'adjustment'].includes(d.type) && !d.reason) throw badRequest('REASON_REQUIRED');
      const qty = d.type === 'stock_out' || d.type === 'wastage' ? raw.neg() : raw;
      let batchId: number | undefined;
      if (d.type === 'stock_in') {
        batchId = Number((await tx.insertInto('stock_batches').values({ cafe_id: tenantId(), branch_id: branch, ingredient_id: ingredientId, batch_code: d.batchCode ?? null, received_quantity: qty.toFixed(4), remaining_quantity: qty.toFixed(4), unit_cost: D(d.unitCost!).toFixed(6), received_at: new Date(), expires_on: d.expiresOn ? new Date(d.expiresOn) : null }).executeTakeFirstOrThrow()).insertId);
      }
      const { cost, after } = await this.move(tx, { branchId: branch, ingredientId, type: d.type, quantity: qty, unitCost: d.unitCost, reason: d.reason, batchId, sourceType: 'manual' });
      const value = qty.abs().times(cost).toFixed(4);
      const lastMove = await tx.selectFrom('stock_movements').select('id').where('cafe_id', '=', tenantId()).orderBy('id', 'desc').limit(1).executeTakeFirstOrThrow();
      const accounts: Record<string, [string, string]> = {
        stock_in: ['inventory', 'accounts_payable'], stock_out: ['cogs', 'inventory'], wastage: ['wastage', 'inventory'],
        adjustment: qty.gt(0) ? ['inventory', 'wastage'] : ['wastage', 'inventory'],
      };
      const [dr, cr] = accounts[d.type]!;
      await this.accounting.post(tx, { sourceType: 'stock_movement', sourceId: lastMove.id, kind: d.type, date: this.today(), branchId: branch, memo: d.reason ?? d.type, lines: [{ key: dr, debit: value }, { key: cr, credit: value }] });
      await audit(tx, { action: `stock.${d.type}`, entityType: 'ingredient', entityId: d.ingredientId, reason: d.reason, after: { quantity: qty.toString() } });
      return { onHand: after.toString() };
    });
  }

  async movements(ingredientPublicId?: string) {
    let q = this.db.q.selectFrom('stock_movements as m').innerJoin('ingredients as i', 'i.id', 'm.ingredient_id').select(['m.id', 'i.name', 'm.movement_type', 'm.quantity', 'm.unit_cost', 'm.currency_code', 'm.reason', 'm.occurred_at']).where('m.cafe_id', '=', tenantId()).where('m.branch_id', '=', currentBranch());
    if (ingredientPublicId) q = q.where('i.public_id', '=', ingredientPublicId);
    return q.orderBy('m.id', 'desc').limit(200).execute();
  }
  async valuation() {
    const rows = await this.stock();
    const lines = rows.map((r) => ({ ...r, value: D(r.on_hand_quantity ?? 0).times(r.average_unit_cost ?? 0).toFixed(4) }));
    return { lines, total: lines.reduce((a, l) => a.plus(l.value), ZERO).toFixed(4) };
  }
  async expiring(days: number) {
    return this.db.q.selectFrom('stock_batches as b').innerJoin('ingredients as i', 'i.id', 'b.ingredient_id').select(['i.name', 'b.batch_code', 'b.remaining_quantity', 'b.expires_on']).where('b.cafe_id', '=', tenantId()).where('b.branch_id', '=', currentBranch()).where('b.remaining_quantity', '>', '0')
      .where('b.expires_on', '<=', new Date(Date.now() + days * 86400_000)).orderBy('b.expires_on').execute();
  }

  // Suppliers and purchasing
  async suppliers() { return this.db.q.selectFrom('suppliers').select(['public_id', 'name', 'contact_name', 'email', 'phone', 'address', 'tax_registration_number', 'payment_terms_days']).where('cafe_id', '=', tenantId()).where('deleted_at', 'is', null).orderBy('name').execute(); }
  async createSupplier(d: { name: string; contactName?: string; email?: string; phone?: string; address?: string; taxRegistrationNumber?: string; paymentTermsDays?: number }) {
    const publicId = ulid();
    await this.db.q.insertInto('suppliers').values({ public_id: publicId, cafe_id: tenantId(), name: d.name, contact_name: d.contactName ?? null, email: d.email ?? null, phone: d.phone ?? null, address: d.address ?? null, tax_registration_number: d.taxRegistrationNumber ?? null, payment_terms_days: d.paymentTermsDays ?? null }).execute();
    return { publicId };
  }
  async deleteSupplier(publicId: string) {
    const r = await this.db.q.updateTable('suppliers').set({ deleted_at: new Date() }).where('cafe_id', '=', tenantId()).where('public_id', '=', publicId).executeTakeFirst();
    if (!r.numUpdatedRows) throw notFound();
    return { ok: true };
  }

  async listPurchaseOrders() {
    return this.db.q.selectFrom('purchase_orders as p').innerJoin('suppliers as s', 's.id', 'p.supplier_id').select(['p.public_id', 'p.po_number', 'p.status', 'p.currency_code', 'p.total_amount', 'p.expected_on', 's.name as supplier', 'p.created_at']).where('p.cafe_id', '=', tenantId()).orderBy('p.id', 'desc').limit(100).execute();
  }
  async createPurchaseOrder(d: { supplierId: string; expectedOn?: string; notes?: string; items: Array<{ ingredientId: string; quantity: string; unitCost: string }> }) {
    const branch = currentBranch();
    return this.db.tx(async (tx) => {
      const total = d.items.reduce((a, i) => a.plus(D(i.quantity).times(i.unitCost)), ZERO);
      const publicId = ulid();
      const poNumber = `PO-${publicId.slice(-10)}`;
      const id = Number((await tx.insertInto('purchase_orders').values({ public_id: publicId, cafe_id: tenantId(), branch_id: branch, supplier_id: await idOf(tx, 'suppliers', d.supplierId, 'SUPPLIER_NOT_FOUND'), po_number: poNumber, currency_code: await this.currency(tx), total_amount: dbMoney(total), expected_on: d.expectedOn ? new Date(d.expectedOn) : null, notes: d.notes ?? null, created_by_user_id: actorUserId(), status: 'sent' }).executeTakeFirstOrThrow()).insertId);
      for (const i of d.items) await tx.insertInto('purchase_order_items').values({ cafe_id: tenantId(), purchase_order_id: id, ingredient_id: await idOf(tx, 'ingredients', i.ingredientId), ordered_quantity: i.quantity, unit_cost: D(i.unitCost).toFixed(6) }).execute();
      await audit(tx, { action: 'purchase_order.created', entityType: 'purchase_order', entityId: publicId });
      return { publicId, poNumber };
    });
  }
  async getPurchaseOrder(publicId: string) {
    const id = await idOf(this.db.q, 'purchase_orders', publicId);
    const items = await this.db.q.selectFrom('purchase_order_items as p').innerJoin('ingredients as i', 'i.id', 'p.ingredient_id').select(['p.id', 'i.public_id as ingredient_id', 'i.name', 'p.ordered_quantity', 'p.received_quantity', 'p.unit_cost']).where('p.cafe_id', '=', tenantId()).where('p.purchase_order_id', '=', id).execute();
    return { publicId, items };
  }
  async receivePurchaseOrder(publicId: string, lines: Array<{ ingredientId: string; quantity: string; expiresOn?: string; batchCode?: string }>) {
    return this.db.tx(async (tx) => {
      const po = await tx.selectFrom('purchase_orders').select(['id', 'branch_id', 'status']).where('cafe_id', '=', tenantId()).where('public_id', '=', publicId).forUpdate().executeTakeFirst();
      if (!po) throw notFound();
      assertBranchAllowed(po.branch_id);
      if (!['sent', 'partially_received'].includes(po.status)) throw conflict('PURCHASE_ORDER_NOT_RECEIVABLE');
      const items = await tx.selectFrom('purchase_order_items').selectAll().where('cafe_id', '=', tenantId()).where('purchase_order_id', '=', po.id).forUpdate().execute();
      let value = ZERO;
      for (const l of lines) {
        const ingredientId = await idOf(tx, 'ingredients', l.ingredientId);
        const item = items.find((i) => i.ingredient_id === ingredientId);
        if (!item) throw badRequest('INGREDIENT_NOT_ON_ORDER');
        const qty = D(l.quantity);
        const received = D(item.received_quantity).plus(qty);
        if (qty.lte(0) || received.gt(item.ordered_quantity)) throw badRequest('RECEIVE_QUANTITY_INVALID');
        await tx.updateTable('purchase_order_items').set({ received_quantity: received.toFixed(4) }).where('cafe_id', '=', tenantId()).where('id', '=', item.id).execute();
        item.received_quantity = received.toFixed(4);
        const batchId = Number((await tx.insertInto('stock_batches').values({ cafe_id: tenantId(), branch_id: po.branch_id, ingredient_id: ingredientId, batch_code: l.batchCode ?? null, received_quantity: qty.toFixed(4), remaining_quantity: qty.toFixed(4), unit_cost: item.unit_cost, received_at: new Date(), expires_on: l.expiresOn ? new Date(l.expiresOn) : null }).executeTakeFirstOrThrow()).insertId);
        await this.move(tx, { branchId: po.branch_id, ingredientId, type: 'purchase_receipt', quantity: qty, unitCost: item.unit_cost, sourceType: 'purchase_order', sourceId: po.id, batchId });
        value = value.plus(qty.times(item.unit_cost));
      }
      const done = items.every((i) => D(i.received_quantity).gte(i.ordered_quantity));
      await tx.updateTable('purchase_orders').set({ status: done ? 'received' : 'partially_received' }).where('cafe_id', '=', tenantId()).where('id', '=', po.id).execute();
      await this.accounting.post(tx, { sourceType: 'purchase_receipt', sourceId: (await tx.selectFrom('stock_movements').select('id').where('cafe_id', '=', tenantId()).orderBy('id', 'desc').limit(1).executeTakeFirstOrThrow()).id, kind: 'receipt', date: this.today(), branchId: po.branch_id, memo: 'Goods received', lines: [{ key: 'inventory', debit: value.toFixed(4) }, { key: 'accounts_payable', credit: value.toFixed(4) }] });
      await audit(tx, { action: 'purchase_order.received', entityType: 'purchase_order', entityId: publicId });
      return { status: done ? 'received' : 'partially_received' };
    });
  }

  async listSupplierInvoices() {
    return this.db.q.selectFrom('supplier_invoices as i').innerJoin('suppliers as s', 's.id', 'i.supplier_id').select(['i.public_id', 'i.supplier_invoice_number', 'i.status', 'i.currency_code', 'i.total_amount', 'i.paid_amount', 'i.invoice_date', 'i.due_on', 's.name as supplier']).where('i.cafe_id', '=', tenantId()).orderBy('i.id', 'desc').limit(200).execute();
  }
  // With a purchase order, the liability was booked at goods receipt. Without one, this books it.
  async createSupplierInvoice(d: { supplierId: string; purchaseOrderId?: string; number: string; subtotal: string; tax?: string; invoiceDate: string; dueOn?: string }) {
    return this.db.tx(async (tx) => {
      const { minor_unit } = await tx.selectFrom('currencies').select('minor_unit').where('code', '=', await this.currency(tx)).executeTakeFirstOrThrow();
      for (const a of [d.subtotal, d.tax]) if (a !== undefined && !assertPrecision(a, minor_unit)) throw badRequest('AMOUNT_PRECISION_INVALID', { maxDecimals: minor_unit });
      const publicId = ulid();
      const total = D(d.subtotal).plus(d.tax ?? 0);
      const id = Number((await tx.insertInto('supplier_invoices').values({
        public_id: publicId, cafe_id: tenantId(), supplier_id: await idOf(tx, 'suppliers', d.supplierId, 'SUPPLIER_NOT_FOUND'), purchase_order_id: d.purchaseOrderId ? await idOf(tx, 'purchase_orders', d.purchaseOrderId) : null,
        supplier_invoice_number: d.number, currency_code: await this.currency(tx), subtotal_amount: dbMoney(d.subtotal), tax_amount: dbMoney(d.tax ?? 0), total_amount: dbMoney(total), invoice_date: new Date(d.invoiceDate), due_on: d.dueOn ? new Date(d.dueOn) : null,
      }).executeTakeFirstOrThrow()).insertId);
      if (!d.purchaseOrderId) {
        await this.accounting.post(tx, { sourceType: 'supplier_invoice', sourceId: id, kind: 'bill', date: d.invoiceDate, memo: `Supplier invoice ${d.number}`, lines: [{ key: 'inventory', debit: dbMoney(total) }, { key: 'accounts_payable', credit: dbMoney(total) }] });
      }
      await audit(tx, { action: 'supplier_invoice.created', entityType: 'supplier_invoice', entityId: publicId });
      return { publicId };
    });
  }
  async paySupplierInvoice(publicId: string, d: { amount: string; methodCode: string; reference?: string; paidOn: string }) {
    return this.db.tx(async (tx) => {
      const inv = await tx.selectFrom('supplier_invoices').selectAll().where('cafe_id', '=', tenantId()).where('public_id', '=', publicId).forUpdate().executeTakeFirst();
      if (!inv) throw notFound();
      const paid = D(inv.paid_amount).plus(d.amount);
      if (D(d.amount).lte(0) || paid.gt(inv.total_amount)) throw badRequest('PAYMENT_EXCEEDS_INVOICE');
      const pid = ulid();
      const payId = Number((await tx.insertInto('supplier_payments').values({ public_id: pid, cafe_id: tenantId(), supplier_invoice_id: inv.id, method_code: d.methodCode, currency_code: inv.currency_code, amount: dbMoney(d.amount), reference: d.reference ?? null, paid_on: new Date(d.paidOn), recorded_by_user_id: requiredUserId() }).executeTakeFirstOrThrow()).insertId);
      await tx.updateTable('supplier_invoices').set({ paid_amount: dbMoney(paid), status: paid.eq(inv.total_amount) ? 'paid' : 'partially_paid' }).where('cafe_id', '=', tenantId()).where('id', '=', inv.id).execute();
      await this.accounting.post(tx, { sourceType: 'supplier_payment', sourceId: payId, kind: 'payment', date: d.paidOn, memo: `Payment ${inv.supplier_invoice_number}`, lines: [{ key: 'accounts_payable', debit: dbMoney(d.amount) }, { key: d.methodCode === 'cash' ? 'cash' : 'bank', credit: dbMoney(d.amount) }] });
      await audit(tx, { action: 'supplier_invoice.paid', entityType: 'supplier_invoice', entityId: publicId, after: { amount: d.amount } });
      return { publicId: pid, status: paid.eq(inv.total_amount) ? 'paid' : 'partially_paid' };
    });
  }
}
