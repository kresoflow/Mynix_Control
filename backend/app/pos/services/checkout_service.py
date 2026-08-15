from typing import Optional

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload
from sqlmodel import select, func

from app.pos.models import (
    Order, OrderItem, CashTransaction,
    OrderStatus, PaymentMethod, CashTransactionType,
    CreateOrderRequest
)
from app.inventory.models import MenuItem
from app.inventory import services as inventory_svc
from app.pos.services.shift_service import get_open_shift


async def get_next_order_number(
    session: AsyncSession,
    shift_id: int,
) -> int:
    """Get the next sequential order number within a shift."""
    stmt = select(func.coalesce(func.max(Order.order_number), 0)).where(
        Order.shift_id == shift_id,
    )
    result = await session.execute(stmt)
    return (result.scalar() or 0) + 1


async def create_order(
    session: AsyncSession,
    user_id: int,
    tenant_id: int,
    data: CreateOrderRequest,
) -> Order:
    """
    Create an order:
      1. Validate shift is open
      2. Resolve menu item prices
      3. Create Order + OrderItems
      4. Auto-deduct ingredients (cross-module call to inventory)
      5. Log cash income if payment is cash
      6. Return the created order
    """
    from app.users.models import Tenant
    tenant = (await session.execute(select(Tenant).where(Tenant.id == tenant_id))).scalar_one_or_none()
    use_kds = tenant.use_kds if tenant else True
    enable_inventory = tenant.enable_inventory_deduction if tenant else True

    # 1. Validate shift
    shift = await get_open_shift(session)
    if not shift:
        raise ValueError("Cannot create order: no open shift.")

    # 2. Resolve prices and build items
    order_items_data = []
    total = 0.0

    for item_req in data.items:
        stmt = select(MenuItem).where(
            MenuItem.id == item_req.menu_item_id,
        ).options(selectinload(MenuItem.retail_product))
        result = await session.execute(stmt)
        menu_item = result.scalar_one_or_none()
        if not menu_item:
            raise ValueError(f"Menu item #{item_req.menu_item_id} not found")
        if not menu_item.is_available:
            raise ValueError(f"Menu item '{menu_item.name}' is not available")

        # Use overridden price if provided (e.g. for variations), otherwise use base price
        actual_price = item_req.unit_price_override if item_req.unit_price_override is not None else menu_item.price

        # Calculate unit cost
        unit_cost = 0.0
        if menu_item.type == "retail" and menu_item.retail_product:
            unit_cost = menu_item.retail_product.cost
        elif enable_inventory:
            from app.inventory.services.recipe_service import calc_food_cost
            unit_cost = await calc_food_cost(session, menu_item.id)

        subtotal = actual_price * item_req.quantity
        total += subtotal

        # Parse options
        import json
        selected_options = {}
        if item_req.options_json:
            try:
                selected_options = json.loads(item_req.options_json)
            except Exception:
                pass

        order_items_data.append({
            "menu_item_id": menu_item.id,
            "menu_item_name": menu_item.name,
            "quantity": item_req.quantity,
            "unit_price": actual_price,
            "unit_cost": unit_cost,
            "subtotal": subtotal,
            "item_type": menu_item.type,
            "selected_options": selected_options,
        })

    # 3. Create Order
    order_number = await get_next_order_number(session, shift.id)
    
    has_dish = any(oi["item_type"] == "dish" for oi in order_items_data)
    all_retail = all(oi["item_type"] == "retail" for oi in order_items_data)
    
    if not use_kds:
        initial_status = OrderStatus.COMPLETED
    elif has_dish:
        initial_status = OrderStatus.COOKING
    elif all_retail and order_items_data:
        initial_status = OrderStatus.COMPLETED
    else:
        initial_status = OrderStatus.NEW

    order = Order(
        shift_id=shift.id,
        created_by=user_id,
        order_number=order_number,
        status=initial_status,
        payment_method=data.payment_method,
        total=round(total, 2),
        note=data.note,
    )
    session.add(order)
    await session.flush()

    # Create OrderItems
    for oi_data in order_items_data:
        oi = OrderItem(order_id=order.id, **oi_data)
        session.add(oi)

    # 4. Auto-deduct ingredients from stock
    if enable_inventory:
        inventory_items = [
            {"menu_item_id": oi["menu_item_id"], "quantity": oi["quantity"]}
            for oi in order_items_data
        ]
        await inventory_svc.deduct_ingredients(
            session, inventory_items, user_id
        )

    # 5. Record cash income (if cash payment)
    if data.payment_method in (PaymentMethod.CASH, PaymentMethod.MIXED):
        cash_amount = total if data.payment_method == PaymentMethod.CASH else total / 2
        txn = CashTransaction(
            shift_id=shift.id,
            user_id=user_id,
            type=CashTransactionType.INCOME,
            amount=round(cash_amount, 2),
            description=f"Order #{order_number} payment",
        )
        session.add(txn)

    await session.flush()
    return order


