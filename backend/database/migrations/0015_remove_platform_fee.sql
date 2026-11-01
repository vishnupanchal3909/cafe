-- The owner withdrew the flat platform fee from 0014. Cafes still receive customer money directly (D-1).
DROP TABLE platform_fee_ledger;
DROP TABLE platform_fee_configs;

ALTER TABLE orders DROP CHECK chk_orders_platform_fee, DROP COLUMN platform_fee_amount;

DROP TRIGGER trg_invoices_guard;
ALTER TABLE invoices DROP COLUMN platform_fee_amount;
CREATE TRIGGER trg_invoices_guard BEFORE UPDATE ON invoices FOR EACH ROW
BEGIN
  IF OLD.status <> 'draft' THEN
    IF NOT (NEW.cafe_id <=> OLD.cafe_id AND NEW.branch_id <=> OLD.branch_id
        AND NEW.document_type <=> OLD.document_type AND NEW.series <=> OLD.series
        AND NEW.fiscal_year <=> OLD.fiscal_year AND NEW.sequence_no <=> OLD.sequence_no
        AND NEW.invoice_number <=> OLD.invoice_number AND NEW.currency_code <=> OLD.currency_code
        AND NEW.subtotal_amount <=> OLD.subtotal_amount AND NEW.discount_amount <=> OLD.discount_amount
        AND NEW.tax_amount <=> OLD.tax_amount AND NEW.rounding_amount <=> OLD.rounding_amount
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

-- Fails loudly, rather than losing history, if any ledger line ever used this account.
DELETE FROM accounting_accounts WHERE system_key = 'platform_fee_payable';
DELETE FROM coa_template_accounts WHERE system_key = 'platform_fee_payable';
