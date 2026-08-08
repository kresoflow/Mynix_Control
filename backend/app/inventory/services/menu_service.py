from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload
from sqlmodel import select
from fastapi import HTTPException

from app.inventory.models import (
    MenuItem, MenuItemRead, RetailProduct, RetailProductRead,
    Recipe, StockTransaction, StockTransactionType
)
from app.pos.models import OrderItem

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
    # Variations are now exclusively read from the JSON attributes by the frontend,
    # so we no longer generate child MenuItem rows in the database.

    return menu_item

async def delete_menu_item(session: AsyncSession, item_id: int) -> dict:
    stmt = select(MenuItem).order_by(MenuItem.sort_order, MenuItem.id).where(MenuItem.id == item_id)
    result = await session.execute(stmt)
    item = result.scalars().first()
    
    if not item:
        raise HTTPException(status_code=404, detail="Menu item not found")
        
    order_stmt = select(OrderItem).where(OrderItem.menu_item_id == item_id).limit(1)
    order_res = await session.execute(order_stmt)
    if order_res.scalars().first() is not None:
        item.is_available = False
        session.add(item)
        await session.flush()
        return {"status": "archived", "message": "Товар участвовал в заказах и был скрыт (отправлен в архив)."}
        
    recipe_stmt = select(Recipe).where(Recipe.menu_item_id == item_id)
    recipe_res = await session.execute(recipe_stmt)
    for r in recipe_res.scalars().all():
        await session.delete(r)
        
    await session.delete(item)
    await session.flush()
    return {"status": "deleted", "message": "Товар успешно удален."}

async def create_retail_product(session: AsyncSession, data: dict, user_id: int = 1) -> MenuItem:
    initial_stock = data.get("initial_stock", 0.0)

    retail_product = RetailProduct(
        name=data["name"],
        category_id=data["category_id"],
        price=data["selling_price"],
        cost=data["purchase_price"],
        unit=data["unit"],
        min_stock_alert=data.get("min_stock_alert", 0.0),
        barcode=data.get("barcode"),
        current_stock=initial_stock,
        is_available=True,
        attributes=data.get("attributes"),
        sort_order=data.get("sort_order", 0),
    )
    session.add(retail_product)
    await session.flush()

    if initial_stock > 0:
        txn = StockTransaction(
            retail_product_id=retail_product.id,
            type=StockTransactionType.RECEIPT,
            quantity=initial_stock,
            reason="Начальный остаток при создании",
            created_by=user_id,
        )
        session.add(txn)
        await session.flush()

    menu_item = MenuItem(
        name=data["name"],
        short_name=data.get("short_name"),
        tags=data.get("tags", []),
        category_id=data["category_id"],
        retail_product_id=retail_product.id,
        price=data["selling_price"],
        type="retail",
        barcode=data.get("barcode"),
        sort_order=data.get("sort_order", 0),
        is_available=True,
        attributes=data.get("attributes"),
        parent_id=data.get("parent_id"),
    )
    session.add(menu_item)
    await session.flush()

    attributes = data.get("attributes")
    # Variations are now exclusively read from the JSON attributes by the frontend,
    # so we no longer generate child MenuItem rows in the database.

    return menu_item

async def list_retail_products(session: AsyncSession) -> list[RetailProductRead]:
    stmt = select(RetailProduct).options(selectinload(RetailProduct.category)).order_by(RetailProduct.sort_order, RetailProduct.id)
    result = await session.execute(stmt)
    products = result.scalars().all()
    return [
        RetailProductRead(
            id=p.id,
            name=p.name,
            category_id=p.category_id,
            category_name=p.category.name if p.category else None,
            price=p.price,
            cost=p.cost,
            unit=p.unit,
            current_stock=p.current_stock,
            min_stock_alert=p.min_stock_alert,
            is_available=p.is_available,
            barcode=p.barcode,
            attributes=p.attributes,
            is_low_stock=p.current_stock <= p.min_stock_alert,
        )
        for p in products
    ]

async def list_menu_items(session: AsyncSession) -> list[MenuItemRead]:
    stmt = select(MenuItem).options(selectinload(MenuItem.category)).order_by(MenuItem.sort_order, MenuItem.id)
    result = await session.execute(stmt)
    items = result.scalars().all()
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
    await session.flush()
    return item

async def update_retail_product(session: AsyncSession, product_id: int, data: dict) -> RetailProduct:
    stmt = select(RetailProduct).where(RetailProduct.id == product_id)
    result = await session.execute(stmt)
    product = result.scalar_one_or_none()
    if not product:
        raise ValueError("Retail product not found")

    for key, value in data.items():
        if hasattr(product, key) and value is not None:
            setattr(product, key, value)
    
    session.add(product)
    
    stmt_menu = select(MenuItem).where(MenuItem.retail_product_id == product_id)
    res_menu = await session.execute(stmt_menu)
    menu_item = res_menu.scalar_one_or_none()
    if menu_item:
        if "name" in data and data["name"] is not None:
            menu_item.name = data["name"]
        if "price" in data and data["price"] is not None:
            menu_item.price = data["price"]
        if "category_id" in data and data["category_id"] is not None:
            menu_item.category_id = data["category_id"]
        session.add(menu_item)

    await session.flush()
    return product
