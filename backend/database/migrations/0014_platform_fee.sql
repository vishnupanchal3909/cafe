-- Cafes receive customer money directly (decision D-1). A flat platform fee per order is added to the bill.
-- It is never the cafe's revenue: it accrues here as an amount the cafe owes the platform.

CREATE TABLE platform_fee_configs (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  currency_code CHAR(3) COLLATE ascii_bin NOT NULL,
  amount DECIMAL(19,4) NOT NULL,
  valid_from DATETIME(3) NOT NULL,
  valid_to DATETIME(3) NULL,
  created_by_user_id BIGINT UNSIGNED NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  KEY idx_platform_fee_configs_lookup (currency_code, valid_from),
  FOREIGN KEY (currency_code) REFERENCES currencies (code),
  FOREIGN KEY (created_by_user_id) REFERENCES users (id),
  CONSTRAINT chk_platform_fee_configs_amount CHECK (amount >= 0)
);

-- Signed and append-only: accrual +, refund reversal -, settlement -. The sum is what the cafe owes.
CREATE TABLE platform_fee_ledger (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  cafe_id BIGINT UNSIGNED NOT NULL,
  entry_type ENUM('accrual','reversal','settlement') NOT NULL,
  currency_code CHAR(3) COLLATE ascii_bin NOT NULL,
  amount DECIMAL(19,4) NOT NULL,
  source_type VARCHAR(40) COLLATE ascii_bin NOT NULL,
  source_id BIGINT UNSIGNED NOT NULL,
  reference VARCHAR(191) NULL,
  recorded_by_user_id BIGINT UNSIGNED NULL,
  occurred_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_platform_fee_ledger_tenant (cafe_id, id),
  -- A retried payment or refund cannot accrue or reverse twice.
  UNIQUE KEY uq_platform_fee_ledger_source (cafe_id, source_type, source_id, entry_type),
  FOREIGN KEY (cafe_id, currency_code) REFERENCES cafes (id, currency_code),
  FOREIGN KEY (recorded_by_user_id) REFERENCES users (id),
  CONSTRAINT chk_platform_fee_ledger_amount CHECK (amount <> 0)
);

CREATE TRIGGER trg_platform_fee_ledger_no_update BEFORE UPDATE ON platform_fee_ledger FOR EACH ROW
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'platform_fee_ledger is append-only';
CREATE TRIGGER trg_platform_fee_ledger_no_delete BEFORE DELETE ON platform_fee_ledger FOR EACH ROW
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'platform_fee_ledger is append-only';

ALTER TABLE orders
  ADD COLUMN platform_fee_amount DECIMAL(19,4) NOT NULL DEFAULT 0 AFTER delivery_fee_amount,
  ADD CONSTRAINT chk_orders_platform_fee CHECK (platform_fee_amount >= 0);

ALTER TABLE invoices
  ADD COLUMN platform_fee_amount DECIMAL(19,4) NOT NULL DEFAULT 0 AFTER rounding_amount;

-- Existing cafes need the liability account; new cafes get it from the template seed.
INSERT INTO accounting_accounts (cafe_id, code, name, account_type, system_key)
SELECT id, '2300', 'Platform fees payable', 'liability', 'platform_fee_payable' FROM cafes;

-- The issued-invoice guard must also pin the new amount.
DROP TRIGGER trg_invoices_guard;
CREATE TRIGGER trg_invoices_guard BEFORE UPDATE ON invoices FOR EACH ROW
BEGIN
  IF OLD.status <> 'draft' THEN
    IF NOT (NEW.cafe_id <=> OLD.cafe_id AND NEW.branch_id <=> OLD.branch_id
        AND NEW.document_type <=> OLD.document_type AND NEW.series <=> OLD.series
        AND NEW.fiscal_year <=> OLD.fiscal_year AND NEW.sequence_no <=> OLD.sequence_no
        AND NEW.invoice_number <=> OLD.invoice_number AND NEW.currency_code <=> OLD.currency_code
        AND NEW.subtotal_amount <=> OLD.subtotal_amount AND NEW.discount_amount <=> OLD.discount_amount
        AND NEW.tax_amount <=> OLD.tax_amount AND NEW.rounding_amount <=> OLD.rounding_amount
        AND NEW.platform_fee_amount <=> OLD.platform_fee_amount
        AND NEW.total_amount <=> OLD.total_amount AND NEW.issued_at <=> OLD.issued_at
        AND NEW.order_id <=> OLD.order_id AND NEW.place_of_supply <=> OLD.place_of_supply
        AND NEW.seller_snapshot <=> OLD.seller_snapshot AND NEW.buyer_snapshot <=> OLD.buyer_snapshot) THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'an issued invoice is immutable; issue a credit note';
    END IF;
    IF NOT (OLD.status = NEW.status OR (OLD.status = 'issued' AND NEW.status = 'voided')) THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'illegal invoice status transition';
    END IF;
  END IF;
END;
