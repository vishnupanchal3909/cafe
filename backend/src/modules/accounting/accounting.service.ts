import { Injectable } from '@nestjs/common';
import { sql } from 'kysely';
import { actorUserId, requiredUserId, tenantId } from '../../common/context';
import { badRequest, conflict, notFound } from '../../common/errors';
import { ulid } from '../../common/ids';
import { D, Decimal, dbMoney, ZERO } from '../../common/money';
import { audit, Db, Q, Tx } from '../../infra/db/db.service';

export interface PostingLine { key?: string; accountId?: number; debit?: Decimal.Value; credit?: Decimal.Value; description?: string }
export interface Posting { sourceType: string; sourceId: number; kind: string; date: string; branchId?: number | null; memo?: string; lines: PostingLine[] }

@Injectable()
export class AccountingService {
  constructor(private readonly db: Db) {}

  private async periodFor(tx: Tx, date: string): Promise<number> {
    const existing = await tx.selectFrom('financial_periods').select('id').where('cafe_id', '=', tenantId())
      .where('starts_on', '<=', new Date(date)).where('ends_on', '>=', new Date(date)).orderBy('starts_on', 'desc').executeTakeFirst();
    if (existing) return existing.id;
    const [y, m] = date.split('-').map(Number) as [number, number];
    const start = new Date(Date.UTC(y, m - 1, 1));
    const end = new Date(Date.UTC(y, m, 0));
    const r = await tx.insertInto('financial_periods').values({ cafe_id: tenantId(), name: `${y}-${String(m).padStart(2, '0')}`, starts_on: start, ends_on: end }).executeTakeFirstOrThrow();
    return Number(r.insertId);
  }

  // Idempotent per (source, kind): a retried event finds its entry instead of double posting.
  async post(tx: Tx, p: Posting): Promise<number | null> {
    const lines = p.lines.filter((l) => D(l.debit ?? 0).gt(0) || D(l.credit ?? 0).gt(0));
    if (!lines.length) return null;
    const existing = await tx.selectFrom('journal_entries').select('id').where('cafe_id', '=', tenantId()).where('source_type', '=', p.sourceType).where('source_id', '=', p.sourceId).where('entry_kind', '=', p.kind).executeTakeFirst();
    if (existing) return existing.id;

    const cafe = await tx.selectFrom('cafes').select('currency_code').where('id', '=', tenantId()).executeTakeFirstOrThrow();
    const keys = [...new Set(lines.map((l) => l.key).filter(Boolean))] as string[];
    const accounts = keys.length ? await tx.selectFrom('accounting_accounts').select(['id', 'system_key']).where('cafe_id', '=', tenantId()).where('system_key', 'in', keys).execute() : [];
    const entryId = Number((await tx.insertInto('journal_entries').values({
      public_id: ulid(), cafe_id: tenantId(), branch_id: p.branchId ?? null, period_id: await this.periodFor(tx, p.date), entry_date: new Date(p.date), currency_code: cafe.currency_code,
      memo: p.memo ?? null, source_type: p.sourceType, source_id: p.sourceId, entry_kind: p.kind, created_by_user_id: actorUserId(),
    }).executeTakeFirstOrThrow()).insertId);
    for (const l of lines) {
      const accountId = l.accountId ?? accounts.find((a) => a.system_key === l.key)?.id;
      if (!accountId) throw new Error(`Account ${l.key} is missing from this cafe's chart of accounts`);
      await tx.insertInto('journal_entry_lines').values({ cafe_id: tenantId(), journal_entry_id: entryId, account_id: accountId, debit_amount: dbMoney(l.debit ?? 0), credit_amount: dbMoney(l.credit ?? 0), description: l.description ?? null }).execute();
    }
    await tx.updateTable('journal_entries').set({ status: 'posted' }).where('cafe_id', '=', tenantId()).where('id', '=', entryId).execute();
    return entryId;
  }

