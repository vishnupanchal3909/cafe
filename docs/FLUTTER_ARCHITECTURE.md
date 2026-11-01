# Flutter Architecture

Implementation status: **all four apps and shared packages are built, tested and run in a real browser.**

**Known departures from the plan:** the customer and kitchen apps follow data/domain/presentation per feature. The owner and admin apps are mostly plain record screens, so they share one repository per app and a schema-driven `CrudPage` rather than a domain layer per feature. Only the customer app has android and ios folders; it builds for the iOS simulator and as a debug APK, but has not run on a device.

## Workspace

Dart pub workspace; apps depend on shared packages.

```
frontend/
  pubspec.yaml                 workspace root
  apps/
    cafe_admin_app/            Super Admin (web, desktop)
    cafe_owner_app/            Owner and floor staff (web, tablet, mobile)
    cafe_kitchen_app/          KDS (tablet, web)
    cafe_customer_app/         Customer (Flutter Web first, mobile)
  packages/
    shared_core/               Result/Failure types, Decimal money, logger, DI helpers
    shared_design_system/      Tokens, DynamicTheme from backend config, components, skeletons, empty and error states
    shared_models/             Freezed + JSON models for API contracts
    shared_network/            Dio client, auth + refresh interceptor, Socket.IO client with replay
    shared_localization/       ARB, generated localizations, money and date formatters
```

The brief's `frontend/cafe_*` layout is preserved by name, grouped under `apps/` and `packages/` for tooling clarity.

## Feature structure

```
lib/features/<feature>/
  domain/        entities, repository interfaces, use cases (pure Dart)
  data/          DTOs, remote data source, repository implementation
  presentation/  Cubit/BLoC, pages, widgets
```

Rules: domain imports no Flutter or Dio. Widgets do not call repositories. Business logic that two apps need goes in a shared package. All user text uses `context.l10n`, all money uses `MoneyFormatter`, all spacing uses tokens. A CI grep flags string literals in `Text(...)` and currency symbols in app code.

## State

Every async screen state is modeled: `initial | loading | success | empty | failure(retryable)`. A shared `AsyncView` widget renders loading skeleton, empty and error states consistently.

## Stack

As mandated: Material 3, BLoC/Cubit, Dio, GoRouter, GetIt, Freezed, JSON Serializable, flutter_secure_storage (mobile), shared_preferences, socket_io_client, intl, decimal.

## Dynamic theming

`GET /public/cafes/{slug}/config` returns `CafeThemeDto`, converted to `ThemeData` via `ColorScheme.fromSeed` plus explicit overrides. Owner-selected colors are checked for WCAG AA in the theme editor, and contrast is corrected at runtime rather than rendering illegible text. Fonts are restricted to a vetted list that covers all supported scripts, including Devanagari, Arabic and Japanese.

## Customer web QR path

Route `/t/{qrToken}`. Priorities: first paint speed (deferred loading per feature, HTML splash, cached config), then conversion. No login gate. See risk R-1 in `SYSTEM_ARCHITECTURE.md`.

## Distinct experiences

| App | Layout | Design priority |
|---|---|---|
| Admin | Dense sidebar, analytics grid, tables | Platform analytics |
| Owner | Adaptive rail, role-based home | Today's operations and money |
| Kitchen | Full-screen ticket columns, huge type, dark default, large touch targets, sound | Readable from 2 m, one tap per action |
| Customer | Cafe-branded, single-column, sticky cart | Add to cart in under 3 taps |

## Testing

See `TESTING_STRATEGY.md`.
