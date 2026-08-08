import sys
import asyncio
import argparse

# Force UTF-8 encoding for Windows console
if sys.platform == 'win32':
    sys.stdout.reconfigure(encoding='utf-8')
import random
from sqlalchemy import text
from app.database import async_engine

# Таблицы, которые мы будем очищать (только склад, не трогаем юзеров)
INVENTORY_TABLES = [
    "stock_transactions",
    "recipes",
    "inventory_document_items",
    "inventory_documents",
    "retail_products",
    "ingredients",
    "menu_categories",
    "suppliers",
]

async def wipe_inventory():
    """Жестко очищает все складские таблицы во всех тенантах."""
    print("Начинаем зачистку склада...")
    async with async_engine.begin() as conn:
        res = await conn.execute(text("SELECT schema_name FROM information_schema.schemata WHERE schema_name LIKE 'tenant_%'"))
        schemas = [row[0] for row in res.fetchall()]
        
        for schema in schemas:
            print(f"  Уничтожаем складские данные в схеме: {schema}")
            for table in INVENTORY_TABLES:
                # TRUNCATE CASCADE игнорирует foreign keys и сносит все связанные данные
                await conn.execute(text(f"TRUNCATE TABLE {schema}.{table} CASCADE;"))
                
    print("Склад полностью очищен! (Пользователи и настройки целы)")

async def seed_inventory(count: int = 50):
    """Генерирует тестовые данные для склада."""
    print(f"Начинаем посев данных (Сырье: {count} шт.)...")
    
    from sqlalchemy.ext.asyncio import AsyncSession
    from app.users.models import User # Ensure public.users is in metadata
    from app.inventory.models import MenuCategory, Ingredient, StockTransaction, StockTransactionType, UnitType
    
    async with async_engine.begin() as conn:
        res = await conn.execute(text("SELECT schema_name FROM information_schema.schemata WHERE schema_name LIKE 'tenant_%'"))
        schemas = [row[0] for row in res.fetchall()]
        
    for schema in schemas:
        print(f"  Сеем данные в схему: {schema}")
        
        async with AsyncSession(async_engine) as session:
            # Set search path for this tenant
            await session.execute(text(f"SET search_path TO {schema}"))
            
            # 1. Создаем категории
            categories = [
                ("Мясо и птица", "🥩", "ingredient"),
                ("Овощи и фрукты", "🥦", "ingredient"),
                ("Молочная продукция", "🧀", "ingredient"),
                ("Бакалея", "🌾", "ingredient"),
                ("Специи", "🧂", "ingredient"),
            ]
            
            cat_models = []
            for idx, (name, icon, ctype) in enumerate(categories):
                cat = MenuCategory(
                    name=name, 
                    icon=icon, 
                    category_type=ctype, 
                    is_visible=True,
                    sort_order=idx
                )
                session.add(cat)
                cat_models.append(cat)
            
            await session.flush()
            
            # Делаем Специи дочерней категорией Бакалеи (4 -> 3 индекс)
            if len(cat_models) >= 5:
                cat_models[4].parent_id = cat_models[3].id
                session.add(cat_models[4])
                await session.flush()
            
            # 2. Создаем сырье
            units = [UnitType.KG, UnitType.G, UnitType.L, UnitType.ML, UnitType.PCS]
            prefixes = ["Свежий", "Органический", "Премиум", "Домашний", "Замороженный"]
            bases = ["Картофель", "Томат", "Говядина", "Сыр Чеддер", "Лук", "Молоко", "Соус BBQ", "Сахар", "Мука", "Перец черный"]
            
            print("    Генерация сырья...")
            for i in range(count):
                name = f"{random.choice(prefixes)} {random.choice(bases)} {i+1}"
                unit = random.choice(units)
                cat_id = random.choice(cat_models).id
                cost = round(random.uniform(10.0, 500.0), 2)
                stock = round(random.uniform(0.0, 100.0), 2)
                alert = round(random.uniform(5.0, 20.0), 2)
                
                ing = Ingredient(
                    name=name,
                    unit=unit,
                    category_id=cat_id,
                    cost_per_unit=cost,
                    current_stock=stock,
                    min_stock_alert=alert,
                    sort_order=i
                )
                session.add(ing)
                await session.flush()
                
                # Добавляем историю (Транзакция прихода)
                if stock > 0:
                    txn = StockTransaction(
                        ingredient_id=ing.id,
                        type=StockTransactionType.RECEIPT,
                        quantity=stock,
                        reason='Авто-генерация начального остатка'
                    )
                    session.add(txn)
            
            await session.commit()
            
    print("Посев завершен! Откройте приложение и наслаждайтесь данными.")

def main():
    parser = argparse.ArgumentParser(description="Mynix Control Developer CLI Swarm")
    subparsers = parser.add_subparsers(dest="command", required=True)
    
    # Команда WIPE
    wipe_parser = subparsers.add_parser("wipe", help="Уничтожить все данные склада (TRUNCATE CASCADE)")
    
    # Команда SEED
    seed_parser = subparsers.add_parser("seed", help="Засеять склад фейковыми данными")
    seed_parser.add_argument("--count", type=int, default=50, help="Количество сырья для генерации")
    
    args = parser.parse_args()
    
    if args.command == "wipe":
        asyncio.run(wipe_inventory())
    elif args.command == "seed":
        asyncio.run(seed_inventory(args.count))

if __name__ == "__main__":
    main()
