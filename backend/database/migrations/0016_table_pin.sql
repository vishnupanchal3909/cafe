-- An optional PIN per table session, so a photo of a table's QR code is not enough to order from elsewhere.
-- Stored encrypted: staff read it out to the guests at the table.
ALTER TABLE table_sessions ADD COLUMN pin_ciphertext VARBINARY(255) NULL AFTER token_hash;
