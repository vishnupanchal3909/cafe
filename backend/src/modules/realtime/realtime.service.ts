import { Injectable, Logger, OnApplicationShutdown } from '@nestjs/common';
import { createAdapter } from '@socket.io/redis-adapter';
import Redis from 'ioredis';
import type { Server as HttpServer } from 'node:http';
import { Server, Socket } from 'socket.io';
import { sql } from 'kysely';
import { config } from '../../common/config';
import { als, unscoped } from '../../common/context';
import { sha256 } from '../../common/ids';
import { Db, rooms } from '../../infra/db/db.service';
import { AuthService } from '../identity/auth.service';

@Injectable()
export class RealtimeService implements OnApplicationShutdown {
  private readonly logger = new Logger('Realtime');
  private io?: Server;
  private redis: Redis[] = [];
  constructor(private readonly db: Db, private readonly auth: AuthService) {}

  attach(http: HttpServer) {
    this.io = new Server(http, { path: '/socket.io', cors: { origin: config.corsOrigins, credentials: true } });
    if (config.redisUrl) {
      const pub = new Redis(config.redisUrl, { maxRetriesPerRequest: 2 });
      const sub = pub.duplicate();
      pub.on('error', () => undefined); sub.on('error', () => undefined);
      this.redis = [pub, sub];
      this.io.adapter(createAdapter(pub, sub));
    }
    this.io.use(async (socket, next) => {
      try { socket.data.rooms = await als.run({ requestId: socket.id, lang: 'en' }, () => this.authorize(socket)); next(); }
      catch { next(new Error('UNAUTHORIZED')); }
    });
    this.io.on('connection', async (socket) => {
      const allowed = socket.data.rooms as string[];
      await socket.join(allowed);
      socket.emit('ready', { rooms: allowed.length });
      const lastSeq = Number(socket.handshake.auth?.lastSeq ?? 0);
      if (lastSeq > 0) await this.replay(socket, allowed, lastSeq);
    });
  }

  // Rooms are computed from the verified credential. A client can never name a room.
  private async authorize(socket: Socket): Promise<string[]> {
    const { token, tableSession } = socket.handshake.auth as { token?: string; tableSession?: string };
    if (tableSession) {
      const s = await unscoped('token precedes tenant resolution', () => this.db.q.selectFrom('table_sessions').select(['public_id', 'status', 'expires_at']).where('token_hash', '=', sha256(tableSession)).executeTakeFirst());
      if (!s || s.status === 'closed' || s.expires_at < new Date()) throw new Error('session');
      return [rooms.session(s.public_id)];
    }
    if (!token) throw new Error('no credential');
    const claims = await this.auth.verifyAccess(token);
    const { principal, cafeId } = await this.auth.loadPrincipal(claims);
    if (claims.aud === 'customer') return [rooms.customer(principal.id!)];
    if (claims.aud === 'platform') return [rooms.platform()];
    const p = principal.permissions;
    const branches = principal.branchIds ?? (await unscoped('branch list for own tenant', () => this.db.q.selectFrom('cafe_branches').select('id').where('cafe_id', '=', cafeId!).where('deleted_at', 'is', null).execute())).map((b) => b.id);
    const out: string[] = [];
    for (const b of branches) {
      if (p.has('kitchen.read')) out.push(rooms.branch(cafeId!, b, 'kitchen'));
      if (claims.aud === 'cafe') {
        if (p.has('orders.read')) out.push(rooms.branch(cafeId!, b, 'floor'));
        if (p.has('payments.read')) out.push(rooms.branch(cafeId!, b, 'cashier'));
        if (p.has('inventory.manage') || p.has('reports.read')) out.push(rooms.branch(cafeId!, b, 'manager'));
      }
    }
    if (claims.aud === 'cafe' && p.has('finance.manage')) out.push(rooms.owner(cafeId!));
    return out;
  }

  // Replays only events addressed to a room this credential was just authorized for.
  private async replay(socket: Socket, allowed: string[], lastSeq: number) {
    const set = new Set(allowed);
    const rows = await unscoped('replay, filtered to authorized rooms below', () => this.db.q.selectFrom('outbox_events').select(['event_id', 'dispatch_seq', 'event_type', 'occurred_at', 'payload', 'audience']).where('dispatch_seq', '>', lastSeq).orderBy('dispatch_seq').limit(500).execute());
    for (const r of rows) {
      const target = (r.audience as { rooms: string[] }).rooms;
      if (target.some((x) => set.has(x))) socket.emit('event', { eventId: r.event_id, seq: r.dispatch_seq, type: r.event_type, occurredAt: r.occurred_at, payload: r.payload, replay: true });
    }
  }

  // One dispatcher at a time across all instances. The sequence is assigned here, so replay cursors are safe.
  async dispatchOnce(batch = 200): Promise<number> {
    return unscoped('outbox spans tenants', () => this.db.tx(async (tx) => {
      const lock = await sql<{ l: number }>`SELECT GET_LOCK('cafe_outbox_dispatch', 0) AS l`.execute(tx);
      if (lock.rows[0]?.l !== 1) return 0;
      try {
        const events = await tx.selectFrom('outbox_events').select(['id', 'event_id', 'event_type', 'occurred_at', 'payload', 'audience']).where('dispatched_at', 'is', null).orderBy('id').limit(batch).execute();
        if (!events.length) return 0;
        const max = await tx.selectFrom('outbox_events').select((eb) => eb.fn.max('dispatch_seq').as('m')).executeTakeFirstOrThrow();
        let seq = Number(max.m ?? 0);
        for (const e of events) {
          seq += 1;
          await tx.updateTable('outbox_events').set({ dispatch_seq: seq, dispatched_at: new Date(), attempts: 1 }).where('id', '=', e.id).execute();
          const target = (e.audience as { rooms: string[] }).rooms;
          if (this.io && target.length) this.io.to(target).emit('event', { eventId: e.event_id, seq, type: e.event_type, occurredAt: e.occurred_at, payload: e.payload });
        }
        return events.length;
      } finally {
        await sql`SELECT RELEASE_LOCK('cafe_outbox_dispatch')`.execute(tx);
      }
    }));
  }

  async cleanup(retainDays = 7) {
    await unscoped('outbox spans tenants', () => this.db.q.deleteFrom('outbox_events').where('dispatched_at', '<', new Date(Date.now() - retainDays * 86400_000)).execute());
  }

  async onApplicationShutdown() {
    await this.io?.close();
    this.redis.forEach((r) => r.disconnect());
  }
}
