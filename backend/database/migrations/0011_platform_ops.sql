-- Platform administration, notifications, audit, outbox, idempotency.

CREATE TABLE platform_settings (
  setting_key VARCHAR(100) COLLATE ascii_bin NOT NULL,
  value JSON NOT NULL,
  description VARCHAR(255) NULL,
  updated_by_user_id BIGINT UNSIGNED NULL,
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (setting_key),
  FOREIGN KEY (updated_by_user_id) REFERENCES users (id)
);

CREATE TABLE announcements (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  public_id CHAR(26) COLLATE ascii_bin NOT NULL,
  audience ENUM('all_cafes','owners','customers') NOT NULL DEFAULT 'all_cafes',
  starts_at DATETIME(3) NOT NULL,
  ends_at DATETIME(3) NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_by_user_id BIGINT UNSIGNED NOT NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_announcements_public_id (public_id),
  FOREIGN KEY (created_by_user_id) REFERENCES users (id)
);

CREATE TABLE announcement_translations (
  announcement_id BIGINT UNSIGNED NOT NULL,
  language_code VARCHAR(12) COLLATE ascii_bin NOT NULL,
  title VARCHAR(200) NOT NULL,
  body TEXT NOT NULL,
  PRIMARY KEY (announcement_id, language_code),
  FOREIGN KEY (announcement_id) REFERENCES announcements (id),
  FOREIGN KEY (language_code) REFERENCES languages (code)
);

CREATE TABLE support_tickets (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  public_id CHAR(26) COLLATE ascii_bin NOT NULL,
  cafe_id BIGINT UNSIGNED NOT NULL,
  subject VARCHAR(200) NOT NULL,
  status ENUM('open','in_progress','waiting_on_cafe','resolved','closed') NOT NULL DEFAULT 'open',
  priority ENUM('low','normal','high','urgent') NOT NULL DEFAULT 'normal',
  opened_by_user_id BIGINT UNSIGNED NOT NULL,
  assigned_to_user_id BIGINT UNSIGNED NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_support_tickets_public_id (public_id),
  UNIQUE KEY uq_support_tickets_tenant (cafe_id, id),
  KEY idx_support_tickets_queue (status, priority, created_at),
  FOREIGN KEY (cafe_id) REFERENCES cafes (id),
  FOREIGN KEY (opened_by_user_id) REFERENCES users (id),
  FOREIGN KEY (assigned_to_user_id) REFERENCES users (id)
);

CREATE TABLE support_ticket_messages (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  cafe_id BIGINT UNSIGNED NOT NULL,
  ticket_id BIGINT UNSIGNED NOT NULL,
  author_user_id BIGINT UNSIGNED NOT NULL,
  body TEXT NOT NULL,
  is_internal_note TINYINT(1) NOT NULL DEFAULT 0,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_support_ticket_messages_tenant (cafe_id, id),
  FOREIGN KEY (cafe_id, ticket_id) REFERENCES support_tickets (cafe_id, id),
  FOREIGN KEY (author_user_id) REFERENCES users (id)
);

-- Append-only (triggers in 0012). Actor and entity are not FKs so history outlives its subject.
-- Must not contain secrets; personal data in before/after state is minimized by the writer.
CREATE TABLE audit_logs (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  cafe_id BIGINT UNSIGNED NULL,
  branch_id BIGINT UNSIGNED NULL,
  actor_type ENUM('user','customer','system','webhook') NOT NULL,
  actor_id BIGINT UNSIGNED NULL,
  action VARCHAR(100) COLLATE ascii_bin NOT NULL,
  entity_type VARCHAR(60) COLLATE ascii_bin NULL,
  entity_id VARCHAR(40) COLLATE ascii_bin NULL,
  reason VARCHAR(500) NULL,
  before_state JSON NULL,
  after_state JSON NULL,
  ip_address VARCHAR(45) COLLATE ascii_bin NULL,
  request_id VARCHAR(40) COLLATE ascii_bin NULL,
  occurred_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_audit_logs_tenant (cafe_id, id),
  KEY idx_audit_logs_tenant_time (cafe_id, occurred_at),
  KEY idx_audit_logs_actor (actor_type, actor_id, occurred_at),
  KEY idx_audit_logs_entity (entity_type, entity_id),
  KEY idx_audit_logs_action (action, occurred_at)
);

-- Written in the business transaction. dispatch_seq is assigned by the single dispatcher, in commit-safe
-- order, and is the replay cursor for reconnecting Socket.IO clients: an auto-increment id is not safe as
-- a cursor because a lower id can commit after a higher one.
CREATE TABLE outbox_events (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  event_id CHAR(26) COLLATE ascii_bin NOT NULL,
  cafe_id BIGINT UNSIGNED NULL,
  branch_id BIGINT UNSIGNED NULL,
  event_type VARCHAR(80) COLLATE ascii_bin NOT NULL,
  audience JSON NOT NULL,
  payload JSON NOT NULL,
  occurred_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  dispatch_seq BIGINT UNSIGNED NULL,
  dispatched_at DATETIME(3) NULL,
  attempts INT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  UNIQUE KEY uq_outbox_events_event_id (event_id),
  UNIQUE KEY uq_outbox_events_tenant (cafe_id, id),
  UNIQUE KEY uq_outbox_events_seq (dispatch_seq),
  KEY idx_outbox_events_pending (dispatched_at, id),
  KEY idx_outbox_events_replay (cafe_id, branch_id, dispatch_seq),
  FOREIGN KEY (cafe_id) REFERENCES cafes (id),
  FOREIGN KEY (cafe_id, branch_id) REFERENCES cafe_branches (cafe_id, id)
);

