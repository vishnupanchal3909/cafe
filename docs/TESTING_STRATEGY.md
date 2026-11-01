# Testing Strategy

## Pyramid

| Level | Tooling | Runs against |
|---|---|---|
| Database | `node:test` + mysql2, in `backend/database/tests` | Real MySQL 8.4, never mocks |
| Backend unit | `node:test` (no Jest: Rule 14, fewer dependencies) | Pure services: pricing, tax, money, signatures, tenant guard |
| Backend API | `node:test` + real HTTP | Real MySQL and Redis, as the least-privilege DB user. Only the payment gateway is a double, labelled as such |
| Route sweep | Enumerates every registered route | No credential, or a customer token, gets nothing except the explicit public list |
| Tenant isolation | Second-cafe attacks | Main read, write, payment and guest paths are attacked with another cafe's credentials |
| Flutter | `flutter test`, `bloc_test`, golden | Widgets, BLoCs, repositories, locales, currencies, RTL, breakpoints |
| E2E | Over real HTTP, two cafes in two currencies | The 17-step brief §16 scenario (`backend/test/e2e.test.ts`) |
| Contract | `live_contract_test.dart` against a running API | Real responses parsed into the Dart models |
| Browser | Real Chrome driven by hand via DevTools | Guest, kitchen, owner, admin, Arabic, Hindi, Japanese. **Not yet automated in the repo** |

## Currently implemented (database)

Run with `npm run db:test`, then `npm test`, in `backend/`.

- **Schema lint**: table classification complete; tenant tables have `cafe_id NOT NULL` and `UNIQUE (cafe_id, id)`; tenant-to-tenant FKs include `cafe_id`; no `FLOAT`/`DOUBLE`; money columns' scale; no prohibited payment columns; InnoDB and utf8mb4 everywhere; no cascading FKs.
- **Tenant isolation**: cross-cafe references rejected by the storage layer.
- **Financial**: journal balance, immutability, period closure, payment confirmation rules, refund limits, currency match, gapless invoicing under concurrency.
- **Privilege**: `cafe_app` cannot DDL, cannot delete ledgers, `cafe_reporting` cannot read credentials.
- **Migrations**: idempotent, checksum drift detected.
- **Unicode**: Devanagari, Arabic, Japanese, emoji round-trip.

The suite was mutation-checked: deliberately broken safeguards made it fail (see `CHANGELOG.md`). Repeat this for new critical safeguards, as a test that cannot fail proves nothing.

## Rules

Payments are never faked as successful outside a clearly labelled test double. A failing test is a stop. Coverage is reported, but critical-path scenarios matter more than a percentage.
