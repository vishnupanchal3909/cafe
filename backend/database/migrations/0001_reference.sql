-- Global reference data. No tenant ownership.

CREATE TABLE languages (
  code VARCHAR(12) COLLATE ascii_bin NOT NULL,
  name VARCHAR(64) NOT NULL,
  native_name VARCHAR(64) NOT NULL,
  direction ENUM('ltr','rtl') NOT NULL DEFAULT 'ltr',
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  sort_order SMALLINT NOT NULL DEFAULT 0,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (code)
);

CREATE TABLE currencies (
  code CHAR(3) COLLATE ascii_bin NOT NULL,
  numeric_code CHAR(3) COLLATE ascii_bin NOT NULL,
  name VARCHAR(64) NOT NULL,
  symbol VARCHAR(8) NOT NULL,
  minor_unit TINYINT UNSIGNED NOT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (code),
  CONSTRAINT chk_currencies_code CHECK (REGEXP_LIKE(code, '^[A-Z]{3}$', 'c')),
  CONSTRAINT chk_currencies_minor_unit CHECK (minor_unit <= 4)
);

CREATE TABLE countries (
  code CHAR(2) COLLATE ascii_bin NOT NULL,
  name VARCHAR(100) NOT NULL,
  default_currency_code CHAR(3) COLLATE ascii_bin NOT NULL,
  default_language_code VARCHAR(12) COLLATE ascii_bin NOT NULL,
  default_timezone VARCHAR(64) NOT NULL,
  fiscal_year_start_month TINYINT UNSIGNED NOT NULL DEFAULT 1,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (code),
  FOREIGN KEY (default_currency_code) REFERENCES currencies (code),
  FOREIGN KEY (default_language_code) REFERENCES languages (code),
  CONSTRAINT chk_countries_fy CHECK (fiscal_year_start_month BETWEEN 1 AND 12)
);

-- System text keyed by stable identifier (validation messages, server-sent labels).
CREATE TABLE translations (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  namespace VARCHAR(64) COLLATE ascii_bin NOT NULL,
  translation_key VARCHAR(191) COLLATE ascii_bin NOT NULL,
  language_code VARCHAR(12) COLLATE ascii_bin NOT NULL,
  value TEXT NOT NULL,
  is_reviewed TINYINT(1) NOT NULL DEFAULT 0,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_translations (namespace, translation_key, language_code),
  FOREIGN KEY (language_code) REFERENCES languages (code)
);

CREATE TABLE units (
  code VARCHAR(12) COLLATE ascii_bin NOT NULL,
  name VARCHAR(40) NOT NULL,
  dimension ENUM('mass','volume','count') NOT NULL,
  factor_to_base DECIMAL(18,6) NOT NULL,
  PRIMARY KEY (code),
  CONSTRAINT chk_units_factor CHECK (factor_to_base > 0)
);

-- Tax structure per country. Deliberately holds no rates: rates are per-cafe configuration.
CREATE TABLE tax_component_definitions (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  country_code CHAR(2) COLLATE ascii_bin NOT NULL,
  code VARCHAR(16) COLLATE ascii_bin NOT NULL,
  name VARCHAR(100) NOT NULL,
  applies_to ENUM('always','intra_region','inter_region') NOT NULL DEFAULT 'always',
  PRIMARY KEY (id),
  UNIQUE KEY uq_tax_component_def (country_code, code),
  FOREIGN KEY (country_code) REFERENCES countries (code)
);

CREATE TABLE payment_providers (
  code VARCHAR(32) COLLATE ascii_bin NOT NULL,
  name VARCHAR(64) NOT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (code)
);

CREATE TABLE payment_methods (
  code VARCHAR(32) COLLATE ascii_bin NOT NULL,
  name VARCHAR(64) NOT NULL,
  is_manual TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (code)
);

CREATE TABLE coa_templates (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  code VARCHAR(32) COLLATE ascii_bin NOT NULL,
  name VARCHAR(100) NOT NULL,
  country_code CHAR(2) COLLATE ascii_bin NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_coa_templates_code (code),
  FOREIGN KEY (country_code) REFERENCES countries (code)
);

CREATE TABLE coa_template_accounts (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  template_id BIGINT UNSIGNED NOT NULL,
  code VARCHAR(20) COLLATE ascii_bin NOT NULL,
  name VARCHAR(120) NOT NULL,
  account_type ENUM('asset','liability','equity','revenue','expense') NOT NULL,
  system_key VARCHAR(40) COLLATE ascii_bin NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_coa_template_accounts (template_id, code),
  FOREIGN KEY (template_id) REFERENCES coa_templates (id)
);
