# ==============================================================================
# МОДУЛЬ: Инвентарь / Помощник консолидации серийных товаров (Retail)
# ДОМЕН: backend/app/inventory/services/retail_consolidation_helper.py
# ==============================================================================

from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select

from app.inventory.models import MenuItem, RetailProduct
from app.inventory.services.menu_variation_helper import _sync_child_variations


# ─── 1. Поиск существующего родителя ──────────────────────────────────────────

async def find_matching_retail_parent(
    session: AsyncSession, name: str, flavor: str | None
) -> MenuItem | None:
    """
    [ИНВАРИАНТ] Поиск существующей активной карточки витрины по чистому имени и вкусу.
    """
    clean_name = name.strip()
    stmt = (
        select(MenuItem)
        .where(
            MenuItem.parent_id.is_(None),
            MenuItem.type == "retail",
            MenuItem.is_available == True,
            MenuItem.name == clean_name,
        )
    )
    result = await session.execute(stmt)
    candidates = result.scalars().all()
    target_flavor = (flavor or "").strip().lower()

    for c in candidates:
        c_attrs = c.attributes if isinstance(c.attributes, dict) else {}
        c_flavor = str(c_attrs.get("flavor") or "").strip().lower()
        if c_flavor == target_flavor:
            return c
    return None


# ─── 2. Слияние вариаций в родительскую карточку ──────────────────────────────

async def consolidate_into_retail_parent(
    session: AsyncSession,
    parent: MenuItem,
    data: dict,
    valid_vars: list[dict],
    clean_attrs: dict | None,
    effective_price: float,
    effective_cost: float,
    effective_unit: str,
    effective_barcode: str | None,
) -> tuple[MenuItem, list[RetailProduct]]:
    """
    [ИНВАРИАНТ] Консолидация входящего товара витрины с существующим родителем.
    """
    parent_attrs = dict(parent.attributes) if isinstance(parent.attributes, dict) else {}
    existing_vars = list(parent_attrs.get("variations", []))

    incoming_vars: list[dict] = []
    if valid_vars:
        incoming_vars = valid_vars
    else:
        vol = (clean_attrs or {}).get("volume")
        parent_flavor = parent_attrs.get("flavor") or (clean_attrs or {}).get("flavor")
        name_parts = [parent.name]
        if parent_flavor and parent_flavor not in parent.name:
            name_parts.append(str(parent_flavor))
        if vol and vol not in parent.name:
            name_parts.append(str(vol))
        v_name = " ".join(name_parts).strip() if len(name_parts) > 1 else (vol or parent.name)
        incoming_vars = [{
            "name": v_name,
            "price": effective_price,
            "selling_price": effective_price,
            "purchase_price": effective_cost,
            "unit": effective_unit,
            "barcode": effective_barcode,
        }]

    # Если родитель был плоским (Flat SKU) или имеет retail_product_id, переносим его в первую вариацию
    if parent.retail_product_id is not None:
        has_base_in_vars = any(
            ev.get("retail_product_id") == parent.retail_product_id
            for ev in existing_vars
        )
        if not has_base_in_vars:
            old_rp = await session.get(RetailProduct, parent.retail_product_id)
            old_vol = parent_attrs.get("volume")
            old_flavor = parent_attrs.get("flavor")
            old_name_parts = [parent.name]
            if old_flavor and old_flavor not in parent.name:
                old_name_parts.append(str(old_flavor))
            if old_vol and old_vol not in parent.name:
                old_name_parts.append(str(old_vol))
            old_v_name = " ".join(old_name_parts).strip() if len(old_name_parts) > 1 else (old_vol or parent.name)

            base_var = {
                "name": old_v_name,
                "price": parent.price,
                "selling_price": parent.price,
                "purchase_price": old_rp.cost if old_rp else 0.0,
                "unit": old_rp.unit if old_rp else "pcs",
                "barcode": parent.barcode or (old_rp.barcode if old_rp else None),
                "retail_product_id": parent.retail_product_id,
            }
            existing_vars.insert(0, base_var)
        parent.retail_product_id = None
        parent_attrs.pop("volume", None)

    # Добавляем входящие вариации, обновляя совпадения по имени/объему/штрихкоду
    for inc in incoming_vars:
        inc_name = str(inc.get("name", "")).strip().lower()
        inc_bc = inc.get("barcode")
        match_idx = -1
        for i, ev in enumerate(existing_vars):
            ev_name = str(ev.get("name", "")).strip().lower()
            ev_bc = ev.get("barcode")
            if ev_name == inc_name or (inc_bc and ev_bc and inc_bc == ev_bc):
                match_idx = i
                break
        if match_idx >= 0:
            existing_vars[match_idx].update({
                "price": inc.get("price", inc.get("selling_price", existing_vars[match_idx].get("price"))),
                "selling_price": inc.get("price", inc.get("selling_price", existing_vars[match_idx].get("price"))),
                "purchase_price": inc.get("purchase_price", existing_vars[match_idx].get("purchase_price")),
            })
            if inc_bc:
                existing_vars[match_idx]["barcode"] = inc_bc
        else:
            existing_vars.append(inc)

    updated_vars = await _sync_child_variations(session, parent, existing_vars)
    parent_attrs["variations"] = updated_vars
    parent.attributes = parent_attrs
    if updated_vars:
        first_p = updated_vars[0].get("price") or updated_vars[0].get("selling_price")
        if first_p is not None:
            parent.price = float(first_p)
    session.add(parent)
    await session.flush()

    synced_rps: list[RetailProduct] = []
    for uv in updated_vars:
        rp_id = uv.get("retail_product_id")
        if rp_id:
            rp = await session.get(RetailProduct, rp_id)
            if rp:
                synced_rps.append(rp)

    return parent, synced_rps
