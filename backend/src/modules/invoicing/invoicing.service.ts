import { Injectable } from '@nestjs/common';
import PDFDocument from 'pdfkit';
import { actorUserId, tenantId } from '../../common/context';
import { notFound } from '../../common/errors';
import { ulid } from '../../common/ids';
import { idOf } from '../../common/lookup';
import { allocate, D, dbMoney, Decimal, money, ZERO } from '../../common/money';
import { audit, Db, Tx } from '../../infra/db/db.service';
import { AccountingService } from '../accounting/accounting.service';
import { loadSettings } from '../tenancy/settings';

@Injectable()
export class InvoicingService {
  constructor(private readonly db: Db, private readonly accounting: AccountingService) {}

  private fiscalYear(date: string, startMonth: number): number {
    const [y, m] = date.split('-').map(Number) as [number, number];
    return m >= startMonth ? y : y - 1;
  }

  // Row lock on the sequence: gapless numbers even with concurrent checkouts. Rollback releases the number.
  private async nextNumber(tx: Tx, branchId: number, series: string, fy: number) {
    const cafeId = tenantId();
    await tx.insertInto('invoice_sequences').ignore().values({ cafe_id: cafeId, branch_id: branchId, series, fiscal_year: fy }).execute();
    const seq = await tx.selectFrom('invoice_sequences').select(['id', 'last_number']).where('cafe_id', '=', cafeId).where('branch_id', '=', branchId).where('series', '=', series).where('fiscal_year', '=', fy).forUpdate().executeTakeFirstOrThrow();
    const next = Number(seq.last_number) + 1;
    await tx.updateTable('invoice_sequences').set({ last_number: next }).where('cafe_id', '=', cafeId).where('id', '=', seq.id).execute();
    return next;
  }

  private async seller(tx: Tx, branchId: number, date: string) {
    const cafeId = tenantId();
    const cafe = await tx.selectFrom('cafes').select(['legal_name', 'display_name', 'fiscal_year_start_month', 'currency_code', 'business_registration_number']).where('id', '=', cafeId).executeTakeFirstOrThrow();
    const branch = await tx.selectFrom('cafe_branches').select(['code', 'address_line1', 'address_line2', 'city', 'state_code', 'state_name', 'postal_code']).where('cafe_id', '=', cafeId).where('id', '=', branchId).executeTakeFirstOrThrow();
    const regs = await tx.selectFrom('tax_registrations').select(['branch_id', 'tax_system', 'registration_number', 'legal_name', 'region_code']).where('cafe_id', '=', cafeId).where('valid_from', '<=', new Date(date)).where((eb) => eb.or([eb('valid_to', 'is', null), eb('valid_to', '>=', new Date(date))])).execute();
    const reg = regs.find((r) => r.branch_id === branchId) ?? regs.find((r) => r.branch_id === null);
    return { cafe, branch, reg, snapshot: { legalName: reg?.legal_name ?? cafe.legal_name, displayName: cafe.display_name, address: branch, taxSystem: reg?.tax_system ?? null, taxRegistration: reg?.registration_number ?? null, businessRegistration: cafe.business_registration_number } };
  }

