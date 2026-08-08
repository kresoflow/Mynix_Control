import asyncio
from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy import text

async def main():
    engine = create_async_engine("postgresql+asyncpg://mynix:mynix_secret@127.0.0.1:5444/mynix_control")
    try:
        async with engine.begin() as conn:
            # Get all schema names
            result = await conn.execute(text("SELECT schema_name FROM information_schema.schemata WHERE schema_name NOT IN ('information_schema', 'pg_catalog', 'pg_toast', 'public')"))
            schemas = [row[0] for row in result.fetchall()]
            
            for schema in schemas:
                print(f"Applying to schema: {schema}")
                
                # Create suppliers table
                await conn.execute(text(f"""
                    CREATE TABLE IF NOT EXISTS {schema}.suppliers (
                        id SERIAL PRIMARY KEY,
                        name VARCHAR(150) NOT NULL,
                        contact_info VARCHAR(255),
                        is_active BOOLEAN NOT NULL DEFAULT TRUE,
                        created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL,
                        updated_at TIMESTAMP WITHOUT TIME ZONE
                    );
                """))

                # Create inventory_documents table
                await conn.execute(text(f"""
                    CREATE TABLE IF NOT EXISTS {schema}.inventory_documents (
                        id SERIAL PRIMARY KEY,
                        type VARCHAR NOT NULL,
                        status VARCHAR NOT NULL DEFAULT 'draft',
                        date TIMESTAMP WITH TIME ZONE NOT NULL,
                        supplier_id INTEGER REFERENCES {schema}.suppliers(id),
                        invoice_number VARCHAR(100),
                        reason VARCHAR(255),
                        total_amount FLOAT NOT NULL DEFAULT 0.0,
                        created_by INTEGER,
                        created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL,
                        updated_at TIMESTAMP WITHOUT TIME ZONE
                    );
                """))

                # Create inventory_document_items table
                await conn.execute(text(f"""
                    CREATE TABLE IF NOT EXISTS {schema}.inventory_document_items (
                        id SERIAL PRIMARY KEY,
                        document_id INTEGER NOT NULL REFERENCES {schema}.inventory_documents(id) ON DELETE CASCADE,
                        ingredient_id INTEGER REFERENCES {schema}.ingredients(id),
                        retail_product_id INTEGER REFERENCES {schema}.retail_products(id),
                        quantity FLOAT NOT NULL,
                        price_per_unit FLOAT NOT NULL,
                        total_price FLOAT NOT NULL,
                        created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL,
                        updated_at TIMESTAMP WITHOUT TIME ZONE
                    );
                """))

            print("Tables created successfully")
    except Exception as e:
        print("Error:", e)

if __name__ == "__main__":
    asyncio.run(main())