  async accounts() {
    return this.db.q.selectFrom('accounting_accounts').select(['id', 'code', 'name', 'account_type', 'system_key', 'is_active']).where('cafe_id', '=', tenantId()).orderBy('code').execute();
  }
  async createAccount(d: { code: string; name: string; accountType: 'asset' | 'liability' | 'equity' | 'revenue' | 'expense' }) {
    const r = await this.db.q.insertInto('accounting_accounts').values({ cafe_id: tenantId(), code: d.code, name: d.name, account_type: d.accountType }).executeTakeFirstOrThrow();
    return { id: Number(r.insertId) };
  }
  async periods() {
    return this.db.q.selectFrom('financial_periods').selectAll().where('cafe_id', '=', tenantId()).orderBy('starts_on', 'desc').execute();
  }
  async createPeriod(d: { name: string; startsOn: string; endsOn: string }) {
    const r = await this.db.q.insertInto('financial_periods').values({ cafe_id: tenantId(), name: d.name, starts_on: new Date(d.startsOn), ends_on: new Date(d.endsOn) }).executeTakeFirstOrThrow();
    return { id: Number(r.insertId) };
  }
  async closePeriod(id: number) {
    await this.db.tx(async (tx) => {
      const r = await tx.updateTable('financial_periods').set({ status: 'closed', closed_by_user_id: requiredUserId(), closed_at: new Date() }).where('cafe_id', '=', tenantId()).where('id', '=', id).where('status', '=', 'open').executeTakeFirst();
      if (!r.numUpdatedRows) throw notFound();
      await audit(tx, { action: 'finance.period_closed', entityType: 'financial_period', entityId: id });
    });
    return { ok: true };
  }

  async listEntries(from?: string, to?: string) {
    let q = this.db.q.selectFrom('journal_entries').select(['id', 'public_id', 'entry_date', 'status', 'memo', 'source_type', 'entry_kind', 'reversal_of_entry_id', 'posted_at', 'currency_code']).where('cafe_id', '=', tenantId());
    if (from) q = q.where('entry_date', '>=', new Date(from));
    if (to) q = q.where('entry_date', '<=', new Date(to));
    const entries = await q.orderBy('id', 'desc').limit(200).execute();
    const lines = entries.length ? await this.db.q.selectFrom('journal_entry_lines as l').innerJoin('accounting_accounts as a', 'a.id', 'l.account_id').select(['l.journal_entry_id', 'a.code', 'a.name', 'l.debit_amount', 'l.credit_amount']).where('l.cafe_id', '=', tenantId()).where('l.journal_entry_id', 'in', entries.map((e) => e.id)).execute() : [];
    return entries.map((e) => ({ ...e, lines: lines.filter((l) => l.journal_entry_id === e.id) }));
  }

  async manualEntry(d: { date: string; memo: string; lines: Array<{ accountId: number; debit?: string; credit?: string; description?: string }> }) {
    return this.db.tx(async (tx) => {
      const debit = d.lines.reduce((a, l) => a.plus(l.debit ?? 0), ZERO);
      const credit = d.lines.reduce((a, l) => a.plus(l.credit ?? 0), ZERO);
      if (!debit.eq(credit)) throw badRequest('JOURNAL_UNBALANCED');
      const sourceId = Date.now();
      const id = await this.post(tx, { sourceType: 'manual', sourceId, kind: ulid(), date: d.date, memo: d.memo, lines: d.lines });
      await audit(tx, { action: 'finance.manual_journal', entityType: 'journal_entry', entityId: id ?? undefined, reason: d.memo });
      return { id };
    });
  }

  // Corrections never edit history: a new entry mirrors the original with sides swapped.
  async reverse(entryId: number, reason: string, date?: string) {
    return this.db.tx(async (tx) => this.reverseIn(tx, entryId, reason, date));
  }

