-- ==============================================================================
-- Mynix Control: Tenant Schema Migration Patch 004
-- Add client_uuid column to gift_card_transactions for idempotency
-- ==============================================================================

ALTER TABLE "{schema}".gift_card_transactions
ADD COLUMN IF NOT EXISTS client_uuid VARCHAR(64);

CREATE INDEX IF NOT EXISTS ix_gift_card_transactions_client_uuid
ON "{schema}".gift_card_transactions (client_uuid);
