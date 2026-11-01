-- Idempotent reference data. Contains structure only: no tax rates, no prices.

INSERT INTO languages (code, name, native_name, direction, sort_order) VALUES
  ('en', 'English', 'English', 'ltr', 1),
  ('hi', 'Hindi', 'हिन्दी', 'ltr', 2),
  ('mr', 'Marathi', 'मराठी', 'ltr', 3),
  ('es', 'Spanish', 'Español', 'ltr', 4),
  ('fr', 'French', 'Français', 'ltr', 5),
  ('de', 'German', 'Deutsch', 'ltr', 6),
  ('ar', 'Arabic', 'العربية', 'rtl', 7),
  ('pt', 'Portuguese', 'Português', 'ltr', 8),
  ('ja', 'Japanese', '日本語', 'ltr', 9)
AS new ON DUPLICATE KEY UPDATE name = new.name, native_name = new.native_name, direction = new.direction, sort_order = new.sort_order;

INSERT INTO currencies (code, numeric_code, name, symbol, minor_unit) VALUES
  ('INR', '356', 'Indian Rupee', '₹', 2),
  ('USD', '840', 'US Dollar', '$', 2),
  ('EUR', '978', 'Euro', '€', 2),
  ('GBP', '826', 'British Pound', '£', 2),
  ('AED', '784', 'UAE Dirham', 'د.إ', 2),
  ('AUD', '036', 'Australian Dollar', 'A$', 2),
  ('CAD', '124', 'Canadian Dollar', 'CA$', 2),
  ('SGD', '702', 'Singapore Dollar', 'S$', 2),
  ('JPY', '392', 'Japanese Yen', '¥', 0),
  ('CHF', '756', 'Swiss Franc', 'CHF', 2)
AS new ON DUPLICATE KEY UPDATE numeric_code = new.numeric_code, name = new.name, symbol = new.symbol, minor_unit = new.minor_unit;

-- fiscal_year_start_month is only a suggested default at onboarding; each cafe can change it.
INSERT INTO countries (code, name, default_currency_code, default_language_code, default_timezone, fiscal_year_start_month) VALUES
  ('IN', 'India', 'INR', 'en', 'Asia/Kolkata', 4),
  ('US', 'United States', 'USD', 'en', 'America/New_York', 1),
  ('GB', 'United Kingdom', 'GBP', 'en', 'Europe/London', 4),
  ('DE', 'Germany', 'EUR', 'de', 'Europe/Berlin', 1),
  ('FR', 'France', 'EUR', 'fr', 'Europe/Paris', 1),
  ('ES', 'Spain', 'EUR', 'es', 'Europe/Madrid', 1),
  ('PT', 'Portugal', 'EUR', 'pt', 'Europe/Lisbon', 1),
  ('AE', 'United Arab Emirates', 'AED', 'ar', 'Asia/Dubai', 1),
  ('AU', 'Australia', 'AUD', 'en', 'Australia/Sydney', 7),
  ('CA', 'Canada', 'CAD', 'en', 'America/Toronto', 1),
  ('SG', 'Singapore', 'SGD', 'en', 'Asia/Singapore', 1),
  ('JP', 'Japan', 'JPY', 'ja', 'Asia/Tokyo', 4),
  ('CH', 'Switzerland', 'CHF', 'de', 'Europe/Zurich', 1)
AS new ON DUPLICATE KEY UPDATE name = new.name, default_currency_code = new.default_currency_code,
  default_language_code = new.default_language_code, default_timezone = new.default_timezone,
  fiscal_year_start_month = new.fiscal_year_start_month;

INSERT INTO units (code, name, dimension, factor_to_base) VALUES
  ('mg', 'Milligram', 'mass', 0.001), ('g', 'Gram', 'mass', 1), ('kg', 'Kilogram', 'mass', 1000),
  ('ml', 'Millilitre', 'volume', 1), ('l', 'Litre', 'volume', 1000),
  ('pc', 'Piece', 'count', 1), ('dozen', 'Dozen', 'count', 12)
AS new ON DUPLICATE KEY UPDATE name = new.name, dimension = new.dimension, factor_to_base = new.factor_to_base;

