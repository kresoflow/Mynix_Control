from datetime import datetime, timedelta
from typing import Optional
from collections import defaultdict

from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select, func

from app.pos.models import Order, OrderItem, OrderStatus
from app.analytics.models import (
    AnalyticsMetrics, TimeSeriesPoint, AnalyticsXRay, 
    CategorySales, XRayItem
)
from app.inventory.models import RetailProduct, MenuItem, MenuCategory
from app.analytics.utils import format_selected_options

async def get_analytics_metrics(
    session: AsyncSession, 
    start_date: datetime, 
    end_date: datetime, 
    group_by: str
) -> AnalyticsMetrics:
    # Get all completed orders in range
    orders_query = select(Order).where(
        Order.created_at >= start_date,
        Order.created_at <= end_date,
        Order.status != "cancelled",
        Order.status != "CANCELLED",
    )
    orders_result = await session.execute(orders_query)
    orders = orders_result.scalars().all()

    total_orders = len(orders)
    total_revenue = sum(o.total for o in orders)
    average_check = total_revenue / total_orders if total_orders > 0 else 0.0

    # Calculate COGS (Cost of Goods Sold) via single SQL aggregate join
    cogs_stmt = (
        select(func.coalesce(func.sum(OrderItem.unit_cost * OrderItem.quantity), 0.0))
        .join(Order, OrderItem.order_id == Order.id)
        .where(
            Order.created_at >= start_date,
            Order.created_at <= end_date,
            Order.status != "cancelled",
            Order.status != "CANCELLED",
        )
    )
    cogs_res = await session.execute(cogs_stmt)
    total_cogs = float(cogs_res.scalar() or 0.0)

    net_profit = total_revenue - total_cogs
    margin_percentage = (net_profit / total_revenue * 100) if total_revenue > 0 else 0.0

    # Time series grouping
    time_series_map = defaultdict(lambda: {"revenue": 0.0, "orders": 0})
    
    # Pre-fill timeline
    current = start_date
    while current <= end_date:
        if group_by == "hour":
            key = current.strftime("%Y-%m-%d %H:00")
            time_series_map[key] = {"revenue": 0.0, "orders": 0}
            current += timedelta(hours=1)
        elif group_by == "day":
            key = current.strftime("%Y-%m-%d")
            time_series_map[key] = {"revenue": 0.0, "orders": 0}
            current += timedelta(days=1)
        elif group_by == "month":
            key = current.strftime("%Y-%m")
            time_series_map[key] = {"revenue": 0.0, "orders": 0}
            # Go to next month
            current = (current.replace(day=28) + timedelta(days=4)).replace(day=1)
        else:
            key = current.strftime("%Y-%m-%d")
            time_series_map[key] = {"revenue": 0.0, "orders": 0}
            current += timedelta(days=1)

    for order in orders:
        if group_by == "hour":
            key = order.created_at.strftime("%Y-%m-%d %H:00")
        elif group_by == "day":
            key = order.created_at.strftime("%Y-%m-%d")
        elif group_by == "month":
            key = order.created_at.strftime("%Y-%m")
        else:
            key = order.created_at.strftime("%Y-%m-%d")
            
        if key in time_series_map:
            time_series_map[key]["revenue"] += order.total
            time_series_map[key]["orders"] += 1

    time_series = [
        TimeSeriesPoint(timestamp=k, revenue=v["revenue"], orders=v["orders"])
        for k, v in sorted(time_series_map.items())
    ]

    if not time_series:
        time_series.append(TimeSeriesPoint(timestamp=start_date.strftime("%Y-%m-%d"), revenue=0.0, orders=0))

    return AnalyticsMetrics(
        total_revenue=total_revenue,
        total_orders=total_orders,
        net_profit=net_profit,
        margin_percentage=margin_percentage,
        average_check=average_check,
        time_series=time_series
    )

async def get_analytics_xray(
    session: AsyncSession, 
    start_date: datetime, 
    end_date: datetime
) -> AnalyticsXRay:
    orders_query = select(Order.id).where(
        Order.created_at >= start_date,
        Order.created_at <= end_date,
        Order.status != OrderStatus.CANCELLED
    )
    orders_result = await session.execute(orders_query)
    order_ids = orders_result.scalars().all()

    if not order_ids:
        return AnalyticsXRay(categories=[], items=[])

    items_query = select(OrderItem).where(OrderItem.order_id.in_(order_ids))
    items_result = await session.execute(items_query)
    order_items = items_result.scalars().all()

    menu_item_ids = list({item.menu_item_id for item in order_items if item.item_type == "dish" and item.menu_item_id is not None})
    retail_ids = list({item.menu_item_id for item in order_items if item.item_type == "retail" and item.menu_item_id is not None})

    menu_categories = {}
    if menu_item_ids:
        cat_query = select(MenuItem.id, MenuCategory.name).join(MenuCategory, MenuItem.category_id == MenuCategory.id).where(MenuItem.id.in_(menu_item_ids))
        cat_res = await session.execute(cat_query)
        for row in cat_res.all():
            menu_categories[row[0]] = row[1]
            
    retail_categories = {}
    if retail_ids:
        ret_query = select(RetailProduct.id, MenuCategory.name).join(MenuCategory, RetailProduct.category_id == MenuCategory.id, isouter=True).where(RetailProduct.id.in_(retail_ids))
        ret_res = await session.execute(ret_query)
        for row in ret_res.all():
            retail_categories[row[0]] = row[1] or "Витрина"

    category_totals = defaultdict(float)
    total_revenue = 0.0
    item_aggregates = {}

    for item in order_items:
        cat_name = "Без категории"
        if item.item_type == "dish":
            cat_name = menu_categories.get(item.menu_item_id, "Блюда")
        elif item.item_type == "retail":
            cat_name = retail_categories.get(item.menu_item_id, "Витрина")

        category_totals[cat_name] += item.subtotal
        total_revenue += item.subtotal
        
        display_name = item.menu_item_name
        options_text = format_selected_options(item.selected_options)
                
        group_key = f"{display_name}|{options_text or ''}"
        
        if group_key not in item_aggregates:
            item_aggregates[group_key] = {
                "name": display_name,
                "options": options_text,
                "category": cat_name,
                "quantity": 0,
                "revenue": 0.0
            }
        
        item_aggregates[group_key]["quantity"] += item.quantity
        item_aggregates[group_key]["revenue"] += item.subtotal

    categories_out = []
    for cat, rev in sorted(category_totals.items(), key=lambda x: x[1], reverse=True):
        perc = (rev / total_revenue * 100) if total_revenue > 0 else 0.0
        categories_out.append(CategorySales(category_name=cat, revenue=rev, percentage=perc))
        
    items_out = []
    for agg in sorted(item_aggregates.values(), key=lambda x: x["quantity"], reverse=True):
        items_out.append(XRayItem(
            name=agg["name"],
            options=agg["options"],
            category=agg["category"],
            quantity=agg["quantity"],
            revenue=agg["revenue"]
        ))

    return AnalyticsXRay(categories=categories_out, items=items_out)
