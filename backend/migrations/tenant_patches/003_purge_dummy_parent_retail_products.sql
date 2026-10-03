-- ==============================================================================
-- Mynix Control: Tenant Schema Migration Patch 003
-- Purge dummy parent RetailProduct records created for group containers with variations
-- ==============================================================================

-- Step 1: Unlink parent group menu_items from dummy retail_products
UPDATE "{schema}".menu_items
SET retail_product_id = NULL
WHERE attributes IS NOT NULL
  AND attributes ? 'variations'
  AND jsonb_array_length(attributes->'variations') > 0
  AND parent_id IS NULL
  AND retail_product_id IS NOT NULL;

-- Step 2: Delete dummy parent retail_products with variations
DELETE FROM "{schema}".retail_products
WHERE attributes IS NOT NULL
  AND attributes ? 'variations'
  AND jsonb_array_length(attributes->'variations') > 0
  AND id NOT IN (SELECT retail_product_id FROM "{schema}".menu_items WHERE retail_product_id IS NOT NULL);
