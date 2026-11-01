# Deployment Guide

Status: **local setup works and is what all tests ran on. Docker, CI and production are written but have never been executed.**

## Local development (no Docker required)

```bash
brew install mysql@8.4          # keg-only, does not alter PATH or register a service
./scripts/dev-mysql.sh start    # data in .devdata/mysql, port 3307
cd backend && cp .env.example .env && npm ci
npm run keys:generate
npm run db:migrate && npm run db:seed && npm run db:grants
npm run db:test && npm test      # needs ./scripts/dev-redis.sh start for the Redis paths
npm run dev                      # API on :3000, Swagger on /api/docs

ADMIN_EMAIL=you@example.com ADMIN_PASSWORD='12+ characters' npm run admin:create
```

Flutter (`frontend/`): `flutter pub get`, then in `apps/cafe_customer_app` (or kitchen, owner, admin) `flutter run -d chrome --dart-define=API_URL=http://localhost:3000`. To serve a release build: `node scripts/serve-web.mjs apps/cafe_customer_app/build/web 8083`. Add each origin to `CORS_ORIGINS`, and set `PUBLIC_CUSTOMER_APP_URL` to the customer app's URL, because QR codes embed it.

MySQL Workbench connection: host `127.0.0.1`, port `3307`, user `root`, empty password. This is **local only**: the script binds to loopback.

## With Docker

`docker compose up -d` runs MySQL 8.4, Redis and the API. Docker is not installed on the development machine, so **`docker-compose.yml`, `backend/Dockerfile` and `frontend/Dockerfile.web` have never been built or run**.

## Required MySQL settings (all environments)

| Setting | Value | Why |
|---|---|---|
| `default-time-zone` | `+00:00` | All timestamps are UTC |
| `character-set-server` | `utf8mb4` | Unicode |
| `collation-server` | `utf8mb4_0900_ai_ci` | Language-aware comparisons |
| `sql_mode` | Includes `STRICT_TRANS_TABLES` | Reject silent truncation |
| `log_bin_trust_function_creators` | `1` | Non-SUPER migrator can create triggers |
| `transaction_isolation` | `READ-COMMITTED` recommended | Fewer gap-lock deadlocks; explicit locks for sequences |

## Database users

`npm run db:grants` creates or refreshes roles. Run it after every migration, because table-level grants need new tables.

| User | Used by | Privileges |
|---|---|---|
| `cafe_migrator` | CI migration step only | DDL on the schema |
| `cafe_app` | API and workers | DML without `UPDATE`/`DELETE` on append-only tables |
| `cafe_reporting` | Replica reports, Workbench analysis | `SELECT` except credential, identity and salary tables (see K-6 in `KNOWN_ISSUES.md`) |

Passwords come from environment variables and a secret manager in production.

## Production plan (Phase 5)

Managed MySQL with Multi-AZ and PITR; TLS required; container service for API and worker; managed Redis; private S3 bucket and CDN; GitHub Actions `test -> build -> migrate -> deploy`; structured logs and metrics, alerting on webhook failures and outbox lag; quarterly restore drill.

MySQL DDL is not transactional, so migrations must be backward compatible with the running version (expand then contract), and a failed migration is fixed forward.
