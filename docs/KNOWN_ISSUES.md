# Known Issues and Limits

## Never verified

| Item | Detail |
|---|---|
| Razorpay | The adapter, checkout, webhooks, refunds, links and settlements run against a local simulator built from Razorpay's public docs, not the real service. Real keys are pending. Stripe and Cashfree adapters are hidden from the UI and untested beyond signatures |
| Docker | `docker-compose.yml` and both Dockerfiles have never been built: Docker is not installed here |
| CI | `.github/workflows/ci.yml` has never run: there is no remote repository. Everything ran on Node 26, while CI pins Node 24 |
| S3 | The adapter exists but has never run. Local disk storage was used, and production refuses to start without a bucket |
| Google sign-in | Implemented on the server, never exercised. No client button |
| Mobile | Customer app builds for the iOS simulator and as a debug APK, but has not run on a device. Kitchen, owner and admin are web only here. Android licences are not accepted on this machine |
| Load and performance | No load test. `main.dart.js` is 3.6 MB plus the rendering engine, and QR first-paint on a real phone over 4G has not been measured (risk R-1) |
| Translations | All machine-written by an AI, unreviewed |
| Security | Internal tests only. No independent penetration test |
| Browser test | Run by hand through Chrome DevTools, which checks screens load, not every button. Not automated in the repo |

## Not implemented

| Item | Detail |
|---|---|
| Push, email, SMS, WhatsApp | Not implemented, including FCM. Only in-app rows are written. Staff invitations return a token for the owner to pass on, since email does not exist |
| Offline mode | Network errors are handled, but there is no offline queue |
| Screens | Most are built, and a few features remain API only. See the tracker in `DEVELOPMENT_ROADMAP.md` |
| Inter-state GST | Applied for delivery when the order carries a destination `stateCode`. The customer app has no delivery flow to supply it, so this is staff API only. Needs a tax adviser's review |
| Delivery | Basic only. Delivery zones have a table and no API. Delivery fee is not set from a zone |
| Cash rounding | `cashRoundingIncrement` is stored and not applied |
| Service charge tax | Service charge is added untaxed, which is wrong in some jurisdictions. Leave it at 0 until reviewed |
| Consolidated reporting UI | API only |
| Audit coverage | State changes on money, staff and governance are audited. Some minor edits (for example coupon toggles, table-level service requests) are not. The brief's "every action" for Super Admin holds for writes and main reads |
| Password reset | The token table exists. There is no endpoint, as it needs email |

## Limits to carry forward

| # | Limit | Mitigation |
|---|---|---|
| K-1 | Composite FKs block cross-tenant writes, not reads. A sweep now calls every `/cafe` and `/kitchen` id route with real ids from another cafe, except tax, reports, periods and journal routes. Routes with a request body often stop at validation (400) before the lookup, so GET and DELETE give the strongest proof | Send valid bodies per route |
| K-2 | The database cannot judge whether claimed gateway evidence is true | Webhook signature check and amount match are implemented; a live sandbox run is still needed |
| K-3 | Currency precision is enforced in services, not the DB | Covered for prices, cash, refunds, online payments, expenses, payroll and supplier invoices |
| K-4 | Editing an order quantity rescales tax rather than re-pricing, so a line could differ by one minor unit from fresh pricing | Re-price through `priceOrder` on edit |
| K-5 | `payments.refunded_amount` is maintained by the app, not derived | Same transaction, and a CHECK ties status to amount |
| K-6 | `cafe_reporting` can read personal data inside `orders.delivery_address_snapshot`, `invoices.buyer_snapshot`, and possibly audit state | Restrict access, or add column grants |
| K-7 | Triggers cannot stop a privileged admin | Production credentials and access control; a hash chain on `audit_logs` if an audit requires it |
| K-9 | Order status transitions are enforced in the service, not the DB | Payments have both layers; orders have one |
| K-10 | PDF invoices and exports use a Latin font. **Devanagari, Arabic and Japanese will not render correctly in PDFs.** On-screen receipts are fine | Bundle Noto fonts and a shaping engine, or render PDFs from HTML |
| K-11 | Fonts are not bundled, so non-Latin text relies on Flutter fetching Noto at runtime. `font_key` is stored and not applied | Bundle a vetted set |
| K-12 | Web cookie refresh needs the app and API on the same site in production | Host under one registrable domain |
| K-13 | Rate limiting is per IP, so a busy cafe's shared Wi-Fi shares one budget on QR routes | Add per-session limits |
| K-14 | A printed QR code can open a session and order remotely. Staff acceptance is the mitigation, and the optional session PIN from the design is not built | Build the PIN before a public launch |
| K-15 | The moderate `npm audit` findings remain in `exceljs` and `@nestjs/swagger`, since fixing them needs major upgrades. `multer` is pinned to its patched version by an override | Upgrade when moving to Nest 12 |

## Business and legal

See the compliance warning and D-1 to D-5 in `PROJECT_REQUIREMENTS.md`. **No fiscal or POS certification exists for any country, and the chart of accounts, postings and tax logic have not been reviewed by an accountant.**
