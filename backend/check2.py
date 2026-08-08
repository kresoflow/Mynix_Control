import asyncio
from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy import text
from app.config import settings

async def main():
    engine = create_async_engine(str(settings.database_url))
    try:
        async with engine.begin() as conn:
            # Let's query using SQLModel syntax
            pass
    except Exception as e:
        print('Error:', e)

