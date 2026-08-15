import asyncio
from sqlalchemy import text
from app.database import async_session_factory
from app.pos.services.shift_service import get_open_shift, calculate_expected_cash

async def main():
    async with async_session_factory() as session:
        await session.execute(text('SET search_path TO "tenant_1"'))
        shift = await get_open_shift(session)
        if shift:
            print("Open shift ID:", shift.id)
            exp = await calculate_expected_cash(session, shift.id, shift.opening_cash)
            print("Expected cash:", exp)
        else:
            print("No open shift")

if __name__ == "__main__":
    asyncio.run(main())
