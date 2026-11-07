# Development Roadmap

A phase is done only when it meets the Definition of Done in brief §20. **By that strict definition, no business module is complete yet**, mainly because owner UI coverage is partial and gateways have never run live.

| Phase | Scope | Status |
|---|---|---|
| 0. Requirements and architecture | Docs, ERD, decisions | Done. D-1 decided. D-2 to D-5 and platform charges outstanding |
| 1. Database foundation | Schema, migrations, seeds, safeguards | Done |
| 2. Backend foundation | NestJS, auth, RBAC, tenant context, Swagger, health | Done |
| 3. Flutter foundation | Workspace, design system, l10n, money, API client, realtime | Done |
| 4. Business modules | See tracker | Backend mostly done, UI partial |
| 5. Testing and deployment | E2E done locally. Staging and production not started | Partial |

## Feature completion tracker

`Y` done and tested. `P` partial, see the gap. Every screen and tab of the owner and admin apps was opened in real Chrome, and every owner, admin and customer write runs against a live API in `live_writes_test.dart` and `live_contract_test.dart`.

| Module | DB | API | Auth | UI | L10n | Currency | Tests | E2E | What is missing |
|---|---|---|---|---|---|---|---|---|---|
| 1. Super Admin | Y | Y | Y | Y | Y | Y | Y | Y | Cafe orders and finance have an API, and the UI shows a summary only |
| 2. Cafe onboarding | Y | Y | Y | Y | Y | Y | Y | Y | Tax registration is API only |
| 3. Cafe branding | Y | Y | Y | P | Y | - | Y | Y | Fonts are not bundled, and `font_key` is not applied. Only the primary colour has an editor |
| 4. Menu | Y | Y | Y | P | Y | Y | Y | Y | Photo grid with one main photo per product; the API can hold more, with no gallery screen. Combos, schedules and branch prices are API only. Each add-on form creates a new group |
| 5. Tables and QR | Y | Y | Y | P | Y | - | Y | Y | Table merge is API only. Print is via download. No session PIN |
| 6. Customer ordering | Y | Y | Y | P | Y | Y | Y | Y | Google sign-in is not configured. Reservations use an hours-ahead field rather than a date picker |
| 7. Kitchen | Y | Y | Y | Y | Y | - | Y | Y | |
| 8. Payments | Y | Y | Y | Y | Y | Y | Y | Y | Razorpay complete against a simulator. **Awaiting real keys: never run against real Razorpay.** Runbook in `PAYMENT_INTEGRATION.md`. Disputes not handled |
| 9. Inventory | Y | Y | Y | P | Y | Y | Y | Y | Purchase orders take one line in the UI. Recipes apply to the base product in the UI, not per variant |
| 10. Finance | Y | Y | Y | P | Y | Y | Y | Y | Manual journal entry is API only. Needs accountant review |
| 11. Analytics | Y | Y | Y | P | Y | Y | Y | Y | Fewer metrics are shown than the API returns. No downloadable analytics report |
| 12. Subscriptions | Y | Y | Y | P | Y | Y | Y | Y | No billing provider, and invoices are marked paid by hand. Platform charges undecided |

Supporting: Staff has list, invite, deactivate and attendance; custom roles are API only. Notifications are in-app only, with an inbox on the owner app. Push, email, SMS and WhatsApp are not implemented.

## The exact next steps

1. Answer D-2 to D-5 in `PROJECT_REQUIREMENTS.md`, and decide how the platform charges cafes.
2. When Razorpay test keys arrive, follow the runbook in `PAYMENT_INTEGRATION.md`, and fix what it finds.
3. Fill the owner UI gaps above, in the order you need them to run a pilot cafe.
4. Install Docker, run compose and CI, then stand up staging.
5. Accountant and tax review, native-speaker translation review, penetration test, load test, and a Flutter Web load-time measurement on a real phone (R-1).
6. Pilot with one real cafe before any wider launch.
