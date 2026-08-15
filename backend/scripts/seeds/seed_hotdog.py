import asyncio
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from sqlmodel import select, text
from app.inventory.models.ingredient_models import Ingredient
from app.inventory.models.menu_models import MenuItem, MenuCategory
from app.inventory.models.recipe_models import Recipe
from app.inventory.models.enums import UnitType

async def main():
    engine = create_async_engine("postgresql+asyncpg://mynix:mynix_secret@127.0.0.1:5444/mynix_control")
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    schema = "tenant_1"
    
    async with async_session() as session:
        await session.execute(text(f"SET search_path TO {schema}"))
        
        # 1. Находим или создаем категорию ингредиентов
        cat_raw = (await session.execute(select(MenuCategory).where(MenuCategory.name == "Тестовое Сырье"))).scalar_one_or_none()
        if not cat_raw:
            cat_raw = MenuCategory(name="Тестовое Сырье", category_type="ingredient")
            session.add(cat_raw)
            await session.commit()
            await session.refresh(cat_raw)

        # 2. Создаем ингредиенты для Хот-дога
        # Булочка: Покупаем пачку 10 шт за 25 сомони. Цена за 1 шт = 2.5 сомони.
        ing_bun = Ingredient(
            name="Булочка для хот-дога", category_id=cat_raw.id, unit=UnitType.PCS, 
            current_stock=50.0, min_stock_alert=10.0, cost_per_unit=2.5
        )
        
        # Сосиска: Покупаем 1 кг за 60 сомони. Цена за 1 грамм = 60 / 1000 = 0.06 сомони.
        ing_sausage = Ingredient(
            name="Сосиска говяжья", category_id=cat_raw.id, unit=UnitType.G, 
            current_stock=2000.0, min_stock_alert=500.0, cost_per_unit=0.06
        )
        
        # Кетчуп: Покупаем бутылку 1 литр (1000 мл) за 20 сомони. Цена за 1 мл = 0.02 сомони.
        ing_ketchup = Ingredient(
            name="Кетчуп томатный", category_id=cat_raw.id, unit=UnitType.ML, 
            current_stock=1000.0, min_stock_alert=200.0, cost_per_unit=0.02
        )

        # Горчица: Покупаем банку 500 мл за 15 сомони. Цена за 1 мл = 0.03 сомони.
        ing_mustard = Ingredient(
            name="Горчица", category_id=cat_raw.id, unit=UnitType.ML, 
            current_stock=500.0, min_stock_alert=100.0, cost_per_unit=0.03
        )

        session.add_all([ing_bun, ing_sausage, ing_ketchup, ing_mustard])
        await session.commit()
        await session.refresh(ing_bun)
        await session.refresh(ing_sausage)
        await session.refresh(ing_ketchup)
        await session.refresh(ing_mustard)

        # 3. Находим категорию для блюда "Хот-доги"
        cat_hotdog = (await session.execute(select(MenuCategory).where(MenuCategory.name == "Хот-доги"))).scalar_one_or_none()
        if not cat_hotdog:
            cat_hotdog = MenuCategory(name="Хот-доги", type="menu", sort_order=2)
            session.add(cat_hotdog)
            await session.commit()
            await session.refresh(cat_hotdog)

        # 4. Создаем блюдо
        hotdog_dish = MenuItem(
            category_id=cat_hotdog.id,
            name="Хот-дог Классический",
            description="Классический хот-дог с говяжьей сосиской, кетчупом и горчицей.",
            price=20.0, # Продаем за 20 сомони
            type="dish",
            is_available=True
        )
        session.add(hotdog_dish)
        await session.commit()
        await session.refresh(hotdog_dish)

        # 5. Собираем тех. карту (Рецепт)
        # 1 булочка
        r1 = Recipe(menu_item_id=hotdog_dish.id, ingredient_id=ing_bun.id, quantity_required=1.0)
        # 70 грамм сосиски (1 шт весит 70г)
        r2 = Recipe(menu_item_id=hotdog_dish.id, ingredient_id=ing_sausage.id, quantity_required=70.0)
        # 20 мл кетчупа
        r3 = Recipe(menu_item_id=hotdog_dish.id, ingredient_id=ing_ketchup.id, quantity_required=20.0)
        # 10 мл горчицы
        r4 = Recipe(menu_item_id=hotdog_dish.id, ingredient_id=ing_mustard.id, quantity_required=10.0)
        
        session.add_all([r1, r2, r3, r4])
        await session.commit()

        print("Hotdog test data seeded successfully!")

if __name__ == "__main__":
    asyncio.run(main())
