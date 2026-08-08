import asyncio
from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy import text
from app.config import settings

async def main():
    engine = create_async_engine(str(settings.database_url))
    try:
        async with engine.begin() as conn:
            result = await conn.execute(text("SELECT schema_name FROM information_schema.schemata WHERE schema_name LIKE 'tenant_%'"))
            schemas = [row[0] for row in result.fetchall()]
            for schema in schemas:
                print(f'Applying to schema: {schema}')
                await conn.execute(text(f'ALTER TABLE {schema}.menu_items ADD COLUMN IF NOT EXISTS parent_id INTEGER REFERENCES {schema}.menu_items(id);'))
            print('Success')
    except Exception as e:
        print('Error:', e)
asyncio.run(main())
