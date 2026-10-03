# ==============================================================================
# МОДУЛЬ: Инвентарь / Сервис товаров витрины (Retail)
# ДОМЕН: backend/app/inventory/services/retail_service.py
# ==============================================================================

from sqlalchemy import case
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload
from sqlmodel import select

from app.inventory.models import MenuItem, RetailProduct, RetailProductRead
from app.inventory.services.menu_variation_helper import (
    _sync_child_variations,
    get_next_menu_sort_order,
)
from app.inventory.services.retail_consolidation_helper import (
    consolidate_into_retail_parent,
    find_matching_retail_parent,
)


# ─── 1. Обработка и создание товаров витрины ──────────────────────────────────

async def _process_retail_item(
    session: AsyncSession, data: dict, user_id: int = 1
) -> tuple[MenuItem, list[RetailProduct]]:
    raw_cat_id = data.get("category_id")
    category_id = None if (raw_cat_id in (0, "0", "null", None)) else int(raw_cat_id)

    attributes = dict(data.get("attributes")) if isinstance(data.get("attributes"), dict) else None
    raw_vars = attributes.get("variations", []) if attributes else []
    valid_vars = [v for v in raw_vars if isinstance(v, dict) and str(v.get("name", "")).strip()]
    has_variations = len(valid_vars) >= 2

    clean_attrs = dict(attributes) if attributes else None
    effective_price = float(data.get("selling_price") or 0.0)
    effective_cost = float(data.get("purchase_price") or 0.0)
    effective_unit = str(data.get("unit") or "pcs")
    effective_barcode = data.get("barcode")

    if valid_vars and not has_variations:
        single_var = valid_vars[0]
        effective_price = float(single_var.get("price") or single_var.get("selling_price") or effective_price)
        effective_cost = float(single_var.get("purchase_price") or single_var.get("purchasePrice") or effective_cost)
        effective_unit = str(single_var.get("unit") or effective_unit)
        if single_var.get("barcode"):
            effective_barcode = single_var.get("barcode")
        if clean_attrs:
            clean_attrs.pop("variations", None)

    # [ИНВАРИАНТ] Проверка на наличие существующего родителя для склейки (Smart Merge)
    flavor = (attributes or {}).get("flavor") if attributes else None
    existing_parent = await find_matching_retail_parent(session, data["name"], flavor)
    if existing_parent is not None:
        return await consolidate_into_retail_parent(
            session=session,
            parent=existing_parent,
            data=data,
            valid_vars=valid_vars,
            clean_attrs=clean_attrs,
            effective_price=effective_price,
            effective_cost=effective_cost,
            effective_unit=effective_unit,
            effective_barcode=effective_barcode,
        )

    # Создание нового товара витрины
    effective_sort = int(data.get("sort_order") or 0)
    if effective_sort <= 0:
        effective_sort = await get_next_menu_sort_order(session, category_id)

    if has_variations:
        menu_item = MenuItem(
            name=data["name"],
            short_name=data.get("short_name"),
            tags=data.get("tags", []),
            category_id=category_id,
            retail_product_id=None,
            price=data["selling_price"],
            type="retail",
            barcode=data.get("barcode"),
            sort_order=effective_sort,
            is_available=True,
            attributes=attributes,
            parent_id=data.get("parent_id"),
        )
        session.add(menu_item)
        await session.flush()

        updated_vars = await _sync_child_variations(session, menu_item, valid_vars)
        attributes["variations"] = updated_vars
        menu_item.attributes = attributes
        session.add(menu_item)
        await session.flush()

        child_rps = []
        for uv in updated_vars:
            rp_id = uv.get("retail_product_id")
            if rp_id:
                rp = await session.get(RetailProduct, rp_id)
                if rp:
                    child_rps.append(rp)
        return menu_item, child_rps
    else:
        rp_name_parts = [data["name"]]
        if clean_attrs:
            f_val = clean_attrs.get("flavor")
            if f_val and f_val not in data["name"]:
                rp_name_parts.append(str(f_val))
            v_val = clean_attrs.get("volume")
            if v_val and v_val not in data["name"]:
                rp_name_parts.append(str(v_val))
        rp_name = " ".join(rp_name_parts).strip()

        retail_product = RetailProduct(
            name=rp_name,
            category_id=category_id,
            price=effective_price,
            cost=effective_cost,
            unit=effective_unit,
            min_stock_alert=data.get("min_stock_alert", 0.0),
            barcode=effective_barcode,
            current_stock=0.0,
            is_available=True,
            attributes=clean_attrs,
            sort_order=effective_sort,
        )
        session.add(retail_product)
        await session.flush()

        menu_item = MenuItem(
            name=data["name"],
            short_name=data.get("short_name"),
            tags=data.get("tags", []),
            category_id=category_id,
            retail_product_id=retail_product.id,
            price=effective_price,
            type="retail",
            barcode=effective_barcode,
            sort_order=effective_sort,
            is_available=True,
            attributes=clean_attrs,
            parent_id=data.get("parent_id"),
        )
        session.add(menu_item)
        await session.flush()
        return menu_item, [retail_product]


# ─── 2. Точки входа API (Bulk & Single) ───────────────────────────────────────

async def bulk_create_retail_products(
    session: AsyncSession, items_data: list[dict], user_id: int = 1
) -> list[RetailProduct]:
    created_products: list[RetailProduct] = []
    for data in items_data:
        _, products = await _process_retail_item(session, data, user_id=user_id)
        created_products.extend(products)
    return created_products


async def create_retail_product(
    session: AsyncSession, data: dict, user_id: int = 1
) -> MenuItem:
    menu_item, _ = await _process_retail_item(session, data, user_id=user_id)
    return menu_item


# ─── 3. Чтение и обновление данных ───────────────────────────────────────────

async def list_retail_products(
    session: AsyncSession, include_archived: bool = False
) -> list[RetailProductRead]:
    stmt = (
        select(RetailProduct)
        .options(selectinload(RetailProduct.category))
    )
    if not include_archived:
        stmt = stmt.where(RetailProduct.is_available == True)
    stmt = stmt.order_by(
        case((RetailProduct.sort_order == 0, 999999), else_=RetailProduct.sort_order).asc(),
        RetailProduct.id.asc(),
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
            is_archived=not p.is_available,
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
