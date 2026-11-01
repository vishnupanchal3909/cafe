-- Carts, orders, kitchen. Cart items hold no prices: prices are computed by the server at placement.

CREATE TABLE carts (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  public_id CHAR(26) COLLATE ascii_bin NOT NULL,
  cafe_id BIGINT UNSIGNED NOT NULL,
  branch_id BIGINT UNSIGNED NOT NULL,
  session_id BIGINT UNSIGNED NULL,
  customer_id BIGINT UNSIGNED NULL,
  status ENUM('active','converted','abandoned') NOT NULL DEFAULT 'active',
  coupon_code VARCHAR(40) NULL,
  expires_at DATETIME(3) NOT NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_carts_public_id (public_id),
  UNIQUE KEY uq_carts_tenant (cafe_id, id),
  KEY idx_carts_expiry (status, expires_at),
  FOREIGN KEY (cafe_id, branch_id) REFERENCES cafe_branches (cafe_id, id),
  FOREIGN KEY (cafe_id, session_id) REFERENCES table_sessions (cafe_id, id),
  FOREIGN KEY (cafe_id, customer_id) REFERENCES cafe_customers (cafe_id, customer_id)
);

CREATE TABLE cart_items (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  cafe_id BIGINT UNSIGNED NOT NULL,
  cart_id BIGINT UNSIGNED NOT NULL,
  product_id BIGINT UNSIGNED NOT NULL,
  variant_id BIGINT UNSIGNED NULL,
  quantity INT UNSIGNED NOT NULL,
  notes VARCHAR(500) NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_cart_items_tenant (cafe_id, id),
  FOREIGN KEY (cafe_id, cart_id) REFERENCES carts (cafe_id, id),
  FOREIGN KEY (cafe_id, product_id) REFERENCES products (cafe_id, id),
  FOREIGN KEY (cafe_id, product_id, variant_id) REFERENCES product_variants (cafe_id, product_id, id),
  CONSTRAINT chk_cart_items_qty CHECK (quantity > 0)
);

CREATE TABLE cart_item_addons (
  cafe_id BIGINT UNSIGNED NOT NULL,
  cart_item_id BIGINT UNSIGNED NOT NULL,
  addon_id BIGINT UNSIGNED NOT NULL,
  quantity INT UNSIGNED NOT NULL DEFAULT 1,
  PRIMARY KEY (cart_item_id, addon_id),
  FOREIGN KEY (cafe_id, cart_item_id) REFERENCES cart_items (cafe_id, id),
  FOREIGN KEY (cafe_id, addon_id) REFERENCES product_addons (cafe_id, id),
  CONSTRAINT chk_cart_item_addons_qty CHECK (quantity > 0)
);

CREATE TABLE order_sequences (
  cafe_id BIGINT UNSIGNED NOT NULL,
  branch_id BIGINT UNSIGNED NOT NULL,
  business_date DATE NOT NULL,
  last_number INT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (branch_id, business_date),
  FOREIGN KEY (cafe_id, branch_id) REFERENCES cafe_branches (cafe_id, id)
);

