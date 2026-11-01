-- Cafes, branches, staff, RBAC, subscriptions.

CREATE TABLE subscription_plans (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  code VARCHAR(32) COLLATE ascii_bin NOT NULL,
  name VARCHAR(64) NOT NULL,
  description TEXT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 0,
  is_public TINYINT(1) NOT NULL DEFAULT 0,
  trial_days SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  grace_days SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  sort_order SMALLINT NOT NULL DEFAULT 0,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_subscription_plans_code (code)
);

CREATE TABLE plan_prices (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  plan_id BIGINT UNSIGNED NOT NULL,
  currency_code CHAR(3) COLLATE ascii_bin NOT NULL,
  billing_interval ENUM('monthly','yearly') NOT NULL,
  amount DECIMAL(19,4) NOT NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_plan_prices (plan_id, currency_code, billing_interval),
  FOREIGN KEY (plan_id) REFERENCES subscription_plans (id),
  FOREIGN KEY (currency_code) REFERENCES currencies (code),
  CONSTRAINT chk_plan_prices_amount CHECK (amount >= 0)
);

-- limit_value NULL with is_enabled=1 means unlimited.
CREATE TABLE plan_entitlements (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  plan_id BIGINT UNSIGNED NOT NULL,
  feature_key VARCHAR(64) COLLATE ascii_bin NOT NULL,
  is_enabled TINYINT(1) NOT NULL DEFAULT 0,
  limit_value BIGINT UNSIGNED NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_plan_entitlements (plan_id, feature_key),
  FOREIGN KEY (plan_id) REFERENCES subscription_plans (id)
);

CREATE TABLE cafes (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  public_id CHAR(26) COLLATE ascii_bin NOT NULL,
  slug VARCHAR(80) COLLATE ascii_bin NOT NULL,
  owner_user_id BIGINT UNSIGNED NOT NULL,
  legal_name VARCHAR(200) NOT NULL,
  display_name VARCHAR(150) NOT NULL,
  description TEXT NULL,
  status ENUM('pending_approval','active','suspended','rejected','closed') NOT NULL DEFAULT 'pending_approval',
  country_code CHAR(2) COLLATE ascii_bin NOT NULL,
  currency_code CHAR(3) COLLATE ascii_bin NOT NULL,
  default_language_code VARCHAR(12) COLLATE ascii_bin NOT NULL,
  timezone VARCHAR(64) NOT NULL,
  fiscal_year_start_month TINYINT UNSIGNED NOT NULL DEFAULT 1,
  contact_email VARCHAR(254) NULL,
  contact_phone VARCHAR(20) NULL,
  website VARCHAR(255) NULL,
  business_registration_number VARCHAR(64) NULL,
  logo_asset_id BIGINT UNSIGNED NULL,
  cover_asset_id BIGINT UNSIGNED NULL,
  approved_by_user_id BIGINT UNSIGNED NULL,
  approved_at DATETIME(3) NULL,
  suspended_at DATETIME(3) NULL,
  status_reason VARCHAR(500) NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  deleted_at DATETIME(3) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_cafes_public_id (public_id),
  UNIQUE KEY uq_cafes_slug (slug),
  -- Target of (cafe_id, currency_code) FKs: currency cannot change once anything financial exists.
  UNIQUE KEY uq_cafes_id_currency (id, currency_code),
  KEY idx_cafes_status (status),
  FOREIGN KEY (owner_user_id) REFERENCES users (id),
  FOREIGN KEY (approved_by_user_id) REFERENCES users (id),
  FOREIGN KEY (country_code) REFERENCES countries (code),
  FOREIGN KEY (currency_code) REFERENCES currencies (code),
  FOREIGN KEY (default_language_code) REFERENCES languages (code),
  CONSTRAINT chk_cafes_fy CHECK (fiscal_year_start_month BETWEEN 1 AND 12)
);

CREATE TABLE media_assets (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  public_id CHAR(26) COLLATE ascii_bin NOT NULL,
  cafe_id BIGINT UNSIGNED NULL,
  kind ENUM('logo','cover','banner','product_image','document','invoice_pdf','report_export','qr_code','other') NOT NULL,
  storage_key VARCHAR(512) COLLATE ascii_bin NOT NULL,
  mime_type VARCHAR(100) COLLATE ascii_bin NOT NULL,
  byte_size BIGINT UNSIGNED NOT NULL,
  sha256 CHAR(64) COLLATE ascii_bin NULL,
  width INT UNSIGNED NULL,
  height INT UNSIGNED NULL,
  status ENUM('pending','ready','rejected') NOT NULL DEFAULT 'pending',
  uploaded_by_user_id BIGINT UNSIGNED NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  deleted_at DATETIME(3) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_media_assets_public_id (public_id),
  UNIQUE KEY uq_media_assets_tenant (cafe_id, id),
  UNIQUE KEY uq_media_assets_key (storage_key),
  FOREIGN KEY (cafe_id) REFERENCES cafes (id),
  FOREIGN KEY (uploaded_by_user_id) REFERENCES users (id)
);

