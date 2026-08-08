import asyncio
from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy import text

async def main():
    engine = create_async_engine("postgresql+asyncpg://mynix:mynix_secret@127.0.0.1:5444/mynix_control")
    try:
        async with engine.begin() as conn:
            result = await conn.execute(text("SELECT schema_name FROM information_schema.schemata WHERE schema_name NOT IN ('information_schema', 'pg_catalog', 'pg_toast', 'public')"))
            schemas = [row[0] for row in result.fetchall()]
            
            categories_to_add = [
                "Мясо и птица",
                "Овощи и фрукты",
                "Молочная продукция и сыры",
                "Бакалея",
                "Напитки и сиропы",
                "Упаковка и расходники"
            ]
            
            for schema in schemas:
                print(f"Applying to schema: {schema}")
                await conn.execute(text(f"ALTER TABLE {schema}.ingredients ADD COLUMN IF NOT EXISTS category_id INTEGER REFERENCES {schema}.menu_categories(id)"))
                
                # Check existing ingredient categories
                result = await conn.execute(text(f"SELECT name FROM {schema}.menu_categories WHERE category_type = 'ingredient'"))
                existing_names = [row[0] for row in result.fetchall()]
                
                for i, cat_name in enumerate(categories_to_add):
                    if cat_name not in existing_names:
                        await conn.execute(text(f"INSERT INTO {schema}.menu_categories (name, category_type, sort_order, is_visible, created_at, updated_at, level) VALUES (:name, 'ingredient', :sort, true, NOW(), NOW(), 1)"), {"name": cat_name, "sort": i})
                        print("  Added category")
            print("Done!")
    except Exception as e:
        print("Error:", e)

if __name__ == "__main__":
    asyncio.run(main())
