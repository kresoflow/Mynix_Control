import asyncio
from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy import text
from app.config import settings

async def main():
    engine = create_async_engine(str(settings.database_url))
    try:
        async with engine.begin() as conn:
            result = await conn.execute(text("SELECT id, name, parent_id FROM tenant_2.menu_items ORDER BY id DESC LIMIT 15"))
            print('Tenant 2 recent items:')
            for row in result.fetchall():
                print(row)
    except Exception as e:
        pass

asyncio.run(main())
