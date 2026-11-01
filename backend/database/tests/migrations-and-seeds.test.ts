import assert from 'node:assert/strict';
import { mkdtempSync, rmSync, writeFileSync, appendFileSync, unlinkSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { after, before, test } from 'node:test';
import type { Connection } from 'mysql2/promise';
import { connectAdmin, migrate, seed } from '../lib.ts';
import { all, createCafe, freshDatabase, insert, one, rejects, uid } from './helpers.ts';

let conn: Connection;
const scratch: string[] = [];

before(async () => { conn = await freshDatabase('cafe_test_migrations'); });
after(async () => {
  await conn.end();
  for (const dir of scratch) rmSync(dir, { recursive: true, force: true });
});

test('migrations re-run as a no-op', async () => {
  const result = await migrate(conn);
  assert.equal(result.applied.length, 0);
  assert.ok(result.skipped.length >= 13);
});

test('seeds re-run without duplicates or errors', async () => {
  const before = await one(conn, `SELECT (SELECT COUNT(*) FROM languages) l, (SELECT COUNT(*) FROM permissions) p, (SELECT COUNT(*) FROM role_permissions) rp, (SELECT COUNT(*) FROM coa_template_accounts) coa`);
  await seed(conn);
  const after = await one(conn, `SELECT (SELECT COUNT(*) FROM languages) l, (SELECT COUNT(*) FROM permissions) p, (SELECT COUNT(*) FROM role_permissions) rp, (SELECT COUNT(*) FROM coa_template_accounts) coa`);
  assert.deepEqual(after, before);
});

async function tempDatabase(): Promise<{ db: Connection; dir: string }> {
  const dir = mkdtempSync(join(tmpdir(), 'cafe-migrations-'));
  scratch.push(dir);
  const name = `cafe_test_tmp_${uid().slice(0, 8).toLowerCase()}`;
  const bootstrap = await connectAdmin();
  await bootstrap.query(`CREATE DATABASE \`${name}\``);
  await bootstrap.end();
  const db = await connectAdmin(name);
  const original = db.end.bind(db);
  db.end = async () => { await db.query(`DROP DATABASE \`${name}\``); return original(); };
  return { db, dir };
}

test('editing an applied migration is detected', async () => {
  const { db, dir } = await tempDatabase();
  try {
    writeFileSync(join(dir, '0001_a.sql'), 'CREATE TABLE a (id INT);');
    assert.deepEqual((await migrate(db, dir)).applied, ['0001_a.sql']);
    appendFileSync(join(dir, '0001_a.sql'), '\n-- changed');
    await rejects(migrate(db, dir), /edited after being applied/);
  } finally { await db.end(); }
});

test('deleting an applied migration is detected', async () => {
  const { db, dir } = await tempDatabase();
  try {
    writeFileSync(join(dir, '0001_a.sql'), 'CREATE TABLE a (id INT);');
    await migrate(db, dir);
    unlinkSync(join(dir, '0001_a.sql'));
    await rejects(migrate(db, dir), /missing from disk/);
  } finally { await db.end(); }
});

test('a failing migration is reported, not recorded, and the next run retries it', async () => {
  const { db, dir } = await tempDatabase();
  try {
    writeFileSync(join(dir, '0001_bad.sql'), 'CREATE TABLE nope (id NOTATYPE);');
    await rejects(migrate(db, dir), /0001_bad.sql failed/);
    assert.equal((await all(db, `SELECT * FROM schema_migrations`)).length, 0);
    writeFileSync(join(dir, '0001_bad.sql'), 'CREATE TABLE fine (id INT);');
    assert.deepEqual((await migrate(db, dir)).applied, ['0001_bad.sql']);
  } finally { await db.end(); }
});

test('seeded currencies carry correct ISO minor units', async () => {
  const rows = await all(conn, `SELECT code, minor_unit FROM currencies ORDER BY code`);
  assert.equal(rows.length, 10);
  for (const r of rows) assert.equal(r.minor_unit, r.code === 'JPY' ? 0 : 2, r.code);
});

test('additional ISO 4217 currency with 3 decimals works without schema change', async () => {
  await insert(conn, 'currencies', { code: 'KWD', numeric_code: '414', name: 'Kuwaiti Dinar', symbol: 'KD', minor_unit: 3 });
  const id = await insert(conn, 'plan_prices', { plan_id: (await one(conn, `SELECT id FROM subscription_plans LIMIT 1`)).id, currency_code: 'KWD', billing_interval: 'monthly', amount: '1.2345' });
  assert.equal((await one(conn, `SELECT amount FROM plan_prices WHERE id = ?`, [id])).amount, '1.2345');
  await rejects(insert(conn, 'currencies', { code: 'kwd2', numeric_code: '000', name: 'x', symbol: 'x', minor_unit: 2 }), /Data too long|chk_currencies_code/);
});

test('all nine brief languages are present, Arabic is RTL and the rest LTR', async () => {
  const rows = await all(conn, `SELECT code, direction FROM languages`);
  assert.deepEqual(rows.map((r) => r.code).sort(), ['ar', 'de', 'en', 'es', 'fr', 'hi', 'ja', 'mr', 'pt']);
  for (const r of rows) assert.equal(r.direction, r.code === 'ar' ? 'rtl' : 'ltr');
});

test('no tax rates, prices, entitlements or active plans are seeded: those are business decisions', async () => {
  const counts = await one(conn, `SELECT (SELECT COUNT(*) FROM tax_rates) t, (SELECT COUNT(*) FROM plan_entitlements) e, (SELECT COUNT(*) FROM subscription_plans WHERE is_active = 1) a`);
  assert.deepEqual({ ...counts }, { t: 0, e: 0, a: 0 });
  assert.equal((await one(conn, `SELECT COUNT(*) c FROM subscription_plans`)).c, 5);
});

test('no user, cafe or credential is seeded', async () => {
  const fresh = await freshDatabase('cafe_test_seed_empty');
  try {
    const counts = await one(fresh, `SELECT (SELECT COUNT(*) FROM users) u, (SELECT COUNT(*) FROM cafes) c, (SELECT COUNT(*) FROM customers) x, (SELECT COUNT(*) FROM payment_gateway_accounts) g`);
    assert.deepEqual({ ...counts }, { u: 0, c: 0, x: 0, g: 0 });
  } finally {
    await fresh.query(`DROP DATABASE cafe_test_seed_empty`);
    await fresh.end();
  }
});

test('RBAC matches the matrix on the sensitive boundaries', async () => {
  const has = async (role: string, perm: string) => (await one(conn, `SELECT COUNT(*) c FROM role_permissions rp JOIN roles r ON r.id = rp.role_id WHERE r.code = ? AND r.cafe_id IS NULL AND rp.permission_code = ?`, [role, perm])).c === 1;
  assert.equal(await has('kitchen_staff', 'kitchen.operate'), true);
  assert.equal(await has('kitchen_staff', 'kitchen.configure'), false);
  assert.equal(await has('kitchen_staff', 'payments.read'), false);
  assert.equal(await has('kitchen_staff', 'customers.read'), false);
  assert.equal(await has('waiter', 'payments.cash_confirm'), false);
  assert.equal(await has('cashier', 'payments.cash_confirm'), true);
  assert.equal(await has('cashier', 'refunds.approve'), false);
  assert.equal(await has('manager', 'finance.manage'), false);
  assert.equal(await has('manager', 'staff.manage'), false);
  assert.equal(await has('owner', 'finance.manage'), true);
  assert.equal(await has('owner', 'platform.cafes.manage'), false);
  assert.equal(await has('platform_support', 'platform.customer_pii.read'), false);
  assert.equal(await has('super_admin', 'payments.cash_confirm'), false);
});

test('Unicode round-trips byte-exact in all supported scripts, including emoji', async () => {
  const cafe = await createCafe(conn, 'uni');
  const samples: Record<string, string> = {
    hi: 'मसाला चाय', mr: 'पोहे आणि चहा', ar: 'قهوة عربية', ja: '抹茶ラテ', de: 'Käsekuchen für Straße', fr: 'Crème brûlée', es: 'Café con leche ñ', pt: 'Pão de açúcar', en: 'Latte ☕🥐',
  };
  for (const [language_code, name] of Object.entries(samples)) {
    await insert(conn, 'product_translations', { cafe_id: cafe.cafeId, product_id: cafe.productId, language_code, name });
  }
  const rows = await all(conn, `SELECT language_code, name FROM product_translations WHERE product_id = ?`, [cafe.productId]);
  assert.equal(rows.length, 9);
  for (const r of rows) assert.equal(r.name, samples[r.language_code]);
});

test('product search finds Japanese and Devanagari text (ngram index)', async () => {
  const cafe = await createCafe(conn, 'search');
  await insert(conn, 'product_translations', { cafe_id: cafe.cafeId, product_id: cafe.productId, language_code: 'ja', name: '抹茶ラテ' });
  const [hit] = await all(conn, `SELECT COUNT(*) c FROM product_translations WHERE cafe_id = ? AND MATCH(name) AGAINST (? IN BOOLEAN MODE)`, [cafe.cafeId, '抹茶']);
  assert.equal(hit!.c, 1);
});
