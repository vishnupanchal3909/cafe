// Attempts every kind of cross-cafe reference. Each must be refused by the database itself.
import assert from 'node:assert/strict';
import { after, before, test } from 'node:test';
import type { Connection } from 'mysql2/promise';
import { CHECK_VIOLATION, FK_VIOLATION, createCafe, createOrder, createUser, insert, one, orderRow, paymentRow, rejects, uid } from './helpers.ts';
import type { CafeFixture } from './helpers.ts';
import { freshDatabase } from './helpers.ts';

let conn: Connection;
let a: CafeFixture;
let b: CafeFixture;

before(async () => {
  conn = await freshDatabase('cafe_test_isolation');
  a = await createCafe(conn, 'cafe-a');
  b = await createCafe(conn, 'cafe-b');
});
after(() => conn.end());

test('fixtures are valid: the same insert succeeds with its own cafe data', async () => {
  // Without this, every rejection below could be passing for an unrelated reason.
  const id = await insert(conn, 'products', { cafe_id: a.cafeId, public_id: uid(), category_id: a.categoryId, base_price: '1.0000' });
  assert.ok(id > 0);
  const orderId = await createOrder(conn, a, { table_id: a.tableId, session_id: a.sessionId, customer_id: a.customerId });
  assert.ok(orderId > 0);
});

const cases: Array<[string, () => Promise<unknown>]> = [
  ['product in another cafe\'s category', () => insert(conn, 'products', { cafe_id: a.cafeId, public_id: uid(), category_id: b.categoryId, base_price: '1.0000' })],
  ['product with another cafe\'s tax category', () => insert(conn, 'products', { cafe_id: a.cafeId, public_id: uid(), category_id: a.categoryId, tax_category_id: b.taxCategoryId, base_price: '1.0000' })],
  ['category using another cafe\'s image', () => insert(conn, 'categories', { cafe_id: a.cafeId, public_id: uid(), image_asset_id: b.assetId })],
  ['translation attached to another cafe\'s product', () => insert(conn, 'product_translations', { cafe_id: a.cafeId, product_id: b.productId, language_code: 'en', name: 'x' })],
  ['table in another cafe\'s branch', () => insert(conn, 'cafe_tables', { cafe_id: a.cafeId, public_id: uid(), branch_id: b.branchId, table_number: 'X' })],
  ['QR code on another cafe\'s table', () => insert(conn, 'table_qr_codes', { cafe_id: a.cafeId, table_id: b.tableId, token_hash: uid().padEnd(64, '0'), token_ciphertext: Buffer.from('x'), encryption_key_id: 'k' })],
  ['order in another cafe\'s branch', () => createOrder(conn, a, { branch_id: b.branchId })],
  ['order on another cafe\'s table', () => createOrder(conn, a, { table_id: b.tableId })],
  ['order on another cafe\'s session', () => createOrder(conn, a, { session_id: b.sessionId })],
  ['order for a customer with no link to the cafe', () => createOrder(conn, a, { customer_id: b.customerId })],
  ['journal line on another cafe\'s account', async () => {
    const entry = await insert(conn, 'journal_entries', { public_id: uid(), cafe_id: a.cafeId, period_id: a.periodId, entry_date: '2026-06-01', currency_code: 'INR' });
    await insert(conn, 'journal_entry_lines', { cafe_id: a.cafeId, journal_entry_id: entry, account_id: b.cashAccountId, debit_amount: '1.0000' });
  }],
  ['journal entry in another cafe\'s period', () => insert(conn, 'journal_entries', { public_id: uid(), cafe_id: a.cafeId, period_id: b.periodId, entry_date: '2026-06-01', currency_code: 'INR' })],
  ['recipe using another cafe\'s ingredient', () => insert(conn, 'product_recipes', { cafe_id: a.cafeId, product_id: a.productId, ingredient_id: b.ingredientId, quantity: '1.0000' })],
  ['stock movement on another cafe\'s ingredient', () => insert(conn, 'stock_movements', { cafe_id: a.cafeId, branch_id: a.branchId, ingredient_id: b.ingredientId, movement_type: 'stock_in', quantity: '1.0000', unit_cost: '1.000000', currency_code: 'INR' })],
  ['staff role on a branch of another cafe', async () => {
    await insert(conn, 'user_roles', { user_id: a.ownerId, role_id: a.roleId, cafe_id: a.cafeId, branch_id: b.branchId });
  }],
  ['role granted to someone who is not staff of the cafe', async () => {
    const outsider = await createUser(conn, 'outsider');
    await insert(conn, 'user_roles', { user_id: outsider, role_id: a.roleId, cafe_id: a.cafeId });
  }],
];

for (const [name, attempt] of cases) {
  test(`refused: ${name}`, () => rejects(attempt(), FK_VIOLATION));
}

