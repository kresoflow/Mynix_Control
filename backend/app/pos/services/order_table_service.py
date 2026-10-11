import json
from typing import Optional, List
from datetime import datetime, timezone

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload
from sqlmodel import select

from app.pos.models import (
    Order, OrderItem, CashTransaction,
    OrderStatus, CashTransactionType,
)
from app.inventory.models import MenuItem
from app.inventory import services as inventory_svc
from app.pos.services.shift_service import get_open_shift
from app.pos.services.checkout_service import format_order_dict, get_order_by_id
from app.users.models import Tenant
from app.exceptions import NotFoundError, ConflictError


async def get_active_tables_orders(session: AsyncSession) -> List[dict]:
    """Returns all active, unpaid hall orders grouped by table with batches and clean aggregation."""
    active_statuses = [
        OrderStatus.NEW,
        OrderStatus.COOKING,
        OrderStatus.READY,
    ]
    stmt = (
        select(Order)
        .where(Order.table_number.is_not(None))
        .where(Order.status.in_(active_statuses))
        .options(selectinload(Order.items))
        .order_by(Order.created_at.desc())
    )
    result = await session.execute(stmt)
    orders = result.scalars().all()

    now_utc = datetime.now(timezone.utc).replace(tzinfo=None)
    tables_data = []

    for o in orders:
        created_at_dt = o.created_at or now_utc
        elapsed_minutes = max(0, int((now_utc - created_at_dt).total_seconds() // 60))

        raw_items = []
        served_items = []
        dozakaz_items = []
        clean_map = {}

        for oi in (o.items or []):
            opts = oi.selected_options if isinstance(oi.selected_options, dict) else {}
            is_doz = bool(opts.get("is_dozakaz", False))
            it_dict = {
                "id": oi.id,
                "menu_item_id": oi.menu_item_id,
                "menu_item_name": oi.menu_item_name,
                "quantity": oi.quantity,
                "unit_price": oi.unit_price,
                "subtotal": oi.subtotal,
                "selected_options": oi.selected_options,
                "item_type": oi.item_type,
                "is_dozakaz": is_doz,
            }
            raw_items.append(it_dict)
            if is_doz:
                dozakaz_items.append(it_dict)
            else:
                served_items.append(it_dict)

            # Aggregate for clean final bill (merge same items together)
            key = (oi.menu_item_id, oi.menu_item_name, oi.unit_price)
            if key not in clean_map:
                clean_map[key] = dict(it_dict)
            else:
                clean_map[key]["quantity"] += oi.quantity
                clean_map[key]["subtotal"] = round(clean_map[key]["subtotal"] + oi.subtotal, 2)

        tables_data.append({
            "order_id": o.id,
            "order_number": o.order_number,
            "table_number": o.table_number,
            "order_source": o.order_source,
            "status": o.status,
            "payment_method": o.payment_method,
            "total": o.total,
            "note": o.note,
            "elapsed_minutes": elapsed_minutes,
            "created_at": f"{o.created_at.isoformat()}Z" if o.created_at else None,
            "items": raw_items,
            "clean_items": list(clean_map.values()),
            "served_items": served_items,
            "dozakaz_items": dozakaz_items,
            "has_dozakaz": len(dozakaz_items) > 0,
        })

    return tables_data


async def settle_table_order(
    session: AsyncSession,
    current_user,
    order_id: int,
    payment_method: str,
    note: Optional[str] = None,
) -> dict:
    """Settles and completes a dine-in table order (post-payment)."""
    from app.pos.ws import (
        notify_pos_incoming_resolved,
        notify_inventory_updated,
    )

    # [БЕЗОПАСНОСТЬ] [ТРАНЗАКЦИЯ] Блокировка строки заказа от состояния гонки
    stmt = (
        select(Order)
        .where(Order.id == order_id)
        .options(selectinload(Order.items))
        .with_for_update()
        .execution_options(populate_existing=True)
    )
    res = await session.execute(stmt)
    order = res.scalar_one_or_none()
    if not order:
        raise NotFoundError(f"Заказ #{order_id} не найден")

    if order.status in (OrderStatus.COMPLETED, OrderStatus.COMPLETED.value):
        raise ConflictError(f"Заказ #{order.order_number} уже был оплачен и закрыт.")
    if order.status in (OrderStatus.CANCELLED, OrderStatus.CANCELLED.value):
        raise ConflictError(f"Заказ #{order.order_number} отменен и не может быть оплачен.")

    tenant = (await session.execute(select(Tenant).where(Tenant.id == current_user.tenant_id))).scalar_one_or_none()
    enable_inventory = tenant.enable_inventory_deduction if tenant else True

    if order.status == OrderStatus.PENDING_APPROVAL and enable_inventory:
        inventory_items = [
            {
                "menu_item_id": oi.menu_item_id,
                "quantity": oi.quantity,
                "selected_options": oi.selected_options,
            }
            for oi in order.items
        ]
        await inventory_svc.deduct_ingredients(session, inventory_items, current_user.id)

    order.status = OrderStatus.COMPLETED
    order.payment_method = payment_method.lower()
    if note:
        order.note = f"{order.note or ''} | {note}".strip(" |")
    session.add(order)

    open_shift = await get_open_shift(session)
    if open_shift:
        order.shift_id = open_shift.id
        if str(order.payment_method).lower() == "cash":
            tx = CashTransaction(
                shift_id=open_shift.id,
                user_id=current_user.id,
                type=CashTransactionType.INCOME,
                amount=order.total,
                description=f"Расчет столика {order.table_number or 'Зал'} (Чек #{order.order_number})",
            )
            session.add(tx)

    await session.flush()
    full_order = await get_order_by_id(session, order.id)
    order_data = format_order_dict(full_order or order, current_user.full_name)

    await notify_pos_incoming_resolved(current_user.tenant_id, order_data)
    await notify_inventory_updated(current_user.tenant_id)

    return order_data


async def append_items_to_table_order(
    session: AsyncSession,
    current_user,
    order_id: int,
    items_data: list,
) -> dict:
    """Appends additional items (дозаказ) to an active table order."""
    from app.pos.ws import notify_inventory_updated

    order = await get_order_by_id(session, order_id)
    if not order:
        raise NotFoundError(f"Заказ #{order_id} не найден")

    tenant = (await session.execute(select(Tenant).where(Tenant.id == current_user.tenant_id))).scalar_one_or_none()
    enable_inventory = tenant.enable_inventory_deduction if tenant else True

    new_order_items = []
    added_total = 0.0

    # Batch load all MenuItems in a single query (N+1 query elimination)
    all_item_ids = list({item_req.menu_item_id for item_req in items_data})
    batch_stmt = (
        select(MenuItem)
        .where(MenuItem.id.in_(all_item_ids))
        .options(selectinload(MenuItem.retail_product))
    )
    batch_res = await session.execute(batch_stmt)
    menu_items_map = {m.id: m for m in batch_res.scalars().all()}

    for item_req in items_data:
        menu_item = menu_items_map.get(item_req.menu_item_id)
        if not menu_item or not menu_item.is_available:
            continue

        actual_price = item_req.unit_price_override if item_req.unit_price_override is not None else menu_item.price
        selected_options = {}
        if item_req.options_json:
            try:
                selected_options = json.loads(item_req.options_json)
            except Exception:
                selected_options = {}
        elif item_req.selected_options:
            selected_options = dict(item_req.selected_options)

        # Mark as dozakaz batch!
        selected_options["is_dozakaz"] = True

        unit_cost = 0.0
        if menu_item.type == "retail" and menu_item.retail_product:
            unit_cost = menu_item.retail_product.cost
        elif enable_inventory:
            from app.inventory.services.recipe_service import calc_food_cost
            child_id = selected_options.get("child_item_id") if isinstance(selected_options, dict) else None
            unit_cost = await calc_food_cost(session, child_id if child_id else menu_item.id)

        subtotal = actual_price * item_req.quantity
        added_total += subtotal

        oi = OrderItem(
            order_id=order.id,
            menu_item_id=menu_item.id,
            menu_item_name=menu_item.name,
            quantity=item_req.quantity,
            unit_price=actual_price,
            unit_cost=unit_cost,
            subtotal=subtotal,
            item_type=menu_item.type,
            selected_options=selected_options,
        )
        session.add(oi)
        new_order_items.append(oi)

    order.items = list(order.items or []) + new_order_items
    order.total = round(order.total + added_total, 2)
    session.add(order)

    if order.status != OrderStatus.PENDING_APPROVAL and enable_inventory:
        inv_items = [
            {
                "menu_item_id": oi.menu_item_id,
                "quantity": oi.quantity,
                "selected_options": oi.selected_options,
            }
            for oi in new_order_items
        ]
        await inventory_svc.deduct_ingredients(session, inv_items, current_user.id)

    await session.flush()
    order_data = format_order_dict(order, current_user.full_name)
    await notify_inventory_updated(current_user.tenant_id)
    return order_data


async def split_table_order(
    session: AsyncSession,
    current_user,
    order_id: int,
    split_items: list,
    payment_method: str,
    note: Optional[str] = None,
) -> dict:
    """Splits selected items from active table order and completes their payment."""
    from app.pos.ws import notify_pos_incoming_resolved, notify_inventory_updated

    order = await get_order_by_id(session, order_id)
    if not order:
        raise NotFoundError(f"Заказ #{order_id} не найден")

    open_shift = await get_open_shift(session)
    shift_id = open_shift.id if open_shift else order.shift_id

    split_total = 0.0
    split_order_items = []

    for split_it in split_items:
        menu_item_id = int(split_it.get("menu_item_id", 0))
        split_qty = int(split_it.get("quantity", 1))
        unit_price = float(split_it.get("unit_price", 0.0))
        subtotal = round(unit_price * split_qty, 2)
        split_total += subtotal

        rem_to_deduct = split_qty
        for oi in list(order.items or []):
            if oi.menu_item_id == menu_item_id and rem_to_deduct > 0:
                deduct_here = min(oi.quantity, rem_to_deduct)
                oi.quantity -= deduct_here
                oi.subtotal = round(oi.quantity * oi.unit_price, 2)
                rem_to_deduct -= deduct_here

        split_order_items.append({
            "menu_item_id": menu_item_id,
            "menu_item_name": split_it.get("menu_item_name", ""),
            "quantity": split_qty,
            "unit_price": unit_price,
            "subtotal": subtotal,
            "item_type": split_it.get("item_type", "dish"),
            "selected_options": split_it.get("selected_options", {}),
        })

    # Filter out empty items from parent order
    remaining_items = []
    for oi in list(order.items or []):
        if oi.quantity > 0:
            remaining_items.append(oi)
            session.add(oi)
        else:
            await session.delete(oi)

    order.items = remaining_items
    parent_new_total = sum(oi.subtotal for oi in remaining_items)
    order.total = round(parent_new_total, 2)

    unique_uuid = f"split_{order.id}_{int(datetime.now(timezone.utc).timestamp() * 1000)}"
    child_order = Order(
        client_uuid=unique_uuid,
        shift_id=shift_id,
        created_by=current_user.id,
        order_number=order.order_number,
        table_number=order.table_number,
        order_source="pos_split",
        status=OrderStatus.COMPLETED,
        payment_method=payment_method.lower(),
        total=round(split_total, 2),
        note=f"Раздельный чек ({order.table_number or 'Зал'}) {note or ''}".strip(),
    )
    session.add(child_order)
    await session.flush()

    for soi in split_order_items:
        session.add(OrderItem(order_id=child_order.id, **soi))

    if str(payment_method).lower() == "cash" and open_shift:
        session.add(CashTransaction(
            shift_id=open_shift.id,
            user_id=current_user.id,
            type=CashTransactionType.INCOME,
            amount=round(split_total, 2),
            description=f"Оплата раздельного чека {order.table_number or 'Зал'} (#{order.order_number})",
        ))

    if not remaining_items:
        order.status = OrderStatus.COMPLETED

    session.add(order)
    await session.flush()

    full_child = await get_order_by_id(session, child_order.id)
    order_data = format_order_dict(full_child or child_order, current_user.full_name)
    await notify_pos_incoming_resolved(current_user.tenant_id, order_data)
    await notify_inventory_updated(current_user.tenant_id)

    return {
        "split_order": order_data,
        "parent_order_remaining_total": order.total,
        "is_table_fully_paid": order.status == OrderStatus.COMPLETED,
    }


async def serve_table_order(
    session: AsyncSession,
    current_user,
    order_id: int,
) -> dict:
    """Marks a table order as served (READY) and clears dozakaz items batch flag."""
    from app.pos.ws import notify_pos_incoming_resolved

    order = await get_order_by_id(session, order_id)
    if not order:
        raise NotFoundError(f"Заказ #{order_id} не найден")

    order.status = OrderStatus.READY

    for oi in (order.items or []):
        if isinstance(oi.selected_options, dict) and oi.selected_options.get("is_dozakaz"):
            new_opts = dict(oi.selected_options)
            new_opts["is_dozakaz"] = False
            oi.selected_options = new_opts
            session.add(oi)

    session.add(order)
    await session.flush()

    full_order = await get_order_by_id(session, order.id)
    order_data = format_order_dict(full_order or order, current_user.full_name)
    await notify_pos_incoming_resolved(current_user.tenant_id, order_data)
    return order_data


