import { Injectable, OnModuleDestroy } from '@nestjs/common';
import { Kysely, MysqlAdapter, MysqlDialect, MysqlIntrospector, MysqlQueryCompiler, Transaction } from 'kysely';
import { createPool } from 'mysql2';
import { config } from '../../common/config';
import { GuardedDriver } from './guard-driver';
import type { DB } from './types';
import { actorUserId, store } from '../../common/context';
import { ulid } from '../../common/ids';

export type Tx = Transaction<DB>;
export type Q = Kysely<DB> | Tx;

@Injectable()
export class Db implements OnModuleDestroy {
  readonly pool = createPool({
    host: config.db.host, port: config.db.port, user: config.db.user, password: config.db.password, database: config.db.name,
    connectionLimit: Number(process.env.DB_POOL_SIZE ?? 20), timezone: 'Z', decimalNumbers: false, charset: 'utf8mb4_0900_ai_ci',
    dateStrings: false,
  });

  readonly q: Kysely<DB>;

  constructor() {
    this.pool.on('connection', (c) => c.query(`SET time_zone = '+00:00'`));
    const base = new MysqlDialect({ pool: this.pool as never });
    this.q = new Kysely<DB>({
      dialect: {
        createAdapter: () => new MysqlAdapter(),
        createDriver: () => new GuardedDriver(base.createDriver()),
        createIntrospector: (db) => new MysqlIntrospector(db),
        createQueryCompiler: () => new MysqlQueryCompiler(),
      },
    });
  }

  tx<T>(fn: (tx: Tx) => Promise<T>): Promise<T> {
    return this.q.transaction().execute(fn);
  }

  async onModuleDestroy() { await this.q.destroy(); }
}

export interface AuditInput {
  action: string;
  entityType?: string;
  entityId?: string | number;
  reason?: string;
  before?: unknown;
  after?: unknown;
  cafeId?: number | null;
  branchId?: number | null;
}

// Written with the business change, in the same transaction, so neither can exist without the other.
export async function audit(q: Q, input: AuditInput): Promise<void> {
  const s = store();
  const p = s?.principal;
  await q.insertInto('audit_logs').values({
    cafe_id: input.cafeId !== undefined ? input.cafeId : (s?.cafeId ?? null),
    branch_id: input.branchId ?? s?.branchId ?? null,
    actor_type: p?.type === 'user' ? 'user' : p?.type === 'customer' || p?.type === 'table_session' ? 'customer' : 'system',
    actor_id: p?.id ?? actorUserId(),
    action: input.action,
    entity_type: input.entityType ?? null,
    entity_id: input.entityId != null ? String(input.entityId) : null,
    reason: input.reason ?? null,
    before_state: input.before !== undefined ? JSON.stringify(input.before) : null,
    after_state: input.after !== undefined ? JSON.stringify(input.after) : null,
    ip_address: s?.ip ?? null,
    request_id: s?.requestId?.slice(0, 40) ?? null,
  }).execute();
}

export interface OutboxInput {
  cafeId?: number | null;
  branchId?: number | null;
  type: string;
  rooms: string[];
  payload: Record<string, unknown>;
}

// Transactional outbox: an event exists if and only if the business change committed.
export async function emit(q: Q, e: OutboxInput): Promise<void> {
  await q.insertInto('outbox_events').values({
    event_id: ulid(), cafe_id: e.cafeId ?? null, branch_id: e.branchId ?? null, event_type: e.type,
    audience: JSON.stringify({ rooms: e.rooms }), payload: JSON.stringify(e.payload),
  }).execute();
}

export const rooms = {
  branch: (cafeId: number, branchId: number, role: 'kitchen' | 'floor' | 'cashier' | 'manager') => `cafe:${cafeId}:branch:${branchId}:role:${role}`,
  owner: (cafeId: number) => `cafe:${cafeId}:owner`,
  session: (publicId: string) => `session:${publicId}`,
  customer: (customerId: number) => `customer:${customerId}`,
  platform: () => 'platform:admin',
};
export const staffRooms = (cafeId: number, branchId: number) => [
  rooms.branch(cafeId, branchId, 'floor'), rooms.branch(cafeId, branchId, 'cashier'), rooms.branch(cafeId, branchId, 'manager'), rooms.owner(cafeId),
];
