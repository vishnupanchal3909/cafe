-- Coupons, promotions, banners, loyalty, reviews.

CREATE TABLE banners (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  public_id CHAR(26) COLLATE ascii_bin NOT NULL,
  cafe_id BIGINT UNSIGNED NOT NULL,
  image_asset_id BIGINT UNSIGNED NOT NULL,
  placement ENUM('cover','promotional') NOT NULL DEFAULT 'promotional',
  link_product_id BIGINT UNSIGNED NULL,
  starts_at DATETIME(3) NULL,
  ends_at DATETIME(3) NULL,
  sort_order INT NOT NULL DEFAULT 0,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  deleted_at DATETIME(3) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_banners_public_id (public_id),
  UNIQUE KEY uq_banners_tenant (cafe_id, id),
  FOREIGN KEY (cafe_id, image_asset_id) REFERENCES media_assets (cafe_id, id),
  FOREIGN KEY (cafe_id, link_product_id) REFERENCES products (cafe_id, id)
);

CREATE TABLE banner_translations (
  cafe_id BIGINT UNSIGNED NOT NULL,
  banner_id BIGINT UNSIGNED NOT NULL,
  language_code VARCHAR(12) COLLATE ascii_bin NOT NULL,
  title VARCHAR(150) NOT NULL,
  subtitle VARCHAR(300) NULL,
  PRIMARY KEY (banner_id, language_code),
  FOREIGN KEY (cafe_id, banner_id) REFERENCES banners (cafe_id, id),
  FOREIGN KEY (language_code) REFERENCES languages (code)
);

CREATE TABLE coupons (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  public_id CHAR(26) COLLATE ascii_bin NOT NULL,
  cafe_id BIGINT UNSIGNED NOT NULL,
  code VARCHAR(40) NOT NULL,
  discount_type ENUM('percent','fixed') NOT NULL,
  percent_value DECIMAL(5,2) NULL,
  fixed_amount DECIMAL(19,4) NULL,
  max_discount_amount DECIMAL(19,4) NULL,
  min_order_amount DECIMAL(19,4) NOT NULL DEFAULT 0,
  max_redemptions INT UNSIGNED NULL,
  max_per_customer INT UNSIGNED NULL,
  redemption_count INT UNSIGNED NOT NULL DEFAULT 0,
  starts_at DATETIME(3) NULL,
  ends_at DATETIME(3) NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  deleted_at DATETIME(3) NULL,
  active_marker TINYINT GENERATED ALWAYS AS (IF(deleted_at IS NULL, 1, NULL)) VIRTUAL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_coupons_public_id (public_id),
  UNIQUE KEY uq_coupons_tenant (cafe_id, id),
  UNIQUE KEY uq_coupons_code (cafe_id, code, active_marker),
  FOREIGN KEY (cafe_id) REFERENCES cafes (id),
  CONSTRAINT chk_coupons_value CHECK (
    (discount_type = 'percent' AND percent_value BETWEEN 0 AND 100 AND fixed_amount IS NULL)
    OR (discount_type = 'fixed' AND fixed_amount > 0 AND percent_value IS NULL)
  )
);

CREATE TABLE coupon_redemptions (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  cafe_id BIGINT UNSIGNED NOT NULL,
  coupon_id BIGINT UNSIGNED NOT NULL,
  order_id BIGINT UNSIGNED NOT NULL,
  customer_id BIGINT UNSIGNED NULL,
  currency_code CHAR(3) COLLATE ascii_bin NOT NULL,
  discount_amount DECIMAL(19,4) NOT NULL,
  redeemed_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_coupon_redemptions_tenant (cafe_id, id),
  UNIQUE KEY uq_coupon_redemptions_order (coupon_id, order_id),
  FOREIGN KEY (cafe_id, coupon_id) REFERENCES coupons (cafe_id, id),
  FOREIGN KEY (cafe_id, order_id, currency_code) REFERENCES orders (cafe_id, id, currency_code),
  FOREIGN KEY (cafe_id, customer_id) REFERENCES cafe_customers (cafe_id, customer_id)
);

CREATE TABLE promotions (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  public_id CHAR(26) COLLATE ascii_bin NOT NULL,
  cafe_id BIGINT UNSIGNED NOT NULL,
  discount_type ENUM('percent','fixed') NOT NULL,
  percent_value DECIMAL(5,2) NULL,
  fixed_amount DECIMAL(19,4) NULL,
  starts_at DATETIME(3) NULL,
  ends_at DATETIME(3) NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  priority SMALLINT NOT NULL DEFAULT 0,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  deleted_at DATETIME(3) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_promotions_public_id (public_id),
  UNIQUE KEY uq_promotions_tenant (cafe_id, id),
  FOREIGN KEY (cafe_id) REFERENCES cafes (id),
  CONSTRAINT chk_promotions_value CHECK (
    (discount_type = 'percent' AND percent_value BETWEEN 0 AND 100 AND fixed_amount IS NULL)
    OR (discount_type = 'fixed' AND fixed_amount > 0 AND percent_value IS NULL)
  )
);

