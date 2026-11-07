import { CanActivate, ExecutionContext, Injectable, SetMetadata } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import type { Request } from 'express';
import { als, Audience, unscoped } from '../../common/context';
import { AppError, forbidden, notFound, unauthorized } from '../../common/errors';
import { AUDIENCES, IS_PUBLIC, PERMISSIONS } from '../../common/http';
import { sha256 } from '../../common/ids';
import { Db } from '../../infra/db/db.service';
import { AuthService } from './auth.service';

export const TABLE_SESSION = 'tableSession';
export const ALLOW_NO_MFA = 'allowNoMfa';
export const OPTIONAL_AUTH = 'optionalAuth';
export const CUSTOMER_LOGIN = 'customerLogin';
// Route is callable with a table session (QR guest), with or without a customer login.
export const TableSessionRoute = () => SetMetadata(TABLE_SESSION, true);
export const AllowNoMfa = () => SetMetadata(ALLOW_NO_MFA, true);
// On a table-session route: a guest may look, but this action needs a signed-in customer (owner's rule, D-6).
export const RequiresCustomerLogin = () => SetMetadata(CUSTOMER_LOGIN, true);

// Pipeline: verify token -> live session -> tenant -> permissions -> branch. Default is deny.
@Injectable()
export class AuthGuard implements CanActivate {
  constructor(private readonly reflector: Reflector, private readonly auth: AuthService, private readonly db: Db) {}

  async canActivate(ctx: ExecutionContext): Promise<boolean> {
    const meta = <T>(key: string) => this.reflector.getAllAndOverride<T>(key, [ctx.getHandler(), ctx.getClass()]);
    if (ctx.getType() !== 'http') return true;
    const req = ctx.switchToHttp().getRequest<Request>();
    const s = als.getStore()!;
    const bearer = /^Bearer (.+)$/.exec(req.headers.authorization ?? '')?.[1];

    if (meta<boolean>(IS_PUBLIC)) return true;

    if (meta<boolean>(TABLE_SESSION)) {
      await this.loadTableSession(req);
      if (bearer) {
        // Fully re-checked: a revoked or deleted customer must not be able to attach to a guest order.
        const claims = await this.auth.verifyAccess(bearer);
        if (claims.kind === 'customer') {
          await this.auth.loadPrincipal(claims);
          s.principal!.id = Number(claims.sub);
        }
      }
      if (meta<boolean>(CUSTOMER_LOGIN) && !s.principal!.id) throw unauthorized('CUSTOMER_LOGIN_REQUIRED');
      return true;
    }

    const allowed = meta<Audience[]>(AUDIENCES);
    if (!allowed?.length) throw forbidden();
    if (!bearer) throw unauthorized();
    const claims = await this.auth.verifyAccess(bearer);
    if (!allowed.includes(claims.aud)) throw forbidden('WRONG_AUDIENCE');
    const { principal, cafeId } = await this.auth.loadPrincipal(claims);
    s.principal = principal;
    s.cafeId = cafeId;
    (req as Request & { sid?: string }).sid = claims.sid;

    if (claims.aud === 'platform' && !claims.mfa && !meta<boolean>(ALLOW_NO_MFA)) throw forbidden('MFA_ENROLLMENT_REQUIRED');

    const needed = meta<string[]>(PERMISSIONS);
    if (needed?.length && !needed.every((p) => principal.permissions.has(p))) throw forbidden();

    if (cafeId) await this.resolveBranch(req, principal.branchIds);
    return true;
  }

  private async resolveBranch(req: Request, allowed: number[] | null) {
    const s = als.getStore()!;
    const header = req.headers['x-branch-id'];
    if (typeof header === 'string' && header) {
      const b = await this.db.q.selectFrom('cafe_branches').select('id').where('cafe_id', '=', s.cafeId!).where('public_id', '=', header).where('deleted_at', 'is', null).executeTakeFirst();
      if (!b) throw notFound('BRANCH_NOT_FOUND');
      if (allowed && !allowed.includes(b.id)) throw forbidden('BRANCH_FORBIDDEN');
      s.branchId = b.id;
    } else if (allowed?.length === 1) {
      s.branchId = allowed[0];
    }
  }

  private async loadTableSession(req: Request) {
    const token = req.headers['x-table-session'];
    if (typeof token !== 'string' || !token) throw unauthorized('TABLE_SESSION_REQUIRED');
    const row = await unscoped('token precedes tenant resolution', () =>
      this.db.q.selectFrom('table_sessions as t').innerJoin('cafes as c', 'c.id', 't.cafe_id')
        .select(['t.id', 't.cafe_id', 't.branch_id', 't.status', 't.expires_at', 'c.status as cafe_status'])
        .where('t.token_hash', '=', sha256(token)).executeTakeFirst());
    if (!row || row.status === 'closed' || row.expires_at < new Date()) throw new AppError(410, 'TABLE_SESSION_ENDED');
    if (row.cafe_status !== 'active') throw new AppError(403, 'CAFE_UNAVAILABLE');
    const s = als.getStore()!;
    s.cafeId = row.cafe_id;
    s.branchId = row.branch_id;
    s.principal = { type: 'table_session', id: null, audience: 'customer', tableSessionId: row.id, permissions: new Set(), branchIds: [row.branch_id] };
  }
}
