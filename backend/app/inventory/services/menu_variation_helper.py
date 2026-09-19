from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select

from app.inventory.models import MenuItem, Recipe
from app.pos.models import OrderItem

async def sync_child_variations(session: AsyncSession, parent_item: MenuItem, variations: list[dict]) -> list[dict]:
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

_sync_child_variations = sync_child_variations
