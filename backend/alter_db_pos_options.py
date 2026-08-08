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
                await conn.execute(text(f"ALTER TABLE {schema}.order_items ADD COLUMN IF NOT EXISTS selected_options JSONB DEFAULT '{{}}'::jsonb;"))

            print("Column selected_options added successfully")
    except Exception as e:
        print("Error:", e)

if __name__ == "__main__":
    asyncio.run(main())