ALTER TABLE cafes
  ADD FOREIGN KEY (id, logo_asset_id) REFERENCES media_assets (cafe_id, id),
  ADD FOREIGN KEY (id, cover_asset_id) REFERENCES media_assets (cafe_id, id);

CREATE TABLE cafe_translations (
  cafe_id BIGINT UNSIGNED NOT NULL,
  language_code VARCHAR(12) COLLATE ascii_bin NOT NULL,
  display_name VARCHAR(150) NOT NULL,
  description TEXT NULL,
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (cafe_id, language_code),
  FOREIGN KEY (cafe_id) REFERENCES cafes (id),
  FOREIGN KEY (language_code) REFERENCES languages (code)
);

CREATE TABLE cafe_languages (
  cafe_id BIGINT UNSIGNED NOT NULL,
  language_code VARCHAR(12) COLLATE ascii_bin NOT NULL,
  is_enabled TINYINT(1) NOT NULL DEFAULT 1,
  sort_order SMALLINT NOT NULL DEFAULT 0,
  PRIMARY KEY (cafe_id, language_code),
  FOREIGN KEY (cafe_id) REFERENCES cafes (id),
  FOREIGN KEY (language_code) REFERENCES languages (code)
);

CREATE TABLE cafe_branches (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  public_id CHAR(26) COLLATE ascii_bin NOT NULL,
  cafe_id BIGINT UNSIGNED NOT NULL,
  code VARCHAR(20) COLLATE ascii_bin NOT NULL,
  name VARCHAR(150) NOT NULL,
  address_line1 VARCHAR(200) NOT NULL,
  address_line2 VARCHAR(200) NULL,
  city VARCHAR(100) NOT NULL,
  state_code VARCHAR(10) COLLATE ascii_bin NULL,
  state_name VARCHAR(100) NULL,
  postal_code VARCHAR(20) NULL,
  timezone VARCHAR(64) NULL,
  business_day_cutoff TIME NOT NULL DEFAULT '04:00:00',
  phone VARCHAR(20) NULL,
  email VARCHAR(254) NULL,
  latitude DECIMAL(9,6) NULL,
  longitude DECIMAL(9,6) NULL,
  is_main TINYINT(1) NOT NULL DEFAULT 0,
  status ENUM('active','inactive') NOT NULL DEFAULT 'active',
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  deleted_at DATETIME(3) NULL,
  active_marker TINYINT GENERATED ALWAYS AS (IF(deleted_at IS NULL, 1, NULL)) VIRTUAL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_cafe_branches_public_id (public_id),
  UNIQUE KEY uq_cafe_branches_tenant (cafe_id, id),
  UNIQUE KEY uq_cafe_branches_code (cafe_id, code, active_marker),
  FOREIGN KEY (cafe_id) REFERENCES cafes (id)
);

CREATE TABLE cafe_business_hours (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  cafe_id BIGINT UNSIGNED NOT NULL,
  branch_id BIGINT UNSIGNED NOT NULL,
  weekday TINYINT UNSIGNED NOT NULL,
  opens_at TIME NOT NULL,
  closes_at TIME NOT NULL,
  closes_next_day TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  UNIQUE KEY uq_cafe_business_hours_tenant (cafe_id, id),
  UNIQUE KEY uq_cafe_business_hours (branch_id, weekday, opens_at),
  FOREIGN KEY (cafe_id, branch_id) REFERENCES cafe_branches (cafe_id, id),
  CONSTRAINT chk_business_hours_weekday CHECK (weekday <= 6)
);

CREATE TABLE cafe_settings (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  cafe_id BIGINT UNSIGNED NOT NULL,
  setting_key VARCHAR(100) COLLATE ascii_bin NOT NULL,
  value JSON NOT NULL,
  updated_by_user_id BIGINT UNSIGNED NULL,
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_cafe_settings_tenant (cafe_id, id),
  UNIQUE KEY uq_cafe_settings (cafe_id, setting_key),
  FOREIGN KEY (cafe_id) REFERENCES cafes (id),
  FOREIGN KEY (updated_by_user_id) REFERENCES users (id)
);

