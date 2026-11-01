import { AsyncLocalStorage } from 'node:async_hooks';
import { randomUUID } from 'node:crypto';

export type Audience = 'platform' | 'cafe' | 'kitchen' | 'customer';

export interface Principal {
  type: 'user' | 'customer' | 'table_session' | 'system';
  id: number | null;
  audience?: Audience;
  sessionId?: number;
  permissions: Set<string>;
  // null means all branches in the cafe.
  branchIds: number[] | null;
  tableSessionId?: number;
}

export interface RequestStore {
  requestId: string;
  lang: string;
  ip?: string;
  principal?: Principal;
  cafeId?: number;
  branchId?: number;
  // Set only by unscoped(): the tenant guard skips its check, with a recorded reason.
  unscopedReason?: string;
}

export const als = new AsyncLocalStorage<RequestStore>();

export const store = (): RequestStore | undefined => als.getStore();
export const currentRequestId = () => als.getStore()?.requestId;
export const currentLang = () => als.getStore()?.lang ?? 'en';

export function tenantId(): number {
  const id = als.getStore()?.cafeId;
  if (!id) throw new Error('No tenant in context');
  return id;
}
export function principal(): Principal {
  const p = als.getStore()?.principal;
  if (!p) throw new Error('No principal in context');
  return p;
}
export const actorUserId = (): number | null => {
  const p = als.getStore()?.principal;
  return p?.type === 'user' ? p.id : null;
};

export function requiredUserId(): number {
  const id = actorUserId();
  if (!id) throw new Error('Staff user required');
  return id;
}

// Explicit, greppable escape hatch for queries that legitimately span tenants or precede tenant resolution.
export function unscoped<T>(reason: string, fn: () => Promise<T>): Promise<T> {
  const parent = als.getStore();
  return als.run({ ...(parent ?? { requestId: randomUUID(), lang: 'en' }), unscopedReason: reason }, fn);
}

// Background work on behalf of one cafe. Tenant guard applies as in a request.
export function asTenant<T>(cafeId: number, fn: () => Promise<T>): Promise<T> {
  const parent = als.getStore();
  return als.run({ ...(parent ?? { requestId: randomUUID(), lang: 'en' }), cafeId, unscopedReason: undefined }, fn);
}
