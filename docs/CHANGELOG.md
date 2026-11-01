# Changelog

## Unreleased

### Payments (Razorpay)
- Checkout in the customer app, three-route confirmation, automatic capture, part payment, payment links, two-step refunds, settlement matching, abandoned-checkout expiry, overpayment flagging, a real-API check script, and owner payment screens
- Tested against a simulator built from Razorpay's public docs, including a real browser run. Never run against real Razorpay

### Remaining screens
- Owner: variants, extras, image, logo, cover and banner upload, recipes, stations and routing, bill split, table transfer, purchase orders, supplier invoices, expiring stock, trial balance, balance sheet, journal and reversal, periods, cash registers, payroll, attendance, promotions, loyalty, review replies, branches and hours, languages, gateway setup, subscription, notification inbox, cafe picker
- Kitchen: station filter, completed orders. Customer: addresses, wishlist, reservations. Admin: users, languages, currencies, countries, translations, commissions, announcements, cafe detail with access reason
- Backend: IGST for inter-state delivery; currency precision on expenses, payroll and supplier invoices; another cafe's id now gets 404 from every delete and hours route; a sweep of every id route with another cafe's real ids

### Platform fee
- A flat INR 7 fee was added in migration 0014 and removed in 0015 at the owner's request. Cafes receive money directly (D-1)

### Phase 2: backend
- NestJS modular monolith: 202 API paths across 19 modules, Swagger, OpenAPI export
- Auth: Argon2id, EdDSA JWT, refresh rotation with theft detection, TOTP MFA for platform users, lockout, HttpOnly cookie for web
- Tenancy: default-deny guard, branch scoping, and a driver-level guard that rejects any unscoped query on a tenant table
- Ordering, pricing, kitchen, payments, refunds, gapless invoicing, double-entry posting, inventory, finance reports, Excel and PDF export, subscriptions, analytics, platform admin
- Transactional outbox, Socket.IO with server-computed rooms and replay on reconnect

### Phase 3 and 4: Flutter
- Pub workspace with five shared packages and four apps; 321 strings in nine languages; RTL; dynamic per-cafe themes with contrast correction

### Verified
- `npm run db:test`: 92 passed. `npm test`: 75 passed, on real MySQL 8.4 and Redis, as the least-privilege DB user
- `flutter test`: 66 passed, across 8 packages and apps. Live tests against a running API: 15 passed, covering every write the new screens make
- `dart analyze`: no errors or warnings. All four web builds, an iOS simulator build and a debug APK succeed
- Real Chrome, driven by hand: guest QR order, live kitchen update reaching the guest's phone, cash payment, Arabic RTL, Hindi, Japanese, admin login with MFA

### Bugs found by this testing and fixed
- Peak hours showed midnight: `CONVERT_TZ` returns NULL without MySQL timezone tables
- Indian cafes showed 125,000 rather than 1,25,000: locale resolution dropped the region
- Kitchen app crashed on start: scaling a text theme with no font sizes
- A failed webhook was treated as a duplicate on redelivery, which could have lost a real payment
- Revoked customer tokens were accepted on table-session routes
- Raw status and role values shown in the UI, and status chips clipped in tables
- Dashboards fired requests before the session was restored

### Phase 1: database
- 15 migrations, 143 tables, 300+ foreign keys, triggers for financial immutability, least-privilege users, reference seeds
- Mutation check: five deliberately broken safeguards were each detected by the suite

### Not done
See `DEVELOPMENT_ROADMAP.md` and `KNOWN_ISSUES.md`.
