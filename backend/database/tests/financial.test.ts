// Financial guarantees, including under concurrency. These run against real MySQL locks.
import assert from 'node:assert/strict';
import { after, before, test } from 'node:test';
import type { Connection, Pool } from 'mysql2/promise';
import { CHECK_VIOLATION, all, createCafe, createOrder, createPool, createVerifiedPayment, freshDatabase, insert, one, paymentRow, rejects, uid } from './helpers.ts';
import type { CafeFixture } from './helpers.ts';

const DB = 'cafe_test_financial';
let conn: Connection;
let pool: Pool;
let cafe: CafeFixture;

before(async () => {
  conn = await freshDatabase(DB);
  pool = createPool(DB);
  cafe = await createCafe(conn, 'fin');
});
after(async () => { await pool.end(); await conn.end(); });

async function draftEntry(lines: Array<[number, string, string]>, overrides: Record<string, unknown> = {}): Promise<number> {
  const id = await insert(conn, 'journal_entries', {
    public_id: uid(), cafe_id: cafe.cafeId, period_id: cafe.periodId, entry_date: '2026-06-01', currency_code: cafe.currency, ...overrides,
  });
  for (const [account, debit, credit] of lines) {
    await insert(conn, 'journal_entry_lines', { cafe_id: cafe.cafeId, journal_entry_id: id, account_id: account, debit_amount: debit, credit_amount: credit });
  }
  return id;
}
const post = (id: number) => conn.query(`UPDATE journal_entries SET status = 'posted' WHERE id = ?`, [id]);
const balanced = (): Array<[number, string, string]> => [[cafe.cashAccountId, '100.0000', '0'], [cafe.revenueAccountId, '0', '100.0000']];

test('journal: a balanced entry posts and gets a posted_at', async () => {
  const id = await draftEntry(balanced());
  await post(id);
  const row = await one(conn, `SELECT status, posted_at FROM journal_entries WHERE id = ?`, [id]);
  assert.equal(row.status, 'posted');
  assert.ok(row.posted_at);
});

test('journal: an unbalanced entry cannot post, even by 0.0001', async () => {
  const id = await draftEntry([[cafe.cashAccountId, '100.0000', '0'], [cafe.revenueAccountId, '0', '99.9999']]);
  await rejects(post(id), /do not balance/);
});

test('journal: a one-line or empty entry cannot post', async () => {
  await rejects(post(await draftEntry([])), /at least two lines/);
  await rejects(post(await draftEntry([[cafe.cashAccountId, '1.0000', '0']])), /at least two lines/);
});

test('journal: entries cannot be inserted already posted', async () => {
  await rejects(insert(conn, 'journal_entries', {
    public_id: uid(), cafe_id: cafe.cafeId, period_id: cafe.periodId, entry_date: '2026-06-01', currency_code: cafe.currency, status: 'posted',
  }), /must be created as draft/);
});

test('journal: a line must be one-sided and positive', async () => {
  const id = await draftEntry([]);
  const line = { cafe_id: cafe.cafeId, journal_entry_id: id, account_id: cafe.cashAccountId };
  await rejects(insert(conn, 'journal_entry_lines', { ...line, debit_amount: '1.0000', credit_amount: '1.0000' }), CHECK_VIOLATION);
  await rejects(insert(conn, 'journal_entry_lines', { ...line, debit_amount: '0', credit_amount: '0' }), CHECK_VIOLATION);
  await rejects(insert(conn, 'journal_entry_lines', { ...line, debit_amount: '-1.0000', credit_amount: '0' }), CHECK_VIOLATION);
});

test('journal: a posted entry and its lines are immutable', async () => {
  const id = await draftEntry(balanced());
  await post(id);
  await rejects(conn.query(`UPDATE journal_entries SET memo = 'x' WHERE id = ?`, [id]), /immutable/);
  await rejects(conn.query(`DELETE FROM journal_entries WHERE id = ?`, [id]), /cannot be deleted/);
  await rejects(conn.query(`UPDATE journal_entry_lines SET debit_amount = 999 WHERE journal_entry_id = ? AND debit_amount > 0`, [id]), /cannot change lines/);
  await rejects(conn.query(`DELETE FROM journal_entry_lines WHERE journal_entry_id = ?`, [id]), /cannot delete lines/);
  await rejects(insert(conn, 'journal_entry_lines', { cafe_id: cafe.cafeId, journal_entry_id: id, account_id: cafe.cashAccountId, debit_amount: '1.0000' }), /cannot add lines/);
});

