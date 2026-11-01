import { Injectable } from '@nestjs/common';
import ExcelJS from 'exceljs';
import PDFDocument from 'pdfkit';
import { sql } from 'kysely';
import { requiredUserId, store, tenantId } from '../../common/context';
import { badRequest, conflict, notFound } from '../../common/errors';
import { ulid } from '../../common/ids';
import { assertBranchAllowed, currentBranch, idOf } from '../../common/lookup';
import { assertPrecision, D, dbMoney, ZERO } from '../../common/money';
import { audit, Db } from '../../infra/db/db.service';
import { AccountingService } from '../accounting/accounting.service';

@Injectable()
export class FinanceService {
  constructor(private readonly db: Db, private readonly accounting: AccountingService) {}

  private async currency() {
    return (await this.db.q.selectFrom('cafes').select('currency_code').where('id', '=', tenantId()).executeTakeFirstOrThrow()).currency_code;
  }

  // Expenses
  async categories() { return this.db.q.selectFrom('expense_categories').select(['id', 'name', 'is_active']).where('cafe_id', '=', tenantId()).orderBy('name').execute(); }
  async createCategory(name: string, accountCode?: string) {
    let accountId: number | null = null;
    if (accountCode) {
      const a = await this.db.q.selectFrom('accounting_accounts').select('id').where('cafe_id', '=', tenantId()).where('code', '=', accountCode).executeTakeFirst();
      if (!a) throw notFound('ACCOUNT_NOT_FOUND');
      accountId = a.id;
    }
    const r = await this.db.q.insertInto('expense_categories').values({ cafe_id: tenantId(), name, account_id: accountId }).executeTakeFirstOrThrow();
    return { id: Number(r.insertId) };
  }
  async listExpenses(from?: string, to?: string) {
    let q = this.db.q.selectFrom('expenses as e').innerJoin('expense_categories as c', 'c.id', 'e.expense_category_id').select(['e.public_id', 'c.name as category', 'e.currency_code', 'e.amount', 'e.tax_amount', 'e.expense_date', 'e.description', 'e.method_code', 'e.voided_at']).where('e.cafe_id', '=', tenantId());
    if (from) q = q.where('e.expense_date', '>=', new Date(from));
    if (to) q = q.where('e.expense_date', '<=', new Date(to));
    return q.orderBy('e.expense_date', 'desc').limit(500).execute();
  }
  private async assertCurrencyPrecision(currency: string, ...amounts: Array<string | undefined>) {
    const { minor_unit } = await this.db.q.selectFrom('currencies').select('minor_unit').where('code', '=', currency).executeTakeFirstOrThrow();
    for (const a of amounts) if (a !== undefined && !assertPrecision(a, minor_unit)) throw badRequest('AMOUNT_PRECISION_INVALID', { maxDecimals: minor_unit });
  }

