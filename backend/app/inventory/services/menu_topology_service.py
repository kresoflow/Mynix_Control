# ==============================================================================
# МОДУЛЬ: Inventory — Сервис динамической топологии каталога (Merge / Split)
# ДОМЕН: backend/app/inventory/services/menu_topology_service.py
# ==============================================================================

from typing import Optional, List
from fastapi import HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select

from app.inventory.models import MenuItem, RetailProduct
from app.inventory.services.menu_variation_helper import (
    cascade_menu_item_availability,
    get_next_menu_sort_order,
)


# ─── 1. Объединение товаров в одну карточку (Merge) ───────────────────────────

async def merge_menu_items(
    session: AsyncSession,
    target_item_id: int,
    source_item_ids: List[int],
    target_name: Optional[str] = None,
) -> MenuItem:
    """
    [ТРАНЗАКЦИЯ] Объединяет независимые карточки в одну карточку с вариациями.
    """
    target = await session.get(MenuItem, target_item_id)
    if not target or not target.is_available:
        raise HTTPException(status_code=404, detail="Целевой товар не найден или заархивирован")
    if target.parent_id is not None:
        raise HTTPException(status_code=400, detail="Нельзя объединять в дочернюю вариацию.")

    if target_name and target_name.strip():
        target.name = target_name.strip()

    target_attrs = dict(target.attributes or {})
    target_vars: list[dict] = list(target_attrs.get("variations") or [])

    # Если целевой товар был одиночным, формируем его собственную вариацию
    if not target_vars and target.retail_product_id:
        target_vol = str(target_attrs.get("volume") or "Базовый")
        target_child = MenuItem(
            name=f"{target.clean_name} ({target_vol})",
            category_id=target.category_id,
            price=target.price,
            parent_id=target.id,
            is_available=True,
            barcode=target.barcode,
            type=target.type,
            retail_product_id=target.retail_product_id,
        )
        session.add(target_child)
        await session.flush()
        target_vars.append({
            "id": target_child.id,
            "name": f"{target.clean_name} {target_vol}",
            "price": target.price,
            "unit": target_attrs.get("unit") or "pcs",
            "barcode": target.barcode,
            "retail_product_id": target.retail_product_id,
        })
        target.retail_product_id = None

    for s_id in source_item_ids:
        if s_id == target_item_id:
            continue
        source = await session.get(MenuItem, s_id)
        if not source or not source.is_available:
            continue

        c_res = await session.execute(select(MenuItem).where(MenuItem.parent_id == source.id))
        source_children = c_res.scalars().all()

        if source_children:
            for sc in source_children:
                sc.parent_id, sc.category_id = target.id, target.category_id
                session.add(sc)
                target_vars.append({
                    "id": sc.id,
                    "name": sc.name,
                    "price": sc.price,
                    "unit": "pcs",
                    "barcode": sc.barcode,
                    "retail_product_id": sc.retail_product_id,
                })
            source.is_available = False
            session.add(source)
        else:
            source.parent_id, source.category_id = target.id, target.category_id
            session.add(source)
            src_attrs = dict(source.attributes or {})
            src_vol = str(src_attrs.get("volume") or "").strip()
            target_vars.append({
                "id": source.id,
                "name": f"{target.clean_name} {src_vol}" if src_vol else source.clean_name,
                "price": source.price,
                "unit": src_attrs.get("unit") or "pcs",
                "barcode": source.barcode,
                "retail_product_id": source.retail_product_id,
            })

    target_attrs["variations"] = target_vars
    target.attributes = target_attrs
    if target_vars:
        prices = [float(v.get("price", 0.0)) for v in target_vars if "price" in v]
        if prices:
            target.price = min(prices)

    session.add(target)
    await session.flush()
    return target


# ─── 2. Вынесение вариации в отдельный товар (Split / Extract) ────────────────

async def extract_variation_to_standalone(
    session: AsyncSession,
    child_id: int,
) -> MenuItem:
    """
    [ТРАНЗАКЦИЯ] Превращает дочернюю вариацию в самостоятельную карточку каталога.
    """
    child = await session.get(MenuItem, child_id)
    if not child or child.parent_id is None:
        raise HTTPException(status_code=400, detail="Товар не является вариацией родительской карточки.")

    parent = await session.get(MenuItem, child.parent_id)
    child.parent_id = None
    cat_id = parent.category_id if parent else child.category_id
    child.sort_order = await get_next_menu_sort_order(session, cat_id)
    child.is_available = True
    session.add(child)

    if parent:
        p_attrs = dict(parent.attributes or {})
        p_vars = list(p_attrs.get("variations") or [])
        remaining_vars = [v for v in p_vars if v.get("id") != child.id and v.get("name") != child.name]
        if not remaining_vars:
            p_attrs.pop("variations", None)
        else:
            p_attrs["variations"] = remaining_vars
            prices = [float(v.get("price", 0.0)) for v in remaining_vars if "price" in v]
            if prices:
                parent.price = min(prices)
        parent.attributes = p_attrs
        session.add(parent)

    await session.flush()
    return child


# ─── 3. Распаковка всех вариаций карточки (Unbundle) ───────────────────────────

async def unbundle_menu_item(
    session: AsyncSession,
    parent_id: int,
) -> List[MenuItem]:
    """
    [ТРАНЗАКЦИЯ] Распаковывает все вариации карточки в независимые товары каталога.
    """
    parent = await session.get(MenuItem, parent_id)
    if not parent:
        raise HTTPException(status_code=404, detail="Родительский товар не найден")

    c_res = await session.execute(select(MenuItem).where(MenuItem.parent_id == parent.id))
    children = c_res.scalars().all()

    detached: list[MenuItem] = []
    for c in children:
        c.parent_id = None
        c.sort_order = await get_next_menu_sort_order(session, parent.category_id)
        c.is_available = True
        session.add(c)
        detached.append(c)

    p_attrs = dict(parent.attributes or {})
    p_attrs.pop("variations", None)
    parent.attributes = p_attrs
    if not parent.retail_product_id:
        parent.is_available = False
    session.add(parent)

    await session.flush()
    return detached


# ─── 4. Безопасное удаление по политике (Poka-Yoke Deletion) ───────────────────

async def delete_menu_item_with_policy(
    session: AsyncSession,
    item_id: int,
    policy: str = "archive_all",
) -> dict:
    """
    [ИНВАРИАНТ] Политики удаления карточки с вариациями ('unbundle', 'archive_menu_only', 'archive_all').
    """
    item = await session.get(MenuItem, item_id)
    if not item:
        raise HTTPException(status_code=404, detail="Товар не найден")

    if policy == "unbundle":
        detached = await unbundle_menu_item(session, item_id)
        return {"status": "unbundled", "message": f"Распаковано вариаций: {len(detached)} шт."}

    if policy == "archive_menu_only":
        item.is_available = False
        session.add(item)
        c_res = await session.execute(select(MenuItem).where(MenuItem.parent_id == item.id))
        for c in c_res.scalars().all():
            c.is_available = False
            session.add(c)
        await session.flush()
        return {"status": "archived_menu_only", "message": "Карточка скрыта из меню и кассы. Товары на складе активны."}

    await cascade_menu_item_availability(session, item, False)
    await session.flush()
    return {"status": "archived_all", "message": "Карточка и все связанные товары на складе заархивированы."}
