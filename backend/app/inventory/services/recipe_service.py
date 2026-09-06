from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload
from sqlmodel import select, delete

from app.inventory.models import Recipe, RecipeRead

async def get_recipe(session: AsyncSession, menu_item_id: int) -> list[RecipeRead]:
    stmt = (
        select(Recipe)
        .where(Recipe.menu_item_id == menu_item_id)
        .options(selectinload(Recipe.ingredient))
    )
    result = await session.execute(stmt)
    recipes = result.scalars().all()
    return [
        RecipeRead(
            ingredient_id=r.ingredient.id,
            ingredient_name=r.ingredient.name,
            quantity_required=r.quantity_required,
            unit=r.ingredient.unit,
            cost_per_unit=r.ingredient.cost_per_unit,
        )
        for r in recipes
    ]

async def get_all_recipes_summary(session: AsyncSession) -> list[dict]:
    stmt = select(Recipe).options(selectinload(Recipe.ingredient))
    result = await session.execute(stmt)
    recipes = result.scalars().all()

    summary: dict[int, dict] = {}
    for r in recipes:
        m_id = r.menu_item_id
        if m_id not in summary:
            summary[m_id] = {
                "menu_item_id": m_id,
                "ingredients_count": 0,
                "total_cost": 0.0,
                "has_recipe": True,
            }
        summary[m_id]["ingredients_count"] += 1
        if r.ingredient and r.ingredient.cost_per_unit:
            summary[m_id]["total_cost"] += (r.quantity_required * r.ingredient.cost_per_unit)

    # If recipes are attached to child MenuItem rows, mark the parent item as having a recipe too
    if summary:
        from app.inventory.models import MenuItem
        child_stmt = select(MenuItem).where(MenuItem.id.in_(list(summary.keys())), MenuItem.parent_id.is_not(None))
        child_res = await session.execute(child_stmt)
        children = child_res.scalars().all()
        for child in children:
            p_id = child.parent_id
            if p_id and p_id not in summary:
                child_sum = summary.get(child.id)
                summary[p_id] = {
                    "menu_item_id": p_id,
                    "ingredients_count": child_sum["ingredients_count"] if child_sum else 0,
                    "total_cost": child_sum["total_cost"] if child_sum else 0.0,
                    "has_recipe": True,
                }

    for item in summary.values():
        item["total_cost"] = round(item["total_cost"], 2)

    return list(summary.values())

async def add_ingredient_to_recipe(session: AsyncSession, menu_item_id: int, data: dict) -> Recipe:
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

async def remove_ingredient_from_recipe(session: AsyncSession, menu_item_id: int, ingredient_id: int):
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
    stmt = delete(Recipe).where(Recipe.menu_item_id == menu_item_id)
    await session.execute(stmt)
    
    for req in recipes:
        new_recipe = Recipe(
            menu_item_id=menu_item_id,
            ingredient_id=req["ingredient_id"],
            quantity_required=req["quantity_required"]
        )
        session.add(new_recipe)
    
    await session.flush()

async def calc_food_cost(session: AsyncSession, menu_item_id: int) -> float:
    stmt = (
        select(Recipe)
        .where(Recipe.menu_item_id == menu_item_id)
        .options(selectinload(Recipe.ingredient))
    )
    result = await session.execute(stmt)
    recipes = result.scalars().all()

    if not recipes:
        from app.inventory.models import MenuItem
        item = await session.get(MenuItem, menu_item_id)
        if item and item.parent_id:
            stmt_parent = (
                select(Recipe)
                .where(Recipe.menu_item_id == item.parent_id)
                .options(selectinload(Recipe.ingredient))
            )
            res_parent = await session.execute(stmt_parent)
            recipes = res_parent.scalars().all()

    total_cost = 0.0
    for recipe in recipes:
        if recipe.ingredient and recipe.ingredient.cost_per_unit:
            total_cost += recipe.ingredient.cost_per_unit * recipe.quantity_required
    return round(total_cost, 2)
