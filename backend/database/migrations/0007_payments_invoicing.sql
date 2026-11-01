-- Payments, bills, refunds, settlements, invoices. No card data columns exist or may be added.

CREATE TABLE cafe_payment_methods (
  cafe_id BIGINT UNSIGNED NOT NULL,
  method_code VARCHAR(32) COLLATE ascii_bin NOT NULL,
  is_enabled TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (cafe_id, method_code),
  FOREIGN KEY (cafe_id) REFERENCES cafes (id),
  FOREIGN KEY (method_code) REFERENCES payment_methods (code)
);

CREATE TABLE payment_gateway_accounts (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  public_id CHAR(26) COLLATE ascii_bin NOT NULL,
  cafe_id BIGINT UNSIGNED NOT NULL,
  provider_code VARCHAR(32) COLLATE ascii_bin NOT NULL,
  environment ENUM('sandbox','live') NOT NULL,
  credentials_ciphertext VARBINARY(4096) NOT NULL,
  webhook_secret_ciphertext VARBINARY(1024) NULL,
  encryption_key_id VARCHAR(40) COLLATE ascii_bin NOT NULL,
  status ENUM('pending_configuration','active','disabled') NOT NULL DEFAULT 'pending_configuration',
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_payment_gateway_accounts_public_id (public_id),
  UNIQUE KEY uq_payment_gateway_accounts_tenant (cafe_id, id),
  UNIQUE KEY uq_payment_gateway_accounts (cafe_id, provider_code, environment),
  FOREIGN KEY (cafe_id) REFERENCES cafes (id),
  FOREIGN KEY (provider_code) REFERENCES payment_providers (code)
);

-- Bills group what is to be paid together; a split produces several bills for one session.
CREATE TABLE bills (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  public_id CHAR(26) COLLATE ascii_bin NOT NULL,
  cafe_id BIGINT UNSIGNED NOT NULL,
  branch_id BIGINT UNSIGNED NOT NULL,
  session_id BIGINT UNSIGNED NULL,
  status ENUM('open','partially_paid','paid','void') NOT NULL DEFAULT 'open',
  currency_code CHAR(3) COLLATE ascii_bin NOT NULL,
  total_amount DECIMAL(19,4) NOT NULL,
  paid_amount DECIMAL(19,4) NOT NULL DEFAULT 0,
  created_by_user_id BIGINT UNSIGNED NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_bills_public_id (public_id),
  UNIQUE KEY uq_bills_tenant (cafe_id, id),
  UNIQUE KEY uq_bills_tenant_currency (cafe_id, id, currency_code),
  FOREIGN KEY (cafe_id, currency_code) REFERENCES cafes (id, currency_code),
  FOREIGN KEY (cafe_id, branch_id) REFERENCES cafe_branches (cafe_id, id),
  FOREIGN KEY (cafe_id, session_id) REFERENCES table_sessions (cafe_id, id),
  FOREIGN KEY (created_by_user_id) REFERENCES users (id),
  CONSTRAINT chk_bills_amounts CHECK (total_amount >= 0 AND paid_amount >= 0)
);

CREATE TABLE bill_lines (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  cafe_id BIGINT UNSIGNED NOT NULL,
  bill_id BIGINT UNSIGNED NOT NULL,
  order_id BIGINT UNSIGNED NOT NULL,
  order_item_id BIGINT UNSIGNED NULL,
  amount DECIMAL(19,4) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_bill_lines_tenant (cafe_id, id),
  FOREIGN KEY (cafe_id, bill_id) REFERENCES bills (cafe_id, id),
  FOREIGN KEY (cafe_id, order_id) REFERENCES orders (cafe_id, id),
  FOREIGN KEY (cafe_id, order_item_id) REFERENCES order_items (cafe_id, id),
  CONSTRAINT chk_bill_lines_amount CHECK (amount > 0)
);

