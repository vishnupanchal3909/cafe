# Cafe Platform

Multi-tenant cafe management SaaS: one platform for many cafes, countries, languages and currencies.
Working name; see decision D-4 in `docs/PROJECT_REQUIREMENTS.md`.

**Status: runs end to end locally, and is not ready to launch.** A guest can scan a QR code, order in nine languages, the kitchen sees it live, staff take cash, and an invoice and ledger entries result. Online gateways have never run against a real provider, and many API features have no screen yet. See [the tracker](docs/DEVELOPMENT_ROADMAP.md) and [known issues](docs/KNOWN_ISSUES.md).

## Quick start

```bash
brew install mysql@8.4 redis
./scripts/dev-mysql.sh start && ./scripts/dev-redis.sh start

cd backend
cp .env.example .env       # then set the three DB_*_PASSWORD values
npm ci && npm run keys:generate
npm run db:migrate && npm run db:seed && npm run db:grants
npm run db:test && npm test
npm run dev                # http://localhost:3000/api/docs

cd ../frontend && flutter pub get
cd apps/cafe_customer_app && flutter run -d chrome --dart-define=API_URL=http://localhost:3000
```

Create the first Super Admin with `ADMIN_EMAIL=... ADMIN_PASSWORD=... npm run admin:create`. Full steps are in the [deployment guide](docs/DEPLOYMENT_GUIDE.md).

MySQL Workbench: `127.0.0.1`, port `3307`, user `root`, no password (loopback only, local dev only).

## Layout

```
backend/database/   migrations, seeds, runner, grants, tests
backend/src/        NestJS API
backend/test/       API, security and end-to-end tests
frontend/apps/      customer, kitchen, owner and admin Flutter apps
frontend/packages/  shared core, models, network, localization, design system
docs/               all project documentation
scripts/            development helpers
```

## Documentation

| | |
|---|---|
| Start here | [Requirements and open decisions](docs/PROJECT_REQUIREMENTS.md), [Architecture](docs/SYSTEM_ARCHITECTURE.md), [Roadmap](docs/DEVELOPMENT_ROADMAP.md) |
| Data | [Design](docs/DATABASE_DESIGN.md), [Relationships](docs/DATABASE_RELATIONSHIPS.md), [Dictionary](docs/DATA_DICTIONARY.md), [Multi-tenancy](docs/MULTI_TENANCY.md) |
| Domain | [Currency and finance](docs/CURRENCY_AND_FINANCE.md), [Payments](docs/PAYMENT_INTEGRATION.md), [Localization](docs/LOCALIZATION_GUIDE.md) |
| Engineering | [API](docs/API_DOCUMENTATION.md), [Security](docs/AUTHENTICATION_AND_SECURITY.md), [Flutter](docs/FLUTTER_ARCHITECTURE.md), [Testing](docs/TESTING_STRATEGY.md), [Deployment](docs/DEPLOYMENT_GUIDE.md) |
| Tracking | [Known issues](docs/KNOWN_ISSUES.md), [Changelog](docs/CHANGELOG.md) |
