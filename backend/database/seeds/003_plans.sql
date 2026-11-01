-- Plan names only. Inactive, not public, no prices, no entitlements.
-- Prices, limits and activation are business decisions made by the Super Admin (open decision D-3).
INSERT INTO subscription_plans (code, name, sort_order, is_active, is_public) VALUES
  ('free', 'Free', 1, 0, 0),
  ('starter', 'Starter', 2, 0, 0),
  ('professional', 'Professional', 3, 0, 0),
  ('business', 'Business', 4, 0, 0),
  ('enterprise', 'Enterprise', 5, 0, 0)
AS new ON DUPLICATE KEY UPDATE name = new.name, sort_order = new.sort_order;
