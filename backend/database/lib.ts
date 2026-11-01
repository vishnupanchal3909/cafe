import { createHash } from 'node:crypto';
import { existsSync, readdirSync, readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import mysql from 'mysql2/promise';
import type { Connection, ConnectionOptions, RowDataPacket } from 'mysql2/promise';
import { APPEND_ONLY_TABLES, NO_DELETE_TABLES, SECRET_TABLES } from './table-classification.ts';

const here = dirname(fileURLToPath(import.meta.url));
export const MIGRATIONS_DIR = join(here, 'migrations');
export const SEEDS_DIR = join(here, 'seeds');

const envFile = join(here, '..', '.env');
if (existsSync(envFile)) process.loadEnvFile(envFile);

export function adminOptions(database?: string): ConnectionOptions {
  return {
    host: process.env.DB_HOST ?? '127.0.0.1',
    port: Number(process.env.DB_PORT ?? 3307),
    user: process.env.DB_ADMIN_USER ?? 'root',
    password: process.env.DB_ADMIN_PASSWORD ?? '',
    database,
    multipleStatements: true,
    timezone: 'Z',
    // Money must arrive as strings, never JS numbers.
    decimalNumbers: false,
    charset: 'utf8mb4_0900_ai_ci',
  };
}

export function assertIdentifier(name: string): string {
  if (!/^[a-zA-Z0-9_]+$/.test(name)) throw new Error(`Invalid SQL identifier: ${name}`);
  return name;
}

export async function connectAdmin(database?: string): Promise<Connection> {
  const conn = await mysql.createConnection(adminOptions(database));
  await conn.query(`SET time_zone = '+00:00'`);
  return conn;
}

export async function ensureDatabase(conn: Connection, name: string): Promise<void> {
  await conn.query(
    `CREATE DATABASE IF NOT EXISTS \`${assertIdentifier(name)}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci`,
  );
}

export interface MigrationResult {
  applied: string[];
  skipped: string[];
}

function sha256(text: string): string {
  return createHash('sha256').update(text).digest('hex');
}

// Applies pending *.sql files in name order on a connection whose default database is the target.
// An edited migration that has already been applied is an error: changes go in a new migration.
export async function migrate(conn: Connection, dir: string = MIGRATIONS_DIR): Promise<MigrationResult> {
  const [lockRows] = await conn.query<RowDataPacket[]>(`SELECT GET_LOCK('cafe_platform_migrate', 30) AS locked`);
  if (lockRows[0]?.locked !== 1) throw new Error('Another migration run holds the lock');

  try {
    await conn.query(`CREATE TABLE IF NOT EXISTS schema_migrations (
      version VARCHAR(191) COLLATE ascii_bin NOT NULL,
      checksum CHAR(64) COLLATE ascii_bin NOT NULL,
      execution_ms INT UNSIGNED NOT NULL,
      applied_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
      PRIMARY KEY (version)
    )`);

    const [rows] = await conn.query<RowDataPacket[]>(`SELECT version, checksum FROM schema_migrations`);
    const applied = new Map(rows.map((r) => [r.version as string, r.checksum as string]));
    const files = readdirSync(dir).filter((f) => f.endsWith('.sql')).sort();
    const result: MigrationResult = { applied: [], skipped: [] };

    for (const version of applied.keys()) {
      if (!files.includes(version)) throw new Error(`Applied migration ${version} is missing from disk`);
    }

    for (const file of files) {
      const sql = readFileSync(join(dir, file), 'utf8');
      const checksum = sha256(sql);
      const previous = applied.get(file);
      if (previous) {
        if (previous !== checksum) {
          throw new Error(`Migration ${file} was edited after being applied. Add a new migration instead.`);
        }
        result.skipped.push(file);
        continue;
      }
      const started = Date.now();
      try {
        await conn.query(sql);
      } catch (err) {
        // MySQL DDL is not transactional: earlier statements in this file may have taken effect.
        throw new Error(`Migration ${file} failed and may be partially applied: ${(err as Error).message}`);
      }
      await conn.query(`INSERT INTO schema_migrations (version, checksum, execution_ms) VALUES (?, ?, ?)`, [
        file, checksum, Date.now() - started,
      ]);
      result.applied.push(file);
    }
    return result;
  } finally {
    await conn.query(`SELECT RELEASE_LOCK('cafe_platform_migrate')`);
  }
}

export async function seed(conn: Connection, dir: string = SEEDS_DIR): Promise<string[]> {
  const files = readdirSync(dir).filter((f) => f.endsWith('.sql')).sort();
  for (const file of files) await conn.query(readFileSync(join(dir, file), 'utf8'));
  return files;
}

export interface GrantConfig {
  database: string;
  migrator: { user: string; password: string };
  app: { user: string; password: string };
  reporting: { user: string; password: string };
  host?: string;
}

// Table-level grants, because MySQL cannot subtract from a schema-level grant without partial_revokes.
// Re-run after each migration so new tables are covered.
export async function applyGrants(conn: Connection, config: GrantConfig): Promise<void> {
  const db = assertIdentifier(config.database);
  const host = config.host ?? '%';
  const [rows] = await conn.query<RowDataPacket[]>(
    `SELECT TABLE_NAME AS name FROM information_schema.TABLES WHERE TABLE_SCHEMA = ? AND TABLE_TYPE = 'BASE TABLE'`,
    [db],
  );
  const tables = rows.map((r) => r.name as string);
  const appendOnly = new Set<string>(APPEND_ONLY_TABLES);
  const noDelete = new Set<string>(NO_DELETE_TABLES);
  const secret = new Set<string>(SECRET_TABLES);

  for (const { user, password } of [config.migrator, config.app, config.reporting]) {
    assertIdentifier(user);
    await conn.query(`CREATE USER IF NOT EXISTS ?@? IDENTIFIED BY ?`, [user, host, password]);
    await conn.query(`ALTER USER ?@? IDENTIFIED BY ?`, [user, host, password]);
    await conn.query(`REVOKE ALL PRIVILEGES, GRANT OPTION FROM ?@?`, [user, host]);
  }

  await conn.query(`GRANT ALL PRIVILEGES ON \`${db}\`.* TO ?@?`, [config.migrator.user, host]);

  for (const table of tables) {
    const target = `\`${db}\`.\`${assertIdentifier(table)}\``;
    let appPrivileges: string;
    if (table === 'schema_migrations') appPrivileges = 'SELECT';
    else if (appendOnly.has(table)) appPrivileges = 'SELECT, INSERT';
    else if (noDelete.has(table)) appPrivileges = 'SELECT, INSERT, UPDATE';
    else appPrivileges = 'SELECT, INSERT, UPDATE, DELETE';
    await conn.query(`GRANT ${appPrivileges} ON ${target} TO ?@?`, [config.app.user, host]);

    if (!secret.has(table)) {
      await conn.query(`GRANT SELECT ON ${target} TO ?@?`, [config.reporting.user, host]);
    }
  }
}
