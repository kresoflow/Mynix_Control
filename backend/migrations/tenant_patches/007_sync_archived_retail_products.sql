-- ==============================================================================
-- Mynix Control: Tenant Schema Migration Patch 007
-- 1. Sync is_available = false to RetailProduct for archived MenuItems
-- 2. Clean up sort_order collisions per category by creation order (FIFO)
-- ==============================================================================

-- Step 1: Cascade is_available = false to retail_products linked to archived menu items
UPDATE "{schema}".retail_products
SET is_available = false
WHERE id IN (
    SELECT retail_product_id FROM "{schema}".menu_items WHERE is_available = false AND retail_product_id IS NOT NULL
    UNION
    SELECT c.retail_product_id FROM "{schema}".menu_items p
    JOIN "{schema}".menu_items c ON c.parent_id = p.id
    WHERE p.is_available = false AND c.retail_product_id IS NOT NULL
);

-- Step 2: Re-index sort_order per category chronologically (created_at ASC, id ASC)
WITH ranked AS (
    SELECT id, ROW_NUMBER() OVER (
        PARTITION BY category_id 
        ORDER BY created_at ASC, id ASC
    ) as new_sort
    FROM "{schema}".menu_items
    WHERE parent_id IS NULL
)
UPDATE "{schema}".menu_items m
SET sort_order = ranked.new_sort
FROM ranked
WHERE m.id = ranked.id;
