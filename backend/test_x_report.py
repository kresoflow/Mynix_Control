import asyncio
from sqlalchemy import text
from app.database import async_session_factory
from app.pos.services.shift_service import get_x_report

async def main():
    async with async_session_factory() as session:
        # We need to set search_path to the tenant. The default tenant is 'tenant_1' or whatever.
        # Let's see what tenant exists.
        await session.execute(text('SET search_path TO "tenant_1"'))
        try:
            # Let's find an open shift
            from app.pos.models import Shift
            from sqlmodel import select
            shift = (await session.execute(select(Shift).where(Shift.is_open == True))).scalar_one_or_none()
            if not shift:
                print("No open shift")
                return
            report = await get_x_report(session, shift.id)
            print("Report:", report)
        except Exception as e:
            import traceback
            traceback.print_exc()

if __name__ == "__main__":
    asyncio.run(main())
