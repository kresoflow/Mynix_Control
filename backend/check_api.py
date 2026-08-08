import asyncio
import httpx

async def main():
    async with httpx.AsyncClient() as client:
        # Note: We need a valid token. Let's just bypass auth and query the DB directly,
        # but with the exact same SQL logic.
        from sqlalchemy.ext.asyncio import create_async_engine
        from sqlalchemy import text
        from app.config import settings
        engine = create_async_engine(str(settings.database_url))
        async with engine.begin() as conn:
            result = await conn.execute(text("SELECT id, name, parent_id FROM tenant_1.menu_items WHERE name LIKE '%Q%' AND parent_id IS NULL"))
            print('Parent ID IS NULL:')
            for row in result.fetchall():
                print(row)
                
            result2 = await conn.execute(text("SELECT id, name, parent_id FROM tenant_1.menu_items WHERE name LIKE '%Q%'"))
            print('\nAll items:')
            for row in result2.fetchall():
                print(row)
asyncio.run(main())
