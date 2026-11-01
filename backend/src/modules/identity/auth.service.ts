import { Injectable } from '@nestjs/common';
import { createPublicKey, createPrivateKey } from 'node:crypto';
import { SignJWT, jwtVerify, createRemoteJWKSet } from 'jose';
import { config } from '../../common/config';
import { Audience, Principal, store, unscoped } from '../../common/context';
import { AppError, badRequest, conflict, forbidden, unauthorized } from '../../common/errors';
import { decrypt, encrypt, randomToken, sha256, ulid } from '../../common/ids';
import { audit, Db, Q } from '../../infra/db/db.service';
import { DUMMY_HASH_PROMISE, hashPassword, newTotpSecret, verifyPassword, verifyTotp } from './crypto';

const MAX_FAILURES = 5;
const LOCK_MINUTES = 15;

export interface AccessClaims { sub: string; aud: Audience; sid: string; cafe?: number; kind: 'user' | 'customer'; mfa?: boolean }

export interface TokenPair { accessToken: string; refreshToken: string; expiresIn: number }

@Injectable()
export class AuthService {
  private readonly signKey = createPrivateKey(config.jwt.privateKey);
  private readonly verifyKey = createPublicKey(config.jwt.publicKey);
  constructor(private readonly db: Db) {}

  signAccess(claims: AccessClaims): Promise<string> {
    return new SignJWT({ sid: claims.sid, cafe: claims.cafe, kind: claims.kind, mfa: claims.mfa })
      .setProtectedHeader({ alg: 'EdDSA', kid: config.jwt.keyId })
      .setSubject(claims.sub).setAudience(claims.aud).setIssuer('cafe-platform').setIssuedAt()
      .setExpirationTime(`${config.jwt.accessTtlSeconds}s`).sign(this.signKey);
  }

  async verifyAccess(token: string): Promise<AccessClaims> {
    try {
      const { payload } = await jwtVerify(token, this.verifyKey, { issuer: 'cafe-platform', algorithms: ['EdDSA'] });
      return { sub: payload.sub!, aud: payload.aud as Audience, sid: payload.sid as string, cafe: payload.cafe as number | undefined, kind: payload.kind as 'user' | 'customer', mfa: payload.mfa as boolean | undefined };
    } catch {
      throw unauthorized('TOKEN_INVALID');
    }
  }

  private async issue(q: Q, subject: { userId?: number; customerId?: number }, aud: Audience, cafe: number | undefined, mfa?: boolean): Promise<TokenPair> {
    const s = store();
    const sid = ulid();
    const expires = new Date(Date.now() + config.jwt.refreshTtlDays * 86400_000);
    const session = await q.insertInto('login_sessions').values({
      public_id: sid, user_id: subject.userId ?? null, customer_id: subject.customerId ?? null, cafe_id: cafe ?? null, audience: aud,
      ip_address: s?.ip ?? null, expires_at: expires, last_seen_at: new Date(),
    }).executeTakeFirstOrThrow();
    const refreshToken = await this.createRefresh(q, Number(session.insertId), ulid(), expires);
    const accessToken = await this.signAccess({
      sub: String(subject.userId ?? subject.customerId), aud, sid, cafe, kind: subject.userId ? 'user' : 'customer', mfa,
    });
    return { accessToken, refreshToken, expiresIn: config.jwt.accessTtlSeconds };
  }

  private async createRefresh(q: Q, sessionId: number, familyId: string, expires: Date): Promise<string> {
    const token = randomToken();
    await q.insertInto('refresh_tokens').values({ session_id: sessionId, family_id: familyId, token_hash: sha256(token), expires_at: expires }).execute();
    return token;
  }

  private async recordAttempt(identifier: string, aud: Audience, ok: boolean, reason?: string) {
    await this.db.q.insertInto('login_attempts').values({
      identifier_hash: sha256(identifier.toLowerCase()), audience: aud, ip_address: store()?.ip ?? null, was_successful: ok ? 1 : 0, failure_reason: reason ?? null,
    }).execute();
  }

