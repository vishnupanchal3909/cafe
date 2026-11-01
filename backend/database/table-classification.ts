// Every table must be listed here. The schema lint test fails on any table that is not,
// which forces a tenancy decision whenever a table is added.

// Owned by a cafe: cafe_id NOT NULL.
export const TENANT_TABLES = [
  'accounting_accounts', 'addon_group_translations', 'addon_groups', 'banner_translations', 'banners',
  'bill_lines', 'bills', 'branch_product_overrides', 'cafe_branches', 'cafe_business_hours', 'cafe_customers',
  'cafe_languages', 'cafe_payment_methods', 'cafe_settings', 'cafe_staff', 'cafe_subscriptions', 'cafe_tables',
  'cafe_themes', 'cafe_translations', 'cafe_usage_counters', 'cart_item_addons', 'cart_items', 'carts',
  'cash_register_sessions', 'cash_register_transactions', 'cash_registers', 'categories', 'category_translations',
  'combo_items', 'coupon_redemptions', 'coupons', 'customer_favorites', 'customer_loyalty_points', 'customer_reviews',
  'customer_wishlist_items', 'delivery_zones', 'expense_categories', 'expenses', 'financial_periods', 'ingredients',
  'inventory_items', 'invoice_lines', 'invoice_sequences', 'invoice_tax_lines', 'invoices', 'journal_entries',
  'journal_entry_lines', 'kitchen_order_items', 'kitchen_orders', 'kitchen_stations', 'loyalty_ledger',
  'loyalty_programs', 'notification_preferences', 'order_item_addons', 'order_item_taxes', 'order_items',
  'order_modifications', 'order_sequences', 'order_status_history', 'orders', 'payment_gateway_accounts',
  'payment_transactions', 'payments', 'payroll_entries', 'product_addon_groups', 'product_addon_translations',
  'product_addons', 'product_availability_schedules', 'product_images', 'product_recipes', 'product_station_routes',
  'product_translations', 'product_variant_translations', 'product_variants', 'products', 'promotion_targets',
  'promotion_translations', 'promotions', 'purchase_order_items', 'purchase_orders', 'refunds', 'reservations',
  'service_requests', 'settlement_items', 'settlements', 'staff_attendance', 'stock_batches', 'stock_movements',
  'subscription_invoices', 'supplier_invoices', 'supplier_payments', 'suppliers', 'support_ticket_messages',
  'support_tickets', 'table_qr_codes', 'table_session_tables', 'table_sessions', 'tax_categories', 'tax_rates',
  'tax_registrations',
] as const;

// Nullable cafe_id: NULL means a platform-level row.
export const MIXED_TABLES = [
  'audit_logs', 'commission_configs', 'idempotency_keys', 'media_assets', 'notifications', 'outbox_events',
  'payment_webhooks', 'platform_transactions', 'roles', 'user_roles',
] as const;

// No tenant ownership: reference data, platform data, and global identities.
export const GLOBAL_TABLES = [
  'announcement_translations', 'announcements', 'cafes', 'coa_template_accounts', 'coa_templates', 'countries',
  'currencies', 'customer_addresses', 'customer_identities', 'customers', 'device_tokens', 'exchange_rates',
  'languages', 'login_attempts', 'login_sessions', 'notification_deliveries', 'notification_template_translations',
  'notification_templates', 'payment_methods', 'payment_providers', 'permissions', 'plan_entitlements', 'plan_prices',
  'platform_settings', 'refresh_tokens', 'role_permissions', 'schema_migrations', 'subscription_plans', 'tax_component_definitions',
  'translations', 'units', 'user_tokens', 'users',
] as const;

// Exempt from the UPDATE/DELETE grants given to the application DB user.
export const APPEND_ONLY_TABLES = [
  'audit_logs', 'cash_register_transactions', 'exchange_rates', 'loyalty_ledger', 'order_modifications',
  'order_status_history', 'payment_transactions', 'platform_transactions', 'stock_movements',
] as const;

// App may update these under their guards, but never delete.
export const NO_DELETE_TABLES = [
  'bills', 'cafes', 'customers', 'expenses', 'invoices', 'journal_entries', 'orders', 'payments', 'payroll_entries',
  'refunds', 'settlements', 'supplier_invoices', 'supplier_payments', 'users',
] as const;

// Withheld from the read-only reporting user: credentials, personal data, salaries.
export const SECRET_TABLES = [
  'login_sessions', 'payment_gateway_accounts', 'refresh_tokens', 'table_qr_codes', 'table_sessions', 'user_tokens',
  'device_tokens', 'users', 'customers', 'customer_identities', 'customer_addresses', 'payroll_entries', 'reservations',
  'notifications', 'idempotency_keys', 'login_attempts', 'support_ticket_messages',
] as const;