CREATE TABLE payments (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  public_id CHAR(26) COLLATE ascii_bin NOT NULL,
  cafe_id BIGINT UNSIGNED NOT NULL,
  branch_id BIGINT UNSIGNED NOT NULL,
  order_id BIGINT UNSIGNED NULL,
  bill_id BIGINT UNSIGNED NULL,
  method_code VARCHAR(32) COLLATE ascii_bin NOT NULL,
  provider_code VARCHAR(32) COLLATE ascii_bin NULL,
  gateway_account_id BIGINT UNSIGNED NULL,
  currency_code CHAR(3) COLLATE ascii_bin NOT NULL,
  amount DECIMAL(19,4) NOT NULL,
  refunded_amount DECIMAL(19,4) NOT NULL DEFAULT 0,
  gateway_fee_amount DECIMAL(19,4) NULL,
  status ENUM('created','pending','succeeded','failed','expired','cancelled','partially_refunded','refunded') NOT NULL DEFAULT 'created',
  verification_source ENUM('gateway_webhook','gateway_api','manual_cash') NULL,
  verified_at DATETIME(3) NULL,
  confirmed_by_user_id BIGINT UNSIGNED NULL,
  provider_order_ref VARCHAR(191) COLLATE ascii_bin NULL,
  provider_payment_ref VARCHAR(191) COLLATE ascii_bin NULL,
  instrument_summary VARCHAR(60) NULL,
  idempotency_key VARCHAR(100) COLLATE ascii_bin NOT NULL,
  failure_code VARCHAR(64) NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_payments_public_id (public_id),
  UNIQUE KEY uq_payments_tenant (cafe_id, id),
  UNIQUE KEY uq_payments_tenant_currency (cafe_id, id, currency_code),
  UNIQUE KEY uq_payments_idempotency (cafe_id, idempotency_key),
  UNIQUE KEY uq_payments_provider_ref (provider_code, provider_payment_ref),
  KEY idx_payments_reporting (cafe_id, status, created_at),
  KEY idx_payments_stale (status, created_at),
  FOREIGN KEY (cafe_id, branch_id) REFERENCES cafe_branches (cafe_id, id),
  -- Payment currency must equal the order's/bill's currency.
  FOREIGN KEY (cafe_id, order_id, currency_code) REFERENCES orders (cafe_id, id, currency_code),
  FOREIGN KEY (cafe_id, bill_id, currency_code) REFERENCES bills (cafe_id, id, currency_code),
  FOREIGN KEY (cafe_id, gateway_account_id) REFERENCES payment_gateway_accounts (cafe_id, id),
  FOREIGN KEY (method_code) REFERENCES payment_methods (code),
  FOREIGN KEY (provider_code) REFERENCES payment_providers (code),
  FOREIGN KEY (confirmed_by_user_id) REFERENCES users (id),
  CONSTRAINT chk_payments_target CHECK (order_id IS NOT NULL OR bill_id IS NOT NULL),
  CONSTRAINT chk_payments_amounts CHECK (amount > 0 AND refunded_amount >= 0 AND refunded_amount <= amount),
  CONSTRAINT chk_payments_refund_state CHECK (
    (status <> 'refunded' OR refunded_amount = amount)
    AND (status <> 'partially_refunded' OR (refunded_amount > 0 AND refunded_amount < amount))
  ),
  -- Rule: only a verified gateway path or an identified staff member can mark money received.
  CONSTRAINT chk_payments_verified CHECK (
    status NOT IN ('succeeded','partially_refunded','refunded')
    OR (verified_at IS NOT NULL AND (
         (verification_source IN ('gateway_webhook','gateway_api') AND provider_code IS NOT NULL AND provider_payment_ref IS NOT NULL)
         OR (verification_source = 'manual_cash' AND confirmed_by_user_id IS NOT NULL AND provider_code IS NULL)
    ))
  )
);

