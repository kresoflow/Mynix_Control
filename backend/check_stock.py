import asyncio
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from sqlmodel import select, text
from app.inventory.models.ingredient_models import Ingredient
import sys

sys.stdout.reconfigure(encoding='utf-8')

async def main():
    engine = create_async_engine("postgresql+asyncpg://mynix:mynix_secret@127.0.0.1:5444/mynix_control")
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    async with async_session() as session:
        await session.execute(text("SET search_path TO tenant_1"))
        
        ingredients = (await session.execute(select(Ingredient).where(Ingredient.name.like('Тест %')))).scalars().all()
        for ing in ingredients:
            print(f"Ingredient: {ing.name}, Current Stock: {ing.current_stock}")

if __name__ == "__main__":
    asyncio.run(main())
