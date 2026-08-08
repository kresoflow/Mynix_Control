import asyncio
import json
import sys
sys.stdout.reconfigure(encoding='utf-8')

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from app.database import async_session_factory
from app.inventory.services import menu_service as svc

async def main():
    async with async_session_factory() as session:
        await session.execute(text("SET search_path TO tenant_1"))
        items = await svc.list_menu_items(session)
        
        # Serialize to dicts
        for i in items:
            if "Добрый" in i.name:
                print(json.dumps(i.model_dump(), ensure_ascii=False, indent=2))

asyncio.run(main())