test('journal: a closed period refuses posting; out-of-range dates are refused', async () => {
  const period = await insert(conn, 'financial_periods', { cafe_id: cafe.cafeId, name: 'old', starts_on: '2025-01-01', ends_on: '2025-12-31' });
  const outOfRange = await draftEntry(balanced(), { period_id: period, entry_date: '2026-01-01' });
  await rejects(post(outOfRange), /outside the financial period/);
  const id = await draftEntry(balanced(), { period_id: period, entry_date: '2025-06-01' });
  await conn.query(`UPDATE financial_periods SET status = 'closed' WHERE id = ?`, [period]);
  await rejects(post(id), /closed financial period/);
});

test('journal: a source event can post only once, and an entry can be reversed only once', async () => {
  const source = { source_type: 'order', source_id: 42, entry_kind: 'sale' };
  const original = await draftEntry(balanced(), source);
  await rejects(draftEntry([], source), 'ER_DUP_ENTRY');
  await post(original);
  const reversal = await draftEntry([[cafe.cashAccountId, '0', '100.0000'], [cafe.revenueAccountId, '100.0000', '0']], { reversal_of_entry_id: original });
  await post(reversal);
  await rejects(draftEntry([], { reversal_of_entry_id: original }), 'ER_DUP_ENTRY');
  const [row] = await all(conn, `SELECT SUM(debit_amount - credit_amount) net FROM journal_entry_lines WHERE journal_entry_id IN (?, ?) AND account_id = ?`, [original, reversal, cafe.cashAccountId]);
  assert.equal(row!.net, '0.0000');
});

test('payment: cannot reach succeeded by setting the status alone (the frontend attack)', async () => {
  const orderId = await createOrder(conn, cafe);
  const id = await insert(conn, 'payments', paymentRow(cafe, orderId));
  await rejects(conn.query(`UPDATE payments SET status = 'succeeded' WHERE id = ?`, [id]), CHECK_VIOLATION);
  await rejects(conn.query(`UPDATE payments SET status = 'succeeded', verified_at = NOW(3), verification_source = 'gateway_webhook' WHERE id = ?`, [id]), CHECK_VIOLATION);
  await rejects(insert(conn, 'payments', paymentRow(cafe, orderId, { status: 'succeeded' })), CHECK_VIOLATION);
});

test('payment: cash needs an identified staff member and no provider', async () => {
  const orderId = await createOrder(conn, cafe);
  const row = paymentRow(cafe, orderId, { method_code: 'cash', provider_code: null });
  const id = await insert(conn, 'payments', row);
  await rejects(conn.query(`UPDATE payments SET status = 'succeeded', verified_at = NOW(3), verification_source = 'manual_cash' WHERE id = ?`, [id]), CHECK_VIOLATION);
  await conn.query(`UPDATE payments SET status = 'succeeded', verified_at = NOW(3), verification_source = 'manual_cash', confirmed_by_user_id = ? WHERE id = ?`, [cafe.ownerId, id]);
  assert.equal((await one(conn, `SELECT status FROM payments WHERE id = ?`, [id])).status, 'succeeded');
});

test('payment: a verified gateway path succeeds, and amount or currency cannot change afterwards', async () => {
  const orderId = await createOrder(conn, cafe);
  const id = await insert(conn, 'payments', paymentRow(cafe, orderId));
  await conn.query(`UPDATE payments SET status = 'pending', provider_payment_ref = ? WHERE id = ?`, [uid(), id]);
  await conn.query(`UPDATE payments SET status = 'succeeded', verified_at = NOW(3), verification_source = 'gateway_webhook' WHERE id = ?`, [id]);
  await rejects(conn.query(`UPDATE payments SET amount = 1 WHERE id = ?`, [id]), /immutable/);
  await rejects(conn.query(`DELETE FROM payments WHERE id = ?`, [id]), /cannot be deleted/);
});

