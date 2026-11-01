import { Injectable } from '@nestjs/common';
import { sql } from 'kysely';
import { actorUserId, requiredUserId, store, tenantId, unscoped } from '../../common/context';
import { badRequest, conflict, forbidden, notFound } from '../../common/errors';
import { randomToken, sha256, ulid } from '../../common/ids';
import { currentBranch, idOf } from '../../common/lookup';
import { audit, Db, Tx } from '../../infra/db/db.service';
import { hashPassword } from '../identity/crypto';
import { EntitlementService } from '../subscriptions/entitlement.service';

@Injectable()
export class StaffService {
  constructor(private readonly db: Db, private readonly entitlements: EntitlementService) {}

  async list() {
    const rows = await this.db.q.selectFrom('cafe_staff as s').innerJoin('users as u', 'u.id', 's.user_id').select(['s.public_id', 'u.id as user_id', 's.employee_code', 's.job_title', 's.status', 's.hired_on', 'u.full_name', 'u.email']).where('s.cafe_id', '=', tenantId()).orderBy('u.full_name').execute();
    const roles = await this.db.q.selectFrom('user_roles as ur').innerJoin('roles as r', 'r.id', 'ur.role_id').leftJoin('cafe_branches as b', 'b.id', 'ur.branch_id').select(['ur.user_id', 'r.code', 'r.name', 'b.public_id as branch_id']).where('ur.cafe_id', '=', tenantId()).execute();
    return rows.map(({ user_id, ...s }) => ({ ...s, roles: roles.filter((r) => r.user_id === user_id).map((r) => ({ code: r.code, name: r.name, branchId: r.branch_id })) }));
  }

  private async resolveRole(q: Tx | Db['q'], code: string) {
    const r = await q.selectFrom('roles').select(['id', 'code', 'cafe_id']).where('code', '=', code).where('scope', '=', 'cafe').where('deleted_at', 'is', null).where((eb) => eb.or([eb('cafe_id', '=', tenantId()), eb('cafe_id', 'is', null)])).orderBy(sql`cafe_id IS NULL`).executeTakeFirst();
    if (!r) throw notFound('ROLE_NOT_FOUND');
    // Ownership cannot be handed out through the staff screen.
    if (r.code === 'owner') throw forbidden('ROLE_NOT_ASSIGNABLE');
    return r;
  }

  // Creates the person and a one-time invitation. The password is set by them, never by the employer.
  async invite(d: { email: string; fullName: string; roleCode: string; branchId?: string; jobTitle?: string; employeeCode?: string }) {
    const email = d.email.trim().toLowerCase();
    return this.db.tx(async (tx) => {
      const count = await tx.selectFrom('cafe_staff').select((eb) => eb.fn.countAll<number>().as('n')).where('cafe_id', '=', tenantId()).where('status', '!=', 'inactive').executeTakeFirstOrThrow();
      await this.entitlements.assertWithinLimit(tx, 'employees', 1, Number(count.n));
      const role = await this.resolveRole(tx, d.roleCode);
      const branchId = d.branchId ? await idOf(tx, 'cafe_branches', d.branchId, 'BRANCH_NOT_FOUND') : null;
      let user = await tx.selectFrom('users').select(['id', 'status']).where('email', '=', email).where('deleted_at', 'is', null).executeTakeFirst();
      let token: string | null = null;
      if (!user) {
        const id = Number((await tx.insertInto('users').values({ public_id: ulid(), email, password_hash: await hashPassword(randomToken()), full_name: d.fullName, status: 'pending_verification' }).executeTakeFirstOrThrow()).insertId);
        user = { id, status: 'pending_verification' };
        token = randomToken();
        await tx.insertInto('user_tokens').values({ user_id: id, purpose: 'staff_invitation', token_hash: sha256(token), expires_at: new Date(Date.now() + 7 * 86400_000) }).execute();
      }
      const publicId = ulid();
      await tx.insertInto('cafe_staff').values({ public_id: publicId, cafe_id: tenantId(), user_id: user.id, status: 'active', job_title: d.jobTitle ?? null, employee_code: d.employeeCode ?? null, hired_on: new Date() }).execute();
      await tx.insertInto('user_roles').values({ user_id: user.id, role_id: role.id, cafe_id: tenantId(), branch_id: branchId, granted_by_user_id: actorUserId() }).execute();
      await audit(tx, { action: 'staff.invited', entityType: 'staff', entityId: publicId, after: { role: d.roleCode } });
      // Email delivery is pending configuration, so the owner hands this link to the employee.
      return { publicId, invitationToken: token, existingAccount: !token };
    });
  }

