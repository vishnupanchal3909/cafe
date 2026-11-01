# Multi-Tenancy

## Model

Shared MySQL database. The tenant is a **cafe**. Every cafe-owned row has `cafe_id NOT NULL`. Tables are classified in one manifest, `backend/database/table-classification.ts`:

- `tenant`: owned by a cafe (`cafe_id NOT NULL`)
- `global`: reference or platform data with no owner (`languages`, `currencies`, ...)
- `mixed`: has a nullable `cafe_id` (`roles`, `media_assets`, `user_roles`, `audit_logs`, ...); NULL means platform-level

A new table not listed in the manifest fails the test suite.

## Defence in depth

| Layer | Mechanism | Failure it stops | Status |
|---|---|---|---|
| 1. Identity | Tenant comes from verified JWT + active `cafe_staff`; QR path from a hashed token | Spoofed `cafe_id` | **Done** |
| 2. Query | A guard around the database driver rejects any statement on a tenant table that does not bind the current tenant's id. The escape hatch is `unscoped(reason, ...)` | Forgotten `WHERE cafe_id` | **Done** |
| 3. Branch | Branch checked by the guard, and on loaded records | Manager of branch A reading branch B | **Done** |
| 4. Storage | **Composite FKs**: `FOREIGN KEY (cafe_id, product_id) REFERENCES products (cafe_id, id)` | Cross-tenant references through app bugs or crafted IDs | **Done** |
| 5. DB privilege | App user has least privilege | SQL injection dropping or rewriting history | **Done** |
| 6. Realtime | Rooms computed on the server; replay filtered by the same rooms | Event leakage | **Done** |
| 7. Verification | Schema lint, attack tests with a second cafe, and a route sweep | Regressions | **Done** |

## Why MySQL does not give us row-level security

MySQL has no RLS policies. The closest emulation, views filtered by a session variable, is fragile with connection pooling because a stale variable leaks another tenant. Layers 2 and 4 are chosen instead; no safety claim is made from a mechanism MySQL lacks. Layer 2 remains the primary protection against *reads* across tenants, because composite FKs only protect *writes*.

Limit of the guard: it checks that a tenant id is bound, not how. It would not catch a hand-written query that binds the id in an irrelevant position. Review and the second-cafe attack tests cover that gap, and the attack tests cover the main routes rather than literally every route with a real id (see K-1).

## Rules for developers

1. A tenant table gets `cafe_id`, `UNIQUE (cafe_id, id)`, and composite FKs to other tenant tables.
2. Never accept `cafe_id` from a request. Never look up a tenant row by `id` alone.
3. A cross-tenant platform query goes through `unscoped(reason, ...)`, and platform reads write `audit_logs`.
4. Global `customers` are only reachable through `cafe_customers` from a cafe context.

## Suspension and closure

Suspending a cafe revokes staff sessions and blocks new orders and QR resolution, while preserving all data. Closure never deletes financial data.
