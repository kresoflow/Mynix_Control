from fastapi import APIRouter, Depends, status, Body
from app.dependencies import require_permission, CurrentUser, TenantSession
from app.inventory.models import MenuCategoryCreate, MenuCategoryRead
from app.inventory.services import category_service as svc

router = APIRouter(tags=["Menu Categories"])

@router.get("/categories/", response_model=list[MenuCategoryRead], dependencies=[Depends(require_permission("menu:view"))])
async def list_categories(current_user: CurrentUser, session: TenantSession):
    return await svc.list_categories(session)

@router.post("/categories/", response_model=MenuCategoryRead, dependencies=[Depends(require_permission("menu:manage"))])
async def create_category(data: MenuCategoryCreate, current_user: CurrentUser, session: TenantSession):
    return await svc.create_category(session, data.model_dump())

@router.post("/categories/bulk", response_model=list[MenuCategoryRead], dependencies=[Depends(require_permission("menu:manage"))])
async def bulk_create_categories(data: list[MenuCategoryCreate], current_user: CurrentUser, session: TenantSession):
    return await svc.bulk_create_categories(session, [d.model_dump() for d in data])

@router.put("/categories/{category_id}", response_model=MenuCategoryRead, dependencies=[Depends(require_permission("menu:manage"))])
async def update_category(category_id: int, current_user: CurrentUser, session: TenantSession, data: dict = Body(...)):
    return await svc.update_category(session, category_id, data)

@router.delete("/categories/{category_id}", status_code=status.HTTP_204_NO_CONTENT, dependencies=[Depends(require_permission("menu:manage"))])
async def delete_category(category_id: int, current_user: CurrentUser, session: TenantSession, mode: str = "only"):
    await svc.delete_category(session, category_id, mode=mode)