  async staffLogin(input: { email: string; password: string; audience: 'platform' | 'cafe' | 'kitchen'; cafePublicId?: string; totp?: string }) {
    return unscoped('login precedes tenant resolution', async () => {
      const email = input.email.trim().toLowerCase();
      const user = await this.db.q.selectFrom('users').selectAll().where('email', '=', email).where('deleted_at', 'is', null).executeTakeFirst();
      if (!user) {
        await verifyPassword(await DUMMY_HASH_PROMISE, input.password);
        await this.recordAttempt(email, input.audience, false, 'no_user');
        throw unauthorized('INVALID_CREDENTIALS');
      }
      if (user.locked_until && user.locked_until > new Date()) {
        await this.recordAttempt(email, input.audience, false, 'locked');
        throw new AppError(423, 'ACCOUNT_LOCKED');
      }
      if (!(await verifyPassword(user.password_hash, input.password))) {
        const failures = user.failed_login_count + 1;
        await this.db.q.updateTable('users').set({
          failed_login_count: failures >= MAX_FAILURES ? 0 : failures,
          locked_until: failures >= MAX_FAILURES ? new Date(Date.now() + LOCK_MINUTES * 60000) : null,
        }).where('id', '=', user.id).execute();
        await this.recordAttempt(email, input.audience, false, 'bad_password');
        throw unauthorized('INVALID_CREDENTIALS');
      }
      if (user.status === 'disabled') throw forbidden('ACCOUNT_DISABLED');

      let cafeId: number | undefined;
      let mfaOk = false;
      if (input.audience === 'platform') {
        if (!user.is_platform_user) throw unauthorized('INVALID_CREDENTIALS');
        if (user.mfa_enabled_at) {
          if (!input.totp) throw new AppError(401, 'MFA_REQUIRED');
          if (!verifyTotp(decrypt(Buffer.from(user.mfa_secret_ciphertext!)), input.totp)) {
            await this.recordAttempt(email, input.audience, false, 'bad_totp');
            throw unauthorized('INVALID_TOTP');
          }
          mfaOk = true;
        }
      } else {
        const memberships = await this.db.q.selectFrom('cafe_staff as s').innerJoin('cafes as c', 'c.id', 's.cafe_id')
          .select(['c.id', 'c.public_id', 'c.display_name', 'c.status'])
          .where('s.user_id', '=', user.id).where('s.status', '=', 'active')
          .where('c.status', 'in', ['active', 'pending_approval']).execute();
        const chosen = input.cafePublicId ? memberships.find((m) => m.public_id === input.cafePublicId) : memberships.length === 1 ? memberships[0] : undefined;
        if (!chosen) {
          if (memberships.length > 1 && !input.cafePublicId) {
            throw new AppError(409, 'CAFE_SELECTION_REQUIRED', memberships.map((m) => ({ publicId: m.public_id, name: m.display_name })));
          }
          throw forbidden('NO_CAFE_ACCESS');
        }
        cafeId = chosen.id;
      }

      const tokens = await this.db.tx(async (tx) => {
        await tx.updateTable('users').set({ failed_login_count: 0, locked_until: null, last_login_at: new Date() }).where('id', '=', user.id).execute();
        return this.issue(tx, { userId: user.id }, input.audience, cafeId, mfaOk);
      });
      await this.recordAttempt(email, input.audience, true);
      return { ...tokens, mfaEnrollmentRequired: input.audience === 'platform' && !user.mfa_enabled_at };
    });
  }

  async customerLogin(email: string, password: string) {
    return unscoped('customers are global', async () => {
      const normalized = email.trim().toLowerCase();
      const c = await this.db.q.selectFrom('customers').selectAll().where('email', '=', normalized).where('deleted_at', 'is', null).executeTakeFirst();
      if (!c || !c.password_hash) {
        await verifyPassword(await DUMMY_HASH_PROMISE, password);
        await this.recordAttempt(normalized, 'customer', false, 'no_user');
        throw unauthorized('INVALID_CREDENTIALS');
      }
      if (c.locked_until && c.locked_until > new Date()) throw new AppError(423, 'ACCOUNT_LOCKED');
      if (!(await verifyPassword(c.password_hash, password))) {
        const failures = c.failed_login_count + 1;
        await this.db.q.updateTable('customers').set({
          failed_login_count: failures >= MAX_FAILURES ? 0 : failures,
          locked_until: failures >= MAX_FAILURES ? new Date(Date.now() + LOCK_MINUTES * 60000) : null,
        }).where('id', '=', c.id).execute();
        await this.recordAttempt(normalized, 'customer', false, 'bad_password');
        throw unauthorized('INVALID_CREDENTIALS');
      }
      await this.db.q.updateTable('customers').set({ failed_login_count: 0, locked_until: null, last_login_at: new Date() }).where('id', '=', c.id).execute();
      await this.recordAttempt(normalized, 'customer', true);
      return this.db.tx((tx) => this.issue(tx, { customerId: c.id }, 'customer', undefined));
    });
  }

