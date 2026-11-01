# Project Requirements

The master brief defines the requirement baseline. This document records how it is interpreted, what it leaves out, and which decisions are still open.

## 1. Applications

| App | Primary user | UX priority |
|---|---|---|
| Super Admin | Platform operator | Platform analytics, governance |
| Cafe Owner | Owner, manager, cashier, waiter | Business information, daily operations |
| Kitchen Display | Kitchen staff | Speed, glanceability at distance |
| Customer | Diner (browser via QR, or mobile) | Simplicity, conversion, no install |

## 2. Module breakdown

Identity and RBAC, tenancy and onboarding, branding, localization, catalog, tables and QR, reservations, ordering, kitchen, tax, payments, invoicing, inventory and purchasing, accounting, finance reports, customers, marketing and loyalty, staff and attendance, notifications, subscriptions, analytics, platform administration, realtime.

Delivery status lives in the tracker in `DEVELOPMENT_ROADMAP.md`.

## 3. Requirements added because the brief implied them

The suggested table list did not cover these, but the features cannot be correct without them.

| Added | Required by |
|---|---|
| `bills`, `bill_lines` | Split bill and split payment |
| `invoices`, `invoice_lines`, `invoice_tax_lines`, `invoice_sequences`, credit notes | Tax invoices need gapless numbering; refunds need credit notes |
| `order_item_taxes`, `tax_categories`, `tax_rates`, `tax_registrations` | Per-product tax, CGST/SGST/IGST breakdown |
| `exchange_rates`, `currencies`, `countries` | Multi-currency reporting |
| `outbox_events` | Socket event recovery |
| `idempotency_keys` | Safe retries on order and payment |
| `payment_gateway_accounts` | Per-cafe gateway configuration |
| `cafe_customers` | Tenant-isolated view of a global customer |
| `branch_product_overrides` | Branch-specific price or availability |
| `stock_batches` | Expiry dates need batches; a single stock figure cannot hold them |
| `supplier_invoices`, `supplier_payments` | Payables |
| `staff_attendance`, `payroll_entries` | Attendance and salaries |
| `reservations`, `service_requests` | Booking, call waiter, request bill |
| `media_assets` | Validated uploads |
| `cash_register_sessions` | Open/close and counted-vs-expected reconciliation |
| Day cutoff and `business_date` | Cafes trading past midnight |
| Data erasure (`customers.anonymized_at`) | GDPR/India DPDP erasure while retaining invoices |

## 4. Assumptions (safe defaults, change if wrong)

| # | Assumption |
|---|---|
| A-1 | A cafe's currency cannot change once it has any financial transaction |
| A-2 | Menu is per cafe, with optional per-branch price and availability overrides |
| A-3 | Payment policy (prepay vs. pay-at-end) is configured per cafe, and enforced server-side |
| A-4 | Tax rounding (per line vs. per invoice) and cash rounding are per-cafe settings, not hardcoded |
| A-5 | Default inventory valuation is moving weighted average |
| A-6 | Default fiscal year is seeded per country as a suggestion and is editable per cafe (India April to March) |
| A-7 | Super Admin read access to cafe data is audited; customer personal data is masked unless a stated, logged support reason is given |
| A-8 | Guests can order on a table session with no personal data; a phone or email is only requested for a receipt |
| A-9 | Stock deduction happens at order acceptance, and reverses on cancellation before preparation. Wastage records the rest |
| A-10 | Audit logs and financial records are retained at least 8 years (longest common tax retention is configurable) |
| A-11 | Loyalty points are per cafe and do not transfer between cafes |
| A-12 | Coupons cannot reduce a line below zero. Order of discount vs. tax follows the cafe's tax configuration |

## 5. Open decisions needing your answer

These affect legal, financial or architectural outcomes, so they are not silently assumed. Each has a working default, so work can continue. Changing D-1 after launch would be expensive.

| # | Decision | Working default | Why it matters |
|---|---|---|---|
| **D-1** | **Who receives the customer's money?** | **Decided by the owner: the cafe receives it directly.** Platform charges are undecided: a flat INR 7 fee was built and then withdrawn by the owner. Details to come | Collecting on behalf of cafes usually needs payment-aggregator status, which this avoids |
| **D-2** | **First launch country** | India (GST) | Fiscal law varies. See warning below |
| **D-3** | Plan prices, limits and commission % | Plan names seeded, **inactive with no prices** | Business decision; must not be invented (Rule: no invented financial rules) |
| **D-4** | Product brand name and domain | Working name "CafePlatform" | Customer-facing URLs, QR content and email domains. Changing the QR domain means reprinting QR codes unless a redirect domain is kept |
| **D-5** | Data residency | Single region (Mumbai) | GDPR transfers from EU cafes need an agreement or an EU deployment |

### Compliance warning: this is not achievable with software alone

These items cannot be asserted as done by code. Each needs a licensed professional or vendor before launching in that market.

- **Certified POS/fiscal laws.** Germany (KassenSichV/TSE), France (NF525-type anti-fraud rules), Portugal (certified invoicing), Italy (telematic receipts), Saudi Arabia (ZATCA e-invoicing), and India's e-invoicing thresholds can legally require certified software or hardware. The schema reserves a fiscal adapter seam (`invoices.fiscal_*`), but **the platform must not be sold as compliant in these markets until each adapter is certified.**
- **Tax treatment** (for example Indian restaurant GST rate rules and input-credit restrictions) should be reviewed by a CA or tax adviser. Rates are all per-cafe configuration, none are seeded as fact.
- **Accounting mappings** should be reviewed by an accountant before real books run on them.
- **Privacy, terms, DPAs and PCI SAQ-A attestation** require legal and compliance work.
