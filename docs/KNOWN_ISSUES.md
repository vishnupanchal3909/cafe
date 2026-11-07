# Known Issues and Limits

## Never verified

| Item | Detail |
|---|---|
| Razorpay | The adapter, checkout, webhooks, refunds, links and settlements run against a local simulator built from Razorpay's public docs, not the real service. Real keys are pending. Stripe and Cashfree adapters are hidden from the UI and untested beyond signatures |
| Docker | `docker-compose.yml` and both Dockerfiles have never been built: Docker is not installed here |
| CI | `.github/workflows/ci.yml` has never run: there is no remote repository. Everything ran on Node 26, while CI pins Node 24 |
| S3 | The adapter exists but has never run. Local disk storage was used, and production refuses to start without a bucket |
| Google sign-in | Implemented on the server, never exercised. No client button |
| Mobile | Customer app runs on a real Android phone (debug build, over Wi-Fi) and the iOS simulator; never on a real iPhone, and no release build is signed. Kitchen, owner and admin are web only here |
| Load and performance | No load test. `main.dart.js` is 3.6 MB plus the rendering engine, and QR first-paint on a real phone over 4G has not been measured (risk R-1) |
| Translations | All machine-written by an AI, unreviewed |
| Security | Internal tests only. No independent penetration test |
| Browser test | Run by hand through Chrome DevTools, which checks screens load, not every button. Not automated in the repo |

## Found while checking the design

| Item | Detail |
|---|---|
| Sample photos | Tea Hub's dev photos are from Wikimedia Commons, and most licences require credit (`.devdata/demo-photos/CREDITS.md`, not in git). Replace them with the cafe's own before going live |
| Upload | The photo picker itself was not clicked in a browser test. The upload path below it is covered by API and live tests |
| Replaced photos | Replacing or removing a photo keeps the old file in storage. There is no clean-up yet |
| Depth design | Checked in headless Chrome on desktop and phone sizes, light and dark. Not checked on a real phone or a low-end device, where layered shadows cost more to draw. The lean-on-hover only happens with a mouse |
| Role screens | Screens and buttons are hidden by permission on orders, menu, tables and payments. Screens a cashier or waiter never sees (inventory, finance, marketing, settings, staff) still show every button to managers, who hold most permissions; the server refuses anything not allowed |
| iPhone app | Opens a table only from a `cafeplatform://` link: there is no in-app QR scanner, and universal links need the domain (D-4). Run on the iOS simulator, never a real device |
| Customer theme | The customer app follows the cafe's own light or dark setting, not the phone's |

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
| Password reset | Confirming a reset link works and is tested. Asking for a link answers `PASSWORD_RESET_UNAVAILABLE`, and the app hides "Forgot password?", until an email provider is chosen, integrated and tested (pending configuration). Staff accounts have no reset yet |
| Fake customer accounts | Sign-up is capped at 20 accounts an hour per address, not lower because guests on cafe Wi-Fi share one. Nobody checks an email is real, so one-per-customer coupons can be reused with new accounts. Needs email verification, which needs the email provider |

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
| K-14 | A printed QR code can open a session and order remotely | Optional per-cafe table PIN (setting `tablePinRequired`), off by default; the paying party's session now ends `sessionEndAfterPaymentMinutes` after payment (default 30) |
| K-15 | The moderate `npm audit` findings remain in `exceljs` and `@nestjs/swagger`, since fixing them needs major upgrades. `multer` is pinned to its patched version by an override | Upgrade when moving to Nest 12 |

## Business and legal

See the compliance warning and D-1 to D-5 in `PROJECT_REQUIREMENTS.md`. **No fiscal or POS certification exists for any country, and the chart of accounts, postings and tax logic have not been reviewed by an accountant.**