  async customerRegister(input: { email: string; password: string; fullName: string; language?: string }) {
    return unscoped('customers are global', async () => {
      const email = input.email.trim().toLowerCase();
      const passwordHash = await hashPassword(input.password);
      try {
        return await this.db.tx(async (tx) => {
          const r = await tx.insertInto('customers').values({
            public_id: ulid(), email, password_hash: passwordHash, full_name: input.fullName, preferred_language_code: input.language ?? null, is_guest: 0,
          }).executeTakeFirstOrThrow();
          return this.issue(tx, { customerId: Number(r.insertId) }, 'customer', undefined);
        });
      } catch (e) {
        if ((e as { code?: string }).code === 'ER_DUP_ENTRY') throw conflict('EMAIL_TAKEN');
        throw e;
      }
    });
  }

  async customerGoogle(idToken: string) {
    if (!config.googleClientId) throw new AppError(503, 'GOOGLE_SIGNIN_NOT_CONFIGURED');
    const jwks = createRemoteJWKSet(new URL('https://www.googleapis.com/oauth2/v3/certs'));
    const { payload } = await jwtVerify(idToken, jwks, { issuer: ['https://accounts.google.com', 'accounts.google.com'], audience: config.googleClientId })
      .catch(() => { throw unauthorized('TOKEN_INVALID'); });
    return unscoped('customers are global', () => this.db.tx(async (tx) => {
      const existing = await tx.selectFrom('customer_identities').select('customer_id').where('provider', '=', 'google').where('provider_subject', '=', payload.sub!).executeTakeFirst();
      let id = existing?.customer_id;
      if (!id) {
        // Only a verified Google address may attach to an existing account with the same email.
        const email = payload.email_verified ? String(payload.email).toLowerCase() : null;
        const byEmail = email ? await tx.selectFrom('customers').select('id').where('email', '=', email).where('deleted_at', 'is', null).executeTakeFirst() : undefined;
        id = byEmail?.id ?? Number((await tx.insertInto('customers').values({
          public_id: ulid(), email, full_name: (payload.name as string) ?? null, is_guest: 0, email_verified_at: email ? new Date() : null,
        }).executeTakeFirstOrThrow()).insertId);
        await tx.insertInto('customer_identities').values({ customer_id: id, provider: 'google', provider_subject: payload.sub! }).execute();
      }
      return this.issue(tx, { customerId: id }, 'customer', undefined);
    }));
  }

