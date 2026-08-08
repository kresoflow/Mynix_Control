import asyncio
from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy import text

async def main():
    engine = create_async_engine('postgresql+asyncpg://mynix:mynix_secret@127.0.0.1:5444/mynix_control')
    async with engine.begin() as conn:
        result = await conn.execute(text("SELECT schema_name FROM information_schema.schemata WHERE schema_name NOT IN ('information_schema', 'pg_catalog', 'pg_toast', 'public')"))
        schemas = [r[0] for r in result.fetchall()]
        for schema in schemas:
            await conn.execute(text(f"ALTER TABLE {schema}.inventory_documents ALTER COLUMN date TYPE TIMESTAMP WITHOUT TIME ZONE;"))
        print('Altered columns')

if __name__ == "__main__":
    asyncio.run(main())
