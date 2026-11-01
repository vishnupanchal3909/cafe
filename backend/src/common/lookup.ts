import { Q } from '../infra/db/db.service';
import { tenantId, store } from './context';
import { forbidden, badRequest, notFound } from './errors';
import { DB } from '../infra/db/types';

type PublicTable = { [K in keyof DB]: DB[K] extends { public_id: string; cafe_id: number } ? K : never }[keyof DB];

// Public id to internal id, always inside the current tenant. Another cafe's id looks exactly like a missing one.
export async function idOf(q: Q, table: PublicTable, publicId: string, code = 'NOT_FOUND'): Promise<number> {
  const row = await (q as any).selectFrom(table).select('id').where('cafe_id', '=', tenantId()).where('public_id', '=', publicId).executeTakeFirst();
  if (!row) throw notFound(code);
  return row.id as number;
}

export function currentBranch(): number {
  const id = store()?.branchId;
  if (!id) throw badRequest('BRANCH_REQUIRED');
  return id;
}

export function assertBranchAllowed(branchId: number): void {
  const allowed = store()?.principal?.branchIds;
  if (allowed && !allowed.includes(branchId)) throw forbidden('BRANCH_FORBIDDEN');
}
