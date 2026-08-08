"""
Inventory seed — sample menu items, ingredients, and tech cards (recipes).
Called after user seed to populate the menu for testing.
"""

from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select

from app.inventory.models import (
    Ingredient, MenuItem, Recipe, MenuCategory,
    UnitType,
)

# ── Sample Categories ─────────────────────────────────────────────
CATEGORIES = [
    {"name": "Бургеры", "sort_order": 1, "color": "blue"},
    {"name": "Гарниры", "sort_order": 2, "color": "orange"},
    {"name": "Напитки", "sort_order": 3, "color": "red"},
]

# ── Sample ingredients ───────────────────────────────────────────
INGREDIENTS = [
    # Meat & Protein
    {"name": "Говяжья котлета",   "unit": UnitType.G,   "stock": 5000, "min": 1000, "cost": 0.8},
    {"name": "Куриное филе",      "unit": UnitType.G,   "stock": 3000, "min": 800,  "cost": 0.5},
    # Bread
    {"name": "Булка для бургера", "unit": UnitType.PCS, "stock": 100,  "min": 20,   "cost": 15.0},
    {"name": "Лаваш тонкий",     "unit": UnitType.PCS, "stock": 50,   "min": 10,   "cost": 20.0},
    # Vegetables
    {"name": "Салат айсберг",     "unit": UnitType.G,   "stock": 2000, "min": 500,  "cost": 0.3},
    {"name": "Помидор",           "unit": UnitType.G,   "stock": 3000, "min": 500,  "cost": 0.25},
    {"name": "Огурец маринов.",   "unit": UnitType.G,   "stock": 2000, "min": 300,  "cost": 0.2},
    {"name": "Лук репчатый",      "unit": UnitType.G,   "stock": 2000, "min": 300,  "cost": 0.1},
    # Sauces
    {"name": "Соус фирменный",    "unit": UnitType.ML,  "stock": 3000, "min": 500,  "cost": 0.15},
    {"name": "Кетчуп",            "unit": UnitType.ML,  "stock": 2000, "min": 500,  "cost": 0.1},
    {"name": "Майонез",           "unit": UnitType.ML,  "stock": 2000, "min": 500,  "cost": 0.12},
    # Sides
    {"name": "Картофель фри (заморож.)", "unit": UnitType.G, "stock": 5000, "min": 1000, "cost": 0.2},
    {"name": "Масло фритюрное",   "unit": UnitType.ML,  "stock": 5000, "min": 1000, "cost": 0.08},
    # Drinks
    {"name": "Кола сироп",        "unit": UnitType.ML,  "stock": 5000, "min": 1000, "cost": 0.05},
    {"name": "Стакан 400мл",      "unit": UnitType.PCS, "stock": 200,  "min": 50,   "cost": 3.0},
    {"name": "Чай пакетированный","unit": UnitType.PCS, "stock": 100,  "min": 20,   "cost": 5.0},
    {"name": "Вода кипяток",      "unit": UnitType.ML,  "stock": 99999,"min": 0,    "cost": 0.001},
    # Cheese
    {"name": "Сыр чеддер",        "unit": UnitType.G,   "stock": 2000, "min": 500,  "cost": 1.2},
]


# ── Menu items with recipes ─────────────────────────────────────
MENU_ITEMS = [
    {
        "name": "Классический бургер",
        "category_name": "Бургеры",
        "price": 250.0,
        "description": "Говяжья котлета, салат, помидор, соус, булка",
        "recipe": [
            ("Булка для бургера", 1),
            ("Говяжья котлета", 150),
            ("Салат айсберг", 20),
            ("Помидор", 30),
            ("Соус фирменный", 25),
        ],
    },
    {
        "name": "Чизбургер",
        "category_name": "Бургеры",
        "price": 290.0,
        "description": "Говяжья котлета, чеддер, маринованный огурец, кетчуп",
        "recipe": [
            ("Булка для бургера", 1),
            ("Говяжья котлета", 150),
            ("Сыр чеддер", 30),
            ("Огурец маринов.", 20),
            ("Кетчуп", 20),
            ("Лук репчатый", 15),
        ],
    },
    {
        "name": "Чикен ролл",
        "category_name": "Бургеры",
        "price": 220.0,
        "description": "Куриное филе в лаваше с соусом и салатом",
        "recipe": [
            ("Лаваш тонкий", 1),
            ("Куриное филе", 120),
            ("Салат айсберг", 25),
            ("Помидор", 25),
            ("Майонез", 20),
        ],
    },
    {
        "name": "Картофель фри",
        "category_name": "Гарниры",
        "price": 120.0,
        "description": "Золотистый картофель фри, порция 150г",
        "recipe": [
            ("Картофель фри (заморож.)", 180),
            ("Масло фритюрное", 50),
        ],
    },
    {
        "name": "Кола 0.4л",
        "category_name": "Напитки",
        "price": 80.0,
        "description": "Кола из автомата, 400мл",
        "recipe": [
            ("Кола сироп", 60),
            ("Стакан 400мл", 1),
        ],
    },
    {
        "name": "Чай чёрный",
        "category_name": "Напитки",
        "price": 60.0,
        "description": "Горячий чай, 300мл",
        "recipe": [
            ("Чай пакетированный", 1),
            ("Вода кипяток", 300),
            ("Стакан 400мл", 1),
        ],
    },
]

