-- Menu. Prices inherit the cafe's currency; order lines snapshot price and currency at sale.

CREATE TABLE categories (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  public_id CHAR(26) COLLATE ascii_bin NOT NULL,
  cafe_id BIGINT UNSIGNED NOT NULL,
  parent_id BIGINT UNSIGNED NULL,
  image_asset_id BIGINT UNSIGNED NULL,
  sort_order INT NOT NULL DEFAULT 0,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  deleted_at DATETIME(3) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_categories_public_id (public_id),
  UNIQUE KEY uq_categories_tenant (cafe_id, id),
  KEY idx_categories_list (cafe_id, is_active, sort_order),
  FOREIGN KEY (cafe_id, parent_id) REFERENCES categories (cafe_id, id),
  FOREIGN KEY (cafe_id, image_asset_id) REFERENCES media_assets (cafe_id, id),
  FOREIGN KEY (cafe_id) REFERENCES cafes (id)
);

CREATE TABLE category_translations (
  cafe_id BIGINT UNSIGNED NOT NULL,
  category_id BIGINT UNSIGNED NOT NULL,
  language_code VARCHAR(12) COLLATE ascii_bin NOT NULL,
  name VARCHAR(150) NOT NULL,
  description TEXT NULL,
  PRIMARY KEY (category_id, language_code),
  FOREIGN KEY (cafe_id, category_id) REFERENCES categories (cafe_id, id),
  FOREIGN KEY (language_code) REFERENCES languages (code)
);

CREATE TABLE products (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  public_id CHAR(26) COLLATE ascii_bin NOT NULL,
  cafe_id BIGINT UNSIGNED NOT NULL,
  category_id BIGINT UNSIGNED NOT NULL,
  tax_category_id BIGINT UNSIGNED NULL,
  sku VARCHAR(64) NULL,
  product_type ENUM('simple','combo') NOT NULL DEFAULT 'simple',
  base_price DECIMAL(19,4) NOT NULL,
  dietary_class ENUM('veg','non_veg','egg','vegan','not_applicable') NOT NULL DEFAULT 'not_applicable',
  prep_minutes SMALLINT UNSIGNED NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  is_out_of_stock TINYINT(1) NOT NULL DEFAULT 0,
  sort_order INT NOT NULL DEFAULT 0,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  deleted_at DATETIME(3) NULL,
  active_marker TINYINT GENERATED ALWAYS AS (IF(deleted_at IS NULL, 1, NULL)) VIRTUAL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_products_public_id (public_id),
  UNIQUE KEY uq_products_tenant (cafe_id, id),
  UNIQUE KEY uq_products_sku (cafe_id, sku, active_marker),
  KEY idx_products_list (cafe_id, category_id, is_active, sort_order),
  FOREIGN KEY (cafe_id, category_id) REFERENCES categories (cafe_id, id),
  FOREIGN KEY (cafe_id, tax_category_id) REFERENCES tax_categories (cafe_id, id),
  CONSTRAINT chk_products_price CHECK (base_price >= 0)
);

CREATE TABLE product_translations (
  cafe_id BIGINT UNSIGNED NOT NULL,
  product_id BIGINT UNSIGNED NOT NULL,
  language_code VARCHAR(12) COLLATE ascii_bin NOT NULL,
  name VARCHAR(200) NOT NULL,
  description TEXT NULL,
  PRIMARY KEY (product_id, language_code),
  FULLTEXT KEY ftx_product_translations (name) WITH PARSER ngram,
  FOREIGN KEY (cafe_id, product_id) REFERENCES products (cafe_id, id),
  FOREIGN KEY (language_code) REFERENCES languages (code)
);

CREATE TABLE product_images (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  cafe_id BIGINT UNSIGNED NOT NULL,
  product_id BIGINT UNSIGNED NOT NULL,
  asset_id BIGINT UNSIGNED NOT NULL,
  sort_order INT NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  UNIQUE KEY uq_product_images_tenant (cafe_id, id),
  UNIQUE KEY uq_product_images (product_id, asset_id),
  FOREIGN KEY (cafe_id, product_id) REFERENCES products (cafe_id, id),
  FOREIGN KEY (cafe_id, asset_id) REFERENCES media_assets (cafe_id, id)
);

