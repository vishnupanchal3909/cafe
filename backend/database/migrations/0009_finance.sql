-- Double-entry accounting, expenses, cash registers, staff time and pay.

CREATE TABLE accounting_accounts (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  cafe_id BIGINT UNSIGNED NOT NULL,
  parent_id BIGINT UNSIGNED NULL,
  code VARCHAR(20) COLLATE ascii_bin NOT NULL,
  name VARCHAR(120) NOT NULL,
  account_type ENUM('asset','liability','equity','revenue','expense') NOT NULL,
  system_key VARCHAR(40) COLLATE ascii_bin NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_accounting_accounts_tenant (cafe_id, id),
  UNIQUE KEY uq_accounting_accounts_code (cafe_id, code),
  UNIQUE KEY uq_accounting_accounts_system (cafe_id, system_key),
  FOREIGN KEY (cafe_id) REFERENCES cafes (id),
  FOREIGN KEY (cafe_id, parent_id) REFERENCES accounting_accounts (cafe_id, id)
);

CREATE TABLE financial_periods (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  cafe_id BIGINT UNSIGNED NOT NULL,
  name VARCHAR(40) NOT NULL,
  starts_on DATE NOT NULL,
  ends_on DATE NOT NULL,
  status ENUM('open','closed') NOT NULL DEFAULT 'open',
  closed_by_user_id BIGINT UNSIGNED NULL,
  closed_at DATETIME(3) NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_financial_periods_tenant (cafe_id, id),
  UNIQUE KEY uq_financial_periods_range (cafe_id, starts_on, ends_on),
  FOREIGN KEY (cafe_id) REFERENCES cafes (id),
  FOREIGN KEY (closed_by_user_id) REFERENCES users (id),
  CONSTRAINT chk_financial_periods_range CHECK (ends_on >= starts_on)
);

-- Lifecycle: draft -> posted (immutable). Balance and period checks are triggers in 0012.
CREATE TABLE journal_entries (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  public_id CHAR(26) COLLATE ascii_bin NOT NULL,
  cafe_id BIGINT UNSIGNED NOT NULL,
  branch_id BIGINT UNSIGNED NULL,
  period_id BIGINT UNSIGNED NOT NULL,
  entry_date DATE NOT NULL,
  status ENUM('draft','posted') NOT NULL DEFAULT 'draft',
  currency_code CHAR(3) COLLATE ascii_bin NOT NULL,
  memo VARCHAR(500) NULL,
  source_type VARCHAR(40) COLLATE ascii_bin NULL,
  source_id BIGINT UNSIGNED NULL,
  entry_kind VARCHAR(40) COLLATE ascii_bin NULL,
  reversal_of_entry_id BIGINT UNSIGNED NULL,
  posted_at DATETIME(3) NULL,
  created_by_user_id BIGINT UNSIGNED NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_journal_entries_public_id (public_id),
  UNIQUE KEY uq_journal_entries_tenant (cafe_id, id),
  -- A retried domain event cannot post twice.
  UNIQUE KEY uq_journal_entries_source (cafe_id, source_type, source_id, entry_kind),
  -- An entry can be reversed only once.
  UNIQUE KEY uq_journal_entries_reversal (cafe_id, reversal_of_entry_id),
  KEY idx_journal_entries_date (cafe_id, entry_date),
  FOREIGN KEY (cafe_id, currency_code) REFERENCES cafes (id, currency_code),
  FOREIGN KEY (cafe_id, branch_id) REFERENCES cafe_branches (cafe_id, id),
  FOREIGN KEY (cafe_id, period_id) REFERENCES financial_periods (cafe_id, id),
  FOREIGN KEY (cafe_id, reversal_of_entry_id) REFERENCES journal_entries (cafe_id, id),
  FOREIGN KEY (created_by_user_id) REFERENCES users (id)
);

CREATE TABLE journal_entry_lines (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  cafe_id BIGINT UNSIGNED NOT NULL,
  journal_entry_id BIGINT UNSIGNED NOT NULL,
  account_id BIGINT UNSIGNED NOT NULL,
  debit_amount DECIMAL(19,4) NOT NULL DEFAULT 0,
  credit_amount DECIMAL(19,4) NOT NULL DEFAULT 0,
  description VARCHAR(255) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_journal_entry_lines_tenant (cafe_id, id),
  KEY idx_journal_entry_lines_account (cafe_id, account_id),
  FOREIGN KEY (cafe_id, journal_entry_id) REFERENCES journal_entries (cafe_id, id),
  FOREIGN KEY (cafe_id, account_id) REFERENCES accounting_accounts (cafe_id, id),
  CONSTRAINT chk_journal_lines_one_side CHECK (
    (debit_amount > 0 AND credit_amount = 0) OR (credit_amount > 0 AND debit_amount = 0)
  )
);

