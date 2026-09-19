from sqlalchemy import case
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select

from app.inventory.models import Ingredient, IngredientRead

async def bulk_create_ingredients(session: AsyncSession, items_data: list[dict], user_id: int = 1) -> list[Ingredient]:
    created_ingredients: list[Ingredient] = []
    for data in items_data:
        ingredient = Ingredient(
            name=data["name"],
            unit=data["unit"],
            category_id=data.get("category_id"),
            min_stock_alert=data.get("min_stock_alert", 0.0),
            cost_per_unit=data.get("cost_per_unit", 0.0),
            current_stock=0.0,
            sort_order=data.get("sort_order", 0),
            barcode=data.get("barcode"),
            attributes=data.get("attributes"),
        )
        session.add(ingredient)
        created_ingredients.append(ingredient)

    await session.flush()
    return created_ingredients

async def create_ingredient(session: AsyncSession, data: dict, user_id: int = 1) -> Ingredient:
    items = await bulk_create_ingredients(session, [data], user_id=user_id)
    return items[0]


async def list_ingredients(session: AsyncSession, include_archived: bool = True) -> list[IngredientRead]:
    from app.inventory.models import MenuCategory
    stmt = (
        select(Ingredient, MenuCategory.name)
        .outerjoin(MenuCategory, Ingredient.category_id == MenuCategory.id)
    )
    if not include_archived:
        stmt = stmt.where(Ingredient.is_archived == False)
    stmt = stmt.order_by(
        case((Ingredient.sort_order == 0, 999999), else_=Ingredient.sort_order).asc(),
        Ingredient.id.asc(),
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
            sort_order=i.Ingredient.sort_order,
            is_low_stock=i.Ingredient.current_stock <= i.Ingredient.min_stock_alert,
            barcode=i.Ingredient.barcode,
            is_archived=i.Ingredient.is_archived,
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

async def delete_ingredient(session: AsyncSession, ingredient_id: int, mode: str = "soft"):
    stmt = select(Ingredient).where(Ingredient.id == ingredient_id)
    result = await session.execute(stmt)
    item = result.scalar_one_or_none()
    if not item:
        raise ValueError("Ингредиент не найден")

    if mode == "soft":
        item.is_archived = True
        session.add(item)
        await session.flush()
        return item

    from app.inventory.models import InventoryDocumentItem, StockTransaction, Recipe

    # Poka-yoke: Check if used in documents
    doc_stmt = select(InventoryDocumentItem).where(InventoryDocumentItem.ingredient_id == ingredient_id).limit(1)
    doc_result = await session.execute(doc_stmt)
    if doc_result.first():
        raise ValueError("Невозможно удалить сырье навсегда: оно используется в складских документах. Оставьте в архиве.")

    # Poka-yoke: Check if used in stock transactions (prevent ledger destruction)
    txn_stmt = select(StockTransaction).where(StockTransaction.ingredient_id == ingredient_id).limit(1)
    txn_result = await session.execute(txn_stmt)
    if txn_result.first():
        raise ValueError("Невозможно удалить сырье навсегда: по нему есть история складских проводок. Оставьте в архиве.")

    # Poka-yoke: Check if used in active recipes (prevent breaking dish cost calculation)
    recipe_stmt = select(Recipe).where(Recipe.ingredient_id == ingredient_id).limit(1)
    recipe_result = await session.execute(recipe_stmt)
    if recipe_result.first():
        raise ValueError("Невозможно удалить сырье навсегда: оно привязано к техкартам блюд. Удалите его из рецептов или оставьте в архиве.")

    await session.delete(item)
    await session.flush()

async def restore_ingredient(session: AsyncSession, ingredient_id: int) -> Ingredient:
    stmt = select(Ingredient).where(Ingredient.id == ingredient_id)
    result = await session.execute(stmt)
    item = result.scalar_one_or_none()
    if not item:
        raise ValueError("Ингредиент не найден")

    item.is_archived = False
    session.add(item)
    await session.flush()
    return item