CREATE TABLE product_variants (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  public_id CHAR(26) COLLATE ascii_bin NOT NULL,
  cafe_id BIGINT UNSIGNED NOT NULL,
  product_id BIGINT UNSIGNED NOT NULL,
  sku VARCHAR(64) NULL,
  price DECIMAL(19,4) NOT NULL,
  is_default TINYINT(1) NOT NULL DEFAULT 0,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  sort_order INT NOT NULL DEFAULT 0,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  deleted_at DATETIME(3) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_product_variants_public_id (public_id),
  UNIQUE KEY uq_product_variants_tenant (cafe_id, id),
  -- Lets children require that a variant belongs to the named product.
  UNIQUE KEY uq_product_variants_product (cafe_id, product_id, id),
  FOREIGN KEY (cafe_id, product_id) REFERENCES products (cafe_id, id),
  CONSTRAINT chk_product_variants_price CHECK (price >= 0)
);

CREATE TABLE product_variant_translations (
  cafe_id BIGINT UNSIGNED NOT NULL,
  variant_id BIGINT UNSIGNED NOT NULL,
  language_code VARCHAR(12) COLLATE ascii_bin NOT NULL,
  name VARCHAR(100) NOT NULL,
  PRIMARY KEY (variant_id, language_code),
  FOREIGN KEY (cafe_id, variant_id) REFERENCES product_variants (cafe_id, id),
  FOREIGN KEY (language_code) REFERENCES languages (code)
);

CREATE TABLE addon_groups (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  public_id CHAR(26) COLLATE ascii_bin NOT NULL,
  cafe_id BIGINT UNSIGNED NOT NULL,
  min_select SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  max_select SMALLINT UNSIGNED NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  deleted_at DATETIME(3) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_addon_groups_public_id (public_id),
  UNIQUE KEY uq_addon_groups_tenant (cafe_id, id),
  FOREIGN KEY (cafe_id) REFERENCES cafes (id),
  CONSTRAINT chk_addon_groups_range CHECK (max_select IS NULL OR max_select >= min_select)
);

CREATE TABLE addon_group_translations (
  cafe_id BIGINT UNSIGNED NOT NULL,
  addon_group_id BIGINT UNSIGNED NOT NULL,
  language_code VARCHAR(12) COLLATE ascii_bin NOT NULL,
  name VARCHAR(100) NOT NULL,
  PRIMARY KEY (addon_group_id, language_code),
  FOREIGN KEY (cafe_id, addon_group_id) REFERENCES addon_groups (cafe_id, id),
  FOREIGN KEY (language_code) REFERENCES languages (code)
);

CREATE TABLE product_addons (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  public_id CHAR(26) COLLATE ascii_bin NOT NULL,
  cafe_id BIGINT UNSIGNED NOT NULL,
  addon_group_id BIGINT UNSIGNED NOT NULL,
  price DECIMAL(19,4) NOT NULL DEFAULT 0,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  sort_order INT NOT NULL DEFAULT 0,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  deleted_at DATETIME(3) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_product_addons_public_id (public_id),
  UNIQUE KEY uq_product_addons_tenant (cafe_id, id),
  FOREIGN KEY (cafe_id, addon_group_id) REFERENCES addon_groups (cafe_id, id),
  CONSTRAINT chk_product_addons_price CHECK (price >= 0)
);

CREATE TABLE product_addon_translations (
  cafe_id BIGINT UNSIGNED NOT NULL,
  addon_id BIGINT UNSIGNED NOT NULL,
  language_code VARCHAR(12) COLLATE ascii_bin NOT NULL,
  name VARCHAR(100) NOT NULL,
  PRIMARY KEY (addon_id, language_code),
  FOREIGN KEY (cafe_id, addon_id) REFERENCES product_addons (cafe_id, id),
  FOREIGN KEY (language_code) REFERENCES languages (code)
);