test('payment: illegal transitions are refused; a late gateway capture after expiry is allowed', async () => {
  const orderId = await createOrder(conn, cafe);
  const succeeded = await createVerifiedPayment(conn, cafe, orderId);
  await rejects(conn.query(`UPDATE payments SET status = 'pending' WHERE id = ?`, [succeeded]), /illegal payment status/);
  await rejects(conn.query(`UPDATE payments SET status = 'failed' WHERE id = ?`, [succeeded]), /illegal payment status/);

  const late = await insert(conn, 'payments', paymentRow(cafe, orderId));
  await conn.query(`UPDATE payments SET status = 'pending' WHERE id = ?`, [late]);
  await conn.query(`UPDATE payments SET status = 'expired' WHERE id = ?`, [late]);
  await conn.query(`UPDATE payments SET status = 'succeeded', verified_at = NOW(3), verification_source = 'gateway_webhook', provider_payment_ref = ? WHERE id = ?`, [uid(), late]);

  const cashAfterExpiry = await insert(conn, 'payments', paymentRow(cafe, orderId, { method_code: 'cash', provider_code: null }));
  await conn.query(`UPDATE payments SET status = 'pending' WHERE id = ?`, [cashAfterExpiry]);
  await conn.query(`UPDATE payments SET status = 'expired' WHERE id = ?`, [cashAfterExpiry]);
  await rejects(conn.query(`UPDATE payments SET status = 'succeeded', verified_at = NOW(3), verification_source = 'manual_cash', confirmed_by_user_id = ? WHERE id = ?`, [cafe.ownerId, cashAfterExpiry]), /illegal payment status/);
});

test('payment: verification evidence cannot be rewritten after the fact', async () => {
  const id = await createVerifiedPayment(conn, cafe, await createOrder(conn, cafe));
  await rejects(conn.query(`UPDATE payments SET verification_source = 'gateway_api' WHERE id = ?`, [id]), /evidence is immutable/);
  await rejects(conn.query(`UPDATE payments SET provider_payment_ref = 'forged' WHERE id = ?`, [id]), /evidence is immutable/);
});

test('payment: refund status must agree with the refunded amount', async () => {
  const id = await createVerifiedPayment(conn, cafe, await createOrder(conn, cafe));
  await rejects(conn.query(`UPDATE payments SET status = 'refunded' WHERE id = ?`, [id]), CHECK_VIOLATION);
  await rejects(conn.query(`UPDATE payments SET status = 'partially_refunded' WHERE id = ?`, [id]), CHECK_VIOLATION);
  await rejects(conn.query(`UPDATE payments SET status = 'partially_refunded', refunded_amount = amount WHERE id = ?`, [id]), CHECK_VIOLATION);
  await conn.query(`UPDATE payments SET status = 'partially_refunded', refunded_amount = 40 WHERE id = ?`, [id]);
  await conn.query(`UPDATE payments SET status = 'refunded', refunded_amount = amount WHERE id = ?`, [id]);
});

test('payment: the same idempotency key cannot create two payments; same gateway ref cannot be used twice', async () => {
  const orderId = await createOrder(conn, cafe);
  const key = uid();
  await insert(conn, 'payments', paymentRow(cafe, orderId, { idempotency_key: key }));
  await rejects(insert(conn, 'payments', paymentRow(cafe, orderId, { idempotency_key: key })), 'ER_DUP_ENTRY');
  const ref = uid();
  await insert(conn, 'payments', paymentRow(cafe, orderId, { provider_payment_ref: ref }));
  await rejects(insert(conn, 'payments', paymentRow(cafe, orderId, { provider_payment_ref: ref })), 'ER_DUP_ENTRY');
});

test('webhook: a replayed provider event is refused by the unique key', async () => {
  const row = { provider_code: 'stripe', provider_event_id: uid(), event_type: 'x', signature_verified: 1, sanitized_payload: '{}' };
  await insert(conn, 'payment_webhooks', row);
  await rejects(insert(conn, 'payment_webhooks', row), 'ER_DUP_ENTRY');
});

function refundRow(paymentId: number, amount: string): Record<string, unknown> {
  return { public_id: uid(), cafe_id: cafe.cafeId, payment_id: paymentId, currency_code: cafe.currency, amount, reason: 'test', requested_by_user_id: cafe.ownerId, idempotency_key: uid() };
}

test('refund: partial refunds accumulate and cannot exceed the payment', async () => {
  const payment = await createVerifiedPayment(conn, cafe, await createOrder(conn, cafe));
  await insert(conn, 'refunds', refundRow(payment, '60.0000'));
  await insert(conn, 'refunds', refundRow(payment, '40.0000'));
  await rejects(insert(conn, 'refunds', refundRow(payment, '0.0001')), /exceeds payment/);
});

test('refund: a failed refund releases its amount; a terminal refund cannot change', async () => {
  const payment = await createVerifiedPayment(conn, cafe, await createOrder(conn, cafe));
  const r = await insert(conn, 'refunds', refundRow(payment, '100.0000'));
  await conn.query(`UPDATE refunds SET status = 'failed' WHERE id = ?`, [r]);
  await rejects(conn.query(`UPDATE refunds SET status = 'succeeded' WHERE id = ?`, [r]), /terminal/);
  assert.ok(await insert(conn, 'refunds', refundRow(payment, '100.0000')) > 0);
});

