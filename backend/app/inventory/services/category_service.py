from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select
from fastapi import HTTPException

from app.inventory.models import MenuCategory, MenuCategoryRead, MenuItem, RetailProduct, Recipe, StockTransaction

async def create_category(session: AsyncSession, data: dict) -> MenuCategory:
    category = MenuCategory(
        name=data["name"],
        category_type=data.get("category_type", "dish"),
        sort_order=data.get("sort_order", 0),
        color=data.get("color"),
        icon=data.get("icon"),
        level=data.get("level", 1),
        path=data.get("path"),
        is_visible=data.get("is_visible", True),
        parent_id=data.get("parent_id"),
    )
    session.add(category)
    await session.flush()
    return category

async def bulk_create_categories(session: AsyncSession, categories_data: list[dict]) -> list[MenuCategoryRead]:
    categories = []
    for data in categories_data:
        category = MenuCategory(
            name=data["name"],
            category_type=data.get("category_type", "dish"),
            sort_order=data.get("sort_order", 0),
            color=data.get("color"),
            icon=data.get("icon"),
            level=data.get("level", 1),
            path=data.get("path"),
            is_visible=data.get("is_visible", True),
            parent_id=data.get("parent_id"),
        )
        categories.append(category)
    
    session.add_all(categories)
    await session.flush()
    return [MenuCategoryRead.model_validate(c) for c in categories]

async def list_categories(session: AsyncSession) -> list[MenuCategoryRead]:
    stmt = select(MenuCategory).order_by(MenuCategory.sort_order)
    result = await session.execute(stmt)
    categories = result.scalars().all()
    return [MenuCategoryRead.model_validate(c) for c in categories]

async def update_category(session: AsyncSession, category_id: int, data: dict) -> MenuCategoryRead:
    stmt = select(MenuCategory).where(MenuCategory.id == category_id)
    result = await session.execute(stmt)
    category = result.scalars().first()
    if not category:
        raise HTTPException(status_code=404, detail="Category not found")
    for key, value in data.items():
        if hasattr(category, key) and value is not None:
            setattr(category, key, value)
    await session.flush()
    return MenuCategoryRead.model_validate(category)

async def delete_category(session: AsyncSession, category_id: int, mode: str = "all") -> None:
    stmt = select(MenuCategory).where(MenuCategory.id == category_id)
    result = await session.execute(stmt)
    category = result.scalars().first()
    if not category:
        raise HTTPException(status_code=404, detail="Category not found")
        
    from app.pos.models import OrderItem

    item_stmt = select(MenuItem).where(MenuItem.category_id == category_id)
    item_res = await session.execute(item_stmt)
    menu_items = item_res.scalars().all()

    retail_stmt = select(RetailProduct).where(RetailProduct.category_id == category_id)
    retail_res = await session.execute(retail_stmt)
    retail_products = retail_res.scalars().all()

    sub_stmt = select(MenuCategory).where(MenuCategory.parent_id == category_id)
    sub_res = await session.execute(sub_stmt)
    subcategories = sub_res.scalars().all()

    if mode == "hard":
        # Check if any items have order items
        has_orders = False
        for item in menu_items:
            order_stmt = select(OrderItem).where(OrderItem.menu_item_id == item.id).limit(1)
            order_res = await session.execute(order_stmt)
            if order_res.scalars().first() is not None:
                has_orders = True
                break

        if not has_orders:
            for rp in retail_products:
                m_stmt = select(MenuItem).where(MenuItem.retail_product_id == rp.id)
                m_res = await session.execute(m_stmt)
                for m in m_res.scalars().all():
                    order_stmt = select(OrderItem).where(OrderItem.menu_item_id == m.id).limit(1)
                    order_res = await session.execute(order_stmt)
                    if order_res.scalars().first() is not None:
                        has_orders = True
                        break

        if has_orders:
            raise HTTPException(status_code=400, detail="Нельзя удалить навсегда: по товарам этой категории есть завершенные чеки.")

        # Hard delete allowed
        for item in menu_items:
            recipe_stmt = select(Recipe).where(Recipe.menu_item_id == item.id)
            recipe_res = await session.execute(recipe_stmt)
            for r in recipe_res.scalars().all():
                await session.delete(r)
            await session.delete(item)

        for rp in retail_products:
            m_stmt = select(MenuItem).where(MenuItem.retail_product_id == rp.id)
            m_res = await session.execute(m_stmt)
            for m in m_res.scalars().all():
                await session.delete(m)
            await session.delete(rp)

        for sub in subcategories:
            await delete_category(session, sub.id, mode="hard")

        await session.delete(category)
        await session.flush()
        return

    # Default Soft Delete (Smart Archive)
    for item in menu_items:
        item.is_available = False
        session.add(item)

    for rp in retail_products:
        m_stmt = select(MenuItem).where(MenuItem.retail_product_id == rp.id)
        m_res = await session.execute(m_stmt)
        for m in m_res.scalars().all():
            m.is_available = False
            session.add(m)
        rp.is_available = False
        session.add(rp)

    for sub in subcategories:
        await delete_category(session, sub.id, mode="all")

    category.is_visible = False
    session.add(category)
    await session.flush()

async def restore_category(session: AsyncSession, category_id: int) -> MenuCategoryRead:
    stmt = select(MenuCategory).where(MenuCategory.id == category_id)
    result = await session.execute(stmt)
    category = result.scalars().first()
    if not category:
        raise HTTPException(status_code=404, detail="Category not found")
        
    category.is_visible = True
    session.add(category)

    item_stmt = select(MenuItem).where(MenuItem.category_id == category_id)
    item_res = await session.execute(item_stmt)
    for item in item_res.scalars().all():
        item.is_available = True
        session.add(item)

    retail_stmt = select(RetailProduct).where(RetailProduct.category_id == category_id)
    retail_res = await session.execute(retail_stmt)
    for rp in retail_res.scalars().all():
        m_stmt = select(MenuItem).where(MenuItem.retail_product_id == rp.id)
        m_res = await session.execute(m_stmt)
        for m in m_res.scalars().all():
            m.is_available = True
            session.add(m)
        rp.is_available = True
        session.add(rp)

    sub_stmt = select(MenuCategory).where(MenuCategory.parent_id == category_id)
    sub_res = await session.execute(sub_stmt)
    for sub in sub_res.scalars().all():
        sub.is_visible = True
        session.add(sub)

    await session.flush()
    return MenuCategoryRead.model_validate(category)
