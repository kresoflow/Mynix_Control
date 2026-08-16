from typing import Optional

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload
from sqlmodel import select
from fastapi import HTTPException

from app.inventory.models import (
    Ingredient, MenuItem, Recipe, StockTransaction,
    StockTransactionType, RetailProduct
)

async def deduct_ingredients(
    session: AsyncSession,
    order_items: list[dict],
    user_id: Optional[int] = None,
) -> list[StockTransaction]:
    transactions: list[StockTransaction] = []

    for item in order_items:
        menu_item_id = item["menu_item_id"]
        order_qty = item["quantity"]

        menu_item = await session.get(MenuItem, menu_item_id)
        if not menu_item:
            continue

        if menu_item.type == "retail" and menu_item.retail_product_id:
            retail_product = await session.get(RetailProduct, menu_item.retail_product_id)
            if retail_product:
                retail_product.current_stock -= order_qty
                session.add(retail_product)

                txn = StockTransaction(
                    retail_product_id=retail_product.id,
                    type=StockTransactionType.AUTO_DEDUCTION,
                    quantity=-float(order_qty),
                    reason=f"Order auto-deduction: retail_item={menu_item_id} x{order_qty}",
                    created_by=user_id,
                )
                session.add(txn)
                transactions.append(txn)
        else:
            stmt = (
                select(Recipe)
                .where(Recipe.menu_item_id == menu_item_id)
                .options(selectinload(Recipe.ingredient))
            )
            result = await session.execute(stmt)
            recipes = result.scalars().all()

            for recipe in recipes:
                deduction = recipe.quantity_required * order_qty
                ingredient = recipe.ingredient

                ingredient.current_stock -= deduction
                session.add(ingredient)

                txn = StockTransaction(
                    ingredient_id=ingredient.id,
                    type=StockTransactionType.AUTO_DEDUCTION,
                    quantity=-deduction,
                    reason=f"Order auto-deduction: menu_item={menu_item_id} x{order_qty}",
                    created_by=user_id,
                )
                session.add(txn)
                transactions.append(txn)

    return transactions

async def check_availability(
    session: AsyncSession,
    menu_item_id: int,
    quantity: int = 1,
) -> dict:
    menu_item = await session.get(MenuItem, menu_item_id)
    if not menu_item:
        return {"available": False, "missing": []}

    missing = []
    if menu_item.type == "retail" and menu_item.retail_product_id:
        retail_product = await session.get(RetailProduct, menu_item.retail_product_id)
        if retail_product:
            if retail_product.current_stock < quantity:
                missing.append({
                    "ingredient": retail_product.name,
                    "needed": float(quantity),
                    "available": retail_product.current_stock,
                    "unit": retail_product.unit,
                })
    else:
        stmt = (
            select(Recipe)
            .where(Recipe.menu_item_id == menu_item_id)
            .options(selectinload(Recipe.ingredient))
        )
        result = await session.execute(stmt)
        recipes = result.scalars().all()

        for recipe in recipes:
            needed = recipe.quantity_required * quantity
            if recipe.ingredient.current_stock < needed:
                missing.append({
                    "ingredient": recipe.ingredient.name,
                    "needed": needed,
                    "available": recipe.ingredient.current_stock,
                    "unit": recipe.ingredient.unit,
                })

    return {
        "available": len(missing) == 0,
        "missing": missing,
    }

async def receive_stock(
    session: AsyncSession,
    ingredient_id: int,
    quantity: float,
    reason: str = "Приёмка товара",
    user_id: Optional[int] = None,
) -> StockTransaction:
    stmt = select(Ingredient).where(Ingredient.id == ingredient_id)
    result = await session.execute(stmt)
    ingredient = result.scalar_one()

    ingredient.current_stock += quantity
    session.add(ingredient)

    txn = StockTransaction(
        ingredient_id=ingredient_id,
        type=StockTransactionType.RECEIPT,
        quantity=quantity,
        reason=reason,
        created_by=user_id,
    )
    session.add(txn)
    await session.flush()
    return txn

async def receive_retail_stock(
    session: AsyncSession,
    retail_product_id: int,
    quantity: float,
    reason: str = "Приёмка товара",
    user_id: Optional[int] = None,
) -> StockTransaction:
    retail_product = await session.get(RetailProduct, retail_product_id)
    if not retail_product:
        raise HTTPException(status_code=404, detail="Retail product not found")

    retail_product.current_stock += quantity
    session.add(retail_product)

    txn = StockTransaction(
        retail_product_id=retail_product_id,
        type=StockTransactionType.RECEIPT,
        quantity=quantity,
        reason=reason,
        created_by=user_id,
    )
    session.add(txn)
    await session.flush()
    return txn
