-- Physical tables, QR codes, sessions, reservations and the tenant view of a customer.

CREATE TABLE cafe_tables (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  public_id CHAR(26) COLLATE ascii_bin NOT NULL,
  cafe_id BIGINT UNSIGNED NOT NULL,
  branch_id BIGINT UNSIGNED NOT NULL,
  table_number VARCHAR(20) NOT NULL,
  area_name VARCHAR(60) NULL,
  capacity SMALLINT UNSIGNED NOT NULL DEFAULT 2,
  status ENUM('available','occupied','reserved','cleaning','inactive') NOT NULL DEFAULT 'available',
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  deleted_at DATETIME(3) NULL,
  active_marker TINYINT GENERATED ALWAYS AS (IF(deleted_at IS NULL, 1, NULL)) VIRTUAL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_cafe_tables_public_id (public_id),
  UNIQUE KEY uq_cafe_tables_tenant (cafe_id, id),
  UNIQUE KEY uq_cafe_tables_branch_scope (cafe_id, branch_id, id),
  UNIQUE KEY uq_cafe_tables_number (cafe_id, branch_id, table_number, active_marker),
  FOREIGN KEY (cafe_id, branch_id) REFERENCES cafe_branches (cafe_id, id),
  CONSTRAINT chk_cafe_tables_capacity CHECK (capacity > 0)
);

-- token_hash is the lookup; token_ciphertext allows re-download of the printed code.
CREATE TABLE table_qr_codes (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  cafe_id BIGINT UNSIGNED NOT NULL,
  table_id BIGINT UNSIGNED NOT NULL,
  token_hash CHAR(64) COLLATE ascii_bin NOT NULL,
  token_ciphertext VARBINARY(512) NOT NULL,
  encryption_key_id VARCHAR(40) COLLATE ascii_bin NOT NULL,
  revoked_at DATETIME(3) NULL,
  revoked_by_user_id BIGINT UNSIGNED NULL,
  created_by_user_id BIGINT UNSIGNED NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  active_table_key BIGINT UNSIGNED GENERATED ALWAYS AS (IF(revoked_at IS NULL, table_id, NULL)) VIRTUAL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_table_qr_codes_tenant (cafe_id, id),
  UNIQUE KEY uq_table_qr_codes_hash (token_hash),
  -- At most one live QR per table.
  UNIQUE KEY uq_table_qr_codes_active (active_table_key),
  FOREIGN KEY (cafe_id, table_id) REFERENCES cafe_tables (cafe_id, id),
  FOREIGN KEY (revoked_by_user_id) REFERENCES users (id),
  FOREIGN KEY (created_by_user_id) REFERENCES users (id)
);

CREATE TABLE table_sessions (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  public_id CHAR(26) COLLATE ascii_bin NOT NULL,
  cafe_id BIGINT UNSIGNED NOT NULL,
  branch_id BIGINT UNSIGNED NOT NULL,
  table_id BIGINT UNSIGNED NOT NULL,
  token_hash CHAR(64) COLLATE ascii_bin NOT NULL,
  status ENUM('open','closing','closed') NOT NULL DEFAULT 'open',
  party_size SMALLINT UNSIGNED NULL,
  opened_by_user_id BIGINT UNSIGNED NULL,
  opened_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  closed_by_user_id BIGINT UNSIGNED NULL,
  closed_at DATETIME(3) NULL,
  expires_at DATETIME(3) NOT NULL,
  active_table_key BIGINT UNSIGNED GENERATED ALWAYS AS (IF(status <> 'closed', table_id, NULL)) VIRTUAL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_table_sessions_public_id (public_id),
  UNIQUE KEY uq_table_sessions_tenant (cafe_id, id),
  UNIQUE KEY uq_table_sessions_hash (token_hash),
  -- One open session per table; merges are in table_session_tables.
  UNIQUE KEY uq_table_sessions_active (active_table_key),
  FOREIGN KEY (cafe_id, branch_id, table_id) REFERENCES cafe_tables (cafe_id, branch_id, id),
  FOREIGN KEY (opened_by_user_id) REFERENCES users (id),
  FOREIGN KEY (closed_by_user_id) REFERENCES users (id)
);

-- Tables merged into a session beyond its primary table.
CREATE TABLE table_session_tables (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  cafe_id BIGINT UNSIGNED NOT NULL,
  session_id BIGINT UNSIGNED NOT NULL,
  table_id BIGINT UNSIGNED NOT NULL,
  merged_by_user_id BIGINT UNSIGNED NOT NULL,
  merged_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  unmerged_at DATETIME(3) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_table_session_tables_tenant (cafe_id, id),
  UNIQUE KEY uq_table_session_tables (session_id, table_id),
  FOREIGN KEY (cafe_id, session_id) REFERENCES table_sessions (cafe_id, id),
  FOREIGN KEY (cafe_id, table_id) REFERENCES cafe_tables (cafe_id, id),
  FOREIGN KEY (merged_by_user_id) REFERENCES users (id)
);

