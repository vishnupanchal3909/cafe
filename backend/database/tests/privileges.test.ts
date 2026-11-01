// Connects as the real least-privilege users. An app-level bug or SQL injection is limited to this.
import assert from 'node:assert/strict';
import { after, before, test } from 'node:test';
import mysql from 'mysql2/promise';
import type { Connection } from 'mysql2/promise';
import { adminOptions, applyGrants } from '../lib.ts';
import { createCafe, createVerifiedPayment, createOrder, freshDatabase, insert, one, rejects } from './helpers.ts';
import type { CafeFixture } from './helpers.ts';

const DB = 'cafe_test_privileges';
const USERS = {
  migrator: { user: 'cafe_test_migrator', password: 'test-only-migrator' },
  app: { user: 'cafe_test_app', password: 'test-only-app' },
  reporting: { user: 'cafe_test_reporting', password: 'test-only-reporting' },
};
let admin: Connection;
let app: Connection;
let reporting: Connection;
let cafe: CafeFixture;

const connectAs = (u: { user: string; password: string }) => mysql.createConnection({ ...adminOptions(DB), ...u, multipleStatements: false });

before(async () => {
  admin = await freshDatabase(DB);
  await applyGrants(admin, { database: DB, ...USERS });
  cafe = await createCafe(admin, 'priv');
  app = await connectAs(USERS.app);
  reporting = await connectAs(USERS.reporting);
});
after(async () => {
  await app.end();
  await reporting.end();
  for (const { user } of Object.values(USERS)) await admin.query(`DROP USER IF EXISTS ?@'%'`, [user]);
  await admin.end();
});

test('app user can do its normal work', async () => {
  const orderId = await insert(app, 'orders', {
    public_id: 'PRIVORDER00000000000000001', cafe_id: cafe.cafeId, branch_id: cafe.branchId, order_number: 900001, business_date: '2026-06-01', order_source: 'qr',
    status: 'placed', language_code: 'en', currency_code: cafe.currency, prices_include_tax: 0, subtotal_amount: '1.0000', total_amount: '1.0000',
  });
  assert.ok(orderId > 0);
  await app.query(`UPDATE orders SET status = 'accepted' WHERE id = ?`, [orderId]);
  await insert(app, 'audit_logs', { cafe_id: cafe.cafeId, actor_type: 'system', action: 'test' });
});

test('app user has no DDL', async () => {
  await rejects(app.query(`DROP TABLE orders`), 'ER_TABLEACCESS_DENIED_ERROR');
  await rejects(app.query(`CREATE TABLE evil (id INT)`), 'ER_TABLEACCESS_DENIED_ERROR');
  await rejects(app.query(`ALTER TABLE payments ADD COLUMN evil INT`), 'ER_TABLEACCESS_DENIED_ERROR');
  await rejects(app.query(`TRUNCATE TABLE audit_logs`), 'ER_TABLEACCESS_DENIED_ERROR');
});

test('app user cannot remove the triggers that protect the ledger', async () => {
  await assert.rejects(app.query(`DROP TRIGGER trg_payments_guard`), (e: { code: string }) => /DENIED/.test(e.code));
});

test('app user cannot alter or delete append-only rows (privilege layer, before any trigger)', async () => {
  await rejects(app.query(`UPDATE audit_logs SET action = 'x'`), 'ER_TABLEACCESS_DENIED_ERROR');
  await rejects(app.query(`DELETE FROM audit_logs`), 'ER_TABLEACCESS_DENIED_ERROR');
  await rejects(app.query(`DELETE FROM payment_transactions`), 'ER_TABLEACCESS_DENIED_ERROR');
  await rejects(app.query(`DELETE FROM stock_movements`), 'ER_TABLEACCESS_DENIED_ERROR');
});

test('app user cannot delete financial documents', async () => {
  const paymentId = await createVerifiedPayment(admin, cafe, await createOrder(admin, cafe));
  await rejects(app.query(`DELETE FROM payments WHERE id = ?`, [paymentId]), 'ER_TABLEACCESS_DENIED_ERROR');
  for (const t of ['orders', 'invoices', 'journal_entries', 'refunds', 'settlements', 'expenses', 'cafes', 'users', 'customers', 'payroll_entries']) {
    await rejects(app.query(`DELETE FROM ${t} WHERE id = 0`), 'ER_TABLEACCESS_DENIED_ERROR');
  }
});

test('triggers still fire for the app user', async () => {
  const paymentId = await createVerifiedPayment(admin, cafe, await createOrder(admin, cafe));
  await rejects(app.query(`UPDATE payments SET amount = 1 WHERE id = ?`, [paymentId]), /immutable/);
});

test('app user cannot rewrite the migration history or manage users', async () => {
  await rejects(app.query(`DELETE FROM schema_migrations`), 'ER_TABLEACCESS_DENIED_ERROR');
  await assert.rejects(app.query(`CREATE USER 'evil'@'%'`), (e: { code: string }) => /DENIED/.test(e.code));
  await assert.rejects(app.query(`GRANT ALL ON ${DB}.* TO 'cafe_test_app'@'%'`), (e: { code: string }) => /DENIED/.test(e.code));
});

test('reporting user is read-only and cannot see credentials or personal identity tables', async () => {
  assert.ok((await one(reporting, `SELECT COUNT(*) c FROM orders`)).c >= 0);
  await rejects(reporting.query(`UPDATE orders SET status = 'cancelled'`), 'ER_TABLEACCESS_DENIED_ERROR');
  await rejects(reporting.query(`INSERT INTO audit_logs (actor_type, action) VALUES ('system','x')`), 'ER_TABLEACCESS_DENIED_ERROR');
  for (const t of ['payment_gateway_accounts', 'users', 'customers', 'refresh_tokens', 'table_qr_codes', 'login_sessions', 'payroll_entries', 'reservations']) {
    await rejects(reporting.query(`SELECT * FROM ${t} LIMIT 1`), 'ER_TABLEACCESS_DENIED_ERROR');
  }
});

test('migrator owns DDL, but only inside its schema', async () => {
  const migrator = await connectAs(USERS.migrator);
  try {
    await migrator.query(`CREATE TABLE migrator_probe (id INT)`);
    await migrator.query(`DROP TABLE migrator_probe`);
    await rejects(migrator.query(`SELECT * FROM mysql.user`), 'ER_TABLEACCESS_DENIED_ERROR');
  } finally {
    await migrator.end();
  }
});

test('re-running grants is idempotent', async () => {
  await applyGrants(admin, { database: DB, ...USERS });
  await rejects(app.query(`DELETE FROM audit_logs`), 'ER_TABLEACCESS_DENIED_ERROR');
});
