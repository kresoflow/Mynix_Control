from typing import List
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload
from sqlmodel import select

from app.pos.models import Order, OrderStatus


async def get_active_orders(session: AsyncSession) -> List[Order]:
    """
    Get active orders (status COOKING).
    Only includes items with item_type == "dish".
    Excludes orders that have no "dish" items.
    """
    stmt = (
        select(Order)
        .options(selectinload(Order.items))
        .where(Order.status == OrderStatus.COOKING)
        .order_by(Order.created_at.asc())
    )
    result = await session.execute(stmt)
    orders = result.scalars().all()
    
    filtered_orders = []
    for order in orders:
        if any(item.item_type == "dish" for item in order.items):
            filtered_orders.append(order)
            
    return filtered_orders


async def mark_order_ready(session: AsyncSession, order_id: int) -> Order:
    """
    Change order status from COOKING to READY.
    """
    stmt = select(Order).where(Order.id == order_id)
    result = await session.execute(stmt)
    order = result.scalar_one_or_none()
    
    if not order:
        raise ValueError(f"Order #{order_id} not found")
        
    if order.status != OrderStatus.COOKING:
        raise ValueError(f"Order #{order_id} is not in COOKING status (current: {order.status.value})")
        
    order.status = OrderStatus.READY
    session.add(order)
    await session.flush()
    
    # Refresh to include items in response, or we can just return it.
    # Typically, it's better to reload it.
    stmt_reload = select(Order).options(selectinload(Order.items)).where(Order.id == order.id)
    result_reload = await session.execute(stmt_reload)
    return result_reload.scalar_one()
