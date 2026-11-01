-- Database-level financial and integrity guarantees. These hold even if application code is wrong.
-- Sent to the server in one multi-statement batch, so no DELIMITER is used.
-- In MySQL Workbench or the mysql CLI, wrap each trigger in DELIMITER $$ ... $$ to run it by hand.

-- ---------------------------------------------------------------------------
-- Append-only tables: no UPDATE, no DELETE. Corrections are new rows.
-- ---------------------------------------------------------------------------
CREATE TRIGGER trg_audit_logs_no_update BEFORE UPDATE ON audit_logs FOR EACH ROW
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'audit_logs is append-only';
CREATE TRIGGER trg_audit_logs_no_delete BEFORE DELETE ON audit_logs FOR EACH ROW
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'audit_logs is append-only';

CREATE TRIGGER trg_payment_transactions_no_update BEFORE UPDATE ON payment_transactions FOR EACH ROW
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'payment_transactions is append-only';
CREATE TRIGGER trg_payment_transactions_no_delete BEFORE DELETE ON payment_transactions FOR EACH ROW
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'payment_transactions is append-only';

CREATE TRIGGER trg_platform_transactions_no_update BEFORE UPDATE ON platform_transactions FOR EACH ROW
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'platform_transactions is append-only';
CREATE TRIGGER trg_platform_transactions_no_delete BEFORE DELETE ON platform_transactions FOR EACH ROW
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'platform_transactions is append-only';

CREATE TRIGGER trg_stock_movements_no_update BEFORE UPDATE ON stock_movements FOR EACH ROW
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'stock_movements is append-only';
CREATE TRIGGER trg_stock_movements_no_delete BEFORE DELETE ON stock_movements FOR EACH ROW
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'stock_movements is append-only';

CREATE TRIGGER trg_cash_register_tx_no_update BEFORE UPDATE ON cash_register_transactions FOR EACH ROW
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'cash_register_transactions is append-only';
CREATE TRIGGER trg_cash_register_tx_no_delete BEFORE DELETE ON cash_register_transactions FOR EACH ROW
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'cash_register_transactions is append-only';

CREATE TRIGGER trg_loyalty_ledger_no_update BEFORE UPDATE ON loyalty_ledger FOR EACH ROW
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'loyalty_ledger is append-only';
CREATE TRIGGER trg_loyalty_ledger_no_delete BEFORE DELETE ON loyalty_ledger FOR EACH ROW
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'loyalty_ledger is append-only';

CREATE TRIGGER trg_order_status_history_no_update BEFORE UPDATE ON order_status_history FOR EACH ROW
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'order_status_history is append-only';
CREATE TRIGGER trg_order_status_history_no_delete BEFORE DELETE ON order_status_history FOR EACH ROW
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'order_status_history is append-only';

CREATE TRIGGER trg_order_modifications_no_update BEFORE UPDATE ON order_modifications FOR EACH ROW
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'order_modifications is append-only';
CREATE TRIGGER trg_order_modifications_no_delete BEFORE DELETE ON order_modifications FOR EACH ROW
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'order_modifications is append-only';

CREATE TRIGGER trg_exchange_rates_no_update BEFORE UPDATE ON exchange_rates FOR EACH ROW
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'exchange_rates is append-only';
CREATE TRIGGER trg_exchange_rates_no_delete BEFORE DELETE ON exchange_rates FOR EACH ROW
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'exchange_rates is append-only';

-- Financial documents are never hard-deleted.
CREATE TRIGGER trg_orders_no_delete BEFORE DELETE ON orders FOR EACH ROW
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'orders cannot be deleted';
CREATE TRIGGER trg_refunds_no_delete BEFORE DELETE ON refunds FOR EACH ROW
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'refunds cannot be deleted';
CREATE TRIGGER trg_settlements_no_delete BEFORE DELETE ON settlements FOR EACH ROW
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'settlements cannot be deleted';

-- ---------------------------------------------------------------------------
-- Payments: amount and identity are fixed, and status follows a legal path.
-- ---------------------------------------------------------------------------
CREATE TRIGGER trg_payments_no_delete BEFORE DELETE ON payments FOR EACH ROW
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'payments cannot be deleted';

