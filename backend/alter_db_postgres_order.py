import asyncio
from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy import text

async def main():
    engine = create_async_engine("postgresql+asyncpg://mynix:mynix_secret@127.0.0.1:5444/mynix_control")
    try:
        async with engine.begin() as conn:
            await conn.execute(text("ALTER TABLE order_items ADD COLUMN item_type VARCHAR DEFAULT 'dish'"))
            print("Column item_type added successfully to order_items")
    except Exception as e:
        print("Error:", e)

if __name__ == "__main__":
    asyncio.run(main())