-- Append-only record of everything that happened to a payment (triggers in 0012).
CREATE TABLE payment_transactions (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  cafe_id BIGINT UNSIGNED NOT NULL,
  payment_id BIGINT UNSIGNED NOT NULL,
  transaction_type ENUM('initiated','authorized','captured','failed','expired','cancelled','refund','adjustment','cash_confirmed') NOT NULL,
  currency_code CHAR(3) COLLATE ascii_bin NOT NULL,
  amount DECIMAL(19,4) NOT NULL,
  provider_ref VARCHAR(191) COLLATE ascii_bin NULL,
  provider_status VARCHAR(64) NULL,
  sanitized_payload JSON NULL,
  actor_user_id BIGINT UNSIGNED NULL,
  occurred_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_payment_transactions_tenant (cafe_id, id),
  KEY idx_payment_transactions_payment (payment_id, occurred_at),
  FOREIGN KEY (cafe_id, payment_id, currency_code) REFERENCES payments (cafe_id, id, currency_code),
  FOREIGN KEY (actor_user_id) REFERENCES users (id)
);

CREATE TABLE refunds (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  public_id CHAR(26) COLLATE ascii_bin NOT NULL,
  cafe_id BIGINT UNSIGNED NOT NULL,
  payment_id BIGINT UNSIGNED NOT NULL,
  currency_code CHAR(3) COLLATE ascii_bin NOT NULL,
  amount DECIMAL(19,4) NOT NULL,
  status ENUM('requested','processing','succeeded','failed') NOT NULL DEFAULT 'requested',
  reason VARCHAR(500) NOT NULL,
  requested_by_user_id BIGINT UNSIGNED NOT NULL,
  approved_by_user_id BIGINT UNSIGNED NULL,
  provider_refund_ref VARCHAR(191) COLLATE ascii_bin NULL,
  idempotency_key VARCHAR(100) COLLATE ascii_bin NOT NULL,
  processed_at DATETIME(3) NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_refunds_public_id (public_id),
  UNIQUE KEY uq_refunds_tenant (cafe_id, id),
  UNIQUE KEY uq_refunds_idempotency (cafe_id, idempotency_key),
  FOREIGN KEY (cafe_id, payment_id, currency_code) REFERENCES payments (cafe_id, id, currency_code),
  FOREIGN KEY (requested_by_user_id) REFERENCES users (id),
  FOREIGN KEY (approved_by_user_id) REFERENCES users (id),
  CONSTRAINT chk_refunds_amount CHECK (amount > 0)
);

CREATE TABLE settlements (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  public_id CHAR(26) COLLATE ascii_bin NOT NULL,
  cafe_id BIGINT UNSIGNED NOT NULL,
  gateway_account_id BIGINT UNSIGNED NOT NULL,
  provider_settlement_ref VARCHAR(191) COLLATE ascii_bin NOT NULL,
  currency_code CHAR(3) COLLATE ascii_bin NOT NULL,
  gross_amount DECIMAL(19,4) NOT NULL,
  fee_amount DECIMAL(19,4) NOT NULL DEFAULT 0,
  tax_amount DECIMAL(19,4) NOT NULL DEFAULT 0,
  net_amount DECIMAL(19,4) NOT NULL,
  status ENUM('reported','reconciled','mismatch') NOT NULL DEFAULT 'reported',
  settled_at DATETIME(3) NOT NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_settlements_public_id (public_id),
  UNIQUE KEY uq_settlements_tenant (cafe_id, id),
  UNIQUE KEY uq_settlements_ref (gateway_account_id, provider_settlement_ref),
  FOREIGN KEY (cafe_id, gateway_account_id) REFERENCES payment_gateway_accounts (cafe_id, id),
  FOREIGN KEY (currency_code) REFERENCES currencies (code)
);

