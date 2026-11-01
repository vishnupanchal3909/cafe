import type { CompiledQuery, DatabaseConnection, Driver, QueryResult, TransactionSettings } from 'kysely';
import { TENANT_TABLES } from '../../../database/table-classification';
import { als } from '../../common/context';

const TENANT_RE = new RegExp(`\`(${TENANT_TABLES.join('|')})\``);

export class TenantGuardViolation extends Error {}

// MySQL has no row-level security, so every statement is inspected before it reaches the server.
// A statement touching a tenant table must mention cafe_id and bind the current tenant's id.
// Anything else must run inside an explicit unscoped(reason, ...).
export function assertTenantScoped(sql: string, parameters: readonly unknown[]): void {
  const s = als.getStore();
  if (s?.unscopedReason) return;
  const table = TENANT_RE.exec(sql)?.[1];
  if (!table) return;
  if (!s?.cafeId) throw new TenantGuardViolation(`Tenant table ${table} queried with no tenant in context: ${sql}`);
  if (!/`?cafe_id`?/.test(sql) || !parameters.some((p) => Number(p) === s.cafeId)) {
    throw new TenantGuardViolation(`Query on ${table} is not scoped to the current tenant: ${sql}`);
  }
}

class GuardedConnection implements DatabaseConnection {
  constructor(private readonly inner: DatabaseConnection) {}
  executeQuery<R>(q: CompiledQuery): Promise<QueryResult<R>> {
    assertTenantScoped(q.sql, q.parameters);
    return this.inner.executeQuery<R>(q);
  }
  streamQuery<R>(q: CompiledQuery, chunkSize?: number) {
    assertTenantScoped(q.sql, q.parameters);
    return this.inner.streamQuery<R>(q, chunkSize as number);
  }
}

export class GuardedDriver implements Driver {
  private readonly wrapped = new WeakMap<DatabaseConnection, GuardedConnection>();
  constructor(private readonly inner: Driver) {}
  init() { return this.inner.init(); }
  async acquireConnection() {
    const c = await this.inner.acquireConnection();
    let g = this.wrapped.get(c);
    if (!g) { g = new GuardedConnection(c); this.wrapped.set(c, g); (g as unknown as { raw: DatabaseConnection }).raw = c; }
    return g;
  }
  private raw(c: DatabaseConnection) { return (c as unknown as { raw: DatabaseConnection }).raw; }
  beginTransaction(c: DatabaseConnection, s: TransactionSettings) { return this.inner.beginTransaction(this.raw(c), s); }
  commitTransaction(c: DatabaseConnection) { return this.inner.commitTransaction(this.raw(c)); }
  rollbackTransaction(c: DatabaseConnection) { return this.inner.rollbackTransaction(this.raw(c)); }
  releaseConnection(c: DatabaseConnection) { return this.inner.releaseConnection(this.raw(c)); }
  destroy() { return this.inner.destroy(); }
}
