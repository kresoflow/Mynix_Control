from fastapi import APIRouter, Depends, HTTPException
from app.dependencies import require_permission, CurrentUser, TenantSession
from app.inventory.models import RecipeCreate, BulkRecipeCreate
from app.inventory.services import recipe_service as svc

router = APIRouter(tags=["Recipes"])

@router.get("/recipes/summary", dependencies=[Depends(require_permission("menu:view"))])
async def get_recipes_summary(session: TenantSession):
    return await svc.get_all_recipes_summary(session)

@router.get("/menu/{menu_item_id}/recipe", dependencies=[Depends(require_permission("menu:view"))])
async def get_recipe(menu_item_id: int, session: TenantSession):
    recipe = await svc.get_recipe(session, menu_item_id)
    return recipe

@router.post("/menu/{menu_item_id}/recipe", dependencies=[Depends(require_permission("menu:manage"))])
async def add_ingredient_to_recipe(menu_item_id: int, data: RecipeCreate, session: TenantSession):
    await svc.add_ingredient_to_recipe(session, menu_item_id, data.model_dump())
    return {"status": "ok"}

@router.put("/menu/{menu_item_id}/recipe", dependencies=[Depends(require_permission("menu:manage"))])
async def bulk_update_recipe(menu_item_id: int, data: BulkRecipeCreate, session: TenantSession):
    await svc.bulk_update_recipe(session, menu_item_id, [item.model_dump() for item in data.recipes])
    return {"status": "ok"}

@router.delete("/menu/{menu_item_id}/recipe/{ingredient_id}", dependencies=[Depends(require_permission("menu:manage"))])
async def remove_ingredient_from_recipe(menu_item_id: int, ingredient_id: int, session: TenantSession):
    await svc.remove_ingredient_from_recipe(session, menu_item_id, ingredient_id)
    return {"status": "ok"}

@router.get("/menu/{menu_item_id}/food-cost", dependencies=[Depends(require_permission("analytics:view"))])
async def food_cost(menu_item_id: int, session: TenantSession):
    cost = await svc.calc_food_cost(session, menu_item_id)
    return {"menu_item_id": menu_item_id, "food_cost_rub": cost}
