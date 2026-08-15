import asyncio
from app.database import async_session_factory
from app.pos.routers.shift_router import api_current_shift
from app.users.models import User
from sqlalchemy import text

async def main():
    async with async_session_factory() as session:
        await session.execute(text('SET search_path TO "tenant_1"'))
        dummy_user = User(id=1, email="test@test.com", tenant_id="tenant_1")
        res = await api_current_shift(current_user=dummy_user, session=session)
        print("API CURRENT SHIFT RESULT:", res)

if __name__ == "__main__":
    asyncio.run(main())
