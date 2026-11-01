// Structural rules that must hold for every table, present and future.
import assert from 'node:assert/strict';
import { after, before, test } from 'node:test';
import type { Connection } from 'mysql2/promise';
import { GLOBAL_TABLES, MIXED_TABLES, TENANT_TABLES } from '../table-classification.ts';
import { all, freshDatabase } from './helpers.ts';

const DB = 'cafe_test_lint';
let conn: Connection;
let tables: string[];
const columnsByTable = new Map<string, Map<string, { type: string; nullable: boolean }>>();

// Each entry: "table.column" -> one row per FK column.
interface Fk { table: string; name: string; parent: string; pairs: Array<[string, string]> }
let fks: Fk[];

before(async () => {
  conn = await freshDatabase(DB);
  tables = (await all(conn, `SELECT TABLE_NAME n FROM information_schema.TABLES WHERE TABLE_SCHEMA = ? AND TABLE_TYPE = 'BASE TABLE'`, [DB])).map((r) => r.n);
  const cols = await all(conn, `SELECT TABLE_NAME t, COLUMN_NAME c, COLUMN_TYPE ty, IS_NULLABLE n FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = ?`, [DB]);
  for (const r of cols) {
    if (!columnsByTable.has(r.t)) columnsByTable.set(r.t, new Map());
    columnsByTable.get(r.t)!.set(r.c, { type: String(r.ty), nullable: r.n === 'YES' });
  }
  const rows = await all(conn, `SELECT TABLE_NAME t, CONSTRAINT_NAME k, REFERENCED_TABLE_NAME p, COLUMN_NAME c, REFERENCED_COLUMN_NAME rc
    FROM information_schema.KEY_COLUMN_USAGE WHERE TABLE_SCHEMA = ? AND REFERENCED_TABLE_NAME IS NOT NULL ORDER BY t, k, ORDINAL_POSITION`, [DB]);
  const map = new Map<string, Fk>();
  for (const r of rows) {
    const key = `${r.t}.${r.k}`;
    if (!map.has(key)) map.set(key, { table: r.t, name: r.k, parent: r.p, pairs: [] });
    map.get(key)!.pairs.push([r.c, r.rc]);
  }
  fks = [...map.values()];
});
after(() => conn.end());

const tenant = new Set<string>(TENANT_TABLES);
const mixed = new Set<string>(MIXED_TABLES);
const global = new Set<string>(GLOBAL_TABLES);

test('every table is classified exactly once, and no classified table is missing', () => {
  const classified = [...TENANT_TABLES, ...MIXED_TABLES, ...GLOBAL_TABLES];
  assert.equal(new Set(classified).size, classified.length, 'a table is classified twice');
  assert.deepEqual(tables.filter((t) => !classified.includes(t as never)), [], 'unclassified tables');
  assert.deepEqual(classified.filter((t) => !tables.includes(t)), [], 'classified tables that do not exist');
});

test('tenant tables: cafe_id is NOT NULL and enforced by a foreign key', () => {
  const problems: string[] = [];
  for (const t of TENANT_TABLES) {
    const col = columnsByTable.get(t)?.get('cafe_id');
    if (!col) { problems.push(`${t}: no cafe_id`); continue; }
    if (col.nullable) problems.push(`${t}: cafe_id is nullable`);
    if (!fks.some((f) => f.table === t && f.pairs.some(([c]) => c === 'cafe_id'))) problems.push(`${t}: cafe_id in no FK`);
  }
  assert.deepEqual(problems, []);
});

test('mixed tables: cafe_id is nullable', () => {
  for (const t of MIXED_TABLES) assert.equal(columnsByTable.get(t)?.get('cafe_id')?.nullable, true, t);
});

test('tenant tables with an id expose UNIQUE (cafe_id, id) for composite references', async () => {
  const rows = await all(conn, `SELECT TABLE_NAME t, INDEX_NAME i, GROUP_CONCAT(COLUMN_NAME ORDER BY SEQ_IN_INDEX) c
    FROM information_schema.STATISTICS WHERE TABLE_SCHEMA = ? AND NON_UNIQUE = 0 GROUP BY TABLE_NAME, INDEX_NAME`, [DB]);
  const missing = TENANT_TABLES.filter((t) => columnsByTable.get(t)?.has('id'))
    .filter((t) => !rows.some((r) => r.t === t && r.c === 'cafe_id,id'));
  assert.deepEqual(missing, []);
});

