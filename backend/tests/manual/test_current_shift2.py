import asyncio
from sqlalchemy import text
from app.database import async_session_factory
from app.pos.services.shift_service import get_open_shift, calculate_expected_cash

async def main():
    async with async_session_factory() as session:
        await session.execute(text('SET search_path TO "tenant_1"'))
        shift = await get_open_shift(session)
        if not shift:
            print({"shift": None, "message": "No open shift"})
            return
        
        current_cash_expected = await calculate_expected_cash(
            session, shift.id, shift.opening_cash
        )
        print({
            "shift": {
                "id": shift.id,
                "opened_by": shift.opened_by,
                "opened_at": shift.opened_at.isoformat(),
                "opening_cash": shift.opening_cash,
                "current_cash_expected": current_cash_expected,
            }
        })

if __name__ == "__main__":
    asyncio.run(main())