-- status and payment_status are independent (ADR-7).
CREATE TABLE orders (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  public_id CHAR(26) COLLATE ascii_bin NOT NULL,
  cafe_id BIGINT UNSIGNED NOT NULL,
  branch_id BIGINT UNSIGNED NOT NULL,
  order_number INT UNSIGNED NOT NULL,
  business_date DATE NOT NULL,
  order_source ENUM('qr','customer_app','staff') NOT NULL,
  order_type ENUM('dine_in','takeaway','delivery') NOT NULL DEFAULT 'dine_in',
  table_id BIGINT UNSIGNED NULL,
  session_id BIGINT UNSIGNED NULL,
  customer_id BIGINT UNSIGNED NULL,
  placed_by_user_id BIGINT UNSIGNED NULL,
  status ENUM('pending_payment','placed','accepted','preparing','ready','served','completed','cancelled') NOT NULL,
  payment_status ENUM('unpaid','partially_paid','paid','partially_refunded','refunded') NOT NULL DEFAULT 'unpaid',
  language_code VARCHAR(12) COLLATE ascii_bin NOT NULL,
  currency_code CHAR(3) COLLATE ascii_bin NOT NULL,
  prices_include_tax TINYINT(1) NOT NULL,
  subtotal_amount DECIMAL(19,4) NOT NULL,
  discount_amount DECIMAL(19,4) NOT NULL DEFAULT 0,
  tax_amount DECIMAL(19,4) NOT NULL DEFAULT 0,
  service_charge_amount DECIMAL(19,4) NOT NULL DEFAULT 0,
  delivery_fee_amount DECIMAL(19,4) NOT NULL DEFAULT 0,
  rounding_amount DECIMAL(19,4) NOT NULL DEFAULT 0,
  total_amount DECIMAL(19,4) NOT NULL,
  paid_amount DECIMAL(19,4) NOT NULL DEFAULT 0,
  refunded_amount DECIMAL(19,4) NOT NULL DEFAULT 0,
  customer_notes VARCHAR(1000) NULL,
  cancel_reason VARCHAR(500) NULL,
  delivery_address_snapshot JSON NULL,
  placed_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  accepted_at DATETIME(3) NULL,
  ready_at DATETIME(3) NULL,
  completed_at DATETIME(3) NULL,
  cancelled_at DATETIME(3) NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_orders_public_id (public_id),
  UNIQUE KEY uq_orders_tenant (cafe_id, id),
  UNIQUE KEY uq_orders_tenant_currency (cafe_id, id, currency_code),
  UNIQUE KEY uq_orders_number (cafe_id, branch_id, business_date, order_number),
  KEY idx_orders_board (cafe_id, branch_id, status, placed_at),
  KEY idx_orders_reporting (cafe_id, business_date, status),
  KEY idx_orders_customer (cafe_id, customer_id, placed_at),
  FOREIGN KEY (cafe_id, currency_code) REFERENCES cafes (id, currency_code),
  FOREIGN KEY (cafe_id, branch_id) REFERENCES cafe_branches (cafe_id, id),
  FOREIGN KEY (cafe_id, branch_id, table_id) REFERENCES cafe_tables (cafe_id, branch_id, id),
  FOREIGN KEY (cafe_id, session_id) REFERENCES table_sessions (cafe_id, id),
  FOREIGN KEY (cafe_id, customer_id) REFERENCES cafe_customers (cafe_id, customer_id),
  FOREIGN KEY (placed_by_user_id) REFERENCES users (id),
  FOREIGN KEY (language_code) REFERENCES languages (code),
  CONSTRAINT chk_orders_amounts CHECK (subtotal_amount >= 0 AND discount_amount >= 0 AND tax_amount >= 0
    AND service_charge_amount >= 0 AND delivery_fee_amount >= 0 AND total_amount >= 0
    AND paid_amount >= 0 AND refunded_amount >= 0 AND refunded_amount <= paid_amount)
);

CREATE TABLE order_items (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  cafe_id BIGINT UNSIGNED NOT NULL,
  order_id BIGINT UNSIGNED NOT NULL,
  product_id BIGINT UNSIGNED NOT NULL,
  variant_id BIGINT UNSIGNED NULL,
  tax_category_id BIGINT UNSIGNED NULL,
  name_snapshot VARCHAR(200) NOT NULL,
  variant_name_snapshot VARCHAR(100) NULL,
  name_translations JSON NULL,
  quantity INT UNSIGNED NOT NULL,
  unit_price DECIMAL(19,4) NOT NULL,
  addons_amount DECIMAL(19,4) NOT NULL DEFAULT 0,
  discount_amount DECIMAL(19,4) NOT NULL DEFAULT 0,
  tax_amount DECIMAL(19,4) NOT NULL DEFAULT 0,
  line_total_amount DECIMAL(19,4) NOT NULL,
  status ENUM('active','cancelled') NOT NULL DEFAULT 'active',
  notes VARCHAR(500) NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_order_items_tenant (cafe_id, id),
  KEY idx_order_items_product_sales (cafe_id, product_id),
  FOREIGN KEY (cafe_id, order_id) REFERENCES orders (cafe_id, id),
  FOREIGN KEY (cafe_id, product_id) REFERENCES products (cafe_id, id),
  FOREIGN KEY (cafe_id, product_id, variant_id) REFERENCES product_variants (cafe_id, product_id, id),
  FOREIGN KEY (cafe_id, tax_category_id) REFERENCES tax_categories (cafe_id, id),
  CONSTRAINT chk_order_items_amounts CHECK (quantity > 0 AND unit_price >= 0 AND addons_amount >= 0
    AND discount_amount >= 0 AND tax_amount >= 0 AND line_total_amount >= 0)
);