CREATE TABLE expense_categories (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  cafe_id BIGINT UNSIGNED NOT NULL,
  name VARCHAR(100) NOT NULL,
  account_id BIGINT UNSIGNED NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_expense_categories_tenant (cafe_id, id),
  UNIQUE KEY uq_expense_categories_name (cafe_id, name),
  FOREIGN KEY (cafe_id) REFERENCES cafes (id),
  FOREIGN KEY (cafe_id, account_id) REFERENCES accounting_accounts (cafe_id, id)
);

CREATE TABLE expenses (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  public_id CHAR(26) COLLATE ascii_bin NOT NULL,
  cafe_id BIGINT UNSIGNED NOT NULL,
  branch_id BIGINT UNSIGNED NULL,
  expense_category_id BIGINT UNSIGNED NOT NULL,
  currency_code CHAR(3) COLLATE ascii_bin NOT NULL,
  amount DECIMAL(19,4) NOT NULL,
  tax_amount DECIMAL(19,4) NOT NULL DEFAULT 0,
  expense_date DATE NOT NULL,
  description VARCHAR(500) NULL,
  method_code VARCHAR(32) COLLATE ascii_bin NULL,
  document_asset_id BIGINT UNSIGNED NULL,
  voided_at DATETIME(3) NULL,
  void_reason VARCHAR(500) NULL,
  recorded_by_user_id BIGINT UNSIGNED NOT NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_expenses_public_id (public_id),
  UNIQUE KEY uq_expenses_tenant (cafe_id, id),
  KEY idx_expenses_date (cafe_id, expense_date),
  FOREIGN KEY (cafe_id, currency_code) REFERENCES cafes (id, currency_code),
  FOREIGN KEY (cafe_id, branch_id) REFERENCES cafe_branches (cafe_id, id),
  FOREIGN KEY (cafe_id, expense_category_id) REFERENCES expense_categories (cafe_id, id),
  FOREIGN KEY (method_code) REFERENCES payment_methods (code),
  FOREIGN KEY (cafe_id, document_asset_id) REFERENCES media_assets (cafe_id, id),
  FOREIGN KEY (recorded_by_user_id) REFERENCES users (id),
  CONSTRAINT chk_expenses_amount CHECK (amount > 0 AND tax_amount >= 0)
);

CREATE TABLE cash_registers (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  public_id CHAR(26) COLLATE ascii_bin NOT NULL,
  cafe_id BIGINT UNSIGNED NOT NULL,
  branch_id BIGINT UNSIGNED NOT NULL,
  name VARCHAR(80) NOT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_cash_registers_public_id (public_id),
  UNIQUE KEY uq_cash_registers_tenant (cafe_id, id),
  UNIQUE KEY uq_cash_registers_name (cafe_id, branch_id, name),
  FOREIGN KEY (cafe_id, branch_id) REFERENCES cafe_branches (cafe_id, id)
);

CREATE TABLE cash_register_sessions (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  public_id CHAR(26) COLLATE ascii_bin NOT NULL,
  cafe_id BIGINT UNSIGNED NOT NULL,
  cash_register_id BIGINT UNSIGNED NOT NULL,
  currency_code CHAR(3) COLLATE ascii_bin NOT NULL,
  opening_float_amount DECIMAL(19,4) NOT NULL,
  expected_closing_amount DECIMAL(19,4) NULL,
  counted_closing_amount DECIMAL(19,4) NULL,
  variance_amount DECIMAL(19,4) NULL,
  status ENUM('open','closed') NOT NULL DEFAULT 'open',
  opened_by_user_id BIGINT UNSIGNED NOT NULL,
  opened_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  closed_by_user_id BIGINT UNSIGNED NULL,
  closed_at DATETIME(3) NULL,
  active_register_key BIGINT UNSIGNED GENERATED ALWAYS AS (IF(status = 'open', cash_register_id, NULL)) VIRTUAL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_cash_register_sessions_public_id (public_id),
  UNIQUE KEY uq_cash_register_sessions_tenant (cafe_id, id),
  UNIQUE KEY uq_cash_register_sessions_tenant_currency (cafe_id, id, currency_code),
  -- A register has at most one open session.
  UNIQUE KEY uq_cash_register_sessions_active (active_register_key),
  FOREIGN KEY (cafe_id, currency_code) REFERENCES cafes (id, currency_code),
  FOREIGN KEY (cafe_id, cash_register_id) REFERENCES cash_registers (cafe_id, id),
  FOREIGN KEY (opened_by_user_id) REFERENCES users (id),
  FOREIGN KEY (closed_by_user_id) REFERENCES users (id)
);

