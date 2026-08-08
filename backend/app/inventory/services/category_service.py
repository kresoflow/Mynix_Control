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

async def delete_category(session: AsyncSession, category_id: int, mode: str = "only") -> None:
    stmt = select(MenuCategory).where(MenuCategory.id == category_id)
    result = await session.execute(stmt)
    category = result.scalars().first()
    if not category:
        raise HTTPException(status_code=404, detail="Category not found")
        
    if mode == "only":
        sub_stmt = select(MenuCategory).where(MenuCategory.parent_id == category_id)
        sub_res = await session.execute(sub_stmt)
        for sub in sub_res.scalars().all():
            sub.parent_id = category.parent_id
            session.add(sub)
            
        item_stmt = select(MenuItem).where(MenuItem.category_id == category_id)
        item_res = await session.execute(item_stmt)
        for item in item_res.scalars().all():
            item.category_id = category.parent_id
            session.add(item)
            
        retail_stmt = select(RetailProduct).where(RetailProduct.category_id == category_id)
        retail_res = await session.execute(retail_stmt)
        for rp in retail_res.scalars().all():
            if category.parent_id is None:
                raise HTTPException(status_code=400, detail="Невозможно переместить товары витрины в корень. Удалите их или переместите вручную.")
            rp.category_id = category.parent_id
            session.add(rp)
            
    elif mode == "all":
        item_stmt = select(MenuItem).where(MenuItem.category_id == category_id)
        item_res = await session.execute(item_stmt)
        for item in item_res.scalars().all():
            recipe_stmt = select(Recipe).where(Recipe.menu_item_id == item.id)
            recipe_res = await session.execute(recipe_stmt)
            for r in recipe_res.scalars().all():
                await session.delete(r)
            await session.delete(item)
            
        retail_stmt = select(RetailProduct).where(RetailProduct.category_id == category_id)
        retail_res = await session.execute(retail_stmt)
        for rp in retail_res.scalars().all():
            m_stmt = select(MenuItem).where(MenuItem.retail_product_id == rp.id)
            m_res = await session.execute(m_stmt)
            for m in m_res.scalars().all():
                r_stmt = select(Recipe).where(Recipe.menu_item_id == m.id)
                r_res = await session.execute(r_stmt)
                for r in r_res.scalars().all():
                    await session.delete(r)
                await session.delete(m)
                
            trans_stmt = select(StockTransaction).where(StockTransaction.retail_product_id == rp.id)
            trans_res = await session.execute(trans_stmt)
            for t in trans_res.scalars().all():
                await session.delete(t)
                
            await session.delete(rp)
            
        sub_stmt = select(MenuCategory).where(MenuCategory.parent_id == category_id)
        sub_res = await session.execute(sub_stmt)
        for sub in sub_res.scalars().all():
            await delete_category(session, sub.id, mode="all")
    else:
        raise HTTPException(status_code=400, detail="Invalid deletion mode")
        
    await session.delete(category)
    await session.flush()
