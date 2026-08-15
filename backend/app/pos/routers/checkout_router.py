from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, status, Query

from app.dependencies import require_permission, CurrentUser, TenantSession
from app.pos.models import CreateOrderRequest, OrderStatus
from app.pos.services.checkout_service import (
    create_order, list_orders, get_order_by_id, update_order_status, process_new_order
)
from app.pos.ws import notify_kitchen_status_update

router = APIRouter(tags=["POS — Orders & Checkout"])


@router.post(
    "/orders/",
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(require_permission("orders:create"))],
)
async def api_create_order(
    data: CreateOrderRequest,
    current_user: CurrentUser,
    session: TenantSession,
):
    """
    Create a new order.
    Triggers: inventory deduction, cash recording, kitchen notification via checkout service.
    """
    return await process_new_order(session, current_user, data)


@router.get(
    "/orders/",
    dependencies=[Depends(require_permission("orders:view"))],
)
async def api_list_orders(
    current_user: CurrentUser,
    session: TenantSession,
    shift_id: Optional[int] = Query(None),
    status_filter: Optional[OrderStatus] = Query(None, alias="status"),
    start_date: Optional[str] = Query(None),
    end_date: Optional[str] = Query(None),
):
    """List orders, optionally filtered by shift and/or status."""
    orders = await list_orders(session, shift_id, status_filter, start_date, end_date)
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
                    "selected_options": oi.selected_options,
                    "item_type": oi.item_type,
                }
                for oi in o.items
            ],
        }
        for o in orders
    ]


@router.get(
    "/orders/{order_id}",
    dependencies=[Depends(require_permission("orders:view"))],
)
async def api_get_order(
    order_id: int,
    current_user: CurrentUser,
    session: TenantSession,
):
    """Get a single order with full details."""
    order = await get_order_by_id(session, order_id)
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    return {
        "id": order.id,
        "order_number": order.order_number,
        "status": order.status,
        "payment_method": order.payment_method,
        "total": order.total,
        "note": order.note,
        "created_at": order.created_at.isoformat(),
        "items": [
            {
                "menu_item_name": oi.menu_item_name,
                "quantity": oi.quantity,
                "unit_price": oi.unit_price,
                "subtotal": oi.subtotal,
                "item_type": oi.item_type,
            }
            for oi in order.items
        ],
    }


@router.patch(
    "/orders/{order_id}/status",
    dependencies=[Depends(require_permission("orders:update_status"))],
)
async def api_update_status(
    order_id: int,
    new_status: OrderStatus,
    current_user: CurrentUser,
    session: TenantSession,
):
    """Update order status (e.g., new -> cooking -> ready -> completed)."""
    try:
        order = await update_order_status(session, order_id, new_status)
        await notify_kitchen_status_update(
            current_user.tenant_id, order.id, order.status
        )
        return {"status": "ok", "order_id": order.id, "new_status": order.status}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