# ── Sample Retail products (showcase) ───────────────────────────
RETAIL_PRODUCTS = [
    {"name": "Пепси 0.5л", "category_name": "Напитки", "price": 100.0, "cost": 60.0, "unit": UnitType.PCS, "stock": 50},
    {"name": "Сэндвич с курицей", "category_name": "Бургеры", "price": 180.0, "cost": 110.0, "unit": UnitType.PCS, "stock": 15},
    {"name": "Шоколадный батончик", "category_name": "Гарниры", "price": 70.0, "cost": 40.0, "unit": UnitType.PCS, "stock": 30},
]


async def seed_inventory(session: AsyncSession) -> None:
    """
    Populate categories, menu items, ingredients, recipes, and retail products for BOTH tenants.
    Idempotent - skips if ingredients already exist.
    """
    from sqlalchemy import text
    from app.users.models import Tenant
    tenants = (await session.execute(select(Tenant))).scalars().all()
    
    for tenant in tenants:
        await session.execute(text(f'SET search_path TO "{tenant.schema_name}"'))
        existing = await session.execute(select(Ingredient).limit(1))
        if existing.scalar() is not None:
            print(f">> Inventory already seeded for {tenant.schema_name}, skipping.")
            continue

        print(f"Seeding inventory for {tenant.schema_name}...")

        # Create categories
        category_map: dict[str, MenuCategory] = {}
        for cat_data in CATEGORIES:
            cat = MenuCategory(
                name=cat_data["name"],
                sort_order=cat_data["sort_order"],
                color=cat_data["color"]
            )
            session.add(cat)
            category_map[cat_data["name"]] = cat

        await session.flush()

        # Create ingredients (raw materials)
        ingredient_map: dict[str, Ingredient] = {}
        for ing_data in INGREDIENTS:
            ing = Ingredient(
                name=ing_data["name"],
                unit=ing_data["unit"],
                current_stock=ing_data["stock"],
                min_stock_alert=ing_data["min"],
                cost_per_unit=ing_data["cost"],
            )
            session.add(ing)
            ingredient_map[ing_data["name"]] = ing

        await session.flush()

        # Create menu items (cooked dishes) with recipes
        for mi_data in MENU_ITEMS:
            menu_item = MenuItem(
                name=mi_data["name"],
                category_id=category_map[mi_data["category_name"]].id,
                price=mi_data["price"],
                description=mi_data["description"],
                is_available=True,
            )
            session.add(menu_item)
            await session.flush()

            # Create recipe entries (tech card)
            for ing_name, qty in mi_data["recipe"]:
                recipe = Recipe(
                    menu_item_id=menu_item.id,
                    ingredient_id=ingredient_map[ing_name].id,
                    quantity_required=qty,
                )
                session.add(recipe)

        await session.flush()

        # Create retail products (showcase)
        from app.inventory.models import RetailProduct, StockTransaction, StockTransactionType
        for rp_data in RETAIL_PRODUCTS:
            retail_product = RetailProduct(
                name=rp_data["name"],
                category_id=category_map[rp_data["category_name"]].id,
                price=rp_data["price"],
                cost=rp_data["cost"],
                unit=rp_data["unit"],
                min_stock_alert=5.0,
                current_stock=rp_data["stock"],
                is_available=True,
            )
            session.add(retail_product)
            await session.flush()

            if rp_data["stock"] > 0:
                txn = StockTransaction(
                    retail_product_id=retail_product.id,
                    type=StockTransactionType.RECEIPT,
                    quantity=rp_data["stock"],
                    reason="Начальный остаток при создании",
                    created_by=1,
                )
                session.add(txn)
                await session.flush()

            menu_item = MenuItem(
                name=rp_data["name"],
                category_id=category_map[rp_data["category_name"]].id,
                retail_product_id=retail_product.id,
                price=rp_data["price"],
                type="retail",
                is_available=True,
            )
            session.add(menu_item)

        await session.flush()
        print(f"  - Tenant {tenant.name}: {len(CATEGORIES)} categories, {len(INGREDIENTS)} ingredients, {len(MENU_ITEMS)} dishes, {len(RETAIL_PRODUCTS)} retail items")

    await session.commit()
    print("Inventory seed complete!")