  async acceptInvitation(token: string, password: string) {
    return unscoped('invitation precedes login', () => this.db.tx(async (tx) => {
      const row = await tx.selectFrom('user_tokens').selectAll().where('token_hash', '=', sha256(token)).where('purpose', '=', 'staff_invitation').forUpdate().executeTakeFirst();
      if (!row || row.used_at || row.expires_at < new Date() || !row.user_id) throw badRequest('INVITATION_INVALID');
      await tx.updateTable('users').set({ password_hash: await hashPassword(password), status: 'active', email_verified_at: new Date(), password_changed_at: new Date() }).where('id', '=', row.user_id).execute();
      await tx.updateTable('user_tokens').set({ used_at: new Date() }).where('id', '=', row.id).execute();
      return { ok: true };
    }));
  }

  async update(publicId: string, d: { status?: 'active' | 'inactive'; jobTitle?: string; employeeCode?: string; roleCode?: string; branchId?: string | null }) {
    await this.db.tx(async (tx) => {
      const s = await tx.selectFrom('cafe_staff').select(['id', 'user_id']).where('cafe_id', '=', tenantId()).where('public_id', '=', publicId).executeTakeFirst();
      if (!s) throw notFound();
      const cafe = await tx.selectFrom('cafes').select('owner_user_id').where('id', '=', tenantId()).executeTakeFirstOrThrow();
      if (s.user_id === cafe.owner_user_id) throw forbidden('OWNER_CANNOT_BE_CHANGED');
      await tx.updateTable('cafe_staff').set({ status: d.status, job_title: d.jobTitle, employee_code: d.employeeCode, ended_on: d.status === 'inactive' ? new Date() : undefined }).where('cafe_id', '=', tenantId()).where('id', '=', s.id).execute();
      if (d.status === 'inactive') {
        await unscoped('revoke the person on departure', () => tx.updateTable('login_sessions').set({ revoked_at: new Date(), revoke_reason: 'staff_deactivated' }).where('user_id', '=', s.user_id).where('cafe_id', '=', tenantId()).where('revoked_at', 'is', null).execute());
      }
      if (d.roleCode) {
        const role = await this.resolveRole(tx, d.roleCode);
        await tx.deleteFrom('user_roles').where('cafe_id', '=', tenantId()).where('user_id', '=', s.user_id).execute();
        await tx.insertInto('user_roles').values({ user_id: s.user_id, role_id: role.id, cafe_id: tenantId(), branch_id: d.branchId ? await idOf(tx, 'cafe_branches', d.branchId, 'BRANCH_NOT_FOUND') : null, granted_by_user_id: actorUserId() }).execute();
      }
      await audit(tx, { action: 'staff.updated', entityType: 'staff', entityId: publicId, after: d });
    });
    return { ok: true };
  }

  async roles() {
    const rows = await this.db.q.selectFrom('roles').select(['id', 'code', 'name', 'is_system', 'cafe_id']).where('scope', '=', 'cafe').where('deleted_at', 'is', null).where((eb) => eb.or([eb('cafe_id', '=', tenantId()), eb('cafe_id', 'is', null)])).execute();
    const perms = await this.db.q.selectFrom('role_permissions').selectAll().where('role_id', 'in', rows.map((r) => r.id)).execute();
    return rows.map(({ id, cafe_id: _c, ...r }) => ({ ...r, permissions: perms.filter((p) => p.role_id === id).map((p) => p.permission_code) }));
  }
  permissions() { return this.db.q.selectFrom('permissions').select(['code', 'module', 'description']).where('scope', '=', 'cafe').orderBy('module').execute(); }

