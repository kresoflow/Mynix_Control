from fastapi import APIRouter, Depends, status, HTTPException, Body
from app.dependencies import require_permission, CurrentUser, TenantSession
from app.inventory.models import IngredientCreate, IngredientRead
from app.inventory.services import ingredient_service as svc

router = APIRouter(tags=["Ingredients"])

@router.get("/ingredients/", dependencies=[Depends(require_permission("inventory:view"))])
async def list_ingredients(current_user: CurrentUser, session: TenantSession):
    return await svc.list_ingredients(session)

@router.post("/ingredients/", status_code=status.HTTP_201_CREATED, dependencies=[Depends(require_permission("inventory:manage"))])
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

@router.put("/ingredients/{ingredient_id}", response_model=IngredientRead, dependencies=[Depends(require_permission("inventory:manage"))])
async def update_ingredient(ingredient_id: int, current_user: CurrentUser, session: TenantSession, data: dict = Body(...)):
    return await svc.update_ingredient(session, ingredient_id, data)

@router.delete("/ingredients/{ingredient_id}", status_code=status.HTTP_204_NO_CONTENT, dependencies=[Depends(require_permission("inventory:manage"))])
async def delete_ingredient(ingredient_id: int, current_user: CurrentUser, session: TenantSession):
    try:
        await svc.delete_ingredient(session, ingredient_id)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