  async reverseIn(tx: Tx, entryId: number, reason: string, date?: string) {
    const entry = await tx.selectFrom('journal_entries').selectAll().where('cafe_id', '=', tenantId()).where('id', '=', entryId).executeTakeFirst();
    if (!entry) throw notFound();
    if (entry.status !== 'posted') throw conflict('JOURNAL_NOT_POSTED');
    const used = await tx.selectFrom('journal_entries').select('id').where('cafe_id', '=', tenantId()).where('reversal_of_entry_id', '=', entryId).executeTakeFirst();
    if (used) throw conflict('JOURNAL_ALREADY_REVERSED');
    const lines = await tx.selectFrom('journal_entry_lines').selectAll().where('cafe_id', '=', tenantId()).where('journal_entry_id', '=', entryId).execute();
    const entryDate = date ?? new Date().toISOString().slice(0, 10);
    const id = Number((await tx.insertInto('journal_entries').values({
      public_id: ulid(), cafe_id: tenantId(), branch_id: entry.branch_id, period_id: await this.periodFor(tx, entryDate), entry_date: new Date(entryDate), currency_code: entry.currency_code,
      memo: `Reversal: ${reason}`.slice(0, 500), reversal_of_entry_id: entryId, created_by_user_id: actorUserId(),
    }).executeTakeFirstOrThrow()).insertId);
    for (const l of lines) await tx.insertInto('journal_entry_lines').values({ cafe_id: tenantId(), journal_entry_id: id, account_id: l.account_id, debit_amount: l.credit_amount, credit_amount: l.debit_amount, description: l.description }).execute();
    await tx.updateTable('journal_entries').set({ status: 'posted' }).where('cafe_id', '=', tenantId()).where('id', '=', id).execute();
    await audit(tx, { action: 'finance.journal_reversed', entityType: 'journal_entry', entityId: entryId, reason });
    return { id };
  }

  async trialBalance(from: string, to: string, q: Q = this.db.q) {
    const rows = await sql<{ code: string; name: string; account_type: string; debit: string; credit: string }>`
      SELECT a.code, a.name, a.account_type, COALESCE(SUM(l.debit_amount),0) AS debit, COALESCE(SUM(l.credit_amount),0) AS credit
      FROM accounting_accounts a
      JOIN journal_entry_lines l ON l.account_id = a.id AND l.cafe_id = a.cafe_id
      JOIN journal_entries e ON e.id = l.journal_entry_id AND e.cafe_id = l.cafe_id AND e.status = 'posted' AND e.entry_date BETWEEN ${from} AND ${to}
      WHERE a.cafe_id = ${tenantId()} GROUP BY a.id, a.code, a.name, a.account_type ORDER BY a.code`.execute(q);
    return rows.rows;
  }

  async profitAndLoss(from: string, to: string) {
    const rows = await this.trialBalance(from, to);
    const revenue = rows.filter((r) => r.account_type === 'revenue').map((r) => ({ ...r, amount: D(r.credit).minus(r.debit) }));
    const expense = rows.filter((r) => r.account_type === 'expense').map((r) => ({ ...r, amount: D(r.debit).minus(r.credit) }));
    const totalRevenue = revenue.reduce((a, r) => a.plus(r.amount), ZERO);
    const totalExpense = expense.reduce((a, r) => a.plus(r.amount), ZERO);
    const fmt = (x: { code: string; name: string; amount: Decimal }) => ({ code: x.code, name: x.name, amount: x.amount.toString() });
    return { from, to, revenue: revenue.map(fmt), expenses: expense.map(fmt), totalRevenue: totalRevenue.toString(), totalExpenses: totalExpense.toString(), netProfit: totalRevenue.minus(totalExpense).toString() };
  }

  async balanceSheet(asOf: string) {
    const rows = await this.trialBalance('1000-01-01', asOf);
    const section = (t: string, sign: 1 | -1) => rows.filter((r) => r.account_type === t).map((r) => ({ code: r.code, name: r.name, amount: D(r.debit).minus(r.credit).times(sign).toString() }));
    const sum = (items: Array<{ amount: string }>) => items.reduce((a, i) => a.plus(i.amount), ZERO);
    const earnings = rows.filter((r) => ['revenue', 'expense'].includes(r.account_type)).reduce((a, r) => a.plus(r.credit).minus(r.debit), ZERO);
    const assets = section('asset', 1);
    const liabilities = section('liability', -1);
    const equity = [...section('equity', -1), { code: '-', name: 'Current earnings', amount: earnings.toString() }];
    return { asOf, assets, liabilities, equity, totalAssets: sum(assets).toString(), totalLiabilities: sum(liabilities).toString(), totalEquity: sum(equity).toString(), balanced: sum(assets).eq(sum(liabilities).plus(sum(equity))) };
  }
}