-- Append-only (triggers in 0012). amount is signed: + into the drawer, - out.
CREATE TABLE cash_register_transactions (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  cafe_id BIGINT UNSIGNED NOT NULL,
  session_id BIGINT UNSIGNED NOT NULL,
  transaction_type ENUM('sale','refund','pay_in','pay_out','expense','adjustment') NOT NULL,
  currency_code CHAR(3) COLLATE ascii_bin NOT NULL,
  amount DECIMAL(19,4) NOT NULL,
  payment_id BIGINT UNSIGNED NULL,
  reason VARCHAR(255) NULL,
  recorded_by_user_id BIGINT UNSIGNED NOT NULL,
  occurred_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_cash_register_transactions_tenant (cafe_id, id),
  FOREIGN KEY (cafe_id, session_id, currency_code) REFERENCES cash_register_sessions (cafe_id, id, currency_code),
  FOREIGN KEY (cafe_id, payment_id) REFERENCES payments (cafe_id, id),
  FOREIGN KEY (recorded_by_user_id) REFERENCES users (id),
  CONSTRAINT chk_cash_register_tx CHECK (amount <> 0)
);

CREATE TABLE staff_attendance (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  cafe_id BIGINT UNSIGNED NOT NULL,
  branch_id BIGINT UNSIGNED NOT NULL,
  staff_id BIGINT UNSIGNED NOT NULL,
  clock_in_at DATETIME(3) NOT NULL,
  clock_out_at DATETIME(3) NULL,
  source ENUM('self','manager') NOT NULL DEFAULT 'self',
  note VARCHAR(255) NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_staff_attendance_tenant (cafe_id, id),
  KEY idx_staff_attendance_lookup (cafe_id, staff_id, clock_in_at),
  FOREIGN KEY (cafe_id, branch_id) REFERENCES cafe_branches (cafe_id, id),
  FOREIGN KEY (cafe_id, staff_id) REFERENCES cafe_staff (cafe_id, id),
  CONSTRAINT chk_staff_attendance_time CHECK (clock_out_at IS NULL OR clock_out_at >= clock_in_at)
);

-- Records salary paid as a business cost. This is not a payroll or statutory-deduction engine.
CREATE TABLE payroll_entries (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  public_id CHAR(26) COLLATE ascii_bin NOT NULL,
  cafe_id BIGINT UNSIGNED NOT NULL,
  staff_id BIGINT UNSIGNED NOT NULL,
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  currency_code CHAR(3) COLLATE ascii_bin NOT NULL,
  gross_amount DECIMAL(19,4) NOT NULL,
  deductions_amount DECIMAL(19,4) NOT NULL DEFAULT 0,
  net_amount DECIMAL(19,4) NOT NULL,
  paid_on DATE NULL,
  status ENUM('draft','approved','paid','void') NOT NULL DEFAULT 'draft',
  notes VARCHAR(500) NULL,
  created_by_user_id BIGINT UNSIGNED NOT NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_payroll_entries_public_id (public_id),
  UNIQUE KEY uq_payroll_entries_tenant (cafe_id, id),
  UNIQUE KEY uq_payroll_entries_period (cafe_id, staff_id, period_start, period_end),
  FOREIGN KEY (cafe_id, currency_code) REFERENCES cafes (id, currency_code),
  FOREIGN KEY (cafe_id, staff_id) REFERENCES cafe_staff (cafe_id, id),
  FOREIGN KEY (created_by_user_id) REFERENCES users (id),
  CONSTRAINT chk_payroll_amounts CHECK (gross_amount >= 0 AND deductions_amount >= 0 AND net_amount = gross_amount - deductions_amount)
);
