import asyncio
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from sqlmodel import text

async def main():
    engine = create_async_engine("postgresql+asyncpg://mynix:mynix_secret@127.0.0.1:5444/mynix_control")
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    async with async_session() as session:
        await session.execute(text("UPDATE tenants SET enable_inventory_deduction = true WHERE id = 1;"))
        await session.commit()
        print("enable_inventory_deduction is now set to True for Tenant 1.")

if __name__ == "__main__":
    asyncio.run(main())
