import asyncio
from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy import text
from app.config import settings

async def main():
    engine = create_async_engine(str(settings.database_url))
    try:
        async with engine.begin() as conn:
            result = await conn.execute(text("SELECT id, name, parent_id, price, attributes FROM tenant_1.menu_items ORDER BY id DESC LIMIT 10"))
            for row in result.fetchall():
                print(row)
    except Exception as e:
        print('Error:', e)
asyncio.run(main())