CREATE TABLE cafe_themes (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  cafe_id BIGINT UNSIGNED NOT NULL,
  primary_color CHAR(7) COLLATE ascii_bin NOT NULL,
  secondary_color CHAR(7) COLLATE ascii_bin NOT NULL,
  background_color CHAR(7) COLLATE ascii_bin NOT NULL,
  text_color CHAR(7) COLLATE ascii_bin NOT NULL,
  font_key VARCHAR(40) COLLATE ascii_bin NOT NULL,
  button_style ENUM('rounded','pill','square') NOT NULL DEFAULT 'rounded',
  menu_layout ENUM('list','grid','compact') NOT NULL DEFAULT 'list',
  theme_mode ENUM('light','dark','system') NOT NULL DEFAULT 'light',
  version INT UNSIGNED NOT NULL DEFAULT 1,
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_cafe_themes_tenant (cafe_id, id),
  UNIQUE KEY uq_cafe_themes_cafe (cafe_id),
  FOREIGN KEY (cafe_id) REFERENCES cafes (id),
  CONSTRAINT chk_cafe_themes_primary CHECK (REGEXP_LIKE(primary_color, '^#[0-9A-Fa-f]{6}$')),
  CONSTRAINT chk_cafe_themes_secondary CHECK (REGEXP_LIKE(secondary_color, '^#[0-9A-Fa-f]{6}$')),
  CONSTRAINT chk_cafe_themes_background CHECK (REGEXP_LIKE(background_color, '^#[0-9A-Fa-f]{6}$')),
  CONSTRAINT chk_cafe_themes_text CHECK (REGEXP_LIKE(text_color, '^#[0-9A-Fa-f]{6}$'))
);

CREATE TABLE cafe_staff (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  public_id CHAR(26) COLLATE ascii_bin NOT NULL,
  cafe_id BIGINT UNSIGNED NOT NULL,
  user_id BIGINT UNSIGNED NOT NULL,
  employee_code VARCHAR(32) NULL,
  job_title VARCHAR(100) NULL,
  status ENUM('invited','active','inactive') NOT NULL DEFAULT 'invited',
  hired_on DATE NULL,
  ended_on DATE NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_cafe_staff_public_id (public_id),
  UNIQUE KEY uq_cafe_staff_tenant (cafe_id, id),
  UNIQUE KEY uq_cafe_staff_user (cafe_id, user_id),
  UNIQUE KEY uq_cafe_staff_code (cafe_id, employee_code),
  FOREIGN KEY (cafe_id) REFERENCES cafes (id),
  FOREIGN KEY (user_id) REFERENCES users (id)
);

CREATE TABLE permissions (
  code VARCHAR(64) COLLATE ascii_bin NOT NULL,
  module VARCHAR(40) COLLATE ascii_bin NOT NULL,
  scope ENUM('platform','cafe') NOT NULL,
  description VARCHAR(200) NOT NULL,
  PRIMARY KEY (code)
);

-- cafe_id NULL: system role available to all cafes or to the platform.
CREATE TABLE roles (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  cafe_id BIGINT UNSIGNED NULL,
  cafe_key BIGINT UNSIGNED GENERATED ALWAYS AS (IFNULL(cafe_id, 0)) VIRTUAL,
  code VARCHAR(40) COLLATE ascii_bin NOT NULL,
  name VARCHAR(80) NOT NULL,
  scope ENUM('platform','cafe') NOT NULL,
  is_system TINYINT(1) NOT NULL DEFAULT 0,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  deleted_at DATETIME(3) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_roles_tenant (cafe_id, id),
  UNIQUE KEY uq_roles_code (cafe_key, code),
  FOREIGN KEY (cafe_id) REFERENCES cafes (id)
);

CREATE TABLE role_permissions (
  role_id BIGINT UNSIGNED NOT NULL,
  permission_code VARCHAR(64) COLLATE ascii_bin NOT NULL,
  PRIMARY KEY (role_id, permission_code),
  FOREIGN KEY (role_id) REFERENCES roles (id),
  FOREIGN KEY (permission_code) REFERENCES permissions (code)
);

