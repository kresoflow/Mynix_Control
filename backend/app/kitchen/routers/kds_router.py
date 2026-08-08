from fastapi import APIRouter, Depends, HTTPException

from app.dependencies import require_permission, CurrentUser, TenantSession
from app.pos.models import OrderRead
from app.kitchen.services import kds_service
from app.pos.ws import notify_kitchen_status_update

router = APIRouter(prefix="/kitchen/kds", tags=["Kitchen — KDS"])


@router.get(
    "/active",
    dependencies=[Depends(require_permission("kitchen:view"))],
)
async def api_get_active_orders(
    current_user: CurrentUser,
    session: TenantSession,
):
    """
    Get active orders (COOKING).
    Only returns items with item_type == "dish".
    """
    orders = await kds_service.get_active_orders(session)
    return [
        {
            "id": o.id,
            "order_number": o.order_number,
            "status": o.status,
            "payment_method": o.payment_method,
            "total": o.total,
            "note": o.note,
            "created_at": o.created_at.isoformat(),
            "items": [
                {
                    "menu_item_name": oi.menu_item_name,
                    "quantity": oi.quantity,
                    "unit_price": oi.unit_price,
                    "subtotal": oi.subtotal,
                    "item_type": oi.item_type,
                    "selected_options": oi.selected_options,
                }
                for oi in o.items if oi.item_type == "dish"
            ],
        }
        for o in orders
    ]


@router.post(
    "/{order_id}/ready",
    dependencies=[Depends(require_permission("orders:update_status"))],
)
async def api_mark_order_ready(
    order_id: int,
    current_user: CurrentUser,
    session: TenantSession,
):
    """
    Mark an order as READY.
    """
    try:
        order = await kds_service.mark_order_ready(session, order_id)
        # Notify via websocket if needed
        await notify_kitchen_status_update(current_user.tenant_id, order.id, order.status)
        return {"status": "ok", "order_id": order.id, "new_status": order.status}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