  // A custom role can never hold a permission the person creating it lacks, or a platform permission.
  async saveRole(d: { code: string; name: string; permissions: string[] }) {
    return this.db.tx(async (tx) => {
      const valid = await tx.selectFrom('permissions').select('code').where('scope', '=', 'cafe').where('code', 'in', d.permissions.length ? d.permissions : ['']).execute();
      if (valid.length !== d.permissions.length) throw badRequest('PERMISSION_INVALID');
      const mine = store()!.principal!.permissions;
      if (d.permissions.some((p) => !mine.has(p))) throw forbidden('PERMISSION_NOT_GRANTABLE');
      await tx.insertInto('roles').values({ cafe_id: tenantId(), code: d.code, name: d.name, scope: 'cafe' }).onDuplicateKeyUpdate({ name: d.name, deleted_at: null }).execute();
      const role = await tx.selectFrom('roles').select('id').where('cafe_id', '=', tenantId()).where('code', '=', d.code).executeTakeFirstOrThrow();
      await tx.deleteFrom('role_permissions').where('role_id', '=', role.id).execute();
      if (d.permissions.length) await tx.insertInto('role_permissions').values(d.permissions.map((permission_code) => ({ role_id: role.id, permission_code }))).execute();
      await audit(tx, { action: 'role.saved', entityType: 'role', entityId: d.code, after: d });
      return { code: d.code };
    });
  }

  private async myStaff(q: Tx | Db['q']) {
    const s = await q.selectFrom('cafe_staff').select('id').where('cafe_id', '=', tenantId()).where('user_id', '=', requiredUserId()).executeTakeFirst();
    if (!s) throw forbidden();
    return s.id;
  }
  async clockIn() {
    const branch = currentBranch();
    return this.db.tx(async (tx) => {
      const staff = await this.myStaff(tx);
      const open = await tx.selectFrom('staff_attendance').select('id').where('cafe_id', '=', tenantId()).where('staff_id', '=', staff).where('clock_out_at', 'is', null).forUpdate().executeTakeFirst();
      if (open) throw conflict('ALREADY_CLOCKED_IN');
      await tx.insertInto('staff_attendance').values({ cafe_id: tenantId(), branch_id: branch, staff_id: staff, clock_in_at: new Date() }).execute();
      return { ok: true };
    });
  }
  async clockOut() {
    return this.db.tx(async (tx) => {
      const staff = await this.myStaff(tx);
      const r = await tx.updateTable('staff_attendance').set({ clock_out_at: new Date() }).where('cafe_id', '=', tenantId()).where('staff_id', '=', staff).where('clock_out_at', 'is', null).executeTakeFirst();
      if (!r.numUpdatedRows) throw conflict('NOT_CLOCKED_IN');
      return { ok: true };
    });
  }
  async attendance(from?: string, to?: string) {
    let q = this.db.q.selectFrom('staff_attendance as a').innerJoin('cafe_staff as s', 's.id', 'a.staff_id').innerJoin('users as u', 'u.id', 's.user_id').select(['s.public_id as staff_id', 'u.full_name', 'a.clock_in_at', 'a.clock_out_at', 'a.source', 'a.note']).where('a.cafe_id', '=', tenantId());
    if (from) q = q.where('a.clock_in_at', '>=', new Date(from));
    if (to) q = q.where('a.clock_in_at', '<=', new Date(to));
    return q.orderBy('a.clock_in_at', 'desc').limit(500).execute();
  }
  async performance(from: string, to: string) {
    const rows = await sql<{ full_name: string; orders_entered: number; status_changes: number; hours: string | null }>`
      SELECT u.full_name,
        (SELECT COUNT(*) FROM orders o WHERE o.cafe_id = s.cafe_id AND o.placed_by_user_id = s.user_id AND o.business_date BETWEEN ${from} AND ${to}) AS orders_entered,
        (SELECT COUNT(*) FROM order_status_history h WHERE h.cafe_id = s.cafe_id AND h.changed_by_user_id = s.user_id AND DATE(h.occurred_at) BETWEEN ${from} AND ${to}) AS status_changes,
        (SELECT ROUND(SUM(TIMESTAMPDIFF(MINUTE, a.clock_in_at, a.clock_out_at)) / 60, 2) FROM staff_attendance a WHERE a.cafe_id = s.cafe_id AND a.staff_id = s.id AND DATE(a.clock_in_at) BETWEEN ${from} AND ${to}) AS hours
      FROM cafe_staff s JOIN users u ON u.id = s.user_id WHERE s.cafe_id = ${tenantId()} ORDER BY u.full_name`.execute(this.db.q);
    return rows.rows;
  }
}
