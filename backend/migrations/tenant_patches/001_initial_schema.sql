-- ==============================================================================
-- Mynix Control: Tenant Schema Migration Patch 001
-- Tables, columns, and indexes for tenant schema
-- ==============================================================================

-- 1. Suppliers balance column
ALTER TABLE "{schema}".suppliers ADD COLUMN IF NOT EXISTS balance FLOAT DEFAULT 0.0 NOT NULL;

-- 2. Inventory documents payment columns
ALTER TABLE "{schema}".inventory_documents ADD COLUMN IF NOT EXISTS payment_status VARCHAR(20) DEFAULT 'unpaid';
ALTER TABLE "{schema}".inventory_documents ADD COLUMN IF NOT EXISTS paid_amount FLOAT DEFAULT 0.0 NOT NULL;
ALTER TABLE "{schema}".inventory_documents ADD COLUMN IF NOT EXISTS payment_method VARCHAR(30) DEFAULT 'cash';
ALTER TABLE "{schema}".inventory_document_items ADD COLUMN IF NOT EXISTS expected_quantity DOUBLE PRECISION;

-- 3. Orders status and payment method type normalization
ALTER TABLE "{schema}".orders ALTER COLUMN payment_method TYPE VARCHAR(30) USING payment_method::VARCHAR;
UPDATE "{schema}".orders SET payment_method = LOWER(payment_method) WHERE payment_method IS NOT NULL;
ALTER TABLE "{schema}".orders ALTER COLUMN status TYPE VARCHAR(30) USING status::VARCHAR;
UPDATE "{schema}".orders SET status = LOWER(status) WHERE status IS NOT NULL;

-- 4. Catalog and stock tables category_id nullability
ALTER TABLE "{schema}".retail_products ALTER COLUMN category_id DROP NOT NULL;
ALTER TABLE "{schema}".menu_items ALTER COLUMN category_id DROP NOT NULL;
ALTER TABLE "{schema}".ingredients ALTER COLUMN category_id DROP NOT NULL;

-- 5. Orders table and source columns
ALTER TABLE "{schema}".orders ADD COLUMN IF NOT EXISTS table_number VARCHAR(50);
ALTER TABLE "{schema}".orders ADD COLUMN IF NOT EXISTS order_source VARCHAR(30) DEFAULT 'pos';

-- 6. Supplier transactions table
CREATE TABLE IF NOT EXISTS "{schema}".supplier_transactions (
    id SERIAL PRIMARY KEY,
    supplier_id INTEGER NOT NULL REFERENCES "{schema}".suppliers(id) ON DELETE CASCADE,
    document_id INTEGER REFERENCES "{schema}".inventory_documents(id) ON DELETE SET NULL,
    type VARCHAR(30) NOT NULL,
    amount DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    payment_method VARCHAR(30) DEFAULT 'cash',
    comment VARCHAR(255),
    date TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT (now() AT TIME ZONE 'utc'),
    created_by INTEGER REFERENCES public.users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT (now() AT TIME ZONE 'utc'),
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT NULL
);
CREATE INDEX IF NOT EXISTS ix_{schema}_supplier_transactions_supplier_id ON "{schema}".supplier_transactions(supplier_id);
CREATE INDEX IF NOT EXISTS ix_{schema}_supplier_transactions_document_id ON "{schema}".supplier_transactions(document_id);

-- 7. Customers table
CREATE TABLE IF NOT EXISTS "{schema}".customers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    phone VARCHAR(50),
    email VARCHAR(100),
    address VARCHAR(255),
    balance DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    credit_limit DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    discount_percent DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    notes VARCHAR(500),
    is_active BOOLEAN NOT NULL DEFAULT true,
    total_spent DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    orders_count INTEGER NOT NULL DEFAULT 0,
    average_check DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    last_visit_at TIMESTAMP WITHOUT TIME ZONE DEFAULT NULL,
    bonus_balance DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    tier_level VARCHAR(30) NOT NULL DEFAULT 'standard',
    birth_date DATE DEFAULT NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT (now() AT TIME ZONE 'utc'),
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT NULL
);
CREATE INDEX IF NOT EXISTS ix_{schema}_customers_name ON "{schema}".customers(name);
CREATE INDEX IF NOT EXISTS ix_{schema}_customers_phone ON "{schema}".customers(phone);