-- Platform roles: cafe_id NULL. Cafe roles: must be active staff (composite FK). branch_id NULL means all branches.
CREATE TABLE user_roles (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  role_id BIGINT UNSIGNED NOT NULL,
  cafe_id BIGINT UNSIGNED NULL,
  branch_id BIGINT UNSIGNED NULL,
  cafe_key BIGINT UNSIGNED GENERATED ALWAYS AS (IFNULL(cafe_id, 0)) VIRTUAL,
  branch_key BIGINT UNSIGNED GENERATED ALWAYS AS (IFNULL(branch_id, 0)) VIRTUAL,
  granted_by_user_id BIGINT UNSIGNED NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_user_roles (user_id, role_id, cafe_key, branch_key),
  FOREIGN KEY (user_id) REFERENCES users (id),
  FOREIGN KEY (role_id) REFERENCES roles (id),
  FOREIGN KEY (cafe_id, user_id) REFERENCES cafe_staff (cafe_id, user_id),
  FOREIGN KEY (cafe_id, branch_id) REFERENCES cafe_branches (cafe_id, id),
  FOREIGN KEY (granted_by_user_id) REFERENCES users (id),
  CONSTRAINT chk_user_roles_branch CHECK (branch_id IS NULL OR cafe_id IS NOT NULL)
);

CREATE TABLE cafe_subscriptions (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  public_id CHAR(26) COLLATE ascii_bin NOT NULL,
  cafe_id BIGINT UNSIGNED NOT NULL,
  plan_id BIGINT UNSIGNED NOT NULL,
  status ENUM('trialing','active','past_due','grace','cancelled','expired') NOT NULL,
  billing_interval ENUM('monthly','yearly') NOT NULL,
  currency_code CHAR(3) COLLATE ascii_bin NOT NULL,
  price_amount DECIMAL(19,4) NOT NULL,
  trial_ends_at DATETIME(3) NULL,
  current_period_start DATETIME(3) NOT NULL,
  current_period_end DATETIME(3) NOT NULL,
  grace_ends_at DATETIME(3) NULL,
  cancel_at_period_end TINYINT(1) NOT NULL DEFAULT 0,
  cancelled_at DATETIME(3) NULL,
  provider_code VARCHAR(32) COLLATE ascii_bin NULL,
  provider_subscription_ref VARCHAR(191) COLLATE ascii_bin NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_cafe_subscriptions_public_id (public_id),
  UNIQUE KEY uq_cafe_subscriptions_tenant (cafe_id, id),
  KEY idx_cafe_subscriptions_status (status, current_period_end),
  FOREIGN KEY (cafe_id) REFERENCES cafes (id),
  FOREIGN KEY (plan_id) REFERENCES subscription_plans (id),
  FOREIGN KEY (currency_code) REFERENCES currencies (code),
  FOREIGN KEY (provider_code) REFERENCES payment_providers (code),
  CONSTRAINT chk_cafe_subscriptions_price CHECK (price_amount >= 0)
);

CREATE TABLE subscription_invoices (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  public_id CHAR(26) COLLATE ascii_bin NOT NULL,
  cafe_id BIGINT UNSIGNED NOT NULL,
  subscription_id BIGINT UNSIGNED NOT NULL,
  invoice_number VARCHAR(40) NOT NULL,
  status ENUM('open','paid','failed','void') NOT NULL DEFAULT 'open',
  currency_code CHAR(3) COLLATE ascii_bin NOT NULL,
  subtotal_amount DECIMAL(19,4) NOT NULL,
  tax_amount DECIMAL(19,4) NOT NULL DEFAULT 0,
  total_amount DECIMAL(19,4) NOT NULL,
  period_start DATETIME(3) NOT NULL,
  period_end DATETIME(3) NOT NULL,
  due_at DATETIME(3) NOT NULL,
  paid_at DATETIME(3) NULL,
  provider_payment_ref VARCHAR(191) COLLATE ascii_bin NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_subscription_invoices_public_id (public_id),
  UNIQUE KEY uq_subscription_invoices_tenant (cafe_id, id),
  UNIQUE KEY uq_subscription_invoices_number (invoice_number),
  FOREIGN KEY (cafe_id, subscription_id) REFERENCES cafe_subscriptions (cafe_id, id),
  FOREIGN KEY (currency_code) REFERENCES currencies (code)
);

