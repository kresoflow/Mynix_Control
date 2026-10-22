import json
from typing import Optional
from datetime import datetime, timezone

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
from app.pos.services.checkout_payment_helper import process_customer_checkout, process_cash_income
from app.users.models import Tenant
from app.exceptions import NotFoundError, ConflictError


async def get_next_order_number(session: AsyncSession, shift_id: int) -> int:
    """Get the next sequential order number within a shift."""
    stmt = select(func.coalesce(func.max(Order.order_number), 0)).where(
        Order.shift_id == shift_id,
    )
    result = await session.execute(stmt)
    return (result.scalar() or 0) + 1


def format_order_dict(order: Order, created_by_name: str) -> dict:
    """Standardized serialization of order payload for responses and WS events."""
    return {
        "id": order.id,
        "client_uuid": order.client_uuid,
        "order_number": order.order_number,
        "table_number": order.table_number,
        "order_source": order.order_source,
        "status": order.status,
        "payment_method": order.payment_method,
        "total": order.total,
        "note": order.note,
        "created_by": created_by_name,
        "created_at": f"{order.created_at.isoformat()}Z" if order.created_at else None,
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


async def create_order(
    session: AsyncSession,
    user_id: int,
    tenant_id: int,
    data: CreateOrderRequest,
) -> Order:
    """Create an order in DB. Defers stock deduction and payments for hall orders."""
    tenant = (await session.execute(select(Tenant).where(Tenant.id == tenant_id))).scalar_one_or_none()
    use_kds = False  # KDS module is removed from system; counter orders finalize immediately
    enable_inventory = tenant.enable_inventory_deduction if tenant else True

    if data.client_uuid:
        existing_stmt = select(Order).where(Order.client_uuid == data.client_uuid).options(selectinload(Order.items))
        existing_order = (await session.execute(existing_stmt)).scalar_one_or_none()
        if existing_order:
            return existing_order

    shift = await get_open_shift(session)
    if not shift:
        raise ValueError("Смена закрыта. Откройте смену в кассе для создания заказов.")

    # ── Auto-Merge: If table already has an active open order in shift, append items ──
    if data.table_number:
        active_statuses = [
            OrderStatus.PENDING_APPROVAL,
            OrderStatus.NEW,
            OrderStatus.COOKING,
            OrderStatus.READY,
        ]
        existing_table_stmt = (
            select(Order)
            .where(Order.table_number == data.table_number)
            .where(Order.status.in_(active_statuses))
            .where(Order.shift_id == shift.id)
            .options(selectinload(Order.items))
        )
        existing_table_order = (await session.execute(existing_table_stmt)).scalars().first()
        if existing_table_order:
            from app.pos.services.order_table_service import append_items_to_table_order
            class _SimpleUser:
                def __init__(self, uid, tid, name):
                    self.id = uid
                    self.tenant_id = tid
                    self.full_name = name
            order_data = await append_items_to_table_order(
                session, _SimpleUser(user_id, tenant_id, "Кассир"), existing_table_order.id, data.items
            )
            setattr(existing_table_order, "_is_appended_dozakaz", True)
            setattr(existing_table_order, "_dozakaz_order_data", order_data)
            return existing_table_order

    order_items_data = []
    total = 0.0


    # Batch load all MenuItems in a single query (N+1 query elimination)
    all_item_ids = list({item_req.menu_item_id for item_req in data.items})
    batch_stmt = (
        select(MenuItem)
        .where(MenuItem.id.in_(all_item_ids))
        .options(selectinload(MenuItem.retail_product))
    )
    batch_res = await session.execute(batch_stmt)
    menu_items_map = {m.id: m for m in batch_res.scalars().all()}

    for item_req in data.items:
        menu_item = menu_items_map.get(item_req.menu_item_id)
        if not menu_item:
            raise ValueError(f"Позиция #{item_req.menu_item_id} не найдена в меню")
        if not menu_item.is_available:
            item_label = getattr(menu_item, 'clean_name', menu_item.name)
            raise ValueError(f"Позиция «{item_label}» недоступна для продажи (в архиве).")

        actual_price = item_req.unit_price_override if item_req.unit_price_override is not None else menu_item.price

        selected_options = {}
        if item_req.options_json:
            try:
                selected_options = json.loads(item_req.options_json)
            except Exception:
                selected_options = {}
        elif item_req.selected_options:
            selected_options = item_req.selected_options

        child_item_id = selected_options.get("child_item_id") if isinstance(selected_options, dict) else None

        unit_cost = 0.0
        if menu_item.type == "retail" and menu_item.retail_product:
            unit_cost = menu_item.retail_product.cost
        elif enable_inventory:
            from app.inventory.services.recipe_service import calc_food_cost
            target_cost_id = child_item_id if child_item_id else menu_item.id
            unit_cost = await calc_food_cost(session, target_cost_id)

        subtotal = actual_price * item_req.quantity
        total += subtotal

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

    order_number = await get_next_order_number(session, shift.id)
    has_dish = any(oi["item_type"] == "dish" for oi in order_items_data)
    all_retail = all(oi["item_type"] == "retail" for oi in order_items_data)
    source_lower = (data.order_source or "").lower()
    is_dine_in_order = source_lower in ("dine_in", "hall")

    if is_dine_in_order:
        initial_status = OrderStatus.COOKING if (has_dish and use_kds) else OrderStatus.READY
    elif not use_kds:
        initial_status = OrderStatus.COMPLETED
    elif has_dish:
        initial_status = OrderStatus.COOKING
    elif all_retail and order_items_data:
        initial_status = OrderStatus.COMPLETED
    else:
        initial_status = OrderStatus.NEW

    order = Order(
        client_uuid=data.client_uuid,
        shift_id=shift.id,
        created_by=user_id,
        customer_id=data.customer_id,
        order_number=order_number,
        table_number=data.table_number,
        order_source=data.order_source or "pos",
        status=initial_status,
        payment_method="unpaid" if is_dine_in_order else data.payment_method,
        bonus_spent=round(data.bonus_spent or 0.0, 2),
        total=round(total, 2),
        note=data.note,
    )
    session.add(order)
    await session.flush()

    for oi_data in order_items_data:
        oi = OrderItem(order_id=order.id, **oi_data)
        session.add(oi)

    if not is_dine_in_order:
        if enable_inventory:
            inventory_items = [
                {
                    "menu_item_id": oi["menu_item_id"],
                    "quantity": oi["quantity"],
                    "selected_options": oi["selected_options"],
                }
                for oi in order_items_data
            ]
            await inventory_svc.deduct_ingredients(session, inventory_items, user_id)
        await process_customer_checkout(session, data, total, order, user_id)
        await process_cash_income(session, shift, user_id, order_number, total, data)
    elif is_dine_in_order and enable_inventory:
        inventory_items = [
            {
                "menu_item_id": oi["menu_item_id"],
                "quantity": oi["quantity"],
                "selected_options": oi["selected_options"],
            }
            for oi in order_items_data
        ]
        await inventory_svc.deduct_ingredients(session, inventory_items, user_id)

    await session.flush()
    return order


async def process_new_order(session: AsyncSession, current_user, data: CreateOrderRequest) -> dict:
    """Orchestrates order creation and triggers appropriate WS notifications."""
    from app.pos.ws import notify_inventory_updated

    order = await create_order(session, current_user.id, current_user.tenant_id, data)
    if getattr(order, "_is_appended_dozakaz", False):
        return getattr(order, "_dozakaz_order_data")

    full_order = await get_order_by_id(session, order.id)
    if not full_order:
        raise NotFoundError("Failed to fetch newly created order")

    order_data = format_order_dict(full_order, current_user.full_name)
    await notify_inventory_updated(current_user.tenant_id)
    return order_data


def parse_filter_dt(val: str, is_end: bool = False) -> datetime:
    val = val.strip()
    if "T" in val:
        clean_val = val.replace("Z", "+00:00")
        dt = datetime.fromisoformat(clean_val)
        if dt.tzinfo is not None:
            dt = dt.astimezone(timezone.utc).replace(tzinfo=None)
        return dt
    time_str = "23:59:59" if is_end else "00:00:00"
    return datetime.strptime(f"{val} {time_str}", "%Y-%m-%d %H:%M:%S")


async def list_orders(
    session: AsyncSession,
    shift_id: Optional[int] = None,
    status_filter: Optional[OrderStatus] = None,
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
) -> list[Order]:
    """List orders, optionally filtered by shift and/or status."""
    stmt = select(Order).options(selectinload(Order.items)).order_by(Order.created_at.desc())
    if shift_id:
        stmt = stmt.where(Order.shift_id == shift_id)
    if status_filter:
        stmt = stmt.where(Order.status == status_filter)
    if start_date:
        try:
            start_dt = parse_filter_dt(start_date, is_end=False)
            stmt = stmt.where(Order.created_at >= start_dt)
        except Exception:
            pass
    if end_date:
        try:
            end_dt = parse_filter_dt(end_date, is_end=True)
            stmt = stmt.where(Order.created_at <= end_dt)
        except Exception:
            pass

    result = await session.execute(stmt)
    return list(result.scalars().all())


async def get_order_by_id(session: AsyncSession, order_id: int) -> Optional[Order]:
    """Get a single order with its items."""
    stmt = select(Order).where(Order.id == order_id).options(selectinload(Order.items))
    result = await session.execute(stmt)
    return result.scalar_one_or_none()


async def update_order_status(session: AsyncSession, order_id: int, new_status: OrderStatus) -> Order:
    """Update order status."""
    order = await get_order_by_id(session, order_id)
    if not order:
        raise NotFoundError(f"Заказ #{order_id} не найден")
    order.status = new_status
    session.add(order)
    await session.flush()
    return order