-- 8. Customer LTV and loyalty columns
ALTER TABLE "{schema}".customers ADD COLUMN IF NOT EXISTS total_spent DOUBLE PRECISION NOT NULL DEFAULT 0.0;
ALTER TABLE "{schema}".customers ADD COLUMN IF NOT EXISTS orders_count INTEGER NOT NULL DEFAULT 0;
ALTER TABLE "{schema}".customers ADD COLUMN IF NOT EXISTS average_check DOUBLE PRECISION NOT NULL DEFAULT 0.0;
ALTER TABLE "{schema}".customers ADD COLUMN IF NOT EXISTS last_visit_at TIMESTAMP WITHOUT TIME ZONE DEFAULT NULL;
ALTER TABLE "{schema}".customers ADD COLUMN IF NOT EXISTS bonus_balance DOUBLE PRECISION NOT NULL DEFAULT 0.0;
ALTER TABLE "{schema}".customers ADD COLUMN IF NOT EXISTS tier_level VARCHAR(30) NOT NULL DEFAULT 'standard';
ALTER TABLE "{schema}".customers ADD COLUMN IF NOT EXISTS birth_date DATE DEFAULT NULL;

-- 9. Orders customer and bonus columns
ALTER TABLE "{schema}".orders ADD COLUMN IF NOT EXISTS customer_id INTEGER REFERENCES "{schema}".customers(id) ON DELETE SET NULL;
ALTER TABLE "{schema}".orders ADD COLUMN IF NOT EXISTS bonus_spent DOUBLE PRECISION NOT NULL DEFAULT 0.0;
ALTER TABLE "{schema}".orders ADD COLUMN IF NOT EXISTS client_uuid VARCHAR(64);
CREATE INDEX IF NOT EXISTS ix_{schema}_orders_client_uuid ON "{schema}".orders(client_uuid);

-- 10. Order items columns
ALTER TABLE "{schema}".order_items ADD COLUMN IF NOT EXISTS unit_cost DOUBLE PRECISION NOT NULL DEFAULT 0.0;
ALTER TABLE "{schema}".order_items ADD COLUMN IF NOT EXISTS item_type VARCHAR(50) DEFAULT 'dish';
ALTER TABLE "{schema}".order_items ADD COLUMN IF NOT EXISTS selected_options JSONB DEFAULT '{}'::jsonb;

-- 11. Customer transactions table
CREATE TABLE IF NOT EXISTS "{schema}".customer_transactions (
    id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES "{schema}".customers(id) ON DELETE CASCADE,
    order_id INTEGER REFERENCES "{schema}".orders(id) ON DELETE SET NULL,
    type VARCHAR(30) NOT NULL,
    amount DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    payment_method VARCHAR(30) DEFAULT 'cash',
    comment VARCHAR(255),
    date TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT (now() AT TIME ZONE 'utc'),
    created_by INTEGER REFERENCES public.users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT (now() AT TIME ZONE 'utc'),
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT NULL
);
CREATE INDEX IF NOT EXISTS ix_{schema}_customer_transactions_customer_id ON "{schema}".customer_transactions(customer_id);
CREATE INDEX IF NOT EXISTS ix_{schema}_customer_transactions_order_id ON "{schema}".customer_transactions(order_id);

-- 12. Bonus transactions table
CREATE TABLE IF NOT EXISTS "{schema}".bonus_transactions (
    id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES "{schema}".customers(id) ON DELETE CASCADE,
    order_id INTEGER REFERENCES "{schema}".orders(id) ON DELETE SET NULL,
    type VARCHAR(30) NOT NULL,
    amount DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    comment VARCHAR(255),
    date TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT (now() AT TIME ZONE 'utc'),
    created_by INTEGER REFERENCES public.users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT (now() AT TIME ZONE 'utc'),
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT NULL
);
CREATE INDEX IF NOT EXISTS ix_{schema}_bonus_transactions_customer_id ON "{schema}".bonus_transactions(customer_id);
CREATE INDEX IF NOT EXISTS ix_{schema}_bonus_transactions_order_id ON "{schema}".bonus_transactions(order_id);
