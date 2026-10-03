-- ==============================================================================
-- Mynix Control: Tenant Schema Migration Patch 002
-- Add is_archived column to ingredients table for archiving Poka-yoke feature
-- ==============================================================================

ALTER TABLE "{schema}".ingredients ADD COLUMN IF NOT EXISTS is_archived BOOLEAN DEFAULT FALSE NOT NULL;
