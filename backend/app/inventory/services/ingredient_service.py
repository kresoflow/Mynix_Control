from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select

from app.inventory.models import Ingredient, IngredientRead

async def create_ingredient(session: AsyncSession, data: dict, user_id: int = 1) -> Ingredient:
    ingredient = Ingredient(
        name=data["name"],
        unit=data["unit"],
        category_id=data.get("category_id"),
        min_stock_alert=data["min_stock_alert"],
        cost_per_unit=data["cost_per_unit"],
        current_stock=data.get("initial_stock", 0.0),
        sort_order=data.get("sort_order", 0),
        barcode=data.get("barcode"),
    )
    session.add(ingredient)
    await session.flush()
    
    initial_stock = data.get("initial_stock", 0.0)
    if initial_stock > 0:
        from app.inventory.models import StockTransaction, StockTransactionType
        txn = StockTransaction(
            ingredient_id=ingredient.id,
            type=StockTransactionType.RECEIPT,
            quantity=initial_stock,
            reason="Начальный остаток при создании",
            created_by=user_id,
        )
        session.add(txn)
        await session.flush()

    return ingredient

async def list_ingredients(session: AsyncSession) -> list[IngredientRead]:
    from app.inventory.models import MenuCategory
    stmt = (
        select(Ingredient, MenuCategory.name)
        .outerjoin(MenuCategory, Ingredient.category_id == MenuCategory.id)
        .order_by(Ingredient.sort_order, Ingredient.id)
    )
    result = await session.execute(stmt)
    rows = result.all()
    return [
        IngredientRead(
            id=i.Ingredient.id,
            name=i.Ingredient.name,
            unit=i.Ingredient.unit,
            current_stock=i.Ingredient.current_stock,
            min_stock_alert=i.Ingredient.min_stock_alert,
            cost_per_unit=i.Ingredient.cost_per_unit,
            category_id=i.Ingredient.category_id,
            category_name=i.name,
            is_low_stock=i.Ingredient.current_stock <= i.Ingredient.min_stock_alert,
            barcode=i.Ingredient.barcode,
        )
        for i in rows
    ]

async def update_ingredient(session: AsyncSession, ingredient_id: int, data: dict) -> Ingredient:
    stmt = select(Ingredient).where(Ingredient.id == ingredient_id)
    result = await session.execute(stmt)
    item = result.scalar_one_or_none()
    if not item:
        raise ValueError("Ingredient not found")

    for key, value in data.items():
        if hasattr(item, key) and value is not None:
            setattr(item, key, value)
    
    session.add(item)
    await session.flush()
    return item

async def delete_ingredient(session: AsyncSession, ingredient_id: int):
    from app.inventory.models import InventoryDocumentItem, StockTransaction, Recipe
    
    # Check if used in documents
    doc_stmt = select(InventoryDocumentItem).where(InventoryDocumentItem.ingredient_id == ingredient_id)
    doc_result = await session.execute(doc_stmt)
    if doc_result.first():
        raise ValueError("Cannot delete ingredient because it is used in inventory documents.")

    # Delete related transactions
    txn_stmt = select(StockTransaction).where(StockTransaction.ingredient_id == ingredient_id)
    txn_result = await session.execute(txn_stmt)
    for txn in txn_result.scalars().all():
        await session.delete(txn)
        
    # Delete related recipes
    recipe_stmt = select(Recipe).where(Recipe.ingredient_id == ingredient_id)
    recipe_result = await session.execute(recipe_stmt)
    for recipe in recipe_result.scalars().all():
        await session.delete(recipe)

    stmt = select(Ingredient).where(Ingredient.id == ingredient_id)
    result = await session.execute(stmt)
    item = result.scalar_one_or_none()
    if not item:
        raise ValueError("Ingredient not found")
    
    await session.delete(item)
    await session.flush()
