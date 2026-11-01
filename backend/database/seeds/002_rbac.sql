-- Implements the matrix in docs/AUTHENTICATION_AND_SECURITY.md.

INSERT INTO permissions (code, module, scope, description) VALUES
  ('platform.dashboard.read', 'platform', 'platform', 'View platform dashboard and analytics'),
  ('platform.cafes.read', 'platform', 'platform', 'View cafes across the platform (audited)'),
  ('platform.cafes.manage', 'platform', 'platform', 'Approve, suspend and activate cafes'),
  ('platform.plans.manage', 'platform', 'platform', 'Manage plans, entitlements and subscriptions'),
  ('platform.commissions.manage', 'platform', 'platform', 'Configure commissions'),
  ('platform.users.manage', 'platform', 'platform', 'Manage global users'),
  ('platform.settings.manage', 'platform', 'platform', 'System configuration, branding, countries, currencies'),
  ('platform.translations.manage', 'platform', 'platform', 'Manage languages and translations'),
  ('platform.announcements.manage', 'platform', 'platform', 'Publish announcements'),
  ('platform.support.manage', 'platform', 'platform', 'Handle support tickets'),
  ('platform.audit.read', 'platform', 'platform', 'Read audit logs'),
  ('platform.finance.read', 'platform', 'platform', 'Read platform financial reports'),
  ('platform.health.read', 'platform', 'platform', 'Read system health'),
  ('platform.customer_pii.read', 'platform', 'platform', 'Unmask customer data with a logged reason'),

  ('cafe.profile.read', 'tenancy', 'cafe', 'View cafe profile and branches'),
  ('cafe.profile.manage', 'tenancy', 'cafe', 'Edit cafe profile, branches, hours, settings'),
  ('cafe.branding.manage', 'branding', 'cafe', 'Edit theme and banners'),
  ('menu.read', 'catalog', 'cafe', 'View menu'),
  ('menu.manage', 'catalog', 'cafe', 'Edit menu, prices, availability'),
  ('tax.manage', 'tax', 'cafe', 'Edit tax categories and registrations'),
  ('tables.read', 'tables', 'cafe', 'View tables and QR'),
  ('tables.manage', 'tables', 'cafe', 'Edit tables, regenerate QR'),
  ('tables.transfer', 'tables', 'cafe', 'Authorize table merges and transfers'),
  ('reservations.manage', 'tables', 'cafe', 'Manage reservations'),
  ('orders.read', 'ordering', 'cafe', 'View orders'),
  ('orders.create', 'ordering', 'cafe', 'Enter manual orders'),
  ('orders.update', 'ordering', 'cafe', 'Progress and modify orders'),
  ('orders.cancel', 'ordering', 'cafe', 'Cancel orders'),
  ('service_requests.manage', 'ordering', 'cafe', 'Handle waiter and bill requests'),
  ('kitchen.read', 'kitchen', 'cafe', 'View kitchen tickets'),
  ('kitchen.operate', 'kitchen', 'cafe', 'Accept, start and complete tickets'),
  ('kitchen.configure', 'kitchen', 'cafe', 'Configure stations and routing'),
  ('payments.read', 'payments', 'cafe', 'View payments'),
  ('payments.cash_confirm', 'payments', 'cafe', 'Confirm cash received'),
  ('payments.gateway_manage', 'payments', 'cafe', 'Configure gateway accounts'),
  ('refunds.request', 'payments', 'cafe', 'Request refunds'),
  ('refunds.approve', 'payments', 'cafe', 'Approve refunds'),
  ('invoices.read', 'invoicing', 'cafe', 'View invoices'),
  ('invoices.issue', 'invoicing', 'cafe', 'Issue invoices and credit notes'),
  ('staff.read', 'staff', 'cafe', 'View staff'),
  ('staff.manage', 'staff', 'cafe', 'Add staff and assign roles'),
  ('attendance.self', 'staff', 'cafe', 'Clock in and out'),
  ('attendance.manage', 'staff', 'cafe', 'Manage attendance for others'),
  ('inventory.read', 'inventory', 'cafe', 'View stock'),
  ('inventory.manage', 'inventory', 'cafe', 'Stock movements, recipes, suppliers, purchasing'),
  ('finance.read', 'finance', 'cafe', 'View financial reports'),
  ('finance.manage', 'finance', 'cafe', 'Expenses, journals, periods, payroll'),
  ('cash_register.operate', 'finance', 'cafe', 'Open, close and record on a cash register'),
  ('customers.read', 'customers', 'cafe', 'View this cafe''s customers'),
  ('marketing.manage', 'marketing', 'cafe', 'Coupons, promotions, loyalty, review replies'),
  ('reports.read', 'analytics', 'cafe', 'View business analytics'),
  ('subscription.manage', 'subscriptions', 'cafe', 'Manage the cafe subscription'),
  ('audit.read', 'platform', 'cafe', 'Read this cafe''s audit log'),
  ('support.use', 'platform', 'cafe', 'Open support tickets')
