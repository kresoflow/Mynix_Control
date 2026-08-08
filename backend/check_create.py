import asyncio
from app.inventory.services.menu_service import create_menu_item
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from app.config import settings
from sqlalchemy import text
import pprint

async def main():
    engine = create_async_engine(str(settings.database_url))
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    async with async_session() as session:
        await session.execute(text("SET search_path TO tenant_1"))
        data = {
            'name': 'Test Dish',
            'price': 0.0,
            'category_id': 1,
            'is_available': True,
            'attributes': {'variations': [{'name': 'S', 'price': 10}, {'name': 'L', 'price': 20}]},
            'sort_order': 0
        }
        item = await create_menu_item(session, data)
        # What does item look like?
        print('Item ID:', item.id)
        print('Item children:', item.children)
asyncio.run(main())