CREATE TRIGGER trg_payments_guard BEFORE UPDATE ON payments FOR EACH ROW
BEGIN
  IF NEW.amount <> OLD.amount OR NEW.currency_code <> OLD.currency_code
     OR NEW.cafe_id <> OLD.cafe_id OR NOT (NEW.order_id <=> OLD.order_id) OR NOT (NEW.bill_id <=> OLD.bill_id) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'payment amount, currency and target are immutable';
  END IF;

  IF OLD.verified_at IS NOT NULL AND NOT (NEW.verified_at <=> OLD.verified_at
       AND NEW.verification_source <=> OLD.verification_source
       AND NEW.confirmed_by_user_id <=> OLD.confirmed_by_user_id
       AND NEW.provider_code <=> OLD.provider_code
       AND NEW.provider_payment_ref <=> OLD.provider_payment_ref) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'payment verification evidence is immutable';
  END IF;

  IF NEW.status <> OLD.status AND NOT (
       (OLD.status = 'created' AND NEW.status IN ('pending','succeeded','failed','cancelled'))
    OR (OLD.status = 'pending' AND NEW.status IN ('succeeded','failed','expired','cancelled'))
    -- A provider can confirm capture after we timed out. Only a verified gateway path may do this.
    OR (OLD.status IN ('failed','expired') AND NEW.status = 'succeeded'
        AND NEW.verification_source IN ('gateway_webhook','gateway_api'))
    OR (OLD.status = 'succeeded' AND NEW.status IN ('partially_refunded','refunded'))
    OR (OLD.status = 'partially_refunded' AND NEW.status = 'refunded')
  ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'illegal payment status transition';
  END IF;
END;

-- Refund total can never exceed the payment. The payment row is locked to serialize concurrent refunds.
CREATE TRIGGER trg_refunds_limit BEFORE INSERT ON refunds FOR EACH ROW
BEGIN
  DECLARE v_amount DECIMAL(19,4);
  DECLARE v_status VARCHAR(32);
  DECLARE v_refunded DECIMAL(19,4);

  SELECT amount, status INTO v_amount, v_status
    FROM payments WHERE cafe_id = NEW.cafe_id AND id = NEW.payment_id FOR UPDATE;

  IF v_status NOT IN ('succeeded','partially_refunded') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'only a successful payment can be refunded';
  END IF;

  SELECT COALESCE(SUM(amount), 0) INTO v_refunded
    FROM refunds WHERE cafe_id = NEW.cafe_id AND payment_id = NEW.payment_id AND status <> 'failed';

  IF v_refunded + NEW.amount > v_amount THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'refund total exceeds payment amount';
  END IF;
END;

CREATE TRIGGER trg_refunds_guard BEFORE UPDATE ON refunds FOR EACH ROW
BEGIN
  IF NEW.amount <> OLD.amount OR NEW.currency_code <> OLD.currency_code OR NEW.payment_id <> OLD.payment_id THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'refund amount, currency and payment are immutable';
  END IF;
  IF OLD.status IN ('succeeded','failed') AND NEW.status <> OLD.status THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'refund is in a terminal status';
  END IF;
END;

-- ---------------------------------------------------------------------------
-- Double-entry journal.
-- ---------------------------------------------------------------------------
CREATE TRIGGER trg_journal_entries_insert BEFORE INSERT ON journal_entries FOR EACH ROW
BEGIN
  IF NEW.status <> 'draft' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'journal entries must be created as draft';
  END IF;
END;

CREATE TRIGGER trg_journal_entries_guard BEFORE UPDATE ON journal_entries FOR EACH ROW
BEGIN
  DECLARE v_debit DECIMAL(25,4);
  DECLARE v_credit DECIMAL(25,4);
  DECLARE v_lines INT;
  DECLARE v_period_status VARCHAR(10);
  DECLARE v_starts DATE;
  DECLARE v_ends DATE;

  IF OLD.status = 'posted' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'a posted journal entry is immutable; use a reversal entry';
  END IF;

  IF NEW.status = 'posted' THEN
    SELECT COALESCE(SUM(debit_amount), 0), COALESCE(SUM(credit_amount), 0), COUNT(*)
      INTO v_debit, v_credit, v_lines
      FROM journal_entry_lines WHERE cafe_id = NEW.cafe_id AND journal_entry_id = NEW.id;

    IF v_lines < 2 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'a journal entry needs at least two lines';
    END IF;
    IF v_debit <> v_credit THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'journal entry debits and credits do not balance';
    END IF;

    -- FOR SHARE blocks a concurrent period close from slipping past this check.
    SELECT status, starts_on, ends_on INTO v_period_status, v_starts, v_ends
      FROM financial_periods WHERE cafe_id = NEW.cafe_id AND id = NEW.period_id FOR SHARE;

    IF v_period_status <> 'open' THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'cannot post into a closed financial period';
    END IF;
    IF NEW.entry_date < v_starts OR NEW.entry_date > v_ends THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'entry date is outside the financial period';
    END IF;

    SET NEW.posted_at = COALESCE(NEW.posted_at, CURRENT_TIMESTAMP(3));
  END IF;
END;

CREATE TRIGGER trg_journal_entries_no_delete BEFORE DELETE ON journal_entries FOR EACH ROW
BEGIN
  IF OLD.status = 'posted' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'a posted journal entry cannot be deleted';
  END IF;
END;

CREATE TRIGGER trg_journal_lines_insert BEFORE INSERT ON journal_entry_lines FOR EACH ROW
BEGIN
  IF (SELECT status FROM journal_entries WHERE cafe_id = NEW.cafe_id AND id = NEW.journal_entry_id FOR SHARE) <> 'draft' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'cannot add lines to a posted journal entry';
  END IF;
END;

CREATE TRIGGER trg_journal_lines_update BEFORE UPDATE ON journal_entry_lines FOR EACH ROW
BEGIN
  IF (SELECT status FROM journal_entries WHERE cafe_id = OLD.cafe_id AND id = OLD.journal_entry_id FOR SHARE) <> 'draft' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'cannot change lines of a posted journal entry';
  END IF;
END;

CREATE TRIGGER trg_journal_lines_delete BEFORE DELETE ON journal_entry_lines FOR EACH ROW
BEGIN
  IF (SELECT status FROM journal_entries WHERE cafe_id = OLD.cafe_id AND id = OLD.journal_entry_id FOR SHARE) <> 'draft' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'cannot delete lines of a posted journal entry';
  END IF;
END;

-- ---------------------------------------------------------------------------
-- Invoices: draft is editable; once issued, only void and post-issue artefacts may change.
-- ---------------------------------------------------------------------------
CREATE TRIGGER trg_invoices_no_delete BEFORE DELETE ON invoices FOR EACH ROW
BEGIN
  IF OLD.status <> 'draft' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'an issued invoice cannot be deleted';
  END IF;
END;

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

CREATE TRIGGER trg_invoice_lines_insert BEFORE INSERT ON invoice_lines FOR EACH ROW
BEGIN
  IF (SELECT status FROM invoices WHERE cafe_id = NEW.cafe_id AND id = NEW.invoice_id FOR SHARE) <> 'draft' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'cannot add lines to an issued invoice';
  END IF;
END;

CREATE TRIGGER trg_invoice_lines_update BEFORE UPDATE ON invoice_lines FOR EACH ROW
BEGIN
  IF (SELECT status FROM invoices WHERE cafe_id = OLD.cafe_id AND id = OLD.invoice_id FOR SHARE) <> 'draft' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'cannot change lines of an issued invoice';
  END IF;
END;

CREATE TRIGGER trg_invoice_lines_delete BEFORE DELETE ON invoice_lines FOR EACH ROW
BEGIN
  IF (SELECT status FROM invoices WHERE cafe_id = OLD.cafe_id AND id = OLD.invoice_id FOR SHARE) <> 'draft' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'cannot delete lines of an issued invoice';
  END IF;
END;

CREATE TRIGGER trg_invoice_tax_lines_insert BEFORE INSERT ON invoice_tax_lines FOR EACH ROW
BEGIN
  IF (SELECT status FROM invoices WHERE cafe_id = NEW.cafe_id AND id = NEW.invoice_id FOR SHARE) <> 'draft' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'cannot add tax lines to an issued invoice';
  END IF;
END;

CREATE TRIGGER trg_invoice_tax_lines_update BEFORE UPDATE ON invoice_tax_lines FOR EACH ROW
BEGIN
  IF (SELECT status FROM invoices WHERE cafe_id = OLD.cafe_id AND id = OLD.invoice_id FOR SHARE) <> 'draft' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'cannot change tax lines of an issued invoice';
  END IF;
END;

CREATE TRIGGER trg_invoice_tax_lines_delete BEFORE DELETE ON invoice_tax_lines FOR EACH ROW
BEGIN
  IF (SELECT status FROM invoices WHERE cafe_id = OLD.cafe_id AND id = OLD.invoice_id FOR SHARE) <> 'draft' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'cannot delete tax lines of an issued invoice';
  END IF;
END;

-- ---------------------------------------------------------------------------
-- RBAC: a cafe-specific role can only be assigned inside that cafe.
-- ---------------------------------------------------------------------------
CREATE TRIGGER trg_user_roles_scope BEFORE INSERT ON user_roles FOR EACH ROW
BEGIN
  DECLARE v_role_cafe BIGINT UNSIGNED;
  DECLARE v_role_scope VARCHAR(10);
  SELECT cafe_id, scope INTO v_role_cafe, v_role_scope FROM roles WHERE id = NEW.role_id;
  IF v_role_cafe IS NOT NULL AND NOT (v_role_cafe <=> NEW.cafe_id) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'role belongs to a different cafe';
  END IF;
  IF (v_role_scope = 'platform') <> (NEW.cafe_id IS NULL) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'role scope does not match assignment scope';
  END IF;
END;

CREATE TRIGGER trg_user_roles_scope_update BEFORE UPDATE ON user_roles FOR EACH ROW
BEGIN
  IF NOT (NEW.role_id <=> OLD.role_id AND NEW.cafe_id <=> OLD.cafe_id) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'change a role assignment by deleting and re-inserting it';
  END IF;
END;