INSERT INTO tax_component_definitions (country_code, code, name, applies_to) VALUES
  ('IN', 'CGST', 'Central GST', 'intra_region'),
  ('IN', 'SGST', 'State GST', 'intra_region'),
  ('IN', 'UTGST', 'Union Territory GST', 'intra_region'),
  ('IN', 'IGST', 'Integrated GST', 'inter_region'),
  ('GB', 'VAT', 'Value Added Tax', 'always'),
  ('DE', 'VAT', 'Umsatzsteuer', 'always'),
  ('FR', 'VAT', 'TVA', 'always'),
  ('ES', 'VAT', 'IVA', 'always'),
  ('PT', 'VAT', 'IVA', 'always'),
  ('AE', 'VAT', 'Value Added Tax', 'always'),
  ('CH', 'VAT', 'Mehrwertsteuer', 'always'),
  ('AU', 'GST', 'Goods and Services Tax', 'always'),
  ('SG', 'GST', 'Goods and Services Tax', 'always'),
  ('CA', 'GST', 'Goods and Services Tax', 'always'),
  ('CA', 'HST', 'Harmonized Sales Tax', 'always'),
  ('CA', 'PST', 'Provincial Sales Tax', 'always'),
  ('JP', 'CT', 'Consumption Tax', 'always'),
  ('US', 'SALES', 'Sales Tax', 'always')
AS new ON DUPLICATE KEY UPDATE name = new.name, applies_to = new.applies_to;

INSERT INTO payment_methods (code, name, is_manual) VALUES
  ('cash', 'Cash', 1), ('upi', 'UPI', 0), ('card', 'Credit or debit card', 0), ('payment_link', 'Payment link', 0)
AS new ON DUPLICATE KEY UPDATE name = new.name, is_manual = new.is_manual;

INSERT INTO payment_providers (code, name) VALUES
  ('razorpay', 'Razorpay'), ('cashfree', 'Cashfree'), ('stripe', 'Stripe')
AS new ON DUPLICATE KEY UPDATE name = new.name;

-- Starting chart of accounts, copied per cafe at onboarding. Needs accountant review before real use.
INSERT INTO coa_templates (code, name, country_code) VALUES ('standard', 'Standard cafe chart of accounts', NULL)
AS new ON DUPLICATE KEY UPDATE name = new.name;

INSERT INTO coa_template_accounts (template_id, code, name, account_type, system_key)
SELECT t.id, a.code, a.name, a.account_type, a.system_key
FROM coa_templates t
JOIN (
  SELECT '1000' AS code, 'Cash on hand' AS name, 'asset' AS account_type, 'cash' AS system_key
  UNION ALL SELECT '1010', 'Bank', 'asset', 'bank'
  UNION ALL SELECT '1100', 'Payment gateway clearing', 'asset', 'gateway_clearing'
  UNION ALL SELECT '1200', 'Inventory', 'asset', 'inventory'
  UNION ALL SELECT '1300', 'Accounts receivable', 'asset', 'accounts_receivable'
  UNION ALL SELECT '2000', 'Accounts payable', 'liability', 'accounts_payable'
  UNION ALL SELECT '2100', 'Tax payable', 'liability', 'tax_payable'
  UNION ALL SELECT '2200', 'Salaries payable', 'liability', 'salaries_payable'
  UNION ALL SELECT '3000', 'Owner equity', 'equity', 'owner_equity'
  UNION ALL SELECT '3100', 'Retained earnings', 'equity', 'retained_earnings'
  UNION ALL SELECT '4000', 'Sales revenue', 'revenue', 'sales_revenue'
  UNION ALL SELECT '4100', 'Sales discounts', 'revenue', 'sales_discounts'
  UNION ALL SELECT '4200', 'Sales returns', 'revenue', 'sales_returns'
  UNION ALL SELECT '4300', 'Rounding adjustments', 'revenue', 'rounding'
  UNION ALL SELECT '5000', 'Cost of goods sold', 'expense', 'cogs'
  UNION ALL SELECT '5100', 'Wastage', 'expense', 'wastage'
  UNION ALL SELECT '6000', 'Salaries', 'expense', 'salaries'
  UNION ALL SELECT '6100', 'Rent', 'expense', NULL
  UNION ALL SELECT '6200', 'Utilities', 'expense', NULL
  UNION ALL SELECT '6300', 'Payment gateway fees', 'expense', 'gateway_fees'
  UNION ALL SELECT '6400', 'Platform fees', 'expense', 'platform_fees'
  UNION ALL SELECT '6900', 'Other operating expenses', 'expense', NULL
) a
WHERE t.code = 'standard'
ON DUPLICATE KEY UPDATE name = VALUES(name), account_type = VALUES(account_type), system_key = VALUES(system_key);
