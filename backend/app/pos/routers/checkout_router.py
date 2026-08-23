from typing import Optional
from pydantic import BaseModel
from fastapi import APIRouter, Depends, HTTPException, status, Query

from app.dependencies import require_permission, CurrentUser, TenantSession
from app.pos.models import CreateOrderRequest, OrderStatus
from app.pos.services.checkout_service import (
    create_order, list_orders, get_order_by_id, update_order_status,
    process_new_order, approve_order, reject_order
)
from app.pos.ws import notify_kitchen_status_update

router = APIRouter(tags=["POS — Orders & Checkout"])


class ApproveOrderRequest(BaseModel):
    payment_method: Optional[str] = None
    is_paid: bool = False


class RejectOrderRequest(BaseModel):
    reason: Optional[str] = None


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
    If order_source is waiter/qr_guest: status becomes pending_approval (deferred stock deduction).
    If pos: immediate deduction and kitchen notification.
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
            "table_number": o.table_number,
            "order_source": o.order_source,
            "status": o.status,
            "payment_method": o.payment_method,
            "total": o.total,
            "note": o.note,
            "created_at": o.created_at.isoformat() if o.created_at else None,
            "items": [
                {
                    "menu_item_name": oi.menu_item_name,
                    "quantity": oi.quantity,
                    "unit_price": oi.unit_price,
                    "subtotal": oi.subtotal,
                    "selected_options": oi.selected_options,
                    "item_type": oi.item_type,
                }
                for oi in (o.items or [])
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
        "table_number": order.table_number,
        "order_source": order.order_source,
        "status": order.status,
        "payment_method": order.payment_method,
        "total": order.total,
        "note": order.note,
        "created_at": order.created_at.isoformat() if order.created_at else None,
        "items": [
            {
                "menu_item_name": oi.menu_item_name,
                "quantity": oi.quantity,
                "unit_price": oi.unit_price,
                "subtotal": oi.subtotal,
                "selected_options": oi.selected_options,
                "item_type": oi.item_type,
            }
            for oi in (order.items or [])
        ],
    }


@router.post(
    "/orders/{order_id}/approve",
    dependencies=[Depends(require_permission("orders:edit"))],
)
async def api_approve_order(
    order_id: int,
    current_user: CurrentUser,
    session: TenantSession,
    body: Optional[ApproveOrderRequest] = None,
):
    """Cashier approves incoming hall order -> triggers stock deduction and dispatches to KDS."""
    req = body or ApproveOrderRequest()
    return await approve_order(
        session, current_user, order_id,
        payment_method=req.payment_method,
        is_paid=req.is_paid
    )


@router.post(
    "/orders/{order_id}/reject",
    dependencies=[Depends(require_permission("orders:cancel"))],
)
async def api_reject_order(
    order_id: int,
    current_user: CurrentUser,
    session: TenantSession,
    body: Optional[RejectOrderRequest] = None,
):
    """Cashier rejects incoming hall order -> cancels without deducting stock."""
    req = body or RejectOrderRequest()
    return await reject_order(session, current_user, order_id, reason=req.reason)


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
    """Update order status (e.g., cooking -> ready -> completed)."""
    try:
        order = await update_order_status(session, order_id, new_status)
        await notify_kitchen_status_update(
            current_user.tenant_id, order.id, order.status
        )
        return {"status": "ok", "order_id": order.id, "new_status": order.status}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
