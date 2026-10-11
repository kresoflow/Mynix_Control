# ==============================================================================
# СЕРВИС: Технологические карты и калькуляция фудкоста (RecipeService)
# ДОМЕН: backend/app/inventory/services/recipe_service.py
# ==============================================================================
#
# [ИНВАРИАНТ] Высокопроизводительные агрегации: расчет себестоимости и сводок
# выполняется напрямую на уровне SQL (func.sum, func.count, GROUP BY), без
# накладных расходов выгрузки тысяч ORM-объектов в память Python.
#
# ==============================================================================

from sqlalchemy import func
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload
from sqlmodel import select, delete

from app.inventory.models import Recipe, RecipeRead, Ingredient, MenuItem


# ─── 1. Чтение рецептур и спецификаций ────────────────────────────────────────

async def get_recipe(session: AsyncSession, menu_item_id: int) -> list[RecipeRead]:
    """
    Возвращает спецификацию сырья для блюда.
    Если у вариации нет своей техкарты, наследует рецепт от родительского блюда.
    """
    stmt = (
        select(Recipe)
        .where(Recipe.menu_item_id == menu_item_id)
        .options(selectinload(Recipe.ingredient))
    )
    result = await session.execute(stmt)
    recipes = result.scalars().all()

    if not recipes:
        item = await session.get(MenuItem, menu_item_id)
        if item and item.parent_id:
            stmt_parent = (
                select(Recipe)
                .where(Recipe.menu_item_id == item.parent_id)
                .options(selectinload(Recipe.ingredient))
            )
            res_parent = await session.execute(stmt_parent)
            recipes = res_parent.scalars().all()

    return [
        RecipeRead(
            ingredient_id=r.ingredient.id,
            ingredient_name=r.ingredient.name,
            quantity_required=r.quantity_required,
            unit=r.ingredient.unit,
            cost_per_unit=r.ingredient.cost_per_unit,
        )
        for r in recipes
        if r.ingredient
    ]


async def get_all_recipes_summary(session: AsyncSession) -> list[dict]:
    """
    [ПРОИЗВОДИТЕЛЬНОСТЬ] Возвращает сводку себестоимости через SQL GROUP BY.
    """
    stmt = (
        select(
            Recipe.menu_item_id,
            func.count(Recipe.id).label("ingredients_count"),
            func.coalesce(
                func.sum(Recipe.quantity_required * Ingredient.cost_per_unit),
                0.0,
            ).label("total_cost"),
        )
        .join(Ingredient, Recipe.ingredient_id == Ingredient.id)
        .group_by(Recipe.menu_item_id)
    )
    rows = (await session.execute(stmt)).all()

    summary: dict[int, dict] = {
        row.menu_item_id: {
            "menu_item_id": row.menu_item_id,
            "ingredients_count": int(row.ingredients_count),
            "total_cost": round(float(row.total_cost), 2),
            "has_recipe": True,
        }
        for row in rows
    }

    # Если техкарта привязана к дочерней вариации, помечаем родительское блюдо
    if summary:
        child_stmt = select(MenuItem.parent_id, MenuItem.id).where(
            MenuItem.id.in_(list(summary.keys())),
            MenuItem.parent_id.is_not(None),
        )
        children = (await session.execute(child_stmt)).all()
        for parent_id, child_id in children:
            if parent_id and parent_id not in summary:
                child_sum = summary.get(child_id)
                if child_sum:
                    summary[parent_id] = {
                        "menu_item_id": parent_id,
                        "ingredients_count": child_sum["ingredients_count"],
                        "total_cost": child_sum["total_cost"],
                        "has_recipe": True,
                    }

    return list(summary.values())


async def calc_food_cost(session: AsyncSession, menu_item_id: int) -> float:
    """
    [ПРОИЗВОДИТЕЛЬНОСТЬ] Калькулирует фудкост для блюда в реальном времени через SQL.
    """
    stmt = (
        select(
            func.coalesce(
                func.sum(Recipe.quantity_required * Ingredient.cost_per_unit),
                0.0,
            )
        )
        .join(Ingredient, Recipe.ingredient_id == Ingredient.id)
        .where(Recipe.menu_item_id == menu_item_id)
    )
    cost = (await session.execute(stmt)).scalar_one()

    if cost == 0.0:
        item = await session.get(MenuItem, menu_item_id)
        if item and item.parent_id:
            parent_stmt = (
                select(
                    func.coalesce(
                        func.sum(Recipe.quantity_required * Ingredient.cost_per_unit),
                        0.0,
                    )
                )
                .join(Ingredient, Recipe.ingredient_id == Ingredient.id)
                .where(Recipe.menu_item_id == item.parent_id)
            )
            cost = (await session.execute(parent_stmt)).scalar_one()

    return round(float(cost), 2)


# ─── 2. Модификация техкарт ───────────────────────────────────────────────────

async def add_ingredient_to_recipe(session: AsyncSession, menu_item_id: int, data: dict) -> Recipe:
    """Добавляет или обновляет норму расхода ингредиента."""
    ingredient_id = data["ingredient_id"]
    quantity = data["quantity_required"]

    stmt = select(Recipe).where(
        Recipe.menu_item_id == menu_item_id,
        Recipe.ingredient_id == ingredient_id,
    )
    result = await session.execute(stmt)
    recipe = result.scalar_one_or_none()

    if recipe:
        recipe.quantity_required = quantity
    else:
        recipe = Recipe(
            menu_item_id=menu_item_id,
            ingredient_id=ingredient_id,
            quantity_required=quantity,
        )
        session.add(recipe)

    await session.flush()
    return recipe


async def remove_ingredient_from_recipe(session: AsyncSession, menu_item_id: int, ingredient_id: int) -> None:
    """Удаляет сырье из спецификации блюда."""
    stmt = select(Recipe).where(
        Recipe.menu_item_id == menu_item_id,
        Recipe.ingredient_id == ingredient_id,
    )
    result = await session.execute(stmt)
    recipe = result.scalar_one_or_none()
    if recipe:
        await session.delete(recipe)
        await session.flush()


async def bulk_update_recipe(session: AsyncSession, menu_item_id: int, recipes: list[dict]) -> None:
    """Перезаписывает всю техкарту блюда новым набором ингредиентов."""
    stmt = delete(Recipe).where(Recipe.menu_item_id == menu_item_id)
    await session.execute(stmt)

    for req in recipes:
        new_recipe = Recipe(
            menu_item_id=menu_item_id,
            ingredient_id=req["ingredient_id"],
            quantity_required=req["quantity_required"],
        )
        session.add(new_recipe)

    await session.flush()