  async createExpense(d: { categoryId: number; amount: string; taxAmount?: string; date: string; description?: string; methodCode?: string }) {
    const currency = await this.currency();
    await this.assertCurrencyPrecision(currency, d.amount, d.taxAmount);
    return this.db.tx(async (tx) => {
      const cat = await tx.selectFrom('expense_categories').select(['id', 'account_id']).where('cafe_id', '=', tenantId()).where('id', '=', d.categoryId).executeTakeFirst();
      if (!cat) throw notFound('CATEGORY_NOT_FOUND');
      const publicId = ulid();
      const id = Number((await tx.insertInto('expenses').values({ public_id: publicId, cafe_id: tenantId(), branch_id: store()?.branchId ?? null, expense_category_id: cat.id, currency_code: currency, amount: dbMoney(d.amount), tax_amount: dbMoney(d.taxAmount ?? 0), expense_date: new Date(d.date), description: d.description ?? null, method_code: d.methodCode ?? null, recorded_by_user_id: requiredUserId() }).executeTakeFirstOrThrow()).insertId);
      const fallback = await tx.selectFrom('accounting_accounts').select('id').where('cafe_id', '=', tenantId()).where('code', '=', '6900').executeTakeFirstOrThrow();
      await this.accounting.post(tx, { sourceType: 'expense', sourceId: id, kind: 'expense', date: d.date, memo: d.description, branchId: store()?.branchId, lines: [{ accountId: cat.account_id ?? fallback.id, debit: dbMoney(d.amount) }, { key: d.methodCode === 'cash' ? 'cash' : 'bank', credit: dbMoney(d.amount) }] });
      await audit(tx, { action: 'expense.created', entityType: 'expense', entityId: publicId, after: { amount: d.amount } });
      return { publicId };
    });
  }
  // Voiding keeps the record and reverses its ledger effect.
  async voidExpense(publicId: string, reason: string) {
    await this.db.tx(async (tx) => {
      const e = await tx.selectFrom('expenses').select(['id', 'voided_at']).where('cafe_id', '=', tenantId()).where('public_id', '=', publicId).forUpdate().executeTakeFirst();
      if (!e) throw notFound();
      if (e.voided_at) throw conflict('EXPENSE_ALREADY_VOIDED');
      await tx.updateTable('expenses').set({ voided_at: new Date(), void_reason: reason }).where('cafe_id', '=', tenantId()).where('id', '=', e.id).execute();
      const entry = await tx.selectFrom('journal_entries').select('id').where('cafe_id', '=', tenantId()).where('source_type', '=', 'expense').where('source_id', '=', e.id).executeTakeFirst();
      if (entry) await this.accounting.reverseIn(tx, entry.id, reason);
      await audit(tx, { action: 'expense.voided', entityType: 'expense', entityId: publicId, reason });
    });
    return { ok: true };
  }

  // Cash registers
  async registers() {
    let q = this.db.q.selectFrom('cash_registers').select(['id', 'public_id', 'name', 'is_active']).where('cafe_id', '=', tenantId());
    if (store()?.branchId) q = q.where('branch_id', '=', store()!.branchId!);
    const rows = await q.execute();
    const open = rows.length ? await this.db.q.selectFrom('cash_register_sessions').select(['cash_register_id', 'public_id', 'opened_at', 'opening_float_amount']).where('cafe_id', '=', tenantId()).where('status', '=', 'open').where('cash_register_id', 'in', rows.map((r) => r.id)).execute() : [];
    return rows.map(({ id, ...r }) => ({ ...r, openSession: open.find((o) => o.cash_register_id === id) ?? null }));
  }
  async createRegister(name: string) {
    const publicId = ulid();
    await this.db.q.insertInto('cash_registers').values({ public_id: publicId, cafe_id: tenantId(), branch_id: currentBranch(), name }).execute();
    return { publicId };
  }
  async openRegister(publicId: string, floatAmount: string) {
    const currency = await this.currency();
    return this.db.tx(async (tx) => {
      const reg = await tx.selectFrom('cash_registers').select(['id', 'branch_id']).where('cafe_id', '=', tenantId()).where('public_id', '=', publicId).executeTakeFirst();
      if (!reg) throw notFound();
      assertBranchAllowed(reg.branch_id);
      const sessionPublic = ulid();
      await tx.insertInto('cash_register_sessions').values({ public_id: sessionPublic, cafe_id: tenantId(), cash_register_id: reg.id, currency_code: currency, opening_float_amount: dbMoney(floatAmount), opened_by_user_id: requiredUserId() }).execute();
      await audit(tx, { action: 'cash_register.opened', entityType: 'cash_register', entityId: publicId, after: { float: floatAmount } });
      return { sessionId: sessionPublic };
    });
  }
  async registerTransaction(sessionPublicId: string, d: { type: 'pay_in' | 'pay_out' | 'adjustment'; amount: string; reason: string }) {
    return this.db.tx(async (tx) => {
      const s = await tx.selectFrom('cash_register_sessions').select(['id', 'status', 'currency_code']).where('cafe_id', '=', tenantId()).where('public_id', '=', sessionPublicId).forUpdate().executeTakeFirst();
      if (!s) throw notFound();
      if (s.status !== 'open') throw conflict('REGISTER_CLOSED');
      const signed = d.type === 'pay_out' ? D(d.amount).abs().neg() : d.type === 'pay_in' ? D(d.amount).abs() : D(d.amount);
      if (signed.isZero()) throw badRequest('AMOUNT_ZERO');
      await tx.insertInto('cash_register_transactions').values({ cafe_id: tenantId(), session_id: s.id, transaction_type: d.type, currency_code: s.currency_code, amount: dbMoney(signed), reason: d.reason, recorded_by_user_id: requiredUserId() }).execute();
      await audit(tx, { action: 'cash_register.transaction', entityType: 'cash_register_session', entityId: sessionPublicId, reason: d.reason, after: { type: d.type, amount: signed.toString() } });
      return { ok: true };
    });
  }
  async closeRegister(sessionPublicId: string, counted: string) {
    return this.db.tx(async (tx) => {
      const s = await tx.selectFrom('cash_register_sessions').selectAll().where('cafe_id', '=', tenantId()).where('public_id', '=', sessionPublicId).forUpdate().executeTakeFirst();
      if (!s) throw notFound();
      if (s.status !== 'open') throw conflict('REGISTER_CLOSED');
      const sum = await tx.selectFrom('cash_register_transactions').select((eb) => eb.fn.coalesce(eb.fn.sum<string>('amount'), sql<string>`0`).as('s')).where('cafe_id', '=', tenantId()).where('session_id', '=', s.id).executeTakeFirstOrThrow();
      const expected = D(s.opening_float_amount).plus(sum.s);
      const variance = D(counted).minus(expected);
      await tx.updateTable('cash_register_sessions').set({ status: 'closed', expected_closing_amount: dbMoney(expected), counted_closing_amount: dbMoney(counted), variance_amount: dbMoney(variance), closed_by_user_id: requiredUserId(), closed_at: new Date() }).where('cafe_id', '=', tenantId()).where('id', '=', s.id).execute();
      await audit(tx, { action: 'cash_register.closed', entityType: 'cash_register_session', entityId: sessionPublicId, after: { expected: expected.toString(), counted, variance: variance.toString() } });
      return { expected: expected.toString(), counted, variance: variance.toString() };
    });
  }

