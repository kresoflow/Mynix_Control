-- ==============================================================================
-- Kreso Flow: Tenant Schema Migration Patch 008
-- Add payment_account column to orders for P2P transfer / account breakdown
-- ==============================================================================

ALTER TABLE "{schema}".orders
ADD COLUMN IF NOT EXISTS payment_account VARCHAR(30) DEFAULT NULL;

CREATE INDEX IF NOT EXISTS ix_orders_payment_account
ON "{schema}".orders (payment_account);

-- Backfill existing cash orders
UPDATE "{schema}".orders
SET payment_account = 'cash'
WHERE payment_account IS NULL AND LOWER(payment_method) = 'cash';

-- Backfill DC transfers
UPDATE "{schema}".orders
SET payment_account = 'dc'
WHERE payment_account IS NULL AND (LOWER(COALESCE(note, '')) LIKE '%dc%' OR LOWER(payment_method) LIKE '%dc%');

-- Backfill Alif transfers
UPDATE "{schema}".orders
SET payment_account = 'alif'
WHERE payment_account IS NULL AND (LOWER(COALESCE(note, '')) LIKE '%alif%' OR LOWER(COALESCE(note, '')) LIKE '%алиф%' OR LOWER(payment_method) LIKE '%alif%');

-- Backfill Spitamen transfers
UPDATE "{schema}".orders
SET payment_account = 'spitamen'
WHERE payment_account IS NULL AND (LOWER(COALESCE(note, '')) LIKE '%spitamen%' OR LOWER(COALESCE(note, '')) LIKE '%спитамен%' OR LOWER(payment_method) LIKE '%spitamen%');
