from typing import Optional, List
from fastapi import APIRouter, Depends, status, Body
from app.dependencies import require_permission, CurrentUser, TenantSession
from app.users.permissions import Perm
from app.inventory.models import (
    MenuItem, MenuItemCreate, MenuItemRead,
    RetailProduct, RetailProductRead, RetailProductCreate
)
from app.inventory.services import menu_service, retail_service

router = APIRouter(tags=["Menu Items"])

@router.post("/menu/", status_code=status.HTTP_201_CREATED, dependencies=[Depends(require_permission(Perm.MENU_MANAGE))])
async def create_menu_item(data: MenuItemCreate, current_user: CurrentUser, session: TenantSession):
    item = await menu_service.create_menu_item(session, data.model_dump())
    return {
        "id": item.id,
        "name": item.name,
        "category_id": item.category_id,
        "price": item.price,
        "is_available": item.is_available,
        "description": item.description,
    }

@router.post(
    "/menu/bulk",
    response_model=List[MenuItemRead],
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(require_permission(Perm.MENU_CREATE))],
)
async def bulk_create_menu_items(
    items: List[MenuItemCreate],
    current_user: CurrentUser,
    session: TenantSession,
) -> List[MenuItem]:
    return await menu_service.bulk_create_menu_items(session, [i.model_dump() for i in items])

@router.get("/menu/", dependencies=[Depends(require_permission(Perm.MENU_VIEW))])
async def list_menu(current_user: CurrentUser, session: TenantSession):
    return await menu_service.list_menu_items(session)

@router.put("/menu/{item_id}", response_model=MenuItemRead, dependencies=[Depends(require_permission(Perm.MENU_MANAGE))])
async def update_menu_item(item_id: int, current_user: CurrentUser, session: TenantSession, data: dict = Body(...)):
    return await menu_service.update_menu_item(session, item_id, data)

@router.delete("/menu/{item_id}", dependencies=[Depends(require_permission(Perm.MENU_MANAGE))])
async def delete_menu_item(item_id: int, current_user: CurrentUser, session: TenantSession, mode: str = "soft"):
    return await menu_service.delete_menu_item(session, item_id, mode=mode)

@router.post("/retail-product/", status_code=status.HTTP_201_CREATED, dependencies=[Depends(require_permission(Perm.MENU_MANAGE))])
async def create_retail_product(data: RetailProductCreate, current_user: CurrentUser, session: TenantSession):
    item = await retail_service.create_retail_product(session, data.model_dump(), user_id=current_user.id)
    return {"status": "ok", "id": item.retail_product_id}

@router.post(
    "/retail-product/bulk",
    response_model=List[RetailProductRead],
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(require_permission(Perm.MENU_CREATE))],
)
async def bulk_create_retail_products(
    items: List[RetailProductCreate],
    current_user: CurrentUser,
    session: TenantSession,
) -> List[RetailProduct]:
    return await retail_service.bulk_create_retail_products(
        session, [i.model_dump() for i in items], user_id=current_user.id
    )

@router.get("/inventory/retail/", response_model=list[RetailProductRead], dependencies=[Depends(require_permission(Perm.INVENTORY_VIEW))])
async def list_retail_products(current_user: CurrentUser, session: TenantSession):
    return await retail_service.list_retail_products(session)

@router.put("/retail-product/{product_id}", response_model=RetailProductRead, dependencies=[Depends(require_permission(Perm.MENU_MANAGE))])
async def update_retail_product(product_id: int, current_user: CurrentUser, session: TenantSession, data: dict = Body(...)):
    return await retail_service.update_retail_product(session, product_id, data)