AS new ON DUPLICATE KEY UPDATE module = new.module, scope = new.scope, description = new.description;

INSERT INTO roles (cafe_id, code, name, scope, is_system) VALUES
  (NULL, 'super_admin', 'Super Admin', 'platform', 1),
  (NULL, 'platform_support', 'Platform Support', 'platform', 1),
  (NULL, 'owner', 'Owner', 'cafe', 1),
  (NULL, 'manager', 'Manager', 'cafe', 1),
  (NULL, 'cashier', 'Cashier', 'cafe', 1),
  (NULL, 'waiter', 'Waiter', 'cafe', 1),
  (NULL, 'kitchen_staff', 'Kitchen Staff', 'cafe', 1)
AS new ON DUPLICATE KEY UPDATE name = new.name, scope = new.scope, is_system = new.is_system;

-- System role permissions are replaced wholesale, so removing one from this file removes it from the role.
DELETE rp FROM role_permissions rp JOIN roles r ON r.id = rp.role_id WHERE r.cafe_id IS NULL AND r.is_system = 1;

INSERT INTO role_permissions (role_id, permission_code)
SELECT r.id, p.code FROM roles r JOIN permissions p ON p.scope = 'platform'
WHERE r.cafe_id IS NULL AND r.code = 'super_admin';

INSERT INTO role_permissions (role_id, permission_code)
SELECT r.id, p.code FROM roles r JOIN permissions p
  ON p.code IN ('platform.dashboard.read','platform.cafes.read','platform.support.manage','platform.audit.read','platform.health.read')
WHERE r.cafe_id IS NULL AND r.code = 'platform_support';

INSERT INTO role_permissions (role_id, permission_code)
SELECT r.id, p.code FROM roles r JOIN permissions p ON p.scope = 'cafe'
WHERE r.cafe_id IS NULL AND r.code = 'owner';

INSERT INTO role_permissions (role_id, permission_code)
SELECT r.id, p.code FROM roles r JOIN permissions p ON p.code IN (
  'cafe.profile.read','menu.read','menu.manage','tables.read','tables.manage','tables.transfer','reservations.manage',
  'orders.read','orders.create','orders.update','orders.cancel','service_requests.manage',
  'kitchen.read','kitchen.operate','kitchen.configure','payments.read','payments.cash_confirm','refunds.request','refunds.approve',
  'invoices.read','invoices.issue','staff.read','attendance.self','attendance.manage','inventory.read','inventory.manage',
  'finance.read','cash_register.operate','customers.read','reports.read','support.use')
WHERE r.cafe_id IS NULL AND r.code = 'manager';

INSERT INTO role_permissions (role_id, permission_code)
SELECT r.id, p.code FROM roles r JOIN permissions p ON p.code IN (
  'menu.read','tables.read','orders.read','orders.create','orders.update','service_requests.manage',
  'payments.read','payments.cash_confirm','refunds.request','invoices.read','invoices.issue','attendance.self','cash_register.operate')
WHERE r.cafe_id IS NULL AND r.code = 'cashier';

INSERT INTO role_permissions (role_id, permission_code)
SELECT r.id, p.code FROM roles r JOIN permissions p ON p.code IN (
  'menu.read','tables.read','orders.read','orders.create','orders.update','service_requests.manage','reservations.manage','attendance.self')
WHERE r.cafe_id IS NULL AND r.code = 'waiter';

INSERT INTO role_permissions (role_id, permission_code)
SELECT r.id, p.code FROM roles r JOIN permissions p ON p.code IN (
  'menu.read','orders.read','kitchen.read','kitchen.operate','inventory.read','attendance.self')
WHERE r.cafe_id IS NULL AND r.code = 'kitchen_staff';
