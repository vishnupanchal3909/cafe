import assert from 'node:assert/strict';
import { randomBytes } from 'node:crypto';
import mysql from 'mysql2/promise';
import type { Connection, Pool, ResultSetHeader, RowDataPacket } from 'mysql2/promise';
import { adminOptions, assertIdentifier, connectAdmin, migrate, seed } from '../lib.ts';

export function uid(): string {
  return randomBytes(13).toString('hex').toUpperCase();
}

// Rebuilds a dedicated database for one test file. Refuses names that could be a real database.
export async function freshDatabase(name: string): Promise<Connection> {
  if (!name.startsWith('cafe_test_')) throw new Error(`Refusing to reset non-test database ${name}`);
  const bootstrap = await connectAdmin();
  await bootstrap.query(`DROP DATABASE IF EXISTS \`${assertIdentifier(name)}\``);
  await bootstrap.query(`CREATE DATABASE \`${name}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci`);
  await bootstrap.end();
  const conn = await connectAdmin(name);
  await migrate(conn);
  await seed(conn);
  return conn;
}

export function createPool(database: string): Pool {
  return mysql.createPool({ ...adminOptions(database), connectionLimit: 12 });
}

export async function insert(conn: Connection | Pool, table: string, row: Record<string, unknown>): Promise<number> {
  const [result] = await conn.query<ResultSetHeader>(`INSERT INTO \`${assertIdentifier(table)}\` SET ?`, [row]);
  return result.insertId;
}

export async function one(conn: Connection | Pool, sql: string, params: unknown[] = []): Promise<RowDataPacket> {
  const [rows] = await conn.query<RowDataPacket[]>(sql, params);
  assert.ok(rows[0], `expected a row from: ${sql}`);
  return rows[0];
}

export async function all(conn: Connection | Pool, sql: string, params: unknown[] = []): Promise<RowDataPacket[]> {
  const [rows] = await conn.query<RowDataPacket[]>(sql, params);
  return rows;
}

// Asserts a specific rejection. A bare "it threw" would also pass on a typo in the test's SQL.
export async function rejects(action: Promise<unknown>, expected: RegExp | string): Promise<void> {
  await assert.rejects(action, (err: { code?: string; message: string }) => {
    const matched = typeof expected === 'string' ? err.code === expected : expected.test(err.message);
    assert.ok(matched, `expected ${expected}, got ${err.code}: ${err.message}`);
    return true;
  });
}

export const FK_VIOLATION = 'ER_NO_REFERENCED_ROW_2';
export const CHECK_VIOLATION = 'ER_CHECK_CONSTRAINT_VIOLATED';

export interface CafeFixture {
  cafeId: number;
  ownerId: number;
  branchId: number;
  categoryId: number;
  productId: number;
  variantId: number;
  addonId: number;
  tableId: number;
  sessionId: number;
  taxCategoryId: number;
  customerId: number;
  roleId: number;
  periodId: number;
  cashAccountId: number;
  revenueAccountId: number;
  assetId: number;
  ingredientId: number;
  currency: string;
}

export async function createUser(conn: Connection, label: string): Promise<number> {
  return insert(conn, 'users', {
    public_id: uid(), email: `${label}-${uid()}@example.test`, password_hash: 'not-a-real-hash', full_name: label, status: 'active',
  });
}