  // One-time rotation: reusing a rotated token means theft, so the whole session family is revoked.
  async refresh(token: string) {
    return unscoped('token precedes tenant resolution', async () => {
      const hash = sha256(token);
      const outcome = await this.db.tx(async (tx) => {
        const row = await tx.selectFrom('refresh_tokens as r').innerJoin('login_sessions as s', 's.id', 'r.session_id')
          .select(['r.id', 'r.family_id', 'r.used_at', 'r.revoked_at', 'r.expires_at', 'r.session_id', 's.user_id', 's.customer_id', 's.audience', 's.cafe_id', 's.revoked_at as session_revoked', 's.public_id as sid'])
          .where('r.token_hash', '=', hash).forUpdate().executeTakeFirst();
        if (!row) return { error: 'TOKEN_INVALID' } as const;
        if (row.used_at) {
          await tx.updateTable('login_sessions').set({ revoked_at: new Date(), revoke_reason: 'refresh_reuse' }).where('id', '=', row.session_id).execute();
          await tx.updateTable('refresh_tokens').set({ revoked_at: new Date() }).where('family_id', '=', row.family_id).where('revoked_at', 'is', null).execute();
          await audit(tx, { action: 'auth.refresh_reuse_detected', entityType: 'session', entityId: row.sid, cafeId: null });
          return { error: 'TOKEN_REUSED' } as const;
        }
        if (row.revoked_at || row.session_revoked || row.expires_at < new Date()) return { error: 'TOKEN_INVALID' } as const;

        const newToken = randomToken();
        const created = await tx.insertInto('refresh_tokens').values({ session_id: row.session_id, family_id: row.family_id, token_hash: sha256(newToken), expires_at: row.expires_at }).executeTakeFirstOrThrow();
        await tx.updateTable('refresh_tokens').set({ used_at: new Date(), replaced_by_id: Number(created.insertId) }).where('id', '=', row.id).execute();
        await tx.updateTable('login_sessions').set({ last_seen_at: new Date() }).where('id', '=', row.session_id).execute();

        const cafe = row.cafe_id ?? undefined;
        if (cafe && row.user_id) {
          const access = await tx.selectFrom('cafe_staff as s').innerJoin('cafes as c', 'c.id', 's.cafe_id').select('s.id')
            .where('s.cafe_id', '=', cafe).where('s.user_id', '=', row.user_id).where('s.status', '=', 'active').where('c.status', 'in', ['active', 'pending_approval']).executeTakeFirst();
          if (!access) return { error: 'TOKEN_INVALID' } as const;
        }
        let mfa: boolean | undefined;
        if (row.audience === 'platform' && row.user_id) {
          const u = await tx.selectFrom('users').select('mfa_enabled_at').where('id', '=', row.user_id).executeTakeFirstOrThrow();
          mfa = !!u.mfa_enabled_at;
        }
        const accessToken = await this.signAccess({
          sub: String(row.user_id ?? row.customer_id), aud: row.audience, sid: row.sid, cafe, kind: row.user_id ? 'user' : 'customer', mfa,
        });
        return { tokens: { accessToken, refreshToken: newToken, expiresIn: config.jwt.accessTtlSeconds } } as const;
      });
      if ('error' in outcome) throw unauthorized(outcome.error);
      return outcome.tokens;
    });
  }

  async revokeSession(sid: string, reason = 'logout') {
    await unscoped('own session', () => this.db.q.updateTable('login_sessions').set({ revoked_at: new Date(), revoke_reason: reason }).where('public_id', '=', sid).where('revoked_at', 'is', null).execute());
  }

  async revokeAll(subject: { userId?: number; customerId?: number }, reason = 'logout_all') {
    await unscoped('own sessions', () => {
      let q = this.db.q.updateTable('login_sessions').set({ revoked_at: new Date(), revoke_reason: reason }).where('revoked_at', 'is', null);
      q = subject.userId ? q.where('user_id', '=', subject.userId) : q.where('customer_id', '=', subject.customerId!);
      return q.execute();
    });
  }

  async listSessions(userId: number) {
    return unscoped('own sessions', () => this.db.q.selectFrom('login_sessions').select(['public_id', 'audience', 'ip_address', 'last_seen_at', 'created_at', 'expires_at'])
      .where('user_id', '=', userId).where('revoked_at', 'is', null).where('expires_at', '>', new Date()).orderBy('last_seen_at', 'desc').execute());
  }

  async mfaBegin(userId: number) {
    const secret = newTotpSecret();
    await unscoped('platform account', () => this.db.q.updateTable('users').set({ mfa_secret_ciphertext: encrypt(secret), mfa_enabled_at: null }).where('id', '=', userId).where('mfa_enabled_at', 'is', null).execute());
    return { secret, otpauthUrl: `otpauth://totp/CafePlatform:${userId}?secret=${secret}&issuer=CafePlatform` };
  }

