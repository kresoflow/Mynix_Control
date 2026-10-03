-- ==============================================================================
-- Mynix Control: Tenant Schema Migration Patch 006
-- Clear retail_product_id from parent menu items that have variations
-- ==============================================================================

-- If a parent MenuItem has variations in attributes, it must NOT have retail_product_id
UPDATE "{schema}".menu_items
SET retail_product_id = NULL
WHERE retail_product_id IS NOT NULL
  AND attributes IS NOT NULL
  AND attributes::text LIKE '%"variations"%';
