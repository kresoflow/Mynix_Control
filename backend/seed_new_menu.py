import asyncio
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from sqlmodel import select, text
from app.inventory.models.category_models import MenuCategory
from app.inventory.models.menu_models import MenuItem

async def main():
    engine = create_async_engine("postgresql+asyncpg://mynix:mynix_secret@127.0.0.1:5444/mynix_control")
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    # We will seed into tenant_1
    schema = "tenant_1"
    
    async with async_session() as session:
        await session.execute(text(f"SET search_path TO {schema}"))
        
        # Clear existing menu items and categories
        await session.execute(text(f"TRUNCATE TABLE {schema}.menu_items CASCADE;"))
        await session.execute(text(f"TRUNCATE TABLE {schema}.menu_categories CASCADE;"))
        await session.commit()
        
        print("Creating categories...")
        cat_shawarma = MenuCategory(name="Шаурма", type="menu", sort_order=1)
        cat_hotdogs = MenuCategory(name="Хот-доги", type="menu", sort_order=2)
        cat_sides = MenuCategory(name="Гарниры", type="menu", sort_order=3)
        cat_pizza = MenuCategory(name="Пицца", type="menu", sort_order=4)
        cat_burgers = MenuCategory(name="Бургеры", type="menu", sort_order=5)
        cat_icecream = MenuCategory(name="Мороженое", type="menu", sort_order=6)
        
        session.add_all([cat_shawarma, cat_hotdogs, cat_sides, cat_pizza, cat_burgers, cat_icecream])
        await session.commit()
        await session.refresh(cat_shawarma)
        await session.refresh(cat_hotdogs)
        await session.refresh(cat_sides)
        await session.refresh(cat_pizza)
        await session.refresh(cat_burgers)
        await session.refresh(cat_icecream)

        print("Creating items...")
        
        sauces_modifier = {
            "name": "Соусы",
            "required": False,
            "max_selections": 3,
            "modifiers": [
                {"name": "Сырный соус", "price": 5},
                {"name": "Кетчуп", "price": 5},
                {"name": "Чесночный соус", "price": 5}
            ]
        }
        
        items = []
        
        # 1. Шаурма
        items.append(MenuItem(
            name="Шаурма в пите (Шаурмаи нони)",
            category_id=cat_shawarma.id,
            price=10,
            type="dish",
            attributes={
                "variations": [
                    {"name": "Стандарт", "price": 10},
                    {"name": "Мега", "price": 15}
                ]
            }
        ))
        items.append(MenuItem(
            name="Шаурма куриная",
            category_id=cat_shawarma.id,
            price=15,
            type="dish",
            attributes={
                "variations": [
                    {"name": "S", "price": 15},
                    {"name": "M", "price": 20},
                    {"name": "L", "price": 25}
                ]
            }
        ))
        items.append(MenuItem(name="Шаурма говяжья", category_id=cat_shawarma.id, price=30, type="dish"))
        
        # 2. Хот-доги
        items.append(MenuItem(
            name="Классический хот-дог",
            category_id=cat_hotdogs.id,
            price=5,
            type="dish",
            attributes={
                "variations": [
                    {"name": "XS", "price": 5},
                    {"name": "S", "price": 7},
                    {"name": "M", "price": 10},
                    {"name": "L", "price": 12},
                    {"name": "XL", "price": 15}
                ]
            }
        ))
        items.append(MenuItem(
            name="Хот-дог в булочке",
            category_id=cat_hotdogs.id,
            price=6,
            type="dish",
            attributes={
                "variations": [
                    {"name": "Одинарный", "price": 6},
                    {"name": "Двойной", "price": 8},
                    {"name": "Тройной", "price": 10},
                    {"name": "Квадро", "price": 12},
                    {"name": "Мега-Дог", "price": 15}
                ]
            }
        ))
        items.append(MenuItem(name="Хот-дог S", category_id=cat_hotdogs.id, price=15, type="dish"))
        items.append(MenuItem(name="Нон кабоб", category_id=cat_hotdogs.id, price=12, type="dish"))
        
        # 3. Гарниры
        items.append(MenuItem(
            name="Картофель Фри", category_id=cat_sides.id, price=11, type="dish",
            attributes={"variations": [{"name": "Малый", "price": 11}, {"name": "Большой", "price": 20}], "modifier_groups": [sauces_modifier]}
        ))
        items.append(MenuItem(
            name="Наггетсы", category_id=cat_sides.id, price=18, type="dish",
            attributes={"variations": [{"name": "6 шт", "price": 18}, {"name": "9 шт", "price": 35}], "modifier_groups": [sauces_modifier]}
        ))
        items.append(MenuItem(name="Крылышки", category_id=cat_sides.id, price=24, type="dish", attributes={"modifier_groups": [sauces_modifier]}))
        items.append(MenuItem(
            name="Фри шарики", category_id=cat_sides.id, price=14, type="dish",
            attributes={"variations": [{"name": "Малая", "price": 14}, {"name": "Большая", "price": 22}], "modifier_groups": [sauces_modifier]}
        ))
        items.append(MenuItem(name="Картофель по-деревенски", category_id=cat_sides.id, price=10, type="dish", attributes={"modifier_groups": [sauces_modifier]}))
        items.append(MenuItem(name="Чикен Фри", category_id=cat_sides.id, price=35, type="dish", attributes={"modifier_groups": [sauces_modifier]}))
        
        # 4. Пицца
        pizzas = [
            ("Маргарита", 59), ("Мясная", 71), ("Цезарь", 65), ("Пепперони", 63),
            ("С двойной пепперони", 75), ("Барбекю", 73), ("Ассорти", 70), ("4 сыра", 72),
            ("4 сезона", 78), ("Пицца SCafe", 81), ("Пицца с курицей", 61), ("Пицца с грибами", 66)
        ]
        for name, price in pizzas:
            items.append(MenuItem(name=name, category_id=cat_pizza.id, price=price, type="dish"))
            
        # 5. Бургеры
        burgers = [
            ("Дабл Бургер", 37), ("Бест Бургер", 28), ("Бургер по-мексикански", 30),
            ("Бургер классический", 30), ("Бургер Гота", 25), ("Чикен Бургер", 20),
            ("Бургер SCafe", 49)
        ]
        for name, price in burgers:
            items.append(MenuItem(name=name, category_id=cat_burgers.id, price=price, type="dish"))
            
        # 6. Мороженое
        items.append(MenuItem(
            name="Мороженое в рожке", category_id=cat_icecream.id, price=2, type="dish",
            attributes={"variations": [{"name": "Малый", "price": 2}, {"name": "Средний", "price": 3}, {"name": "Большой", "price": 5}]}
        ))
        items.append(MenuItem(
            name="Мороженое в стаканчике", category_id=cat_icecream.id, price=5, type="dish",
            attributes={"variations": [{"name": "Малый", "price": 5}, {"name": "Большой", "price": 10}]}
        ))
        
        session.add_all(items)
        await session.commit()
        print("Menu seeded successfully!")

if __name__ == "__main__":
    asyncio.run(main())