export async function createCafe(conn: Connection, label: string, currency = 'INR'): Promise<CafeFixture> {
  const ownerId = await createUser(conn, `${label}-owner`);
  const cafeId = await insert(conn, 'cafes', {
    public_id: uid(), slug: `${label}-${uid()}`.toLowerCase(), owner_user_id: ownerId, legal_name: `${label} Ltd`, display_name: label,
    status: 'active', country_code: 'IN', currency_code: currency, default_language_code: 'en', timezone: 'Asia/Kolkata',
  });
  const tenant = { cafe_id: cafeId };
  const branchId = await insert(conn, 'cafe_branches', {
    ...tenant, public_id: uid(), code: 'MAIN', name: 'Main', address_line1: '1 Test St', city: 'Pune', is_main: 1,
  });
  await insert(conn, 'cafe_staff', { ...tenant, public_id: uid(), user_id: ownerId, status: 'active' });
  const taxCategoryId = await insert(conn, 'tax_categories', { ...tenant, code: 'FOOD', name: 'Food' });
  const assetId = await insert(conn, 'media_assets', {
    ...tenant, public_id: uid(), kind: 'product_image', storage_key: `${label}/${uid()}`, mime_type: 'image/png', byte_size: 10,
  });
  const categoryId = await insert(conn, 'categories', { ...tenant, public_id: uid() });
  const productId = await insert(conn, 'products', {
    ...tenant, public_id: uid(), category_id: categoryId, tax_category_id: taxCategoryId, base_price: '100.0000',
  });
  const variantId = await insert(conn, 'product_variants', { ...tenant, public_id: uid(), product_id: productId, price: '120.0000' });
  const addonGroupId = await insert(conn, 'addon_groups', { ...tenant, public_id: uid() });
  const addonId = await insert(conn, 'product_addons', { ...tenant, public_id: uid(), addon_group_id: addonGroupId, price: '10.0000' });
  const tableId = await insert(conn, 'cafe_tables', { ...tenant, public_id: uid(), branch_id: branchId, table_number: 'T1' });
  const sessionId = await insert(conn, 'table_sessions', {
    ...tenant, public_id: uid(), branch_id: branchId, table_id: tableId, token_hash: uid().padEnd(64, '0'), expires_at: '2030-01-01 00:00:00',
  });
  const globalCustomerId = await insert(conn, 'customers', { public_id: uid(), full_name: `${label} customer` });
  await insert(conn, 'cafe_customers', { ...tenant, public_id: uid(), customer_id: globalCustomerId });
  const roleId = await insert(conn, 'roles', { ...tenant, code: 'custom', name: 'Custom', scope: 'cafe' });
  const periodId = await insert(conn, 'financial_periods', { ...tenant, name: '2026', starts_on: '2026-01-01', ends_on: '2026-12-31' });
  const cashAccountId = await insert(conn, 'accounting_accounts', { ...tenant, code: '1000', name: 'Cash', account_type: 'asset' });
  const revenueAccountId = await insert(conn, 'accounting_accounts', { ...tenant, code: '4000', name: 'Revenue', account_type: 'revenue' });
  const ingredientId = await insert(conn, 'ingredients', { ...tenant, public_id: uid(), name: 'Coffee', unit_code: 'g' });
  return {
    cafeId, ownerId, branchId, categoryId, productId, variantId, addonId, tableId, sessionId, taxCategoryId,
    customerId: globalCustomerId, roleId, periodId, cashAccountId, revenueAccountId, assetId, ingredientId, currency,
  };
}

let orderCounter = 0;
export function orderRow(cafe: CafeFixture, overrides: Record<string, unknown> = {}): Record<string, unknown> {
  orderCounter += 1;
  return {
    public_id: uid(), cafe_id: cafe.cafeId, branch_id: cafe.branchId, order_number: orderCounter, business_date: '2026-06-01',
    order_source: 'qr', status: 'placed', language_code: 'en', currency_code: cafe.currency, prices_include_tax: 0,
    subtotal_amount: '100.0000', total_amount: '100.0000', ...overrides,
  };
}

export async function createOrder(conn: Connection, cafe: CafeFixture, overrides: Record<string, unknown> = {}): Promise<number> {
  return insert(conn, 'orders', orderRow(cafe, overrides));
}

export function paymentRow(cafe: CafeFixture, orderId: number, overrides: Record<string, unknown> = {}): Record<string, unknown> {
  return {
    public_id: uid(), cafe_id: cafe.cafeId, branch_id: cafe.branchId, order_id: orderId, method_code: 'card', provider_code: 'razorpay',
    currency_code: cafe.currency, amount: '100.0000', idempotency_key: uid(), ...overrides,
  };
}

export async function createVerifiedPayment(conn: Connection, cafe: CafeFixture, orderId: number, amount = '100.0000'): Promise<number> {
  return insert(conn, 'payments', paymentRow(cafe, orderId, {
    amount, status: 'succeeded', verification_source: 'gateway_webhook', verified_at: '2026-06-01 10:00:00', provider_payment_ref: uid(),
  }));
}
