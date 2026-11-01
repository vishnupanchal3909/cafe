-- Staff/admin accounts and customer accounts are deliberately separate (ADR-14).

CREATE TABLE users (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  public_id CHAR(26) COLLATE ascii_bin NOT NULL,
  email VARCHAR(254) NOT NULL,
  phone VARCHAR(20) NULL,
  password_hash VARCHAR(255) NOT NULL,
  full_name VARCHAR(150) NOT NULL,
  preferred_language_code VARCHAR(12) COLLATE ascii_bin NULL,
  status ENUM('active','disabled','pending_verification') NOT NULL DEFAULT 'pending_verification',
  is_platform_user TINYINT(1) NOT NULL DEFAULT 0,
  email_verified_at DATETIME(3) NULL,
  mfa_secret_ciphertext VARBINARY(512) NULL,
  mfa_enabled_at DATETIME(3) NULL,
  password_changed_at DATETIME(3) NULL,
  failed_login_count INT UNSIGNED NOT NULL DEFAULT 0,
  locked_until DATETIME(3) NULL,
  last_login_at DATETIME(3) NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  deleted_at DATETIME(3) NULL,
  active_marker TINYINT GENERATED ALWAYS AS (IF(deleted_at IS NULL, 1, NULL)) VIRTUAL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_users_public_id (public_id),
  UNIQUE KEY uq_users_email_active (email, active_marker),
  FOREIGN KEY (preferred_language_code) REFERENCES languages (code)
);

CREATE TABLE customers (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  public_id CHAR(26) COLLATE ascii_bin NOT NULL,
  email VARCHAR(254) NULL,
  phone VARCHAR(20) NULL,
  password_hash VARCHAR(255) NULL,
  full_name VARCHAR(150) NULL,
  preferred_language_code VARCHAR(12) COLLATE ascii_bin NULL,
  is_guest TINYINT(1) NOT NULL DEFAULT 1,
  status ENUM('active','disabled') NOT NULL DEFAULT 'active',
  email_verified_at DATETIME(3) NULL,
  phone_verified_at DATETIME(3) NULL,
  failed_login_count INT UNSIGNED NOT NULL DEFAULT 0,
  locked_until DATETIME(3) NULL,
  last_login_at DATETIME(3) NULL,
  anonymized_at DATETIME(3) NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  deleted_at DATETIME(3) NULL,
  active_marker TINYINT GENERATED ALWAYS AS (IF(deleted_at IS NULL, 1, NULL)) VIRTUAL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_customers_public_id (public_id),
  UNIQUE KEY uq_customers_email_active (email, active_marker),
  UNIQUE KEY uq_customers_phone_active (phone, active_marker),
  FOREIGN KEY (preferred_language_code) REFERENCES languages (code)
);

CREATE TABLE customer_identities (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  customer_id BIGINT UNSIGNED NOT NULL,
  provider VARCHAR(32) COLLATE ascii_bin NOT NULL,
  provider_subject VARCHAR(191) COLLATE ascii_bin NOT NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_customer_identity (provider, provider_subject),
  FOREIGN KEY (customer_id) REFERENCES customers (id)
);

CREATE TABLE customer_addresses (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  public_id CHAR(26) COLLATE ascii_bin NOT NULL,
  customer_id BIGINT UNSIGNED NOT NULL,
  label VARCHAR(40) NULL,
  address_line1 VARCHAR(200) NOT NULL,
  address_line2 VARCHAR(200) NULL,
  city VARCHAR(100) NOT NULL,
  state_name VARCHAR(100) NULL,
  postal_code VARCHAR(20) NULL,
  country_code CHAR(2) COLLATE ascii_bin NOT NULL,
  latitude DECIMAL(9,6) NULL,
  longitude DECIMAL(9,6) NULL,
  is_default TINYINT(1) NOT NULL DEFAULT 0,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  deleted_at DATETIME(3) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_customer_addresses_public_id (public_id),
  FOREIGN KEY (customer_id) REFERENCES customers (id),
  FOREIGN KEY (country_code) REFERENCES countries (code)
);