async def update_order_status(
    session: AsyncSession,
    order_id: int,
    new_status: OrderStatus,
) -> Order:
    """Update order status (e.g., cooking -> ready -> completed)."""
    stmt = select(Order).where(
        Order.id == order_id,
    )
    result = await session.execute(stmt)
    order = result.scalar_one_or_none()
    if not order:
        raise ValueError(f"Order #{order_id} not found")

    order.status = new_status
    session.add(order)
    return order


async def list_orders(
    session: AsyncSession,
    shift_id: Optional[int] = None,
    status_filter: Optional[OrderStatus] = None,
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
) -> list[Order]:
    """List orders, optionally filtered by shift and/or status."""
    stmt = (
        select(Order)
        .options(selectinload(Order.items))
        .order_by(Order.created_at.desc())
    )
    if shift_id:
        stmt = stmt.where(Order.shift_id == shift_id)
    if status_filter:
        stmt = stmt.where(Order.status == status_filter)
    from datetime import datetime
    if start_date:
        start_dt = datetime.strptime(f"{start_date} 00:00:00", "%Y-%m-%d %H:%M:%S")
        stmt = stmt.where(Order.created_at >= start_dt)
    if end_date:
        end_dt = datetime.strptime(f"{end_date} 23:59:59", "%Y-%m-%d %H:%M:%S")
        stmt = stmt.where(Order.created_at <= end_dt)

    result = await session.execute(stmt)
    return list(result.scalars().all())


async def get_order_by_id(
    session: AsyncSession,
    order_id: int,
) -> Optional[Order]:
    """Get a single order with its items."""
    stmt = (
        select(Order)
        .where(Order.id == order_id)
        .options(selectinload(Order.items))
    )
    result = await session.execute(stmt)
    return result.scalar_one_or_none()


async def process_new_order(
    session: AsyncSession,
    current_user,
    data: CreateOrderRequest,
) -> dict:
    """
    Orchestrates full checkout workflow:
    1. Validates and saves Order + items + cash ledger + inventory deductions
    2. Eagerly loads full order
    3. Triggers async WebSocket notifications for kitchen and inventory
    4. Returns serialized order dictionary
    """
    from app.pos.ws import notify_kitchen_new_order, notify_inventory_updated
    from app.exceptions import NotFoundError

    order = await create_order(session, current_user.id, current_user.tenant_id, data)
    full_order = await get_order_by_id(session, order.id)
    if not full_order:
        raise NotFoundError("Failed to fetch newly created order")

    order_data = {
        "id": full_order.id,
        "order_number": full_order.order_number,
        "status": full_order.status,
        "payment_method": full_order.payment_method,
        "total": full_order.total,
        "note": full_order.note,
        "created_by": current_user.full_name,
        "items": [
            {
                "menu_item_name": oi.menu_item_name,
                "quantity": oi.quantity,
                "unit_price": oi.unit_price,
                "subtotal": oi.subtotal,
                "selected_options": oi.selected_options,
                "item_type": oi.item_type,
            }
            for oi in full_order.items
        ],
    }

    has_dishes = any(oi.item_type == "dish" for oi in full_order.items)
    if has_dishes:
        await notify_kitchen_new_order(current_user.tenant_id, order_data)

    await notify_inventory_updated(current_user.tenant_id)
    return order_data