  // Payroll records (not a statutory payroll engine)
  async listPayroll() {
    return this.db.q.selectFrom('payroll_entries as p').innerJoin('cafe_staff as s', 's.id', 'p.staff_id').innerJoin('users as u', 'u.id', 's.user_id').select(['p.public_id', 'u.full_name', 'p.period_start', 'p.period_end', 'p.currency_code', 'p.gross_amount', 'p.deductions_amount', 'p.net_amount', 'p.status', 'p.paid_on']).where('p.cafe_id', '=', tenantId()).orderBy('p.id', 'desc').limit(200).execute();
  }
  async createPayroll(d: { staffId: string; periodStart: string; periodEnd: string; gross: string; deductions?: string; notes?: string }) {
    const currency = await this.currency();
    await this.assertCurrencyPrecision(currency, d.gross, d.deductions);
    const net = D(d.gross).minus(d.deductions ?? 0);
    const publicId = ulid();
    await this.db.tx(async (tx) => {
      await tx.insertInto('payroll_entries').values({ public_id: publicId, cafe_id: tenantId(), staff_id: await idOf(tx, 'cafe_staff', d.staffId, 'STAFF_NOT_FOUND'), period_start: new Date(d.periodStart), period_end: new Date(d.periodEnd), currency_code: currency, gross_amount: dbMoney(d.gross), deductions_amount: dbMoney(d.deductions ?? 0), net_amount: dbMoney(net), notes: d.notes ?? null, created_by_user_id: requiredUserId() }).execute();
      await audit(tx, { action: 'payroll.created', entityType: 'payroll', entityId: publicId });
    });
    return { publicId };
  }
  async payPayroll(publicId: string, paidOn: string, method: 'cash' | 'bank') {
    await this.db.tx(async (tx) => {
      const p = await tx.selectFrom('payroll_entries').selectAll().where('cafe_id', '=', tenantId()).where('public_id', '=', publicId).forUpdate().executeTakeFirst();
      if (!p) throw notFound();
      if (p.status === 'paid') throw conflict('PAYROLL_ALREADY_PAID');
      await tx.updateTable('payroll_entries').set({ status: 'paid', paid_on: new Date(paidOn) }).where('cafe_id', '=', tenantId()).where('id', '=', p.id).execute();
      await this.accounting.post(tx, { sourceType: 'payroll', sourceId: p.id, kind: 'salary', date: paidOn, memo: 'Salary', lines: [{ key: 'salaries', debit: p.gross_amount }, { key: 'salaries_payable', credit: p.deductions_amount }, { key: method, credit: p.net_amount }] });
      await audit(tx, { action: 'payroll.paid', entityType: 'payroll', entityId: publicId });
    });
    return { ok: true };
  }

