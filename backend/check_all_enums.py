import asyncio
from sqlalchemy import text
from app.database import async_session_factory

async def main():
    async with async_session_factory() as session:
        await session.execute(text('SET search_path TO "tenant_1"'))
        result = await session.execute(text("SELECT unnest(enum_range(NULL::cashtransactiontype))"))
        for row in result.fetchall():
            print("ENUM VALUE cashtransactiontype:", row[0])

        result2 = await session.execute(text("SELECT unnest(enum_range(NULL::orderstatus))"))
        for row in result2.fetchall():
            print("ENUM VALUE orderstatus:", row[0])

if __name__ == "__main__":
    asyncio.run(main())
