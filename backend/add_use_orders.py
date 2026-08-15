import asyncio
from sqlalchemy import text
from app.database import async_session_factory

async def main():
    async with async_session_factory() as session:
        await session.execute(text('ALTER TABLE tenants ADD COLUMN IF NOT EXISTS use_orders BOOLEAN NOT NULL DEFAULT TRUE'))
        await session.commit()
        print('Added use_orders')

if __name__ == "__main__":
    asyncio.run(main())