CREATE TABLE product_addon_groups (
  cafe_id BIGINT UNSIGNED NOT NULL,
  product_id BIGINT UNSIGNED NOT NULL,
  addon_group_id BIGINT UNSIGNED NOT NULL,
  sort_order INT NOT NULL DEFAULT 0,
  PRIMARY KEY (product_id, addon_group_id),
  FOREIGN KEY (cafe_id, product_id) REFERENCES products (cafe_id, id),
  FOREIGN KEY (cafe_id, addon_group_id) REFERENCES addon_groups (cafe_id, id)
);

CREATE TABLE combo_items (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  cafe_id BIGINT UNSIGNED NOT NULL,
  combo_product_id BIGINT UNSIGNED NOT NULL,
  item_product_id BIGINT UNSIGNED NOT NULL,
  item_variant_id BIGINT UNSIGNED NULL,
  quantity INT UNSIGNED NOT NULL DEFAULT 1,
  PRIMARY KEY (id),
  UNIQUE KEY uq_combo_items_tenant (cafe_id, id),
  UNIQUE KEY uq_combo_items (combo_product_id, item_product_id, item_variant_id),
  FOREIGN KEY (cafe_id, combo_product_id) REFERENCES products (cafe_id, id),
  FOREIGN KEY (cafe_id, item_product_id) REFERENCES products (cafe_id, id),
  FOREIGN KEY (cafe_id, item_product_id, item_variant_id) REFERENCES product_variants (cafe_id, product_id, id),
  CONSTRAINT chk_combo_items_qty CHECK (quantity > 0),
  CONSTRAINT chk_combo_items_self CHECK (combo_product_id <> item_product_id)
);

-- Scheduled availability: a row grants a time window; a product with no rows is always available.
CREATE TABLE product_availability_schedules (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  cafe_id BIGINT UNSIGNED NOT NULL,
  product_id BIGINT UNSIGNED NULL,
  category_id BIGINT UNSIGNED NULL,
  weekday TINYINT UNSIGNED NULL,
  starts_at TIME NOT NULL,
  ends_at TIME NOT NULL,
  valid_from DATE NULL,
  valid_to DATE NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_product_availability_tenant (cafe_id, id),
  FOREIGN KEY (cafe_id, product_id) REFERENCES products (cafe_id, id),
  FOREIGN KEY (cafe_id, category_id) REFERENCES categories (cafe_id, id),
  CONSTRAINT chk_availability_subject CHECK ((product_id IS NULL) <> (category_id IS NULL)),
  CONSTRAINT chk_availability_weekday CHECK (weekday IS NULL OR weekday <= 6)
);

CREATE TABLE branch_product_overrides (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  cafe_id BIGINT UNSIGNED NOT NULL,
  branch_id BIGINT UNSIGNED NOT NULL,
  product_id BIGINT UNSIGNED NOT NULL,
  variant_id BIGINT UNSIGNED NULL,
  variant_key BIGINT UNSIGNED GENERATED ALWAYS AS (IFNULL(variant_id, 0)) VIRTUAL,
  price_override DECIMAL(19,4) NULL,
  is_available TINYINT(1) NULL,
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_branch_product_overrides_tenant (cafe_id, id),
  UNIQUE KEY uq_branch_product_overrides (branch_id, product_id, variant_key),
  FOREIGN KEY (cafe_id, branch_id) REFERENCES cafe_branches (cafe_id, id),
  FOREIGN KEY (cafe_id, product_id) REFERENCES products (cafe_id, id),
  FOREIGN KEY (cafe_id, product_id, variant_id) REFERENCES product_variants (cafe_id, product_id, id),
  CONSTRAINT chk_branch_override_price CHECK (price_override IS NULL OR price_override >= 0)
);
