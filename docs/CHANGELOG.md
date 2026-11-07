# Changelog

## Unreleased

### Customer app on Android
- Runs on a real Android phone (Android 16) over Wi-Fi. The debug build allows plain http to the development API; release builds keep Android's default of https only
- Opens a table from a `cafeplatform://open/t/<token>` link, as on iPhone
- Fixed: on phones, restoring a saved login ran before Flutter had started, so a returning diner was not kept signed in

### Loopholes closed
- **Walk-outs:** orders still unpaid past the cafe's alert time (`unpaidAlertMinutes`, default 60) are flagged red on the Orders screen with how long, and an **Unpaid** filter lists everything owed. The screen re-reads every minute
- **Paying guests ordering from elsewhere:** once the bill is settled, their table session ends after `sessionEndAfterPaymentMinutes` (default 30, 0 ends it at once). Ordering again within that time restores the full session
- **A photo of the QR code:** optional table PIN (`tablePinRequired`, off by default). Each table session gets a 4-digit PIN, shown to staff on the occupied table card; the customer app asks for it once, and the server refuses orders without it. Ten tries per ten minutes. Migration `0016_table_pin.sql`
- **Fake accounts:** sign-up capped at 20 an hour per address. Email verification still needs an email provider
- **Forgot password:** reset-link confirmation built and tested; requesting a link reports unavailable until an email provider exists, and the app hides the link until then
- **Order numbers:** they restart each business day by design. Cards now say which business day an order counts for when it differs from the clock date
- **Buttons by role:** orders, menu, tables and payments show only the actions the signed-in role may take
- **Reload:** the owner app now returns to the page you were on
- Found in live testing and fixed: the server's CORS list did not allow the PIN header, so browsers could not send it. A test now checks the preflight
- The three settings are per cafe, editable by the owner in Settings. 18 new strings in all 9 languages, machine-written

### Tables free themselves after payment
- When a payment settles everything owed at a table, the table turns Available at once, for cash and online payments alike. The guests who paid can still follow their order; the next scan of the QR starts a fresh session, so the next party never sees the previous guests' orders. A new order on a freed table, such as dessert, marks it Occupied again
- Staff can free a table by hand with **Mark available** on the table card (`POST /cafe/tables/:id/release`, needs `orders.update`, so cashiers, waiters and managers can). It is refused while any order on the table is unpaid, with a clear message
- The Tables screen updates live, and table statuses have their own colours and icons. 3 new strings in all 9 languages
- Fixed: moving between Orders and Tables in the owner app could drop the live connection, so new orders stopped appearing until a reload. Screens now share the connection and only the last one closes it

### Cashiers and waiters can sign in to the owner app
- Each portal says who is signed in and as what: the person's name and a role badge in the sidebar, the badge again in the top bar, a colour per role (owner amber, manager purple, cashier green, waiter blue), and the browser tab reads, for example, "Cashier · Tea Hub". `/cafe/workspace` now returns the person's name and roles
- Fixed: cashiers and waiters were sent back to the login screen without a message, because the app loaded the full cafe profile, which only owners and managers may read
- New `GET /cafe/workspace`, readable by any staff member: cafe name, currency, language, the person's own branches and their permissions. No legal, tax or contact details
- The sidebar shows only the screens a role can use, and each person lands on their first one: the dashboard for owners and managers, Orders for cashiers and waiters. No role's permissions changed

### Customer app on iPhone
- The iPhone app opens a table from a `cafeplatform://open/t/<token>` link. Printed QR codes still open the web app; universal links wait for the domain (D-4)

### Sign-in needed to order (D-6)
- Diners can browse the whole customer app without an account, but must sign in or create one to place an order. The cart shows "Sign in to order" and returns the diner to the cart after sign-in
- Enforced on the server: `POST /customer/orders` answers 401 `CUSTOMER_LOGIN_REQUIRED` without a customer login, including for staff logins
- The customer app now restores a saved login after a page reload
- 2 new strings in all 9 languages, machine-written. Tests updated, with new checks that a guest and a staff login are both refused

### Depth design for all four apps
- A shared depth toolkit in `shared_design_system/lib/src/depth.dart`: raised cards with layered brand-tinted shadows and a lit edge, which lift and lean toward the pointer with a sheen; glossy icon badges; a lit backdrop with a perspective floor grid; a one-time float-in. Nothing loops, and reduced-motion settings turn the movement off
- Sign-in for all four apps: lit backdrop, floating panes, a raised form card, show/hide password, and Enter submits the 6-digit code. Admin and kitchen get their own titles and taglines; the customer sign-in has a back button
- Floating sidebar and drawer, 3D bars in the revenue chart, glossy progress bars, glossy buttons in every app
- Owner: raised order, product and table cards, photos fanned out in the welcome banner
- Admin: indigo and cyan palette, coloured figures
- Kitchen: colour-coded lanes, tickets with a coloured header and a glow when delayed or urgent, raised branch picker. Type and touch targets unchanged
- Customer: cover-photo header with logo and table, raised product cards, a floating cart bar, photo in the product sheet, photos in the cart, a stepper for order progress, a lit QR landing screen, grouped account page
- 9 new strings in all 9 languages, machine-written
- Accessibility fix: the sidebar and top bar were hidden from screen readers in every app, because the router's page barrier blocked them. A regression test now covers it. The veg mark and stock switch were also read out twice
- `test/preview-stack.ts` now adds a platform admin with a second factor and a table QR, so all four apps can be checked in a browser

### Owner app design
- New look: labelled sidebar, cream and coffee theme, branded sign-in, welcome banner, coloured figures, revenue chart, recent orders
- Menu is a photo grid with category filters, search and an availability switch. Orders and tables are cards with one clear next action. Staff get avatars
- Photos: `PUT` and `DELETE /cafe/products/:id/image` set the main photo, and `POST /cafe/media/product-image` lets anyone who can edit the menu upload one
- The sidebar, theme and tables also apply to the admin app
- `npm run demo:photos` adds sample photos, and `test/preview-stack.ts` runs a throwaway copy for checking the design

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