  // Sales reports. Derived from recorded orders and payments only. Empty periods return zeros, never estimates.
  private branchFilter() {
    const b = store()?.branchId;
    const allowed = store()?.principal?.branchIds;
    if (b) return sql`AND o.branch_id = ${b}`;
    if (allowed?.length) return sql`AND o.branch_id IN (${sql.join(allowed)})`;
    return sql``;
  }

  async salesReport(from: string, to: string, group: 'day' | 'week' | 'month' | 'year') {
    const bucket = { day: sql`o.business_date`, week: sql`DATE_SUB(o.business_date, INTERVAL WEEKDAY(o.business_date) DAY)`, month: sql`DATE_FORMAT(o.business_date, '%Y-%m-01')`, year: sql`DATE_FORMAT(o.business_date, '%Y-01-01')` }[group];
    const rows = await sql<Record<string, string>>`
      SELECT ${bucket} AS period, COUNT(*) AS orders, COALESCE(SUM(o.subtotal_amount),0) AS gross_sales, COALESCE(SUM(o.discount_amount),0) AS discounts, COALESCE(SUM(o.tax_amount),0) AS tax_collected,
             COALESCE(SUM(o.refunded_amount),0) AS refunds, COALESCE(SUM(o.total_amount - o.tax_amount - o.refunded_amount),0) AS net_sales, COALESCE(SUM(o.paid_amount),0) AS collected
      FROM orders o WHERE o.cafe_id = ${tenantId()} AND o.status <> 'cancelled' AND o.business_date BETWEEN ${from} AND ${to} ${this.branchFilter()}
      GROUP BY period ORDER BY period`.execute(this.db.q);
    return { from, to, group, currency: await this.currency(), rows: rows.rows.map((r) => ({ ...r, period: new Date(r.period!).toISOString().slice(0, 10) }) as Record<string, string>) };
  }

  async paymentBreakdown(from: string, to: string) {
    const rows = await sql<{ method_code: string; provider_code: string | null; n: number; amount: string; refunded: string; fees: string }>`
      SELECT p.method_code, p.provider_code, COUNT(*) AS n, SUM(p.amount) AS amount, SUM(p.refunded_amount) AS refunded, COALESCE(SUM(p.gateway_fee_amount),0) AS fees
      FROM payments p JOIN orders o ON o.id = p.order_id AND o.cafe_id = p.cafe_id
      WHERE p.cafe_id = ${tenantId()} AND p.status IN ('succeeded','partially_refunded','refunded') AND o.business_date BETWEEN ${from} AND ${to} ${this.branchFilter()}
      GROUP BY p.method_code, p.provider_code`.execute(this.db.q);
    return { from, to, currency: await this.currency(), rows: rows.rows };
  }

  async foodCost(from: string, to: string) {
    const rows = await this.accounting.trialBalance(from, to);
    const cogs = rows.filter((r) => r.code === '5000').reduce((a, r) => a.plus(r.debit).minus(r.credit), ZERO);
    const revenue = rows.filter((r) => r.account_type === 'revenue').reduce((a, r) => a.plus(r.credit).minus(r.debit), ZERO);
    return { from, to, cogs: cogs.toString(), revenue: revenue.toString(), foodCostPercent: revenue.isZero() ? null : cogs.div(revenue).times(100).toFixed(2) };
  }

