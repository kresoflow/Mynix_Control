import asyncio
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker, selectinload
from sqlmodel import select
from app.config import settings
from app.inventory.models import MenuItem
from sqlalchemy import text

async def main():
    engine = create_async_engine(str(settings.database_url))
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    async with async_session() as session:
        await session.execute(text("SET search_path TO tenant_1"))
        stmt = select(MenuItem).options(selectinload(MenuItem.category)).where(MenuItem.parent_id.is_(None)).order_by(MenuItem.sort_order, MenuItem.id)
        result = await session.execute(stmt)
        items = result.scalars().all()
        q_items = [i for i in items if 'Q' in i.name]
        print('Total Q items returned by list_menu_items:', len(q_items))
        for i in q_items:
            print(i.id, i.name, i.parent_id)

asyncio.run(main())