CREATE TABLE order_item_addons (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  cafe_id BIGINT UNSIGNED NOT NULL,
  order_item_id BIGINT UNSIGNED NOT NULL,
  addon_id BIGINT UNSIGNED NOT NULL,
  name_snapshot VARCHAR(100) NOT NULL,
  name_translations JSON NULL,
  quantity INT UNSIGNED NOT NULL DEFAULT 1,
  unit_price DECIMAL(19,4) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_order_item_addons_tenant (cafe_id, id),
  FOREIGN KEY (cafe_id, order_item_id) REFERENCES order_items (cafe_id, id),
  FOREIGN KEY (cafe_id, addon_id) REFERENCES product_addons (cafe_id, id),
  CONSTRAINT chk_order_item_addons CHECK (quantity > 0 AND unit_price >= 0)
);

-- Snapshot of the tax actually applied, per component, per line.
CREATE TABLE order_item_taxes (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  cafe_id BIGINT UNSIGNED NOT NULL,
  order_item_id BIGINT UNSIGNED NOT NULL,
  component_code VARCHAR(16) COLLATE ascii_bin NOT NULL,
  display_name VARCHAR(60) NOT NULL,
  rate_percent DECIMAL(9,6) NOT NULL,
  taxable_amount DECIMAL(19,4) NOT NULL,
  tax_amount DECIMAL(19,4) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_order_item_taxes_tenant (cafe_id, id),
  FOREIGN KEY (cafe_id, order_item_id) REFERENCES order_items (cafe_id, id)
);

CREATE TABLE order_status_history (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  cafe_id BIGINT UNSIGNED NOT NULL,
  order_id BIGINT UNSIGNED NOT NULL,
  from_status VARCHAR(32) COLLATE ascii_bin NULL,
  to_status VARCHAR(32) COLLATE ascii_bin NOT NULL,
  changed_by_user_id BIGINT UNSIGNED NULL,
  reason VARCHAR(500) NULL,
  occurred_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_order_status_history_tenant (cafe_id, id),
  KEY idx_order_status_history_order (order_id, occurred_at),
  FOREIGN KEY (cafe_id, order_id) REFERENCES orders (cafe_id, id),
  FOREIGN KEY (changed_by_user_id) REFERENCES users (id)
);

CREATE TABLE order_modifications (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  cafe_id BIGINT UNSIGNED NOT NULL,
  order_id BIGINT UNSIGNED NOT NULL,
  modification_type ENUM('item_added','item_cancelled','quantity_changed','table_transferred','notes_changed','discount_changed') NOT NULL,
  before_state JSON NULL,
  after_state JSON NULL,
  reason VARCHAR(500) NOT NULL,
  modified_by_user_id BIGINT UNSIGNED NOT NULL,
  authorized_by_user_id BIGINT UNSIGNED NULL,
  occurred_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_order_modifications_tenant (cafe_id, id),
  FOREIGN KEY (cafe_id, order_id) REFERENCES orders (cafe_id, id),
  FOREIGN KEY (modified_by_user_id) REFERENCES users (id),
  FOREIGN KEY (authorized_by_user_id) REFERENCES users (id)
);

