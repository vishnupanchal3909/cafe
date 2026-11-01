# Authentication and Security

Implementation status: **implemented and tested through real HTTP, except where the checklist below is unticked.**

## Authentication

| Item | Design |
|---|---|
| Staff/admin login | Email + password, Argon2id. TOTP MFA is mandatory for Super Admin: a token without MFA reaches nothing except enrolment |
| Customer login | Guest session, email/password, Google where enabled |
| Access token | JWT, 15 min. Asymmetric signing (EdDSA) with a `kid` for rotation. Audiences: `platform`, `cafe`, `kitchen`, `customer` |
| Refresh token | 256-bit random, stored **hashed**, rotated on every use. Reuse of a rotated token revokes the entire family |
| Web token storage | Refresh token in an `HttpOnly; Secure; SameSite=Strict` cookie on web (with CSRF token), secure storage on mobile. Flutter Web `flutter_secure_storage` is not a safe store against XSS |
| Lockout | Exponential backoff per account and IP; every attempt in `login_attempts` |
| Revocation | `login_sessions.revoked_at`; a session-version check runs on sensitive actions, and suspension of a cafe revokes its staff sessions |

## Authorization

Every request passes through one `AuthGuard`: verify token, live session, tenant, permissions, branch. A route with no `@Public` or `@Audiences` is unreachable, and a sweep test proves it for every registered route. `cafe_id` comes from the verified token and is confirmed against an active `cafe_staff` row. Route parameters or bodies containing a `cafe_id` are ignored. Super Admin endpoints live under a separate `/platform` route tree.

## Role and permission matrix

Roles are seeded; owners can create custom roles from the permission list. The authoritative mapping is in `backend/database/seeds/`. `R` read, `W` write/manage, `-` none, `own` own records, `*` audited and masked.

| Area | Super Admin | Platform Support | Owner | Manager | Cashier | Waiter | Kitchen |
|---|---|---|---|---|---|---|---|
| Platform settings, plans, currencies | W | R | - | - | - | - | - |
| Approve / suspend cafes | W | - | - | - | - | - | - |
| Cafe profile, branding | R* | R* | W | R | - | - | - |
| Branches | R* | R* | W | R | - | - | - |
| Menu | R* | R* | W | W | R | R | R |
| Tables, QR | R* | R* | W | W | R | R | - |
| Orders | R* | R* | W | W | W | W | R |
| Kitchen tickets, stations | R* | - | W | W | - | - | W (no station config) |
| Payments (cash confirm) | - | - | W | W | W | - | - |
| Refunds | - | - | W | Approve within limit | Request | - | - |
| Staff, roles | R* | R* | W | R | - | - | - |
| Inventory, purchasing | R* | - | W | W | - | - | R |
| Finance, accounting | R* | - | W | R | - | - | - |
| Customer personal data | R* | R* | R (own cafe) | R (own cafe) | - | - | - |
| Attendance | R* | - | W | W | own | own | own |
| Audit logs | R | R | R (own cafe) | - | - | - | - |

## Tenant isolation layers

See `MULTI_TENANCY.md`.

## Application security checklist (Phase 2 acceptance)

- [x] DTO validation with a whitelist, rejecting unknown fields (a client-sent price is a 400)
- [x] Parameterized queries only (Kysely, and `sql` template tags which bind values)
- [x] Rate limiting on Redis per IP, stricter on auth and QR, with in-memory fallback. Per principal is not implemented
- [x] Helmet headers, strict CORS allow-list per environment
- [x] CSRF defence on the cookie refresh route: a required custom header plus `SameSite=Strict`
- [x] Uploads: size limit, magic-byte validation, SVG refused
- [ ] Image re-encoding is not implemented. S3 path exists but is untested
- [x] Secrets from environment only, never in the repo
- [ ] CI secret scanning is not configured
- [x] Payment webhooks: raw body HMAC verification, Stripe timestamp window, unique `(provider, event_id)`
- [x] Field encryption (AES-256-GCM) for gateway credentials, QR tokens and MFA secrets
- [ ] KMS envelope encryption and key rotation tooling are not implemented. Salaries are protected by grants, not encrypted
- [ ] Structured log redaction: errors log messages only, and there is no central redaction layer yet
- [ ] Independent penetration test

## QR security

Tokens are 256-bit random. The DB stores `token_hash` (SHA-256, for lookup) and `token_ciphertext` (for re-download). Regeneration revokes the old token. A QR only opens a **table session**; a printed code photographed yesterday cannot place an order unless the session policy permits it. Abuse controls: staff acceptance before kitchen, optional session PIN, per-session rate limit.

## Database-level controls (implemented, tested in Phase 1)

| Control | Mechanism |
|---|---|
| Least privilege | `cafe_app` has no DDL and no `DELETE`/`UPDATE` on immutable tables; `cafe_migrator` owns DDL; `cafe_reporting` is read-only and lacks credential tables |
| Immutable ledgers | Triggers reject changes on `audit_logs`, `payment_transactions`, `stock_movements`, `cash_register_transactions`, `loyalty_ledger`, posted journal entries, issued invoices |
| Balanced journal | A trigger rejects posting of unbalanced entries, entries with fewer than 2 lines, and entries in closed periods |
| No frontend-confirmed payments | CHECK on `payments` plus a state-transition trigger |
| Cross-tenant references impossible | Composite foreign keys, verified by a schema lint test |
| Secrets not stored in the clear | Only hashes or ciphertext columns; no column for card number or CVV (lint test) |

## Backups

Binlog PITR plus daily encrypted snapshots, 35-day retention; quarterly restore drill (see `DEPLOYMENT_GUIDE.md`).
