-- ==============================================================================
-- Mynix Control: Tenant Schema Migration Patch 005
-- Normalize RetailProduct units to 'PCS' (piece goods) and update flat SKU names
-- ==============================================================================

-- Step 1: Normalize warehouse storage unit to 'PCS' for retail showcase items
UPDATE "{schema}".retail_products
SET unit = 'PCS'
WHERE unit::text IN ('L', 'ML', 'KG', 'G', 'l', 'ml', 'kg', 'g');

-- Step 2: Ensure flat RetailProduct names contain flavor and volume if specified in attributes
UPDATE "{schema}".retail_products
SET name = TRIM(name || ' ' || COALESCE(attributes->>'flavor', '') || ' ' || COALESCE(attributes->>'volume', ''))
WHERE attributes IS NOT NULL
  AND (attributes->>'flavor' IS NOT NULL OR attributes->>'volume' IS NOT NULL)
  AND (
    (attributes->>'flavor' IS NOT NULL AND position(attributes->>'flavor' in name) = 0)
    OR
    (attributes->>'volume' IS NOT NULL AND position(attributes->>'volume' in name) = 0)
  );
