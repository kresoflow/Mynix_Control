import asyncio
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker, selectinload
from sqlmodel import select
from app.config import settings
from app.inventory.models import MenuItem

def main():
    engine = create_async_engine(str(settings.database_url))
    stmt = select(MenuItem).options(selectinload(MenuItem.category)).where(MenuItem.parent_id.is_(None)).order_by(MenuItem.sort_order, MenuItem.id)
    print(stmt.compile(engine, compile_kwargs={'literal_binds': True}))

main()
