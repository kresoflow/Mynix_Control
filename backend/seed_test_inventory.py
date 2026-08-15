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
        
        print("Cleaning up old test data...")
        await session.execute(text(f"DELETE FROM {schema}.recipes WHERE menu_item_id IN (SELECT id FROM {schema}.menu_items WHERE name = 'Тестовая Шаурма')"))
        await session.execute(text(f"DELETE FROM {schema}.menu_items WHERE name = 'Тестовая Шаурма'"))
        await session.execute(text(f"DELETE FROM {schema}.ingredients WHERE name LIKE 'Тест %'"))
        await session.execute(text(f"DELETE FROM {schema}.menu_categories WHERE name = 'Тестовое Сырье'"))
        await session.commit()
        
        print("Creating Ingredient Category (MenuCategory with type 'ingredient')...")
        cat_raw = MenuCategory(name="Тестовое Сырье", category_type="ingredient")
        session.add(cat_raw)
        await session.commit()
        await session.refresh(cat_raw)

        print("Creating Ingredients...")
        ing_lavash = Ingredient(name="Тест Лаваш", category_id=cat_raw.id, unit=UnitType.PCS, current_stock=100.0, min_stock_alert=10.0, cost_per_unit=5.0)
        ing_meat = Ingredient(name="Тест Мясо Курицы", category_id=cat_raw.id, unit=UnitType.G, current_stock=5000.0, min_stock_alert=500.0, cost_per_unit=0.3)
        ing_sauce = Ingredient(name="Тест Соус Фирменный", category_id=cat_raw.id, unit=UnitType.ML, current_stock=2000.0, min_stock_alert=200.0, cost_per_unit=0.1)
        
        session.add_all([ing_lavash, ing_meat, ing_sauce])
        await session.commit()
        await session.refresh(ing_lavash)
        await session.refresh(ing_meat)
        await session.refresh(ing_sauce)

        print("Creating Menu Category...")
        cat_menu = (await session.execute(select(MenuCategory).where(MenuCategory.name == "Шаурма"))).scalar_one_or_none()
        if not cat_menu:
            cat_menu = MenuCategory(name="Шаурма", type="menu", sort_order=1)
            session.add(cat_menu)
            await session.commit()
            await session.refresh(cat_menu)

        print("Creating Menu Item...")
        test_dish = MenuItem(
            category_id=cat_menu.id,
            name="Тестовая Шаурма",
            description="Списывает 1 лаваш, 200г мяса, 50мл соуса",
            price=250.0,
            type="dish",
            is_available=True
        )
        session.add(test_dish)
        await session.commit()
        await session.refresh(test_dish)

        print("Creating Tech Card (Recipes)...")
        r1 = Recipe(menu_item_id=test_dish.id, ingredient_id=ing_lavash.id, quantity_required=1.0)
        r2 = Recipe(menu_item_id=test_dish.id, ingredient_id=ing_meat.id, quantity_required=200.0)
        r3 = Recipe(menu_item_id=test_dish.id, ingredient_id=ing_sauce.id, quantity_required=50.0)
        
        session.add_all([r1, r2, r3])
        await session.commit()

        print("Done! Test data seeded successfully.")
        print(f"Dish: {test_dish.name}")
        print(f"Ingredients in stock: Лаваш ({ing_lavash.current_stock} шт), Мясо ({ing_meat.current_stock} г), Соус ({ing_sauce.current_stock} мл)")

if __name__ == "__main__":
    asyncio.run(main())
