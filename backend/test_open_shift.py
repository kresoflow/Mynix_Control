import asyncio
from sqlalchemy import text
from app.database import async_session_factory
from app.pos.services.shift_service import get_open_shift, open_shift

async def main():
    async with async_session_factory() as session:
        await session.execute(text('SET search_path TO "tenant_1"'))
        shift = await get_open_shift(session)
        if shift:
            print(f"Shift is currently OPEN. ID: {shift.id}")
            print("Cannot open a new one.")
        else:
            print("No open shift! Trying to open one...")
            try:
                new_shift = await open_shift(session, 1, 500.0)
                print(f"Opened new shift: {new_shift.id}")
            except Exception as e:
                print("Failed to open shift:", e)

if __name__ == "__main__":
    asyncio.run(main())