-- A cafe can only reach a global customer through this row.
CREATE TABLE cafe_customers (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  public_id CHAR(26) COLLATE ascii_bin NOT NULL,
  cafe_id BIGINT UNSIGNED NOT NULL,
  customer_id BIGINT UNSIGNED NOT NULL,
  marketing_consent_at DATETIME(3) NULL,
  marketing_opt_out_at DATETIME(3) NULL,
  first_order_at DATETIME(3) NULL,
  last_order_at DATETIME(3) NULL,
  total_orders INT UNSIGNED NOT NULL DEFAULT 0,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_cafe_customers_public_id (public_id),
  UNIQUE KEY uq_cafe_customers_tenant (cafe_id, id),
  UNIQUE KEY uq_cafe_customers_link (cafe_id, customer_id),
  KEY idx_cafe_customers_recent (cafe_id, last_order_at),
  FOREIGN KEY (cafe_id) REFERENCES cafes (id),
  FOREIGN KEY (customer_id) REFERENCES customers (id)
);

CREATE TABLE customer_favorites (
  customer_id BIGINT UNSIGNED NOT NULL,
  cafe_id BIGINT UNSIGNED NOT NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (customer_id, cafe_id),
  FOREIGN KEY (customer_id) REFERENCES customers (id),
  FOREIGN KEY (cafe_id) REFERENCES cafes (id)
);

CREATE TABLE customer_wishlist_items (
  customer_id BIGINT UNSIGNED NOT NULL,
  cafe_id BIGINT UNSIGNED NOT NULL,
  product_id BIGINT UNSIGNED NOT NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (customer_id, product_id),
  FOREIGN KEY (customer_id) REFERENCES customers (id),
  FOREIGN KEY (cafe_id, product_id) REFERENCES products (cafe_id, id)
);

CREATE TABLE reservations (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  public_id CHAR(26) COLLATE ascii_bin NOT NULL,
  cafe_id BIGINT UNSIGNED NOT NULL,
  branch_id BIGINT UNSIGNED NOT NULL,
  table_id BIGINT UNSIGNED NULL,
  customer_id BIGINT UNSIGNED NULL,
  guest_name VARCHAR(150) NULL,
  guest_phone VARCHAR(20) NULL,
  party_size SMALLINT UNSIGNED NOT NULL,
  starts_at DATETIME(3) NOT NULL,
  ends_at DATETIME(3) NOT NULL,
  status ENUM('requested','confirmed','seated','completed','cancelled','no_show') NOT NULL DEFAULT 'requested',
  notes VARCHAR(500) NULL,
  created_by_user_id BIGINT UNSIGNED NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_reservations_public_id (public_id),
  UNIQUE KEY uq_reservations_tenant (cafe_id, id),
  KEY idx_reservations_time (cafe_id, branch_id, starts_at),
  FOREIGN KEY (cafe_id, branch_id) REFERENCES cafe_branches (cafe_id, id),
  FOREIGN KEY (cafe_id, branch_id, table_id) REFERENCES cafe_tables (cafe_id, branch_id, id),
  FOREIGN KEY (cafe_id, customer_id) REFERENCES cafe_customers (cafe_id, customer_id),
  FOREIGN KEY (created_by_user_id) REFERENCES users (id),
  CONSTRAINT chk_reservations_time CHECK (ends_at > starts_at),
  CONSTRAINT chk_reservations_party CHECK (party_size > 0)
);

CREATE TABLE service_requests (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  public_id CHAR(26) COLLATE ascii_bin NOT NULL,
  cafe_id BIGINT UNSIGNED NOT NULL,
  branch_id BIGINT UNSIGNED NOT NULL,
  table_id BIGINT UNSIGNED NOT NULL,
  session_id BIGINT UNSIGNED NULL,
  request_type ENUM('waiter','bill','staff') NOT NULL,
  status ENUM('open','acknowledged','resolved') NOT NULL DEFAULT 'open',
  acknowledged_by_user_id BIGINT UNSIGNED NULL,
  acknowledged_at DATETIME(3) NULL,
  resolved_at DATETIME(3) NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_service_requests_public_id (public_id),
  UNIQUE KEY uq_service_requests_tenant (cafe_id, id),
  KEY idx_service_requests_open (cafe_id, branch_id, status, created_at),
  FOREIGN KEY (cafe_id, branch_id, table_id) REFERENCES cafe_tables (cafe_id, branch_id, id),
  FOREIGN KEY (cafe_id, session_id) REFERENCES table_sessions (cafe_id, id),
  FOREIGN KEY (acknowledged_by_user_id) REFERENCES users (id)
);