test('refund: an unpaid payment cannot be refunded', async () => {
  const pending = await insert(conn, 'payments', paymentRow(cafe, await createOrder(conn, cafe)));
  await rejects(insert(conn, 'refunds', refundRow(pending, '1.0000')), /only a successful payment/);
});

test('refund: 20 concurrent full refunds on one payment: exactly one succeeds', async () => {
  const payment = await createVerifiedPayment(conn, cafe, await createOrder(conn, cafe));
  const results = await Promise.allSettled(Array.from({ length: 20 }, () => insert(pool, 'refunds', refundRow(payment, '100.0000'))));
  assert.equal(results.filter((r) => r.status === 'fulfilled').length, 1);
  for (const r of results) if (r.status === 'rejected') assert.match(String(r.reason.message), /exceeds payment/);
  assert.equal((await one(conn, `SELECT SUM(amount) s FROM refunds WHERE payment_id = ?`, [payment])).s, '100.0000');
});

test('append-only tables refuse UPDATE and DELETE', async () => {
  const payment = await createVerifiedPayment(conn, cafe, await createOrder(conn, cafe));
  const seeded: Array<[string, Record<string, unknown>]> = [
    ['payment_transactions', { cafe_id: cafe.cafeId, payment_id: payment, transaction_type: 'captured', currency_code: cafe.currency, amount: '1.0000' }],
    ['audit_logs', { cafe_id: cafe.cafeId, actor_type: 'system', action: 'test' }],
    ['stock_movements', { cafe_id: cafe.cafeId, branch_id: cafe.branchId, ingredient_id: cafe.ingredientId, movement_type: 'stock_in', quantity: '1.0000', unit_cost: '1.000000', currency_code: cafe.currency }],
    ['loyalty_ledger', { cafe_id: cafe.cafeId, customer_id: cafe.customerId, entry_type: 'earn', points: 5 }],
    ['platform_transactions', { public_id: uid(), transaction_type: 'adjustment', direction: 'credit', currency_code: 'USD', amount: '1.0000', occurred_at: '2026-01-01 00:00:00' }],
    ['exchange_rates', { base_currency_code: 'USD', quote_currency_code: 'INR', rate: '83.1234567890', provider: 'manual', effective_at: '2026-01-01 00:00:00' }],
    ['order_status_history', { cafe_id: cafe.cafeId, order_id: await createOrder(conn, cafe), to_status: 'placed' }],
  ];
  for (const [table, row] of seeded) {
    const id = await insert(conn, table, row);
    await rejects(conn.query(`UPDATE ${table} SET id = id WHERE id = ?`, [id]), /append-only/);
    await rejects(conn.query(`DELETE FROM ${table} WHERE id = ?`, [id]), /append-only/);
  }
});

async function draftInvoice(c: { query: Connection['query'] }, sequence: number | null = null, status = 'draft'): Promise<number> {
  const [r] = await (c as Connection).query(`INSERT INTO invoices SET ?`, [{
    public_id: uid(), cafe_id: cafe.cafeId, branch_id: cafe.branchId, status, series: 'INV', fiscal_year: 2026,
    language_code: 'en', currency_code: cafe.currency, seller_snapshot: '{}', sequence_no: sequence,
  }]);
  return (r as { insertId: number }).insertId;
}

test('invoice: an issued invoice and its lines are immutable; only voiding is allowed', async () => {
  const id = await draftInvoice(conn as never);
  const line = { cafe_id: cafe.cafeId, invoice_id: id, description: 'x', quantity: '1.0000', unit_price: '10.0000', taxable_amount: '10.0000', line_total_amount: '10.0000' };
  await insert(conn, 'invoice_lines', line);
  await rejects(conn.query(`UPDATE invoices SET status = 'issued' WHERE id = ?`, [id]), CHECK_VIOLATION);
  await conn.query(`UPDATE invoices SET status = 'issued', sequence_no = 900, invoice_number = 'INV-900', issued_at = NOW(3), total_amount = 10 WHERE id = ?`, [id]);

  await rejects(conn.query(`UPDATE invoices SET total_amount = 1 WHERE id = ?`, [id]), /immutable/);
  await rejects(conn.query(`UPDATE invoices SET invoice_number = 'INV-1' WHERE id = ?`, [id]), /immutable/);
  await rejects(conn.query(`DELETE FROM invoices WHERE id = ?`, [id]), /cannot be deleted/);
  await rejects(insert(conn, 'invoice_lines', line), /cannot add lines/);
  await rejects(conn.query(`UPDATE invoice_lines SET unit_price = 1 WHERE invoice_id = ?`, [id]), /cannot change lines/);
  await rejects(conn.query(`DELETE FROM invoice_lines WHERE invoice_id = ?`, [id]), /cannot delete lines/);
  await rejects(conn.query(`UPDATE invoices SET status = 'draft' WHERE id = ?`, [id]), /illegal invoice status/);
  await conn.query(`UPDATE invoices SET pdf_asset_id = ?, status = 'voided', void_reason = 'test', voided_at = NOW(3) WHERE id = ?`, [cafe.assetId, id]);
});

