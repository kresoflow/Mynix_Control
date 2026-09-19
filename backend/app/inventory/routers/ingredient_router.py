from typing import List
from fastapi import APIRouter, Depends, status, HTTPException, Body
from app.dependencies import require_permission, CurrentUser, TenantSession
from app.users.permissions import Perm
from app.inventory.models import Ingredient, IngredientCreate, IngredientRead
from app.inventory.services import ingredient_service as svc

router = APIRouter(tags=["Ingredients"])

@router.get("/ingredients/", dependencies=[Depends(require_permission(Perm.INVENTORY_VIEW))])
async def list_ingredients(current_user: CurrentUser, session: TenantSession, include_archived: bool = True):
    return await svc.list_ingredients(session, include_archived=include_archived)

@router.post("/ingredients/", status_code=status.HTTP_201_CREATED, dependencies=[Depends(require_permission(Perm.INVENTORY_MANAGE))])
async def create_ingredient(data: IngredientCreate, current_user: CurrentUser, session: TenantSession):
    item = await svc.create_ingredient(session, data.model_dump(), user_id=current_user.id)
    return {
        "id": item.id,
        "name": item.name,
        "unit": item.unit,
        "min_stock_alert": item.min_stock_alert,
        "cost_per_unit": item.cost_per_unit,
        "current_stock": item.current_stock,
    }

@router.post(
    "/ingredients/bulk",
    response_model=List[IngredientRead],
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(require_permission(Perm.INVENTORY_CREATE))],
)
async def bulk_create_ingredients(
    items: List[IngredientCreate],
    current_user: CurrentUser,
    session: TenantSession,
) -> List[Ingredient]:
    return await svc.bulk_create_ingredients(
        session, [i.model_dump() for i in items], user_id=current_user.id
    )


@router.put("/ingredients/{ingredient_id}", response_model=IngredientRead, dependencies=[Depends(require_permission(Perm.INVENTORY_MANAGE))])
async def update_ingredient(ingredient_id: int, current_user: CurrentUser, session: TenantSession, data: dict = Body(...)):
    return await svc.update_ingredient(session, ingredient_id, data)

@router.post("/ingredients/{ingredient_id}/restore", dependencies=[Depends(require_permission(Perm.INVENTORY_MANAGE))])
async def restore_ingredient(ingredient_id: int, current_user: CurrentUser, session: TenantSession):
    try:
        item = await svc.restore_ingredient(session, ingredient_id)
        return {
            "id": item.id,
            "name": item.name,
            "is_archived": item.is_archived,
        }
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.delete("/ingredients/{ingredient_id}", status_code=status.HTTP_204_NO_CONTENT, dependencies=[Depends(require_permission(Perm.INVENTORY_MANAGE))])
async def delete_ingredient(ingredient_id: int, current_user: CurrentUser, session: TenantSession, mode: str = "soft"):
    try:
        await svc.delete_ingredient(session, ingredient_id, mode=mode)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
