from sqlalchemy import case
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload
from sqlmodel import select

from app.inventory.models import (
    MenuItem, RetailProduct, RetailProductRead
)
from app.inventory.services.menu_variation_helper import _sync_child_variations

async def bulk_create_retail_products(session: AsyncSession, items_data: list[dict], user_id: int = 1) -> list[RetailProduct]:
    created_products: list[RetailProduct] = []
    for data in items_data:
        raw_cat_id = data.get("category_id")
        category_id = None if (raw_cat_id == 0 or raw_cat_id == "0" or raw_cat_id == "null" or not raw_cat_id) else int(raw_cat_id)

        retail_product = RetailProduct(
            name=data["name"],
            category_id=category_id,
            price=data["selling_price"],
            cost=data["purchase_price"],
            unit=data["unit"],
            min_stock_alert=data.get("min_stock_alert", 0.0),
            barcode=data.get("barcode"),
            current_stock=0.0,
            is_available=True,
            attributes=data.get("attributes"),
            sort_order=data.get("sort_order", 0),
        )
        session.add(retail_product)
        await session.flush()

        menu_item = MenuItem(
            name=data["name"],
            short_name=data.get("short_name"),
            tags=data.get("tags", []),
            category_id=category_id,
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
        if attributes and isinstance(attributes, dict) and "variations" in attributes and attributes["variations"]:
            updated_vars = await _sync_child_variations(session, menu_item, attributes.get("variations", []))
            attributes["variations"] = updated_vars
            menu_item.attributes = attributes
            session.add(menu_item)
            await session.flush()

        created_products.append(retail_product)

    return created_products

async def create_retail_product(session: AsyncSession, data: dict, user_id: int = 1) -> MenuItem:
    raw_cat_id = data.get("category_id")
    category_id = None if (raw_cat_id == 0 or raw_cat_id == "0" or raw_cat_id == "null" or not raw_cat_id) else int(raw_cat_id)

    retail_product = RetailProduct(
        name=data["name"],
        category_id=category_id,
        price=data["selling_price"],
        cost=data["purchase_price"],
        unit=data["unit"],
        min_stock_alert=data.get("min_stock_alert", 0.0),
        barcode=data.get("barcode"),
        current_stock=0.0,
        is_available=True,
        attributes=data.get("attributes"),
        sort_order=data.get("sort_order", 0),
    )
    session.add(retail_product)
    await session.flush()

    menu_item = MenuItem(
        name=data["name"],
        short_name=data.get("short_name"),
        tags=data.get("tags", []),
        category_id=category_id,
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
    if attributes and isinstance(attributes, dict) and "variations" in attributes and attributes["variations"]:
        updated_vars = await _sync_child_variations(session, menu_item, attributes.get("variations", []))
        attributes["variations"] = updated_vars
        menu_item.attributes = attributes
        session.add(menu_item)
        await session.flush()

    return menu_item

async def list_retail_products(session: AsyncSession) -> list[RetailProductRead]:
    stmt = (
        select(RetailProduct)
        .options(selectinload(RetailProduct.category))
        .order_by(
            case((RetailProduct.sort_order == 0, 999999), else_=RetailProduct.sort_order).asc(),
            RetailProduct.id.asc(),
        )
    )
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
            sort_order=p.sort_order,
            attributes=p.attributes,
            is_low_stock=p.current_stock <= p.min_stock_alert,
        )
        for p in products
    ]

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
        if "sort_order" in data and data["sort_order"] is not None:
            menu_item.sort_order = data["sort_order"]
        session.add(menu_item)

    await session.flush()
    return product