CREATE TABLE login_sessions (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  public_id CHAR(26) COLLATE ascii_bin NOT NULL,
  user_id BIGINT UNSIGNED NULL,
  customer_id BIGINT UNSIGNED NULL,
  audience ENUM('platform','cafe','kitchen','customer') NOT NULL,
  device_label VARCHAR(120) NULL,
  ip_address VARCHAR(45) COLLATE ascii_bin NULL,
  user_agent VARCHAR(400) NULL,
  last_seen_at DATETIME(3) NULL,
  expires_at DATETIME(3) NOT NULL,
  revoked_at DATETIME(3) NULL,
  revoke_reason VARCHAR(60) NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_login_sessions_public_id (public_id),
  KEY idx_login_sessions_expires (expires_at),
  FOREIGN KEY (user_id) REFERENCES users (id),
  FOREIGN KEY (customer_id) REFERENCES customers (id),
  CONSTRAINT chk_login_sessions_subject CHECK ((user_id IS NULL) <> (customer_id IS NULL))
);

CREATE TABLE refresh_tokens (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  session_id BIGINT UNSIGNED NOT NULL,
  family_id CHAR(26) COLLATE ascii_bin NOT NULL,
  token_hash CHAR(64) COLLATE ascii_bin NOT NULL,
  replaced_by_id BIGINT UNSIGNED NULL,
  used_at DATETIME(3) NULL,
  revoked_at DATETIME(3) NULL,
  expires_at DATETIME(3) NOT NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_refresh_tokens_hash (token_hash),
  KEY idx_refresh_tokens_family (family_id),
  KEY idx_refresh_tokens_expires (expires_at),
  FOREIGN KEY (session_id) REFERENCES login_sessions (id),
  FOREIGN KEY (replaced_by_id) REFERENCES refresh_tokens (id)
);

CREATE TABLE login_attempts (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  identifier_hash CHAR(64) COLLATE ascii_bin NOT NULL,
  audience ENUM('platform','cafe','kitchen','customer') NOT NULL,
  ip_address VARCHAR(45) COLLATE ascii_bin NULL,
  was_successful TINYINT(1) NOT NULL,
  failure_reason VARCHAR(40) NULL,
  occurred_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  KEY idx_login_attempts_identifier (identifier_hash, occurred_at),
  KEY idx_login_attempts_ip (ip_address, occurred_at)
);

-- One-time tokens: password reset, email verification, staff invitation.
CREATE TABLE user_tokens (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NULL,
  customer_id BIGINT UNSIGNED NULL,
  purpose ENUM('password_reset','email_verification','staff_invitation') NOT NULL,
  token_hash CHAR(64) COLLATE ascii_bin NOT NULL,
  expires_at DATETIME(3) NOT NULL,
  used_at DATETIME(3) NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_user_tokens_hash (token_hash),
  FOREIGN KEY (user_id) REFERENCES users (id),
  FOREIGN KEY (customer_id) REFERENCES customers (id),
  CONSTRAINT chk_user_tokens_subject CHECK ((user_id IS NULL) <> (customer_id IS NULL))
);

CREATE TABLE exchange_rates (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  base_currency_code CHAR(3) COLLATE ascii_bin NOT NULL,
  quote_currency_code CHAR(3) COLLATE ascii_bin NOT NULL,
  rate DECIMAL(24,10) NOT NULL,
  provider VARCHAR(64) NOT NULL,
  effective_at DATETIME(3) NOT NULL,
  created_by_user_id BIGINT UNSIGNED NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_exchange_rates (base_currency_code, quote_currency_code, provider, effective_at),
  KEY idx_exchange_rates_lookup (base_currency_code, quote_currency_code, effective_at),
  FOREIGN KEY (base_currency_code) REFERENCES currencies (code),
  FOREIGN KEY (quote_currency_code) REFERENCES currencies (code),
  FOREIGN KEY (created_by_user_id) REFERENCES users (id),
  CONSTRAINT chk_exchange_rates_positive CHECK (rate > 0),
  CONSTRAINT chk_exchange_rates_pair CHECK (base_currency_code <> quote_currency_code)
);