test('invoice: a credit note must point to its original', async () => {
  await rejects(conn.query(`INSERT INTO invoices SET ?`, [{
    public_id: uid(), cafe_id: cafe.cafeId, branch_id: cafe.branchId, document_type: 'credit_note', series: 'CN', fiscal_year: 2026, language_code: 'en', currency_code: cafe.currency, seller_snapshot: '{}',
  }]), CHECK_VIOLATION);
});

test('invoice numbering: gapless under concurrency, even when transactions roll back', async () => {
  const series = { cafe_id: cafe.cafeId, branch_id: cafe.branchId, series: 'CON', fiscal_year: 2026 };
  await insert(conn, 'invoice_sequences', series);

  const issue = async (i: number): Promise<number | null> => {
    const c = await pool.getConnection();
    try {
      await c.beginTransaction();
      const [rows] = await c.query(`SELECT id, last_number FROM invoice_sequences WHERE cafe_id = ? AND branch_id = ? AND series = 'CON' AND fiscal_year = 2026 FOR UPDATE`, [cafe.cafeId, cafe.branchId]);
      const { id, last_number } = (rows as Array<{ id: number; last_number: number }>)[0]!;
      const next = Number(last_number) + 1;
      await c.query(`UPDATE invoice_sequences SET last_number = ? WHERE id = ?`, [next, id]);
      if (i % 5 === 0) { await c.rollback(); return null; }
      await c.query(`INSERT INTO invoices SET ?`, [{
        public_id: uid(), ...series, status: 'issued', sequence_no: next, invoice_number: `CON-${next}`, issued_at: new Date(),
        language_code: 'en', currency_code: cafe.currency, seller_snapshot: '{}',
      }]);
      await c.commit();
      return next;
    } finally {
      c.release();
    }
  };

  const results = await Promise.all(Array.from({ length: 50 }, (_, i) => issue(i)));
  assert.equal(results.filter((r) => r !== null).length, 40);
  const rows = await all(conn, `SELECT sequence_no s FROM invoices WHERE series = 'CON' ORDER BY s`);
  assert.deepEqual(rows.map((r) => Number(r.s)), Array.from({ length: 40 }, (_, i) => i + 1));
});

test('money precision: decimals round-trip exactly, as strings, and sums do not drift', async () => {
  const id = await insert(conn, 'products', { cafe_id: cafe.cafeId, public_id: uid(), category_id: cafe.categoryId, base_price: '0.1000' });
  const row = await one(conn, `SELECT base_price FROM products WHERE id = ?`, [id]);
  assert.equal(typeof row.base_price, 'string');
  assert.equal(row.base_price, '0.1000');
  const [sum] = await all(conn, `SELECT SUM(x) s FROM (SELECT 0.1000 x UNION ALL SELECT 0.2000) t`);
  assert.equal(sum!.s, '0.3000');
});

test('derived constraints: payroll net must equal gross minus deductions; review is 1 to 5', async () => {
  const staff = await one(conn, `SELECT id FROM cafe_staff WHERE cafe_id = ?`, [cafe.cafeId]);
  await rejects(insert(conn, 'payroll_entries', {
    public_id: uid(), cafe_id: cafe.cafeId, staff_id: staff.id, period_start: '2026-01-01', period_end: '2026-01-31', currency_code: cafe.currency,
    gross_amount: '100.0000', deductions_amount: '10.0000', net_amount: '95.0000', created_by_user_id: cafe.ownerId,
  }), CHECK_VIOLATION);
  await rejects(insert(conn, 'customer_reviews', { public_id: uid(), cafe_id: cafe.cafeId, order_id: await createOrder(conn, cafe), rating: 6 }), CHECK_VIOLATION);
});
