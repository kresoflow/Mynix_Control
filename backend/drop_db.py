import asyncio
from app.database import async_engine
from sqlalchemy import text

async def drop_all():
    async with async_engine.begin() as conn:
        # Get all tenant schemas
        res = await conn.execute(text("SELECT schema_name FROM information_schema.schemata WHERE schema_name LIKE 'tenant_%'"))
        schemas = [row[0] for row in res.fetchall()]
        for schema in schemas:
            print(f"Dropping schema {schema}...")
            await conn.execute(text(f"DROP SCHEMA IF EXISTS {schema} CASCADE"))
            
        print("Dropping public schema...")
        await conn.execute(text("DROP SCHEMA IF EXISTS public CASCADE"))
        print("Creating public schema...")
        await conn.execute(text("CREATE SCHEMA public"))
        print("Done.")

if __name__ == "__main__":
    asyncio.run(drop_all())
