# Currency and Finance

Implementation status: **implemented and tested end to end, with the limits in `KNOWN_ISSUES.md`. The accounting mappings still need review by an accountant before real books run on them.**

## Money representation

| Layer | Type |
|---|---|
| MySQL | `DECIMAL(19,4)` with `currency_code CHAR(3)`; unit costs `DECIMAL(19,6)`; quantities `DECIMAL(18,4)`; rates `DECIMAL(9,6)` percent; FX `DECIMAL(24,10)` |
| Node.js | `string` from mysql2 (`decimalNumbers: false`) into a decimal library; never `Number` |
| JSON API | `{ "amount": "1250.00", "currency": "INR" }`: amount is a string |
| Dart | `Decimal`, formatted with `intl` `NumberFormat.currency` using the cafe's currency and viewer locale |

Precision comes from `currencies.minor_unit`: JPY 0, INR 2, and KWD 3 is supported when added. A lint test bans `FLOAT` and `DOUBLE` across the schema. Symbol and position come from locale formatting, never a literal in code.

Examples the tests must reproduce: `en_IN` `₹1,25,000.00`, `en_US` `$1,250.00`, `de_DE` `1.250,00 €`, `ja_JP` `¥1,250` (the full-width `¥` variant depends on locale data, so tests pin the `intl` version).

## Rules

1. Original amount and currency are never rewritten.
2. Conversion is reporting-only: `exchange_rates` records rate, base, quote, provider and time. Reports store the used rate.
3. With no rate for a period, reports show per-currency totals and a visible gap. They never guess.
4. Prices are recomputed on the server; client totals are not read.

## Tax model

`tax_categories` (per cafe) -> `tax_rates` (components with validity dates). Example India, intra-state: CGST + SGST; inter-state: IGST, using `applies_to`. The tax components for a country are seeded as *structure only*; **no rates are seeded**. Each line stores its breakdown in `order_item_taxes`, so past invoices survive rate changes.

Inclusive/exclusive pricing and rounding mode are cafe settings. Inclusive-tax back-calculation: `tax = gross - gross / (1 + rate)`, and the rounding remainder is assigned so line totals reconcile exactly to the invoice.

## Invoice numbering

`invoice_sequences` is locked with `SELECT ... FOR UPDATE` inside the issuing transaction, giving gapless numbers per `(branch, series, fiscal year)`. Auto-increment cannot be used because it has gaps on rollback. Issued invoices are immutable; corrections are credit notes.

## Accounting

Double entry. Chart of accounts is copied from `coa_templates` at onboarding, then editable. `journal_entries` go `draft -> posted`. Enforced in the database:

- Each line is either debit or credit, positive (CHECK).
- Posting requires total debit = total credit, and at least 2 lines (trigger).
- A posted entry and its lines are immutable. Correction uses a new entry with `reversal_of_entry_id`.
- Posting into a closed period is rejected.
- `(cafe_id, source_type, source_id, entry_kind)` is unique, so a retried event can't double-post.

The default sale posting (subject to accountant review, see `PROJECT_REQUIREMENTS.md`):

| Event | Debit | Credit |
|---|---|---|
| Payment received | Payment clearing or Cash | Accounts receivable |
| Invoice issued (fully paid) | Accounts receivable, Sales discounts | Sales revenue, Tax payable |
| COGS | Cost of goods sold | Inventory |
| Gateway settlement | Bank, Gateway fees | Payment clearing |
| Refund | Sales returns, Tax payable | Payment clearing or Cash |
| Supplier invoice | Inventory or Expense | Accounts payable |
| Supplier payment | Accounts payable | Bank or Cash |

## Reports

Sales by period, payment breakdown, cash reconciliation, food cost %, P&L, trial balance, balance sheet, Excel and PDF export. Every figure is derived from recorded data; zero-data renders as an empty state, and analytics are never fabricated.