CREATE TABLE settlement_items (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  cafe_id BIGINT UNSIGNED NOT NULL,
  settlement_id BIGINT UNSIGNED NOT NULL,
  payment_id BIGINT UNSIGNED NULL,
  refund_id BIGINT UNSIGNED NULL,
  amount DECIMAL(19,4) NOT NULL,
  fee_amount DECIMAL(19,4) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  UNIQUE KEY uq_settlement_items_tenant (cafe_id, id),
  FOREIGN KEY (cafe_id, settlement_id) REFERENCES settlements (cafe_id, id),
  FOREIGN KEY (cafe_id, payment_id) REFERENCES payments (cafe_id, id),
  FOREIGN KEY (cafe_id, refund_id) REFERENCES refunds (cafe_id, id),
  CONSTRAINT chk_settlement_items_subject CHECK ((payment_id IS NULL) <> (refund_id IS NULL))
);

-- Raw inbound events. cafe_id is resolved only after signature verification.
CREATE TABLE payment_webhooks (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  cafe_id BIGINT UNSIGNED NULL,
  provider_code VARCHAR(32) COLLATE ascii_bin NOT NULL,
  provider_event_id VARCHAR(191) COLLATE ascii_bin NOT NULL,
  event_type VARCHAR(100) NOT NULL,
  signature_verified TINYINT(1) NOT NULL,
  sanitized_payload JSON NOT NULL,
  status ENUM('received','processed','failed','ignored') NOT NULL DEFAULT 'received',
  attempts INT UNSIGNED NOT NULL DEFAULT 0,
  error_message VARCHAR(500) NULL,
  received_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  processed_at DATETIME(3) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_payment_webhooks_event (provider_code, provider_event_id),
  KEY idx_payment_webhooks_status (status, received_at),
  FOREIGN KEY (cafe_id) REFERENCES cafes (id),
  FOREIGN KEY (provider_code) REFERENCES payment_providers (code)
);

-- Locked with SELECT ... FOR UPDATE while issuing: numbers are gapless per series and year.
CREATE TABLE invoice_sequences (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  cafe_id BIGINT UNSIGNED NOT NULL,
  branch_id BIGINT UNSIGNED NOT NULL,
  series VARCHAR(16) COLLATE ascii_bin NOT NULL,
  fiscal_year SMALLINT UNSIGNED NOT NULL,
  last_number BIGINT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  UNIQUE KEY uq_invoice_sequences_tenant (cafe_id, id),
  UNIQUE KEY uq_invoice_sequences (cafe_id, branch_id, series, fiscal_year),
  FOREIGN KEY (cafe_id, branch_id) REFERENCES cafe_branches (cafe_id, id)
);

