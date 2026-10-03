from sqlalchemy import func
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select

from app.inventory.models import MenuItem, Recipe, RetailProduct
from app.pos.models import OrderItem

async def sync_child_variations(session: AsyncSession, parent_item: MenuItem, variations: list[dict]) -> list[dict]:
    """
    Syncs child MenuItem rows with the parent's variations list.
    - Creates or updates child MenuItems (parent_id = parent_item.id).
    - If parent is 'retail', creates/syncs corresponding RetailProduct for each child variation.
    - If a child variant is removed, checks OrderItem: if ordered -> sets is_available=False; else deletes.
    - Attaches child.id and retail_product_id into each variation dict so the frontend receives it.
    """
    if not variations:
        stmt = select(MenuItem).where(MenuItem.parent_id == parent_item.id)
        res = await session.execute(stmt)
        for child in res.scalars().all():
            order_res = await session.execute(select(OrderItem).where(OrderItem.menu_item_id == child.id).limit(1))
            if order_res.scalars().first() is not None:
                child.is_available = False
                session.add(child)
            else:
                recipe_stmt = select(Recipe).where(Recipe.menu_item_id == child.id)
                r_res = await session.execute(recipe_stmt)
                for r in r_res.scalars().all():
                    await session.delete(r)
                if child.retail_product_id:
                    child_ret = await session.get(RetailProduct, child.retail_product_id)
                    if child_ret:
                        await session.delete(child_ret)
                await session.delete(child)
        return []

    stmt = select(MenuItem).where(MenuItem.parent_id == parent_item.id)
    res = await session.execute(stmt)
    children_list = res.scalars().all()
    existing_children_by_id = {c.id: c for c in children_list}
    existing_children_by_name = {c.name: c for c in children_list}
    existing_children = existing_children_by_name
    
    updated_variations = []
    seen_child_ids = set()

    for idx, var in enumerate(variations):
        var_name = str(var.get("name", "")).strip()
        var_price = float(var.get("price", var.get("selling_price", 0.0)))
        var_barcode = var.get("barcode")
        child_full_name = f"{parent_item.name} ({var_name})" if not var_name.startswith(parent_item.name) else var_name

        child_id = var.get("id")
        child = None
        if child_id and child_id in existing_children_by_id:
            child = existing_children_by_id[child_id]
        else:
            child = existing_children_by_name.get(child_full_name) or existing_children_by_name.get(var_name)
        item_type = parent_item.type or "dish"

        child_retail_id = None
        if item_type == "retail":
            unit_val = str(var.get("unit") or "pcs")
            cost_val = float(var.get("purchase_price") or var.get("purchasePrice") or var.get("cost") or 0.0)
            
            if child and child.retail_product_id:
                child_retail = await session.get(RetailProduct, child.retail_product_id)
                if child_retail:
                    child_retail.name = child_full_name
                    child_retail.price = var_price
                    child_retail.cost = cost_val
                    child_retail.barcode = var_barcode
                    child_retail.category_id = parent_item.category_id
                    child_retail.is_available = parent_item.is_available
                    session.add(child_retail)
                    child_retail_id = child_retail.id
            elif var.get("retail_product_id"):
                child_retail = await session.get(RetailProduct, var.get("retail_product_id"))
                if child_retail:
                    child_retail.name = child_full_name
                    child_retail.price = var_price
                    child_retail.cost = cost_val
                    child_retail.barcode = var_barcode
                    child_retail.category_id = parent_item.category_id
                    child_retail.is_available = parent_item.is_available
                    session.add(child_retail)
                    child_retail_id = child_retail.id
            
            if not child_retail_id:
                new_retail = RetailProduct(
                    name=child_full_name,
                    category_id=parent_item.category_id,
                    price=var_price,
                    cost=cost_val,
                    unit=unit_val,
                    barcode=var_barcode,
                    current_stock=float(var.get("initial_stock", 0.0)),
                    min_stock_alert=float(var.get("min_stock_alert", 0.0)),
                    is_available=parent_item.is_available,
                    sort_order=idx,
                )
                session.add(new_retail)
                await session.flush()
                child_retail_id = new_retail.id

        if child:
            child.name = child_full_name
            child.price = var_price
            child.category_id = parent_item.category_id
            child.is_available = parent_item.is_available
            child.sort_order = idx
            child.type = item_type
            if child_retail_id:
                child.retail_product_id = child_retail_id
            if var_barcode:
                child.barcode = var_barcode
            session.add(child)
        else:
            child = MenuItem(
                name=child_full_name,
                category_id=parent_item.category_id,
                price=var_price,
                parent_id=parent_item.id,
                is_available=parent_item.is_available,
                sort_order=idx,
                barcode=var_barcode,
                type=item_type,
                retail_product_id=child_retail_id,
            )
            session.add(child)
        
        await session.flush()
        seen_child_ids.add(child.id)
        
        var_dict = dict(var)
        var_dict["id"] = child.id
        var_dict["name"] = child_full_name
        var_dict["price"] = var_price
        if child_retail_id:
            var_dict["retail_product_id"] = child_retail_id
        updated_variations.append(var_dict)

    for child in list(existing_children.values()):
        if child.id not in seen_child_ids:
            order_res = await session.execute(select(OrderItem).where(OrderItem.menu_item_id == child.id).limit(1))
            if order_res.scalars().first() is not None:
                child.is_available = False
                session.add(child)
            else:
                recipe_stmt = select(Recipe).where(Recipe.menu_item_id == child.id)
                r_res = await session.execute(recipe_stmt)
                for r in r_res.scalars().all():
                    await session.delete(r)
                if child.retail_product_id:
                    child_ret = await session.get(RetailProduct, child.retail_product_id)
                    if child_ret:
                        await session.delete(child_ret)
                await session.delete(child)

    await session.flush()
    return updated_variations

_sync_child_variations = sync_child_variations


async def cascade_menu_item_availability(
    session: AsyncSession, item: MenuItem, is_available: bool
) -> None:
    """
    [ИНВАРИАНТ] Каскадная синхронизация статуса доступности (архивации)
    между MenuItem (родитель + дети) и RetailProduct.
    """
    item.is_available = is_available
    session.add(item)
    if item.retail_product_id:
        rp = await session.get(RetailProduct, item.retail_product_id)
        if rp:
            rp.is_available = is_available
            session.add(rp)

    child_stmt = select(MenuItem).where(MenuItem.parent_id == item.id)
    child_res = await session.execute(child_stmt)
    for c in child_res.scalars().all():
        c.is_available = is_available
        session.add(c)
        if c.retail_product_id:
            crp = await session.get(RetailProduct, c.retail_product_id)
            if crp:
                crp.is_available = is_available
                session.add(crp)


async def get_next_menu_sort_order(session: AsyncSession, category_id: int | None) -> int:
    """
    [ИНВАРИАНТ] Вычисляет следующий порядковый номер для нового товара в категории,
    гарантируя монотонное добавление в конец списка (FIFO).
    """
    stmt = select(func.coalesce(func.max(MenuItem.sort_order), 0)).where(
        MenuItem.parent_id.is_(None)
    )
    if category_id is not None:
        stmt = stmt.where(MenuItem.category_id == category_id)
    else:
        stmt = stmt.where(MenuItem.category_id.is_(None))
    result = await session.execute(stmt)
    max_val = result.scalar() or 0
    return max_val + 1