  async auditTrail(from?: string) {
    let q = this.db.q.selectFrom('audit_logs').select(['id', 'actor_type', 'actor_id', 'action', 'entity_type', 'entity_id', 'reason', 'occurred_at']).where('cafe_id', '=', tenantId());
    if (from) q = q.where('occurred_at', '>=', new Date(from));
    return q.orderBy('id', 'desc').limit(500).execute();
  }

  private async tabular(type: string, from: string, to: string): Promise<{ title: string; columns: string[]; rows: Array<Array<string | number>> }> {
    if (type === 'sales') {
      const r = await this.salesReport(from, to, 'day');
      return { title: `Sales ${from} to ${to} (${r.currency})`, columns: ['Date', 'Orders', 'Gross', 'Discounts', 'Tax', 'Refunds', 'Net', 'Collected'], rows: r.rows.map((x) => [x.period!, x.orders!, x.gross_sales!, x.discounts!, x.tax_collected!, x.refunds!, x.net_sales!, x.collected!]) };
    }
    if (type === 'pnl') {
      const r = await this.accounting.profitAndLoss(from, to);
      return { title: `Profit and loss ${from} to ${to}`, columns: ['Code', 'Account', 'Amount'], rows: [...r.revenue.map((x) => [x.code, x.name, x.amount]), ['', 'Total revenue', r.totalRevenue], ...r.expenses.map((x) => [x.code, x.name, x.amount]), ['', 'Total expenses', r.totalExpenses], ['', 'Net profit', r.netProfit]] };
    }
    if (type === 'trial-balance') {
      const r = await this.accounting.trialBalance(from, to);
      return { title: `Trial balance ${from} to ${to}`, columns: ['Code', 'Account', 'Type', 'Debit', 'Credit'], rows: r.map((x) => [x.code, x.name, x.account_type, x.debit, x.credit]) };
    }
    if (type === 'payments') {
      const r = await this.paymentBreakdown(from, to);
      return { title: `Payments ${from} to ${to} (${r.currency})`, columns: ['Method', 'Provider', 'Count', 'Amount', 'Refunded', 'Fees'], rows: r.rows.map((x) => [x.method_code, x.provider_code ?? '', x.n, x.amount, x.refunded, x.fees]) };
    }
    throw badRequest('REPORT_UNKNOWN');
  }

  async export(type: string, format: 'xlsx' | 'pdf', from: string, to: string): Promise<{ body: Buffer; mime: string; filename: string }> {
    const t = await this.tabular(type, from, to);
    const filename = `${type}-${from}-${to}.${format}`;
    if (format === 'xlsx') {
      const wb = new ExcelJS.Workbook();
      const ws = wb.addWorksheet('Report');
      ws.addRow([t.title]).font = { bold: true };
      ws.addRow(t.columns).font = { bold: true };
      // Numeric columns stay decimal strings in the sheet, so exact values are never passed through a float.
      t.rows.forEach((r) => ws.addRow(r));
      ws.columns.forEach((c) => { c.width = 18; });
      return { body: Buffer.from(await wb.xlsx.writeBuffer()), mime: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', filename };
    }
    const body = await new Promise<Buffer>((resolve, reject) => {
      const doc = new PDFDocument({ size: 'A4', margin: 40 });
      const chunks: Buffer[] = [];
      doc.on('data', (c: Buffer) => chunks.push(c));
      doc.on('end', () => resolve(Buffer.concat(chunks)));
      doc.on('error', reject);
      doc.fontSize(14).text(t.title).moveDown();
      doc.fontSize(9).text(t.columns.join('  |  ')).moveDown(0.5);
      t.rows.forEach((r) => doc.text(r.join('  |  ')));
      if (!t.rows.length) doc.text('No data for this period.');
      doc.end();
    });
    return { body, mime: 'application/pdf', filename };
  }
}