-- Lifecycle: draft (lines added) -> issued (immutable, enforced in 0012) -> voided.
CREATE TABLE invoices (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  public_id CHAR(26) COLLATE ascii_bin NOT NULL,
  cafe_id BIGINT UNSIGNED NOT NULL,
  branch_id BIGINT UNSIGNED NOT NULL,
  order_id BIGINT UNSIGNED NULL,
  document_type ENUM('invoice','receipt','credit_note') NOT NULL DEFAULT 'invoice',
  original_invoice_id BIGINT UNSIGNED NULL,
  status ENUM('draft','issued','voided') NOT NULL DEFAULT 'draft',
  series VARCHAR(16) COLLATE ascii_bin NOT NULL,
  fiscal_year SMALLINT UNSIGNED NOT NULL,
  sequence_no BIGINT UNSIGNED NULL,
  invoice_number VARCHAR(40) NULL,
  language_code VARCHAR(12) COLLATE ascii_bin NOT NULL,
  currency_code CHAR(3) COLLATE ascii_bin NOT NULL,
  subtotal_amount DECIMAL(19,4) NOT NULL DEFAULT 0,
  discount_amount DECIMAL(19,4) NOT NULL DEFAULT 0,
  tax_amount DECIMAL(19,4) NOT NULL DEFAULT 0,
  rounding_amount DECIMAL(19,4) NOT NULL DEFAULT 0,
  total_amount DECIMAL(19,4) NOT NULL DEFAULT 0,
  seller_snapshot JSON NOT NULL,
  buyer_snapshot JSON NULL,
  place_of_supply VARCHAR(10) COLLATE ascii_bin NULL,
  issued_at DATETIME(3) NULL,
  voided_at DATETIME(3) NULL,
  void_reason VARCHAR(500) NULL,
  pdf_asset_id BIGINT UNSIGNED NULL,
  -- Reserved seam for fiscal adapters (TSE, NF525, ZATCA, e-invoice IRN). Not implemented.
  fiscal_provider VARCHAR(32) COLLATE ascii_bin NULL,
  fiscal_reference VARCHAR(191) NULL,
  fiscal_payload JSON NULL,
  created_by_user_id BIGINT UNSIGNED NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_invoices_public_id (public_id),
  UNIQUE KEY uq_invoices_tenant (cafe_id, id),
  UNIQUE KEY uq_invoices_number (cafe_id, branch_id, series, fiscal_year, sequence_no),
  KEY idx_invoices_reporting (cafe_id, issued_at),
  FOREIGN KEY (cafe_id, currency_code) REFERENCES cafes (id, currency_code),
  FOREIGN KEY (cafe_id, branch_id) REFERENCES cafe_branches (cafe_id, id),
  FOREIGN KEY (cafe_id, order_id, currency_code) REFERENCES orders (cafe_id, id, currency_code),
  FOREIGN KEY (cafe_id, original_invoice_id) REFERENCES invoices (cafe_id, id),
  FOREIGN KEY (cafe_id, pdf_asset_id) REFERENCES media_assets (cafe_id, id),
  FOREIGN KEY (language_code) REFERENCES languages (code),
  FOREIGN KEY (created_by_user_id) REFERENCES users (id),
  CONSTRAINT chk_invoices_issued CHECK (status = 'draft' OR (sequence_no IS NOT NULL AND invoice_number IS NOT NULL AND issued_at IS NOT NULL)),
  CONSTRAINT chk_invoices_credit_note CHECK (document_type <> 'credit_note' OR original_invoice_id IS NOT NULL)
);

CREATE TABLE invoice_lines (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  cafe_id BIGINT UNSIGNED NOT NULL,
  invoice_id BIGINT UNSIGNED NOT NULL,
  order_item_id BIGINT UNSIGNED NULL,
  description VARCHAR(300) NOT NULL,
  tax_code VARCHAR(20) COLLATE ascii_bin NULL,
  quantity DECIMAL(12,4) NOT NULL,
  unit_price DECIMAL(19,4) NOT NULL,
  discount_amount DECIMAL(19,4) NOT NULL DEFAULT 0,
  taxable_amount DECIMAL(19,4) NOT NULL,
  tax_amount DECIMAL(19,4) NOT NULL DEFAULT 0,
  line_total_amount DECIMAL(19,4) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_invoice_lines_tenant (cafe_id, id),
  FOREIGN KEY (cafe_id, invoice_id) REFERENCES invoices (cafe_id, id),
  FOREIGN KEY (cafe_id, order_item_id) REFERENCES order_items (cafe_id, id)
);

CREATE TABLE invoice_tax_lines (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  cafe_id BIGINT UNSIGNED NOT NULL,
  invoice_id BIGINT UNSIGNED NOT NULL,
  component_code VARCHAR(16) COLLATE ascii_bin NOT NULL,
  display_name VARCHAR(60) NOT NULL,
  rate_percent DECIMAL(9,6) NOT NULL,
  taxable_amount DECIMAL(19,4) NOT NULL,
  tax_amount DECIMAL(19,4) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_invoice_tax_lines_tenant (cafe_id, id),
  FOREIGN KEY (cafe_id, invoice_id) REFERENCES invoices (cafe_id, id)
);
