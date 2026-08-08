import asyncio
from app.database import async_session_factory
from app.inventory.models import MenuCategory
from sqlmodel import select

async def main():
    async with async_session_factory() as session:
        result = await session.execute(select(MenuCategory))
        for c in result.scalars().all():
            print(f"ID: {c.id}, Name: {c.name}, Type: {c.category_type}, Parent: {c.parent_id}")

asyncio.run(main())