  // Issued once per order, when fully paid. Posts revenue and tax; the payment entries clear receivables.
  async issueForOrder(tx: Tx, orderId: number) {
    const cafeId = tenantId();
    const existing = await tx.selectFrom('invoices').select('id').where('cafe_id', '=', cafeId).where('order_id', '=', orderId).where('document_type', '=', 'invoice').executeTakeFirst();
    if (existing) return existing.id;
    const o = await tx.selectFrom('orders').selectAll().where('cafe_id', '=', cafeId).where('id', '=', orderId).executeTakeFirstOrThrow();
    const date = o.business_date.toISOString().slice(0, 10);
    const { cafe, branch, reg, snapshot } = await this.seller(tx, o.branch_id, date);
    const settings = await loadSettings(tx);
    const fy = this.fiscalYear(date, cafe.fiscal_year_start_month);
    const publicId = ulid();
    const id = Number((await tx.insertInto('invoices').values({
      public_id: publicId, cafe_id: cafeId, branch_id: o.branch_id, order_id: o.id, series: settings.invoiceSeries, fiscal_year: fy, language_code: o.language_code, currency_code: o.currency_code,
      subtotal_amount: o.subtotal_amount, discount_amount: o.discount_amount, tax_amount: o.tax_amount, rounding_amount: o.rounding_amount, total_amount: o.total_amount, seller_snapshot: JSON.stringify(snapshot), place_of_supply: reg?.region_code ?? branch.state_code, created_by_user_id: actorUserId(),
    }).executeTakeFirstOrThrow()).insertId);

    const items = await tx.selectFrom('order_items as i').leftJoin('tax_categories as c', 'c.id', 'i.tax_category_id').select(['i.id', 'i.name_snapshot', 'i.variant_name_snapshot', 'i.quantity', 'i.unit_price', 'i.addons_amount', 'i.discount_amount', 'i.tax_amount', 'i.line_total_amount', 'c.tax_code']).where('i.cafe_id', '=', cafeId).where('i.order_id', '=', o.id).where('i.status', '=', 'active').execute();
    for (const i of items) {
      const taxable = D(i.line_total_amount).minus(i.tax_amount);
      await tx.insertInto('invoice_lines').values({ cafe_id: cafeId, invoice_id: id, order_item_id: i.id, description: [i.name_snapshot, i.variant_name_snapshot].filter(Boolean).join(' - ').slice(0, 300), tax_code: i.tax_code, quantity: i.quantity, unit_price: i.unit_price, discount_amount: i.discount_amount, taxable_amount: dbMoney(taxable), tax_amount: i.tax_amount, line_total_amount: i.line_total_amount }).execute();
    }
    const taxes = items.length ? await tx.selectFrom('order_item_taxes').selectAll().where('cafe_id', '=', cafeId).where('order_item_id', 'in', items.map((i) => i.id)).execute() : [];
    const grouped = new Map<string, { name: string; rate: string; taxable: Decimal; amount: Decimal }>();
    for (const t of taxes) {
      const k = `${t.component_code}:${t.rate_percent}`;
      const g = grouped.get(k) ?? { name: t.display_name, rate: t.rate_percent, taxable: ZERO, amount: ZERO };
      grouped.set(k, { ...g, taxable: g.taxable.plus(t.taxable_amount), amount: g.amount.plus(t.tax_amount) });
    }
    for (const [k, g] of grouped) await tx.insertInto('invoice_tax_lines').values({ cafe_id: cafeId, invoice_id: id, component_code: k.split(':')[0]!, display_name: g.name, rate_percent: g.rate, taxable_amount: dbMoney(g.taxable), tax_amount: dbMoney(g.amount) }).execute();

    const seq = await this.nextNumber(tx, o.branch_id, settings.invoiceSeries, fy);
    await tx.updateTable('invoices').set({ status: 'issued', sequence_no: seq, invoice_number: `${settings.invoiceSeries}/${branch.code}/${fy}/${seq}`, issued_at: new Date() }).where('cafe_id', '=', cafeId).where('id', '=', id).execute();

    const revenue = D(o.total_amount).minus(o.tax_amount).plus(o.discount_amount);
    await this.accounting.post(tx, {
      sourceType: 'order', sourceId: o.id, kind: 'sale', date, branchId: o.branch_id, memo: `Sale ${o.public_id}`,
      lines: [{ key: 'accounts_receivable', debit: o.total_amount }, { key: 'sales_discounts', debit: o.discount_amount }, { key: 'sales_revenue', credit: dbMoney(revenue) }, { key: 'tax_payable', credit: o.tax_amount }],
    });
    return id;
  }

  // A refund on an invoiced order always issues a credit note, with tax in the same proportion.
  async issueCreditNote(tx: Tx, orderId: number, amount: string, refundId: number, reason: string, minorUnit: number) {
    const cafeId = tenantId();
    const inv = await tx.selectFrom('invoices').selectAll().where('cafe_id', '=', cafeId).where('order_id', '=', orderId).where('document_type', '=', 'invoice').where('status', '=', 'issued').executeTakeFirst();
    const o = await tx.selectFrom('orders').select(['branch_id', 'language_code', 'currency_code', 'total_amount', 'tax_amount', 'business_date']).where('cafe_id', '=', cafeId).where('id', '=', orderId).executeTakeFirstOrThrow();
    const total = D(amount);
    const tax = D(o.total_amount).isZero() ? ZERO : D(o.tax_amount).times(total).div(o.total_amount).toDecimalPlaces(minorUnit);
    const net = total.minus(tax);
    const today = new Date().toISOString().slice(0, 10);
    const { cafe, snapshot } = await this.seller(tx, o.branch_id, today);
    if (inv) {
      const settings = await loadSettings(tx);
      const series = `${settings.invoiceSeries}-CN`.slice(0, 16);
      const fy = this.fiscalYear(today, cafe.fiscal_year_start_month);
      const id = Number((await tx.insertInto('invoices').values({ public_id: ulid(), cafe_id: cafeId, branch_id: o.branch_id, order_id: orderId, document_type: 'credit_note', original_invoice_id: inv.id, series, fiscal_year: fy, language_code: o.language_code, currency_code: o.currency_code, subtotal_amount: dbMoney(net), tax_amount: dbMoney(tax), total_amount: dbMoney(total), seller_snapshot: JSON.stringify(snapshot), place_of_supply: inv.place_of_supply, created_by_user_id: actorUserId() }).executeTakeFirstOrThrow()).insertId);
      await tx.insertInto('invoice_lines').values({ cafe_id: cafeId, invoice_id: id, description: reason.slice(0, 300), quantity: '1', unit_price: dbMoney(net), taxable_amount: dbMoney(net), tax_amount: dbMoney(tax), line_total_amount: dbMoney(total) }).execute();
      const lines = await tx.selectFrom('invoice_tax_lines').selectAll().where('cafe_id', '=', cafeId).where('invoice_id', '=', inv.id).execute();
      const parts = allocate(tax, lines.map((l) => D(l.tax_amount)), minorUnit);
      for (const [i, l] of lines.entries()) await tx.insertInto('invoice_tax_lines').values({ cafe_id: cafeId, invoice_id: id, component_code: l.component_code, display_name: l.display_name, rate_percent: l.rate_percent, taxable_amount: dbMoney(net), tax_amount: dbMoney(parts[i]!) }).execute();
      const seq = await this.nextNumber(tx, o.branch_id, series, fy);
      await tx.updateTable('invoices').set({ status: 'issued', sequence_no: seq, invoice_number: `${series}/${fy}/${seq}`, issued_at: new Date() }).where('cafe_id', '=', cafeId).where('id', '=', id).execute();
    }
    return { tax, net, today, refundId };
  }

