from fastapi import APIRouter, Depends
from app.dependencies import require_permission, CurrentUser, TenantSession
from app.inventory.models import ReceiveStockRequest, RetailReceiveStockRequest
from app.inventory.services import stock_service as svc

router = APIRouter(tags=["Stock Management"])

@router.post("/ingredients/receive", dependencies=[Depends(require_permission("inventory:manage"))])
async def receive_stock(data: ReceiveStockRequest, current_user: CurrentUser, session: TenantSession):
    txn = await svc.receive_stock(
        session,
        ingredient_id=data.ingredient_id,
        quantity=data.quantity,
        reason=data.reason,
        user_id=current_user.id,
    )
    return {"status": "ok", "transaction_id": txn.id}

@router.post("/inventory/retail/receive", dependencies=[Depends(require_permission("inventory:manage"))])
async def receive_retail_stock(data: RetailReceiveStockRequest, current_user: CurrentUser, session: TenantSession):
    txn = await svc.receive_retail_stock(
        session,
        retail_product_id=data.retail_product_id,
        quantity=data.quantity,
        reason=data.reason,
        user_id=current_user.id,
    )
    return {"status": "ok", "transaction_id": txn.id}

@router.get("/menu/{menu_item_id}/availability", dependencies=[Depends(require_permission("menu:view"))])
async def check_availability(menu_item_id: int, session: TenantSession, quantity: int = 1):
    return await svc.check_availability(session, menu_item_id, quantity)
