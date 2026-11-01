# API Documentation

Status: **implemented: 202 paths.** The authoritative reference is generated from the running app: Swagger at `/api/docs` in development, and [`openapi.json`](openapi.json) (regenerate with `npm run openapi`). This page is the overview, and a few paths below differ slightly from the implemented routes.

## Conventions

- Base: `/api/v1`. Trees: `/platform` (Super Admin), `/cafe` (tenant staff), `/customer`, `/public`, `/webhooks`.
- Success: `{ "data": ..., "meta": { "page": ... } }`. Error: `{ "error": { "code": "ORDER_NOT_EDITABLE", "message": "<localized>", "details": [], "requestId": "..." } }`.
- Money: `{ "amount": "1250.00", "currency": "INR" }`.
- IDs: `public_id` strings.
- Idempotency: `Idempotency-Key` header on order creation, payment initiation, refunds.
- No `/cafe` endpoint takes `cafeId`; the tenant comes from the token. `X-Branch-Id` selects a branch and is validated.

## Endpoints

### Auth
`POST /auth/login`, `POST /auth/refresh`, `POST /auth/logout`, `POST /auth/logout-all`, `POST /auth/password/forgot`, `POST /auth/password/reset`, `GET /auth/me`, `GET|DELETE /auth/sessions[/:id]`, `POST /customer/auth/register|login|google|guest|refresh`

### Platform
`GET /platform/dashboard`, `GET /platform/cafes`, `GET /platform/cafes/:id`, `POST /platform/cafes/:id/approve|suspend|activate`, `GET /platform/cafes/:id/orders|finance`, `CRUD /platform/plans`, `GET|PATCH /platform/subscriptions`, `CRUD /platform/commissions`, `GET /platform/users`, `CRUD /platform/languages|currencies|countries|exchange-rates`, `CRUD /platform/translations`, `GET|PATCH /platform/settings`, `CRUD /platform/announcements`, `CRUD /platform/support-tickets`, `GET /platform/audit-logs`, `GET /platform/reports/*`, `GET /platform/health`

### Cafe: onboarding and profile
`POST /public/cafes/register`, `GET|PATCH /cafe/profile`, `CRUD /cafe/branches`, `PUT /cafe/branches/:id/hours`, `GET|PUT /cafe/theme`, `GET|PUT /cafe/languages`, `GET|PATCH /cafe/settings`, `CRUD /cafe/banners`, `POST /cafe/media/presign`, `POST /cafe/media/:id/complete`

### Cafe: menu
`CRUD /cafe/categories`, `CRUD /cafe/products`, `PUT /cafe/products/:id/translations/:lang`, `CRUD /cafe/products/:id/variants|images|schedules`, `CRUD /cafe/addon-groups`, `PUT /cafe/products/:id/addon-groups`, `PUT /cafe/products/:id/combo-items`, `PATCH /cafe/products/:id/availability`, `PUT /cafe/branches/:id/product-overrides/:productId`

### Cafe: tax
`CRUD /cafe/tax-categories`, `CRUD /cafe/tax-categories/:id/rates`, `CRUD /cafe/tax-registrations`

### Cafe: tables
`CRUD /cafe/tables`, `GET /cafe/tables/:id/qr`, `POST /cafe/tables/:id/qr/regenerate`, `POST /cafe/table-sessions/:id/merge|transfer|close`, `CRUD /cafe/reservations`, `GET|PATCH /cafe/service-requests`

### Cafe: orders
`GET /cafe/orders`, `POST /cafe/orders` (manual), `GET /cafe/orders/:id`, `POST /cafe/orders/:id/accept|cancel|serve|complete`, `PATCH /cafe/orders/:id/items`, `GET /cafe/orders/:id/history`, `POST /cafe/bills`, `POST /cafe/bills/:id/split`

### Kitchen
`CRUD /cafe/kitchen/stations`, `GET /kitchen/tickets`, `POST /kitchen/tickets/:id/accept|start|ready|prioritize`, `POST /kitchen/ticket-items/:id/ready`

### Payments
`POST /customer/orders/:id/payments`, `POST /cafe/payments/cash`, `GET /cafe/payments`, `POST /cafe/payments/:id/refunds`, `CRUD /cafe/gateway-accounts`, `GET /cafe/settlements`, `POST /webhooks/payments/:provider/:accountId`

### Invoicing
`GET /cafe/invoices`, `POST /cafe/orders/:id/invoice`, `GET /cafe/invoices/:id/pdf`, `POST /cafe/invoices/:id/credit-note`, `GET /customer/orders/:id/receipt`

### Inventory
`CRUD /cafe/ingredients`, `CRUD /cafe/suppliers`, `PUT /cafe/products/:id/recipe`, `GET /cafe/stock`, `POST /cafe/stock/in|out|adjust|wastage`, `GET /cafe/stock/movements|valuation`, `CRUD /cafe/purchase-orders`, `POST /cafe/purchase-orders/:id/receive`, `CRUD /cafe/supplier-invoices`, `POST /cafe/supplier-payments`

### Finance
`CRUD /cafe/expenses`, `CRUD /cafe/expense-categories`, `CRUD /cafe/accounts`, `GET|POST /cafe/journal-entries`, `POST /cafe/journal-entries/:id/post|reverse`, `CRUD /cafe/financial-periods`, `POST /cafe/financial-periods/:id/close`, `CRUD /cafe/cash-registers`, `POST /cafe/cash-registers/:id/open|close|transactions`, `CRUD /cafe/payroll`, `GET /cafe/reports/sales|payments|pnl|trial-balance|balance-sheet|food-cost`, `POST /cafe/reports/:type/export`

### Staff
`CRUD /cafe/staff`, `CRUD /cafe/roles`, `GET /cafe/permissions`, `POST /cafe/attendance/clock-in|clock-out`, `GET /cafe/attendance`, `GET /cafe/staff/:id/performance`

### Customer app
`GET /public/qr/:token`, `GET /public/cafes/:slug/config`, `GET /public/cafes/:slug/menu?lang=`, `GET|PUT /customer/cart`, `POST /customer/orders`, `GET /customer/orders[/:id]`, `POST /customer/service-requests`, `POST /customer/orders/:id/review`, `CRUD /customer/addresses|favorites|wishlist`, `GET /customer/loyalty`, `POST /customer/coupons/validate`, `CRUD /customer/reservations`, `GET|PATCH /customer/profile`, `DELETE /customer/account`

### Marketing, notifications, subscriptions, analytics
`CRUD /cafe/coupons|promotions|loyalty-program`, `GET /cafe/customers`, `GET /cafe/reviews`, `GET|PUT /cafe/notification-preferences`, `GET /notifications`, `POST /notifications/:id/read`, `POST /devices`, `GET /cafe/subscription`, `POST /cafe/subscription/upgrade|downgrade|cancel`, `GET /cafe/subscription/invoices`, `GET /cafe/analytics/*`, `GET /platform/analytics/*`

## Socket.IO events

`order.placed`, `order.accepted`, `order.preparing`, `order.ready`, `order.completed`, `order.cancelled`, `payment.status_changed`, `kitchen.ticket_updated`, `table.status_changed`, `stock.low`, `staff.notification`, `service_request.created`. Handshake: JWT plus `lastSeq` for replay.
