-- Refresh must restore the cafe the user chose at login, even if they belong to several.
ALTER TABLE login_sessions
  ADD COLUMN cafe_id BIGINT UNSIGNED NULL AFTER customer_id,
  ADD FOREIGN KEY (cafe_id) REFERENCES cafes (id);
