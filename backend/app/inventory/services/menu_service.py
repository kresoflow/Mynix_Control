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

from sqlalchemy.orm.attributes import flag_modified
from app.inventory.services.menu_variation_helper import (
    _sync_child_variations, sync_child_variations,
    cascade_menu_item_availability, get_next_menu_sort_order
)

async def bulk_create_menu_items(session: AsyncSession, items_data: list[dict]) -> list[MenuItem]:
    created_items: list[MenuItem] = []
    for data in items_data:
        raw_cat_id = data.get("category_id")
        category_id = None if (raw_cat_id == 0 or raw_cat_id == "0" or raw_cat_id == "null" or not raw_cat_id) else int(raw_cat_id)

        sort_order = data.get("sort_order", 0)
        if not sort_order:
            sort_order = await get_next_menu_sort_order(session, category_id)

        menu_item = MenuItem(
            name=data["name"],
            short_name=data.get("short_name"),
            tags=data.get("tags", []),
            category_id=category_id,
            price=data["price"],
            description=data.get("description"),
            image_url=data.get("image_url"),
            is_available=data.get("is_available", True),
            attributes=data.get("attributes"),
            retail_product_id=data.get("retail_product_id"),
            sort_order=sort_order,
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

        created_items.append(menu_item)

    return created_items

async def create_menu_item(session: AsyncSession, data: dict) -> MenuItem:
    items = await bulk_create_menu_items(session, [data])
    return items[0]

async def delete_menu_item(session: AsyncSession, item_id: int, mode: str = "soft") -> dict:
    stmt = select(MenuItem).order_by(MenuItem.sort_order, MenuItem.id).where(MenuItem.id == item_id)
    result = await session.execute(stmt)
    item = result.scalars().first()
    
    if not item:
        raise HTTPException(status_code=404, detail="Menu item not found")

    if mode == "hard":
        # Проверка истории заказов для товара и всех дочерних вариаций
        all_item_ids = [item_id]
        child_stmt = select(MenuItem).where(MenuItem.parent_id == item_id)
        child_res = await session.execute(child_stmt)
        children = child_res.scalars().all()
        for c in children:
            all_item_ids.append(c.id)

        order_stmt = select(OrderItem).where(OrderItem.menu_item_id.in_(all_item_ids)).limit(1)
        order_res = await session.execute(order_stmt)
        if order_res.scalars().first() is not None:
            raise HTTPException(
                status_code=400,
                detail="Невозможно удалить товар навсегда: по нему есть история продаж. Товар останется в архиве."
            )

        # Проверка складских проводок для штучных товаров витрины
        all_rp_ids = []
        if item.retail_product_id:
            all_rp_ids.append(item.retail_product_id)
        for c in children:
            if c.retail_product_id:
                all_rp_ids.append(c.retail_product_id)

        if all_rp_ids:
            txn_stmt = select(StockTransaction).where(StockTransaction.retail_product_id.in_(all_rp_ids)).limit(1)
            txn_res = await session.execute(txn_stmt)
            if txn_res.scalars().first() is not None:
                raise HTTPException(
                    status_code=400,
                    detail="Невозможно удалить товар навсегда: по нему есть складские проводки. Товар останется в архиве."
                )

        # Удаление техкарт и связанных сущностей без истории
        for c_id in all_item_ids:
            recipe_stmt = select(Recipe).where(Recipe.menu_item_id == c_id)
            recipe_res = await session.execute(recipe_stmt)
            for r in recipe_res.scalars().all():
                await session.delete(r)

        for c in children:
            if c.retail_product_id:
                rp_res = await session.execute(select(RetailProduct).where(RetailProduct.id == c.retail_product_id))
                rp = rp_res.scalar_one_or_none()
                if rp:
                    await session.delete(rp)
            await session.delete(c)

        if item.retail_product_id:
            rp_res = await session.execute(select(RetailProduct).where(RetailProduct.id == item.retail_product_id))
            rp = rp_res.scalar_one_or_none()
            if rp:
                await session.delete(rp)

        await session.delete(item)
        await session.flush()
        return {"status": "deleted", "message": "Товар успешно удален навсегда."}

    # Soft delete (Архивация - режим по умолчанию с любого рабочего экрана)
    await cascade_menu_item_availability(session, item, False)
    await session.flush()
    return {"status": "archived", "message": "Товар заархивирован."}

async def restore_menu_item(session: AsyncSession, item_id: int) -> MenuItem:
    """
    Восстанавливает позицию меню из архива с защитой от коллизий дубликатов (Poka-Yoke).
    
    [ИНВАРИАНТ]  Запрещено восстанавливать позицию, если в той же категории уже есть активная позиция с таким же именем.
    """
    stmt = select(MenuItem).where(MenuItem.id == item_id)
    result = await session.execute(stmt)
    item = result.scalar_one_or_none()
    if not item:
        raise HTTPException(status_code=404, detail="Товар не найден")

    # Извлекаем чистое имя позиции
    clean_name = item.name.split('|TYPE|')[0].split('|ATTR|')[0].split('|ICON|')[0].strip()

    # Проверяем наличие активного тезки в целевой категории
    dup_stmt = select(MenuItem).where(
        MenuItem.category_id == item.category_id,
        MenuItem.is_available == True,
        MenuItem.id != item.id
    )
    dup_res = await session.execute(dup_stmt)
    for existing in dup_res.scalars().all():
        existing_clean = existing.name.split('|TYPE|')[0].split('|ATTR|')[0].split('|ICON|')[0].strip()
        if existing_clean.lower() == clean_name.lower():
            existing_is_retail = '|TYPE|retail' in existing.name
            item_is_retail = '|TYPE|retail' in item.name
            if existing_is_retail == item_is_retail:
                raise HTTPException(
                    status_code=400,
                    detail=f"В этой категории уже есть активная позиция «{existing_clean}». Переименуйте или удалите активный дубликат перед восстановлением из архива."
                )

    await cascade_menu_item_availability(session, item, True)
    await session.flush()
    return item

async def bulk_delete_menu_items(session: AsyncSession, item_ids: list[int], mode: str = "soft") -> dict:
    results = []
    for item_id in item_ids:
        try:
            res = await delete_menu_item(session, item_id, mode=mode)
            results.append(res)
        except Exception:
            pass
    return {"status": "ok", "deleted_count": len(results)}

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
    
    if "attributes" in data and data["attributes"] is not None:
        item.attributes = data["attributes"]
        flag_modified(item, "attributes")

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
            if "attributes" in data and data["attributes"] is not None:
                rp.attributes = data["attributes"]
                flag_modified(rp, "attributes")
                stock_u = data["attributes"].get("stock_unit") or data["attributes"].get("unit")
                if stock_u:
                    try:
                        from app.inventory.models.enums import UnitType
                        rp.unit = UnitType(str(stock_u).lower())
                    except ValueError:
                        pass
            session.add(rp)

    await session.flush()

    attributes = item.attributes
    variations_list = attributes.get("variations", []) if (attributes and isinstance(attributes, dict)) else []
    child_exists = (await session.execute(select(MenuItem.id).where(MenuItem.parent_id == item.id).limit(1))).first() is not None
    if variations_list or child_exists:
        updated_vars = await _sync_child_variations(session, item, variations_list)
        new_attrs = dict(attributes) if attributes else {}
        if updated_vars:
            new_attrs["variations"] = updated_vars
            item.retail_product_id = None
        else:
            new_attrs.pop("variations", None)
            if item.type == "retail" and not item.retail_product_id:
                rp = RetailProduct(name=item.name, category_id=item.category_id, price=item.price, cost=0.0, unit=new_attrs.get("unit", "pcs"), current_stock=0.0, is_available=item.is_available, attributes=new_attrs)
                session.add(rp)
                await session.flush()
                item.retail_product_id = rp.id
        item.attributes = new_attrs
        flag_modified(item, "attributes")
        session.add(item)
        await session.flush()

    return item