CREATE TABLE kitchen_stations (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  public_id CHAR(26) COLLATE ascii_bin NOT NULL,
  cafe_id BIGINT UNSIGNED NOT NULL,
  branch_id BIGINT UNSIGNED NOT NULL,
  name VARCHAR(80) NOT NULL,
  delay_threshold_minutes SMALLINT UNSIGNED NOT NULL DEFAULT 15,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_kitchen_stations_public_id (public_id),
  UNIQUE KEY uq_kitchen_stations_tenant (cafe_id, id),
  UNIQUE KEY uq_kitchen_stations_name (cafe_id, branch_id, name),
  FOREIGN KEY (cafe_id, branch_id) REFERENCES cafe_branches (cafe_id, id)
);

CREATE TABLE product_station_routes (
  cafe_id BIGINT UNSIGNED NOT NULL,
  branch_id BIGINT UNSIGNED NOT NULL,
  product_id BIGINT UNSIGNED NOT NULL,
  station_id BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (branch_id, product_id),
  FOREIGN KEY (cafe_id, branch_id) REFERENCES cafe_branches (cafe_id, id),
  FOREIGN KEY (cafe_id, product_id) REFERENCES products (cafe_id, id),
  FOREIGN KEY (cafe_id, station_id) REFERENCES kitchen_stations (cafe_id, id)
);

CREATE TABLE kitchen_orders (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  public_id CHAR(26) COLLATE ascii_bin NOT NULL,
  cafe_id BIGINT UNSIGNED NOT NULL,
  branch_id BIGINT UNSIGNED NOT NULL,
  order_id BIGINT UNSIGNED NOT NULL,
  station_id BIGINT UNSIGNED NULL,
  status ENUM('new','accepted','preparing','ready','completed','cancelled') NOT NULL DEFAULT 'new',
  priority TINYINT UNSIGNED NOT NULL DEFAULT 0,
  accepted_at DATETIME(3) NULL,
  started_at DATETIME(3) NULL,
  ready_at DATETIME(3) NULL,
  completed_at DATETIME(3) NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_kitchen_orders_public_id (public_id),
  UNIQUE KEY uq_kitchen_orders_tenant (cafe_id, id),
  KEY idx_kitchen_orders_board (cafe_id, branch_id, status, priority, created_at),
  FOREIGN KEY (cafe_id, branch_id) REFERENCES cafe_branches (cafe_id, id),
  FOREIGN KEY (cafe_id, order_id) REFERENCES orders (cafe_id, id),
  FOREIGN KEY (cafe_id, station_id) REFERENCES kitchen_stations (cafe_id, id)
);

CREATE TABLE kitchen_order_items (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  cafe_id BIGINT UNSIGNED NOT NULL,
  kitchen_order_id BIGINT UNSIGNED NOT NULL,
  order_item_id BIGINT UNSIGNED NOT NULL,
  status ENUM('new','preparing','ready','cancelled') NOT NULL DEFAULT 'new',
  ready_at DATETIME(3) NULL,
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_kitchen_order_items_tenant (cafe_id, id),
  UNIQUE KEY uq_kitchen_order_items (kitchen_order_id, order_item_id),
  FOREIGN KEY (cafe_id, kitchen_order_id) REFERENCES kitchen_orders (cafe_id, id),
  FOREIGN KEY (cafe_id, order_item_id) REFERENCES order_items (cafe_id, id)
);

CREATE TABLE delivery_zones (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  cafe_id BIGINT UNSIGNED NOT NULL,
  branch_id BIGINT UNSIGNED NOT NULL,
  name VARCHAR(80) NOT NULL,
  radius_km DECIMAL(7,3) NULL,
  fee_amount DECIMAL(19,4) NOT NULL DEFAULT 0,
  min_order_amount DECIMAL(19,4) NOT NULL DEFAULT 0,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_delivery_zones_tenant (cafe_id, id),
  FOREIGN KEY (cafe_id, branch_id) REFERENCES cafe_branches (cafe_id, id)
);
