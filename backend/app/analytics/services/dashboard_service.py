from collections import defaultdict
from typing import List, Type
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select, SQLModel
from app.pos.models import Shift, Order, OrderItem, OrderStatus
from app.inventory.models import RetailProduct, Ingredient
from app.analytics.models import (
    DashboardTodayRead, LowStockAlert, TopItem, 
    RecentOrder, RecentOrderItem
)
from app.analytics.utils import format_selected_options

async def _fetch_low_stock_alerts(session: AsyncSession, model_classes: List[Type[SQLModel]]) -> List[LowStockAlert]:
    """Fetch low-stock alerts across multiple inventory models (RetailProduct, Ingredient)."""
    alerts = []
    for cls in model_classes:
        query = select(cls).where(cls.current_stock <= cls.min_stock_alert)
        result = await session.execute(query)
        for item in result.scalars().all():
            alerts.append(LowStockAlert(name=item.name, current_stock=item.current_stock))
    return alerts

async def get_today_dashboard(session: AsyncSession) -> DashboardTodayRead:
    # Find open shift
    shift_query = select(Shift).where(Shift.is_open == True)
    shift_result = await session.execute(shift_query)
    shift = shift_result.scalar_one_or_none()

    if not shift:
        return DashboardTodayRead(
            total_revenue=0.0,
            total_orders=0,
            dishes_revenue=0.0,
            retail_revenue=0.0,
            low_stock_alerts=[],
            top_items=[],
            recent_orders=[]
        )

    # Get total orders and total revenue
    orders_query = select(Order).where(
        Order.shift_id == shift.id,
        Order.status != OrderStatus.CANCELLED
    )
    orders_result = await session.execute(orders_query)
    orders = orders_result.scalars().all()

    total_orders = len(orders)
    total_revenue = sum(order.total for order in orders)

    # Get dishes and retail revenues
    dishes_revenue = 0.0
    retail_revenue = 0.0
    total_cogs = 0.0
    top_items_list = []
    recent_orders_list = []
    
    if total_orders > 0:
        order_ids = [order.id for order in orders]
        
        items_query = select(OrderItem).where(OrderItem.order_id.in_(order_ids))
        items_result = await session.execute(items_query)
        items = items_result.scalars().all()
        
        item_counts = defaultdict(int)
        item_options_map = {}
        order_items_map = defaultdict(list)
        
        for item in items:
            total_cogs += (item.unit_cost or 0.0) * item.quantity
            if item.item_type == "dish":
                dishes_revenue += item.subtotal
            elif item.item_type == "retail":
                retail_revenue += item.subtotal
            
            # Format options via helper
            display_name = item.menu_item_name
            options_text = format_selected_options(item.selected_options)

            # Aggregate for top items
            group_key = display_name if not options_text else f"{display_name}|{options_text}"
            item_counts[group_key] += item.quantity
            item_options_map[group_key] = {"name": display_name, "options": options_text}
            
            # Aggregate for recent orders
            order_items_map[item.order_id].append(
                RecentOrderItem(name=display_name, options=options_text, quantity=item.quantity)
            )

        # Process top items
        sorted_top = sorted(item_counts.items(), key=lambda x: x[1], reverse=True)[:5]
        top_items_list = [
            TopItem(
                name=item_options_map[k]["name"],
                options=item_options_map[k]["options"],
                quantity_sold=v
            ) 
            for k, v in sorted_top
        ]

        # Process recent orders
        sorted_orders = sorted(orders, key=lambda o: o.created_at, reverse=True)[:10]
        recent_orders_list = [
            RecentOrder(
                order_number=str(o.order_number),
                created_at=o.created_at.isoformat(),
                total=o.total,
                items=order_items_map.get(o.id, [])
            )
            for o in sorted_orders
        ]

    # Get low stock alerts for RetailProduct and Ingredient via DRY helper
    low_stock_alerts = await _fetch_low_stock_alerts(session, [RetailProduct, Ingredient])

    net_profit = total_revenue - total_cogs
    margin_percentage = (net_profit / total_revenue * 100) if total_revenue > 0 else 0.0

    return DashboardTodayRead(
        total_revenue=total_revenue,
        total_orders=total_orders,
        dishes_revenue=dishes_revenue,
        retail_revenue=retail_revenue,
        total_cogs=total_cogs,
        net_profit=net_profit,
        margin_percentage=margin_percentage,
        low_stock_alerts=low_stock_alerts,
        top_items=top_items_list,
        recent_orders=recent_orders_list
    )