test('refused: payment on another cafe\'s order', async () => {
  const orderB = await createOrder(conn, b);
  await rejects(insert(conn, 'payments', paymentRow(a, orderB)), FK_VIOLATION);
});

test('refused: a variant that belongs to a different product of the same cafe', async () => {
  const other = await insert(conn, 'products', { cafe_id: a.cafeId, public_id: uid(), category_id: a.categoryId, base_price: '1.0000' });
  const orderId = await createOrder(conn, a);
  await rejects(insert(conn, 'order_items', {
    cafe_id: a.cafeId, order_id: orderId, product_id: other, variant_id: a.variantId, name_snapshot: 'x', quantity: 1, unit_price: '1.0000', line_total_amount: '1.0000',
  }), FK_VIOLATION);
});

test('refused: assigning cafe A\'s custom role inside cafe B', async () => {
  await rejects(insert(conn, 'user_roles', { user_id: b.ownerId, role_id: a.roleId, cafe_id: b.cafeId }), /role belongs to a different cafe/);
});

test('refused: a platform role assigned inside a cafe, and a cafe role outside one', async () => {
  const sup = await one(conn, `SELECT id FROM roles WHERE code = 'super_admin' AND cafe_id IS NULL`);
  const own = await one(conn, `SELECT id FROM roles WHERE code = 'owner' AND cafe_id IS NULL`);
  await rejects(insert(conn, 'user_roles', { user_id: a.ownerId, role_id: sup.id, cafe_id: a.cafeId }), /role scope does not match/);
  await rejects(insert(conn, 'user_roles', { user_id: a.ownerId, role_id: own.id }), /role scope does not match/);
});

test('allowed: a system cafe role inside a cafe for its staff', async () => {
  const own = await one(conn, `SELECT id FROM roles WHERE code = 'owner' AND cafe_id IS NULL`);
  assert.ok(await insert(conn, 'user_roles', { user_id: a.ownerId, role_id: own.id, cafe_id: a.cafeId }) > 0);
});

test('order in a currency other than the cafe\'s is refused', async () => {
  await rejects(insert(conn, 'orders', orderRow(a, { currency_code: 'USD' })), FK_VIOLATION);
});

test('payment in a different currency from its order is refused', async () => {
  const orderId = await createOrder(conn, a);
  await rejects(insert(conn, 'payments', paymentRow(a, orderId, { currency_code: 'USD' })), FK_VIOLATION);
});

test('a cafe\'s currency cannot change once it has orders, but can before', async () => {
  const empty = await createCafe(conn, 'cafe-empty');
  await conn.query(`UPDATE cafes SET currency_code = 'USD' WHERE id = ?`, [empty.cafeId]);
  await rejects(conn.query(`UPDATE cafes SET currency_code = 'USD' WHERE id = ?`, [a.cafeId]), /foreign key constraint/i);
});

test('QR: a table has only one live code; revoked codes stay as history', async () => {
  const qr = { cafe_id: a.cafeId, table_id: a.tableId, token_ciphertext: Buffer.from('x'), encryption_key_id: 'k' };
  const first = await insert(conn, 'table_qr_codes', { ...qr, token_hash: uid().padEnd(64, '0') });
  await rejects(insert(conn, 'table_qr_codes', { ...qr, token_hash: uid().padEnd(64, '0') }), 'ER_DUP_ENTRY');
  await conn.query(`UPDATE table_qr_codes SET revoked_at = NOW(3) WHERE id = ?`, [first]);
  assert.ok(await insert(conn, 'table_qr_codes', { ...qr, token_hash: uid().padEnd(64, '0') }) > 0);
});

test('table number is reusable after soft delete, not while live', async () => {
  const row = { cafe_id: a.cafeId, branch_id: a.branchId, table_number: 'T9' };
  const id = await insert(conn, 'cafe_tables', { ...row, public_id: uid() });
  await rejects(insert(conn, 'cafe_tables', { ...row, public_id: uid() }), 'ER_DUP_ENTRY');
  await conn.query(`UPDATE cafe_tables SET deleted_at = NOW(3) WHERE id = ?`, [id]);
  assert.ok(await insert(conn, 'cafe_tables', { ...row, public_id: uid() }) > 0);
});

test('same order number is fine in two cafes, refused twice in one', async () => {
  await createOrder(conn, a, { order_number: 777 });
  await createOrder(conn, b, { order_number: 777 });
  await rejects(createOrder(conn, a, { order_number: 777 }), 'ER_DUP_ENTRY');
});

test('negative prices are refused', async () => {
  await rejects(insert(conn, 'products', { cafe_id: a.cafeId, public_id: uid(), category_id: a.categoryId, base_price: '-1.0000' }), CHECK_VIOLATION);
});