test('references between tenant-owned rows always carry cafe_id on both sides', () => {
  const problems: string[] = [];
  for (const fk of fks) {
    const childOwned = tenant.has(fk.table) || mixed.has(fk.table);
    const parentOwned = tenant.has(fk.parent) || fk.parent === 'media_assets';
    if (!childOwned || !parentOwned) continue;
    if (!fk.pairs.some(([c, p]) => c === 'cafe_id' && p === 'cafe_id')) {
      problems.push(`${fk.table} -> ${fk.parent} (${fk.pairs.map(([c]) => c).join(', ')})`);
    }
  }
  assert.deepEqual(problems, []);
});

test('a global table references tenant data only where deliberate', () => {
  const offenders = fks.filter((f) => global.has(f.table) && (tenant.has(f.parent) || f.parent === 'media_assets'))
    .filter((f) => !(f.table === 'cafes' && f.parent === 'media_assets' && f.pairs.some(([c, p]) => c === 'id' && p === 'cafe_id')));
  assert.deepEqual(offenders.map((f) => `${f.table} -> ${f.parent}`), []);
});

test('no foreign key cascades or nulls: history can never be removed indirectly', async () => {
  const rows = await all(conn, `SELECT TABLE_NAME t, CONSTRAINT_NAME k, DELETE_RULE d, UPDATE_RULE u
    FROM information_schema.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_SCHEMA = ?`, [DB]);
  assert.ok(rows.length > 0);
  const offenders = rows.filter((r) => !['RESTRICT', 'NO ACTION'].includes(r.d) || !['RESTRICT', 'NO ACTION'].includes(r.u));
  assert.deepEqual(offenders.map((r) => `${r.t}.${r.k}`), []);
});

test('no floating-point column exists anywhere', () => {
  const offenders: string[] = [];
  for (const [t, cols] of columnsByTable) for (const [c, { type }] of cols) if (/float|double|real/i.test(type)) offenders.push(`${t}.${c}: ${type}`);
  assert.deepEqual(offenders, []);
});

test('money columns have the mandated precision', () => {
  const offenders: string[] = [];
  for (const [t, cols] of columnsByTable) for (const [c, { type }] of cols) {
    if (/(^|_)(amount|price)$|price_override$/.test(c) && type !== 'decimal(19,4)') offenders.push(`${t}.${c}: ${type}`);
    if (/unit_cost$/.test(c) && type !== 'decimal(19,6)') offenders.push(`${t}.${c}: ${type}`);
  }
  assert.deepEqual(offenders, []);
});

test('every financial record stores its currency code', () => {
  const financial = ['orders', 'bills', 'payments', 'payment_transactions', 'refunds', 'settlements', 'invoices', 'expenses',
    'journal_entries', 'cash_register_sessions', 'cash_register_transactions', 'supplier_invoices', 'supplier_payments',
    'purchase_orders', 'payroll_entries', 'stock_movements', 'coupon_redemptions', 'platform_transactions',
    'subscription_invoices', 'cafe_subscriptions', 'plan_prices'];
  for (const t of financial) assert.ok(columnsByTable.get(t)?.has('currency_code'), `${t} has no currency_code`);
});

test('no column can hold card data or plaintext credentials', () => {
  const banned = /(card_?number|^pan$|cvv|cvc|card_?expiry|upi_?pin|^password$|^secret$|api_?key$|^refresh_token$|^access_token$)/i;
  const offenders: string[] = [];
  for (const [t, cols] of columnsByTable) for (const c of cols.keys()) if (banned.test(c)) offenders.push(`${t}.${c}`);
  assert.deepEqual(offenders, []);
});

test('all tables are InnoDB and utf8mb4', async () => {
  const rows = await all(conn, `SELECT TABLE_NAME t, ENGINE e, TABLE_COLLATION c FROM information_schema.TABLES WHERE TABLE_SCHEMA = ? AND TABLE_TYPE = 'BASE TABLE'`, [DB]);
  const offenders = rows.filter((r) => r.e !== 'InnoDB' || !String(r.c).startsWith('utf8mb4'));
  assert.deepEqual(offenders.map((r) => `${r.t}: ${r.e}/${r.c}`), []);
});

test('no TIMESTAMP columns: time is DATETIME(3) stored as UTC', () => {
  const offenders: string[] = [];
  for (const [t, cols] of columnsByTable) for (const [c, { type }] of cols) if (/^timestamp/.test(type)) offenders.push(`${t}.${c}`);
  assert.deepEqual(offenders, []);
});

test('server session runs in UTC', async () => {
  const [row] = await all(conn, `SELECT @@session.time_zone AS tz`);
  assert.equal(row!.tz, '+00:00');
});
