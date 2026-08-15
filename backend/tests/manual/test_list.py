import asyncio
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from app.config import settings
from app.inventory.services.menu_service import list_menu_items
from sqlalchemy import text

async def main():
    engine = create_async_engine(str(settings.database_url))
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    async with async_session() as session:
        await session.execute(text('SET search_path TO tenant_1'))
        items = await list_menu_items(session)
        print('Total returned:', len(items))
        for i in items:
            if 'TOP' in i.name or 'MEGA' in i.name or '???' in i.name:
                print(i.id, i.name)

asyncio.run(main())