-- cafe_id NULL: platform-wide default.
CREATE TABLE commission_configs (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  cafe_id BIGINT UNSIGNED NULL,
  rate_percent DECIMAL(9,6) NOT NULL DEFAULT 0,
  valid_from DATETIME(3) NOT NULL,
  valid_to DATETIME(3) NULL,
  created_by_user_id BIGINT UNSIGNED NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_commission_configs_tenant (cafe_id, id),
  FOREIGN KEY (cafe_id) REFERENCES cafes (id),
  FOREIGN KEY (created_by_user_id) REFERENCES users (id),
  CONSTRAINT chk_commission_rate CHECK (rate_percent BETWEEN 0 AND 100)
);

-- Append-only platform money movements (triggers in 0012).
CREATE TABLE platform_transactions (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  public_id CHAR(26) COLLATE ascii_bin NOT NULL,
  cafe_id BIGINT UNSIGNED NULL,
  transaction_type ENUM('subscription','commission','refund','adjustment') NOT NULL,
  direction ENUM('credit','debit') NOT NULL,
  currency_code CHAR(3) COLLATE ascii_bin NOT NULL,
  amount DECIMAL(19,4) NOT NULL,
  source_type VARCHAR(40) COLLATE ascii_bin NULL,
  source_id BIGINT UNSIGNED NULL,
  note VARCHAR(255) NULL,
  occurred_at DATETIME(3) NOT NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_platform_transactions_public_id (public_id),
  KEY idx_platform_transactions_time (occurred_at),
  FOREIGN KEY (cafe_id) REFERENCES cafes (id),
  FOREIGN KEY (currency_code) REFERENCES currencies (code),
  CONSTRAINT chk_platform_transactions_amount CHECK (amount > 0)
);

CREATE TABLE cafe_usage_counters (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  cafe_id BIGINT UNSIGNED NOT NULL,
  feature_key VARCHAR(64) COLLATE ascii_bin NOT NULL,
  period_start DATE NOT NULL,
  value BIGINT UNSIGNED NOT NULL DEFAULT 0,
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_cafe_usage_counters_tenant (cafe_id, id),
  UNIQUE KEY uq_cafe_usage_counters (cafe_id, feature_key, period_start),
  FOREIGN KEY (cafe_id) REFERENCES cafes (id)
);

-- Tax registration is per branch where the law works that way (Indian GSTIN is per state).
CREATE TABLE tax_registrations (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  cafe_id BIGINT UNSIGNED NOT NULL,
  branch_id BIGINT UNSIGNED NULL,
  tax_system VARCHAR(32) COLLATE ascii_bin NOT NULL,
  registration_number VARCHAR(64) COLLATE ascii_bin NOT NULL,
  legal_name VARCHAR(200) NOT NULL,
  region_code VARCHAR(10) COLLATE ascii_bin NULL,
  valid_from DATE NOT NULL,
  valid_to DATE NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_tax_registrations_tenant (cafe_id, id),
  FOREIGN KEY (cafe_id) REFERENCES cafes (id),
  FOREIGN KEY (cafe_id, branch_id) REFERENCES cafe_branches (cafe_id, id)
);

CREATE TABLE tax_categories (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  cafe_id BIGINT UNSIGNED NOT NULL,
  code VARCHAR(32) COLLATE ascii_bin NOT NULL,
  name VARCHAR(100) NOT NULL,
  tax_code VARCHAR(20) COLLATE ascii_bin NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_tax_categories_tenant (cafe_id, id),
  UNIQUE KEY uq_tax_categories_code (cafe_id, code),
  FOREIGN KEY (cafe_id) REFERENCES cafes (id)
);

CREATE TABLE tax_rates (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  cafe_id BIGINT UNSIGNED NOT NULL,
  tax_category_id BIGINT UNSIGNED NOT NULL,
  component_code VARCHAR(16) COLLATE ascii_bin NOT NULL,
  display_name VARCHAR(60) NOT NULL,
  rate_percent DECIMAL(9,6) NOT NULL,
  applies_to ENUM('always','intra_region','inter_region') NOT NULL DEFAULT 'always',
  valid_from DATE NOT NULL,
  valid_to DATE NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_tax_rates_tenant (cafe_id, id),
  KEY idx_tax_rates_lookup (cafe_id, tax_category_id, valid_from),
  FOREIGN KEY (cafe_id, tax_category_id) REFERENCES tax_categories (cafe_id, id),
  CONSTRAINT chk_tax_rates_rate CHECK (rate_percent BETWEEN 0 AND 100),
  CONSTRAINT chk_tax_rates_validity CHECK (valid_to IS NULL OR valid_to >= valid_from)
);
