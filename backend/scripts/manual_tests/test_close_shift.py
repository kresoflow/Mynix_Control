import asyncio
from sqlalchemy import text
from app.database import async_session_factory
from app.users.models import User  # IMPORT THIS SO METADATA KNOWS ABOUT IT
from app.pos.services.shift_service import get_open_shift, close_shift

async def main():
    async with async_session_factory() as session:
        await session.execute(text('SET search_path TO "tenant_1"'))
        shift = await get_open_shift(session)
        if shift:
            print("Open shift ID:", shift.id)
            print("Closing shift...")
            try:
                closed = await close_shift(session, 1, 26240.0)
                await session.commit()
                print("Shift closed successfully! Discrepancy:", closed.discrepancy)
            except Exception as e:
                import traceback
                traceback.print_exc()
        else:
            print("No open shift")

if __name__ == "__main__":
    asyncio.run(main())