  async mfaConfirm(userId: number, code: string, sid: string) {
    return unscoped('platform account', async () => {
      const u = await this.db.q.selectFrom('users').select(['mfa_secret_ciphertext', 'mfa_enabled_at']).where('id', '=', userId).executeTakeFirstOrThrow();
      if (u.mfa_enabled_at) throw conflict('MFA_ALREADY_ENABLED');
      if (!u.mfa_secret_ciphertext) throw badRequest('MFA_NOT_STARTED');
      if (!verifyTotp(decrypt(Buffer.from(u.mfa_secret_ciphertext)), code)) throw unauthorized('INVALID_TOTP');
      await this.db.tx(async (tx) => {
        await tx.updateTable('users').set({ mfa_enabled_at: new Date() }).where('id', '=', userId).execute();
        await audit(tx, { action: 'auth.mfa_enabled', entityType: 'user', entityId: userId, cafeId: null });
      });
      return { accessToken: await this.signAccess({ sub: String(userId), aud: 'platform', sid, kind: 'user', mfa: true }), expiresIn: config.jwt.accessTtlSeconds };
    });
  }

  // Turns a verified token into a live principal, re-checking everything revocable on every request.
  async loadPrincipal(claims: AccessClaims): Promise<{ principal: Principal; cafeId?: number }> {
    return unscoped('principal resolution', async () => {
      const session = await this.db.q.selectFrom('login_sessions').select(['id', 'revoked_at', 'expires_at']).where('public_id', '=', claims.sid).executeTakeFirst();
      if (!session || session.revoked_at || session.expires_at < new Date()) throw unauthorized('SESSION_REVOKED');
      const id = Number(claims.sub);

      if (claims.kind === 'customer') {
        const c = await this.db.q.selectFrom('customers').select('status').where('id', '=', id).where('deleted_at', 'is', null).executeTakeFirst();
        if (!c || c.status !== 'active') throw unauthorized('ACCOUNT_DISABLED');
        return { principal: { type: 'customer', id, audience: 'customer', sessionId: session.id, permissions: new Set(), branchIds: null } };
      }

      const u = await this.db.q.selectFrom('users').select(['status', 'is_platform_user']).where('id', '=', id).where('deleted_at', 'is', null).executeTakeFirst();
      if (!u || u.status === 'disabled') throw unauthorized('ACCOUNT_DISABLED');

      if (claims.aud === 'platform') {
        if (!u.is_platform_user) throw forbidden();
        const perms = await this.db.q.selectFrom('user_roles as ur').innerJoin('role_permissions as rp', 'rp.role_id', 'ur.role_id')
          .select('rp.permission_code').where('ur.user_id', '=', id).where('ur.cafe_id', 'is', null).execute();
        return { principal: { type: 'user', id, audience: 'platform', sessionId: session.id, permissions: new Set(perms.map((p) => p.permission_code)), branchIds: null } };
      }

      if (!claims.cafe) throw forbidden();
      const cafeId = claims.cafe;
      const access = await this.db.q.selectFrom('cafe_staff as s').innerJoin('cafes as c', 'c.id', 's.cafe_id').select(['s.status as staff', 'c.status as cafe'])
        .where('s.cafe_id', '=', cafeId).where('s.user_id', '=', id).executeTakeFirst();
      if (!access || access.staff !== 'active' || !['active', 'pending_approval'].includes(access.cafe)) throw forbidden('NO_CAFE_ACCESS');

      const grants = await this.db.q.selectFrom('user_roles as ur').innerJoin('role_permissions as rp', 'rp.role_id', 'ur.role_id')
        .innerJoin('roles as r', 'r.id', 'ur.role_id')
        .select(['rp.permission_code', 'ur.branch_id']).where('ur.user_id', '=', id).where('ur.cafe_id', '=', cafeId).where('r.deleted_at', 'is', null).execute();
      const allBranches = grants.some((g) => g.branch_id === null);
      const branchIds = allBranches ? null : [...new Set(grants.map((g) => g.branch_id!))];
      if (claims.aud === 'kitchen' && !grants.some((g) => g.permission_code === 'kitchen.read')) throw forbidden();
      return { cafeId, principal: { type: 'user', id, audience: claims.aud, sessionId: session.id, permissions: new Set(grants.map((g) => g.permission_code)), branchIds } };
    });
  }

}