CREATE TABLE idempotency_keys (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  cafe_id BIGINT UNSIGNED NULL,
  principal VARCHAR(64) COLLATE ascii_bin NOT NULL,
  idempotency_key VARCHAR(100) COLLATE ascii_bin NOT NULL,
  request_hash CHAR(64) COLLATE ascii_bin NOT NULL,
  response_status SMALLINT UNSIGNED NULL,
  response_body JSON NULL,
  expires_at DATETIME(3) NOT NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_idempotency_keys_tenant (cafe_id, id),
  UNIQUE KEY uq_idempotency_keys (principal, idempotency_key),
  KEY idx_idempotency_keys_expiry (expires_at),
  FOREIGN KEY (cafe_id) REFERENCES cafes (id)
);

CREATE TABLE notification_templates (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  template_key VARCHAR(80) COLLATE ascii_bin NOT NULL,
  channel ENUM('push','in_app','email','sms','whatsapp') NOT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_notification_templates (template_key, channel)
);

CREATE TABLE notification_template_translations (
  template_id BIGINT UNSIGNED NOT NULL,
  language_code VARCHAR(12) COLLATE ascii_bin NOT NULL,
  title VARCHAR(200) NOT NULL,
  body TEXT NOT NULL,
  is_reviewed TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (template_id, language_code),
  FOREIGN KEY (template_id) REFERENCES notification_templates (id),
  FOREIGN KEY (language_code) REFERENCES languages (code)
);

CREATE TABLE notifications (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  public_id CHAR(26) COLLATE ascii_bin NOT NULL,
  cafe_id BIGINT UNSIGNED NULL,
  user_id BIGINT UNSIGNED NULL,
  customer_id BIGINT UNSIGNED NULL,
  template_key VARCHAR(80) COLLATE ascii_bin NOT NULL,
  language_code VARCHAR(12) COLLATE ascii_bin NOT NULL,
  title VARCHAR(200) NOT NULL,
  body TEXT NOT NULL,
  data JSON NULL,
  read_at DATETIME(3) NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_notifications_public_id (public_id),
  UNIQUE KEY uq_notifications_tenant (cafe_id, id),
  KEY idx_notifications_user_inbox (user_id, read_at, created_at),
  KEY idx_notifications_customer_inbox (customer_id, read_at, created_at),
  FOREIGN KEY (cafe_id) REFERENCES cafes (id),
  FOREIGN KEY (user_id) REFERENCES users (id),
  FOREIGN KEY (customer_id) REFERENCES customers (id),
  FOREIGN KEY (language_code) REFERENCES languages (code),
  CONSTRAINT chk_notifications_subject CHECK ((user_id IS NULL) <> (customer_id IS NULL))
);

CREATE TABLE notification_deliveries (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  notification_id BIGINT UNSIGNED NOT NULL,
  channel ENUM('push','in_app','email','sms','whatsapp') NOT NULL,
  status ENUM('queued','sent','delivered','failed','skipped') NOT NULL DEFAULT 'queued',
  provider_ref VARCHAR(191) NULL,
  error_message VARCHAR(500) NULL,
  attempts INT UNSIGNED NOT NULL DEFAULT 0,
  sent_at DATETIME(3) NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  KEY idx_notification_deliveries_queue (status, created_at),
  FOREIGN KEY (notification_id) REFERENCES notifications (id)
);

-- A cafe's choices about which alerts it receives.
CREATE TABLE notification_preferences (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  cafe_id BIGINT UNSIGNED NOT NULL,
  user_id BIGINT UNSIGNED NULL,
  user_key BIGINT UNSIGNED GENERATED ALWAYS AS (IFNULL(user_id, 0)) VIRTUAL,
  template_key VARCHAR(80) COLLATE ascii_bin NOT NULL,
  channel ENUM('push','in_app','email','sms','whatsapp') NOT NULL,
  is_enabled TINYINT(1) NOT NULL DEFAULT 1,
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_notification_preferences_tenant (cafe_id, id),
  UNIQUE KEY uq_notification_preferences (cafe_id, user_key, template_key, channel),
  FOREIGN KEY (cafe_id) REFERENCES cafes (id),
  FOREIGN KEY (cafe_id, user_id) REFERENCES cafe_staff (cafe_id, user_id)
);

CREATE TABLE device_tokens (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NULL,
  customer_id BIGINT UNSIGNED NULL,
  platform ENUM('android','ios','web') NOT NULL,
  token VARCHAR(512) COLLATE ascii_bin NOT NULL,
  token_hash CHAR(64) COLLATE ascii_bin NOT NULL,
  last_seen_at DATETIME(3) NULL,
  revoked_at DATETIME(3) NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_device_tokens_hash (token_hash),
  FOREIGN KEY (user_id) REFERENCES users (id),
  FOREIGN KEY (customer_id) REFERENCES customers (id),
  CONSTRAINT chk_device_tokens_subject CHECK ((user_id IS NULL) <> (customer_id IS NULL))
);