CREATE TABLE promotion_translations (
  cafe_id BIGINT UNSIGNED NOT NULL,
  promotion_id BIGINT UNSIGNED NOT NULL,
  language_code VARCHAR(12) COLLATE ascii_bin NOT NULL,
  title VARCHAR(150) NOT NULL,
  description TEXT NULL,
  PRIMARY KEY (promotion_id, language_code),
  FOREIGN KEY (cafe_id, promotion_id) REFERENCES promotions (cafe_id, id),
  FOREIGN KEY (language_code) REFERENCES languages (code)
);

CREATE TABLE promotion_targets (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  cafe_id BIGINT UNSIGNED NOT NULL,
  promotion_id BIGINT UNSIGNED NOT NULL,
  product_id BIGINT UNSIGNED NULL,
  category_id BIGINT UNSIGNED NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_promotion_targets_tenant (cafe_id, id),
  FOREIGN KEY (cafe_id, promotion_id) REFERENCES promotions (cafe_id, id),
  FOREIGN KEY (cafe_id, product_id) REFERENCES products (cafe_id, id),
  FOREIGN KEY (cafe_id, category_id) REFERENCES categories (cafe_id, id),
  CONSTRAINT chk_promotion_targets CHECK ((product_id IS NULL) <> (category_id IS NULL))
);

CREATE TABLE loyalty_programs (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  cafe_id BIGINT UNSIGNED NOT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 0,
  points_per_currency_unit DECIMAL(12,4) NOT NULL DEFAULT 0,
  currency_value_per_point DECIMAL(19,4) NOT NULL DEFAULT 0,
  min_redeem_points INT UNSIGNED NOT NULL DEFAULT 0,
  points_expiry_days INT UNSIGNED NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_loyalty_programs_tenant (cafe_id, id),
  UNIQUE KEY uq_loyalty_programs_cafe (cafe_id),
  FOREIGN KEY (cafe_id) REFERENCES cafes (id)
);

CREATE TABLE customer_loyalty_points (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  cafe_id BIGINT UNSIGNED NOT NULL,
  customer_id BIGINT UNSIGNED NOT NULL,
  balance_points BIGINT NOT NULL DEFAULT 0,
  lifetime_points BIGINT UNSIGNED NOT NULL DEFAULT 0,
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_customer_loyalty_points_tenant (cafe_id, id),
  UNIQUE KEY uq_customer_loyalty_points (cafe_id, customer_id),
  FOREIGN KEY (cafe_id, customer_id) REFERENCES cafe_customers (cafe_id, customer_id),
  CONSTRAINT chk_customer_loyalty_balance CHECK (balance_points >= 0)
);

-- Append-only (triggers in 0012).
CREATE TABLE loyalty_ledger (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  cafe_id BIGINT UNSIGNED NOT NULL,
  customer_id BIGINT UNSIGNED NOT NULL,
  entry_type ENUM('earn','redeem','expire','adjust','reverse') NOT NULL,
  points BIGINT NOT NULL,
  order_id BIGINT UNSIGNED NULL,
  reason VARCHAR(255) NULL,
  expires_at DATETIME(3) NULL,
  occurred_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_loyalty_ledger_tenant (cafe_id, id),
  KEY idx_loyalty_ledger_customer (cafe_id, customer_id, occurred_at),
  FOREIGN KEY (cafe_id, customer_id) REFERENCES cafe_customers (cafe_id, customer_id),
  FOREIGN KEY (cafe_id, order_id) REFERENCES orders (cafe_id, id),
  CONSTRAINT chk_loyalty_ledger_points CHECK (points <> 0)
);

CREATE TABLE customer_reviews (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  public_id CHAR(26) COLLATE ascii_bin NOT NULL,
  cafe_id BIGINT UNSIGNED NOT NULL,
  order_id BIGINT UNSIGNED NOT NULL,
  customer_id BIGINT UNSIGNED NULL,
  rating TINYINT UNSIGNED NOT NULL,
  comment TEXT NULL,
  is_published TINYINT(1) NOT NULL DEFAULT 1,
  reply_text TEXT NULL,
  replied_by_user_id BIGINT UNSIGNED NULL,
  replied_at DATETIME(3) NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_customer_reviews_public_id (public_id),
  UNIQUE KEY uq_customer_reviews_tenant (cafe_id, id),
  -- One review per order; only real orders can be reviewed.
  UNIQUE KEY uq_customer_reviews_order (cafe_id, order_id),
  FOREIGN KEY (cafe_id, order_id) REFERENCES orders (cafe_id, id),
  FOREIGN KEY (cafe_id, customer_id) REFERENCES cafe_customers (cafe_id, customer_id),
  FOREIGN KEY (replied_by_user_id) REFERENCES users (id),
  CONSTRAINT chk_customer_reviews_rating CHECK (rating BETWEEN 1 AND 5)
);