  async list(query: { from?: string; to?: string }) {
    let q = this.db.q.selectFrom('invoices').select(['public_id', 'invoice_number', 'document_type', 'status', 'currency_code', 'total_amount', 'tax_amount', 'issued_at']).where('cafe_id', '=', tenantId()).where('status', '!=', 'draft');
    if (query.from) q = q.where('issued_at', '>=', new Date(query.from));
    if (query.to) q = q.where('issued_at', '<=', new Date(query.to));
    return q.orderBy('id', 'desc').limit(200).execute();
  }

  async get(publicId: string) {
    const id = await idOf(this.db.q, 'invoices', publicId);
    return this.loadById(id);
  }

  async loadById(id: number) {
    const inv = await this.db.q.selectFrom('invoices').selectAll().where('cafe_id', '=', tenantId()).where('id', '=', id).executeTakeFirstOrThrow();
    const [lines, taxes] = await Promise.all([
      this.db.q.selectFrom('invoice_lines').selectAll().where('cafe_id', '=', tenantId()).where('invoice_id', '=', id).execute(),
      this.db.q.selectFrom('invoice_tax_lines').selectAll().where('cafe_id', '=', tenantId()).where('invoice_id', '=', id).execute(),
    ]);
    const c = inv.currency_code;
    return {
      publicId: inv.public_id, number: inv.invoice_number, documentType: inv.document_type, status: inv.status, issuedAt: inv.issued_at, language: inv.language_code, seller: inv.seller_snapshot, placeOfSupply: inv.place_of_supply,
      subtotal: money(inv.subtotal_amount, c), discount: money(inv.discount_amount, c), tax: money(inv.tax_amount, c), rounding: money(inv.rounding_amount, c), total: money(inv.total_amount, c),
      lines: lines.map((l) => ({ description: l.description, taxCode: l.tax_code, quantity: l.quantity, unitPrice: money(l.unit_price, c), discount: money(l.discount_amount, c), taxable: money(l.taxable_amount, c), tax: money(l.tax_amount, c), total: money(l.line_total_amount, c) })),
      taxBreakdown: taxes.map((t) => ({ code: t.component_code, name: t.display_name, ratePercent: t.rate_percent, taxable: money(t.taxable_amount, c), amount: money(t.tax_amount, c) })),
    };
  }

  // Latin-script PDF only for now: non-Latin shaping needs bundled fonts (see KNOWN_ISSUES K-10).
  async pdf(publicId: string): Promise<Buffer> {
    const i = await this.get(publicId);
    const s = i.seller as { legalName?: string; taxRegistration?: string; address?: { address_line1?: string; city?: string } };
    return new Promise((resolve, reject) => {
      const doc = new PDFDocument({ size: 'A4', margin: 50 });
      const chunks: Buffer[] = [];
      doc.on('data', (c: Buffer) => chunks.push(c));
      doc.on('end', () => resolve(Buffer.concat(chunks)));
      doc.on('error', reject);
      doc.fontSize(16).text(s.legalName ?? '');
      doc.fontSize(10).text([s.address?.address_line1, s.address?.city].filter(Boolean).join(', '));
      if (s.taxRegistration) doc.text(`Tax registration: ${s.taxRegistration}`);
      doc.moveDown().fontSize(13).text(`${i.documentType === 'credit_note' ? 'Credit note' : 'Tax invoice'} ${i.number}`);
      doc.fontSize(10).text(`Issued: ${i.issuedAt?.toISOString().slice(0, 10)}`).moveDown();
      for (const l of i.lines) doc.text(`${D(l.quantity).toNumber()} x ${l.description}  ${l.total.amount} ${l.total.currency}`);
      doc.moveDown().text(`Subtotal: ${i.subtotal.amount}`).text(`Discount: ${i.discount.amount}`);
      for (const t of i.taxBreakdown) doc.text(`${t.name} (${D(t.ratePercent).toNumber()}%): ${t.amount.amount}`);
      doc.fontSize(12).text(`Total: ${i.total.amount} ${i.total.currency}`);
      doc.end();
    });
  }
}
