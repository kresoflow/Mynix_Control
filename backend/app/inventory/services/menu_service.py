from sqlalchemy import case
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload
from sqlmodel import select
from fastapi import HTTPException

from app.inventory.models import (
    MenuItem, MenuItemRead, RetailProduct, RetailProductRead,
    Recipe, StockTransaction, StockTransactionType
)
from app.pos.models import OrderItem

async def _sync_child_variations(session: AsyncSession, parent_item: MenuItem, variations: list[dict]) -> list[dict]:
    """
    Syncs child MenuItem rows with the parent's variations list.
    - Creates or updates child MenuItems (parent_id = parent_item.id).
    - If a child variant is removed, checks OrderItem: if ordered -> sets is_available=False; else deletes.
    - Attaches child.id into each variation dict so the frontend receives it.
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
                await session.delete(child)
        return []

    stmt = select(MenuItem).where(MenuItem.parent_id == parent_item.id)
    res = await session.execute(stmt)
    existing_children = {c.name: c for c in res.scalars().all()}
    
    updated_variations = []
    seen_child_ids = set()

    for idx, var in enumerate(variations):
        var_name = str(var.get("name", "")).strip()
        var_price = float(var.get("price", 0.0))
        var_barcode = var.get("barcode")
        child_full_name = f"{parent_item.name} ({var_name})"

        child = existing_children.get(child_full_name) or existing_children.get(var_name)
        if child:
            child.name = child_full_name
            child.price = var_price
            child.category_id = parent_item.category_id
            child.is_available = parent_item.is_available
            child.sort_order = idx
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
                type="dish",
            )
            session.add(child)
        
        await session.flush()
        seen_child_ids.add(child.id)
        
        var_dict = dict(var)
        var_dict["id"] = child.id
        var_dict["price"] = var_price
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
                await session.delete(child)

    await session.flush()
    return updated_variations


from sqlalchemy.orm.attributes import flag_modified

async def create_menu_item(session: AsyncSession, data: dict) -> MenuItem:
    menu_item = MenuItem(
        name=data["name"],
        short_name=data.get("short_name"),
        tags=data.get("tags", []),
        category_id=data["category_id"],
        price=data["price"],
        description=data.get("description"),
        image_url=data.get("image_url"),
        is_available=data.get("is_available", True),
        attributes=data.get("attributes"),
        retail_product_id=data.get("retail_product_id"),
        sort_order=data.get("sort_order", 0),
        barcode=data.get("barcode"),
        parent_id=data.get("parent_id"),
        type=data.get("type", "dish"),
    )
    session.add(menu_item)
    await session.flush()

    attributes = data.get("attributes")
    if attributes and isinstance(attributes, dict) and "variations" in attributes and attributes["variations"]:
        updated_vars = await _sync_child_variations(session, menu_item, attributes.get("variations", []))
        new_attrs = dict(attributes)
        new_attrs["variations"] = updated_vars
        menu_item.attributes = new_attrs
        flag_modified(menu_item, "attributes")
        session.add(menu_item)
        await session.flush()

    return menu_item

async def delete_menu_item(session: AsyncSession, item_id: int, mode: str = "soft") -> dict:
    stmt = select(MenuItem).order_by(MenuItem.sort_order, MenuItem.id).where(MenuItem.id == item_id)
    result = await session.execute(stmt)
    item = result.scalars().first()
    
    if not item:
        raise HTTPException(status_code=404, detail="Menu item not found")
        
    order_stmt = select(OrderItem).where(OrderItem.menu_item_id == item_id).limit(1)
    order_res = await session.execute(order_stmt)
    has_orders = order_res.scalars().first() is not None

    if mode == "hard":
        if has_orders:
            raise HTTPException(
                status_code=400,
                detail="Невозможно удалить товар навсегда: по нему есть история продаж. Товар будет заархивирован."
            )
        recipe_stmt = select(Recipe).where(Recipe.menu_item_id == item_id)
        recipe_res = await session.execute(recipe_stmt)
        for r in recipe_res.scalars().all():
            await session.delete(r)
        
        child_stmt = select(MenuItem).where(MenuItem.parent_id == item_id)
        child_res = await session.execute(child_stmt)
        for c in child_res.scalars().all():
            c_r_stmt = select(Recipe).where(Recipe.menu_item_id == c.id)
            c_r_res = await session.execute(c_r_stmt)
            for cr in c_r_res.scalars().all():
                await session.delete(cr)
            await session.delete(c)

        await session.delete(item)
        await session.flush()
        return {"status": "deleted", "message": "Товар успешно удален."}

    # Soft delete (archive)
    item.is_available = False
    session.add(item)
    child_stmt = select(MenuItem).where(MenuItem.parent_id == item_id)
    child_res = await session.execute(child_stmt)
    for c in child_res.scalars().all():
        c.is_available = False
        session.add(c)

    await session.flush()
    return {"status": "archived", "message": "Товар заархивирован."}

async def list_menu_items(session: AsyncSession) -> list[MenuItemRead]:
    stmt = (
        select(MenuItem)
        .where(MenuItem.parent_id.is_(None))
        .options(selectinload(MenuItem.category))
        .order_by(
            case((MenuItem.sort_order == 0, 999999), else_=MenuItem.sort_order).asc(),
            MenuItem.id.asc(),
        )
    )
    result = await session.execute(stmt)
    items = result.scalars().all()

    modified = False
    for m in items:
        if m.attributes and isinstance(m.attributes, dict) and m.attributes.get("variations"):
            variations = m.attributes.get("variations")
            if any(not v.get("id") for v in variations if isinstance(v, dict)):
                updated_vars = await _sync_child_variations(session, m, variations)
                m.attributes["variations"] = updated_vars
                session.add(m)
                modified = True
    if modified:
        await session.flush()

    return [
        MenuItemRead(
            id=m.id,
            name=m.name,
            short_name=m.short_name,
            tags=m.tags,
            category_id=m.category_id,
            category_name=m.category.name if m.category else None,
            retail_product_id=m.retail_product_id,
            price=m.price,
            is_available=m.is_available,
            description=m.description,
            type=m.type,
            barcode=m.barcode,
            sort_order=m.sort_order,
            attributes=m.attributes,
            parent_id=m.parent_id,
        )
        for m in items
    ]

async def update_menu_item(session: AsyncSession, menu_item_id: int, data: dict) -> MenuItem:
    stmt = select(MenuItem).where(MenuItem.id == menu_item_id)
    result = await session.execute(stmt)
    item = result.scalar_one_or_none()
    if not item:
        raise ValueError("Menu item not found")

    for key, value in data.items():
        if hasattr(item, key) and value is not None:
            setattr(item, key, value)
    
    session.add(item)

    if item.retail_product_id:
        rp_stmt = select(RetailProduct).where(RetailProduct.id == item.retail_product_id)
        rp_res = await session.execute(rp_stmt)
        rp = rp_res.scalar_one_or_none()
        if rp:
            if "name" in data and data["name"] is not None:
                rp.name = data["name"]
            if "price" in data and data["price"] is not None:
                rp.price = data["price"]
            if "category_id" in data and data["category_id"] is not None:
                rp.category_id = data["category_id"]
            if "sort_order" in data and data["sort_order"] is not None:
                rp.sort_order = data["sort_order"]
            if "barcode" in data:
                rp.barcode = data["barcode"]
            session.add(rp)

    await session.flush()

    attributes = item.attributes
    if attributes and isinstance(attributes, dict) and "variations" in attributes:
        updated_vars = await _sync_child_variations(session, item, attributes.get("variations", []))
        new_attrs = dict(attributes)
        new_attrs["variations"] = updated_vars
        item.attributes = new_attrs
        flag_modified(item, "attributes")
        session.add(item)
        await session.flush()

    return item
