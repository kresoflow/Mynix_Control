from typing import Optional
from fastapi import APIRouter, Depends, status, Body
from app.dependencies import require_permission, CurrentUser, TenantSession
from app.inventory.models import MenuItemCreate, MenuItemRead, RetailProductRead, RetailProductCreate
from app.inventory.services import menu_service as svc

router = APIRouter(tags=["Menu Items"])

@router.post("/menu/", status_code=status.HTTP_201_CREATED, dependencies=[Depends(require_permission("menu:manage"))])
async def create_menu_item(data: MenuItemCreate, current_user: CurrentUser, session: TenantSession):
    item = await svc.create_menu_item(session, data.model_dump())
    return {
        "id": item.id,
        "name": item.name,
        "category_id": item.category_id,
        "price": item.price,
        "is_available": item.is_available,
        "description": item.description,
    }

@router.get("/menu/", dependencies=[Depends(require_permission("menu:view"))])
async def list_menu(current_user: CurrentUser, session: TenantSession):
    return await svc.list_menu_items(session)

@router.put("/menu/{item_id}", response_model=MenuItemRead, dependencies=[Depends(require_permission("menu:manage"))])
async def update_menu_item(item_id: int, current_user: CurrentUser, session: TenantSession, data: dict = Body(...)):
    return await svc.update_menu_item(session, item_id, data)

@router.delete("/menu/{item_id}", dependencies=[Depends(require_permission("menu:manage"))])
async def delete_menu_item(item_id: int, current_user: CurrentUser, session: TenantSession):
    return await svc.delete_menu_item(session, item_id)

@router.post("/retail-product/", status_code=status.HTTP_201_CREATED, dependencies=[Depends(require_permission("menu:manage"))])
async def create_retail_product(data: RetailProductCreate, current_user: CurrentUser, session: TenantSession):
    item = await svc.create_retail_product(session, data.model_dump(), user_id=current_user.id)
    return {"status": "ok", "id": item.retail_product_id}

@router.get("/inventory/retail/", response_model=list[RetailProductRead], dependencies=[Depends(require_permission("inventory:view"))])
async def list_retail_products(current_user: CurrentUser, session: TenantSession):
    return await svc.list_retail_products(session)

@router.put("/retail-product/{product_id}", response_model=RetailProductRead, dependencies=[Depends(require_permission("menu:manage"))])
async def update_retail_product(product_id: int, current_user: CurrentUser, session: TenantSession, data: dict = Body(...)):
    return await svc.update_retail_product(session, product_id, data)
