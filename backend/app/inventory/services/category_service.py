from sqlalchemy import case
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select
from fastapi import HTTPException

from app.inventory.models import (
    MenuCategory, MenuCategoryRead, MenuItem, RetailProduct, Recipe, StockTransaction, Ingredient
)

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
        is_archived=data.get("is_archived", False),
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
            is_archived=data.get("is_archived", False),
            parent_id=data.get("parent_id"),
        )
        categories.append(category)
    
    session.add_all(categories)
    await session.flush()
    return [MenuCategoryRead.model_validate(c) for c in categories]

async def list_categories(session: AsyncSession) -> list[MenuCategoryRead]:
    stmt = select(MenuCategory).order_by(
        case((MenuCategory.sort_order == 0, 999999), else_=MenuCategory.sort_order).asc(),
        MenuCategory.id.asc(),
    )
    result = await session.execute(stmt)
    categories = result.scalars().all()
    return [MenuCategoryRead.model_validate(c) for c in categories]

async def update_category(session: AsyncSession, category_id: int, data: dict) -> MenuCategoryRead:
    stmt = select(MenuCategory).where(MenuCategory.id == category_id)
    result = await session.execute(stmt)
    category = result.scalars().first()
    if not category:
        raise HTTPException(status_code=404, detail="Category not found")

    # Cycle detection if parent_id is being updated
    if "parent_id" in data and data["parent_id"] is not None:
        new_parent_id = data["parent_id"]
        if new_parent_id == category_id:
            raise HTTPException(
                status_code=400,
                detail="Категория не может быть родительской для самой себя."
            )
        curr_parent = new_parent_id
        visited = {category_id}
        while curr_parent:
            if curr_parent in visited:
                raise HTTPException(
                    status_code=400,
                    detail="Обнаружена циклическая зависимость: категория не может стать дочерней для собственного потомка."
                )
            visited.add(curr_parent)
            p_stmt = select(MenuCategory).where(MenuCategory.id == curr_parent)
            p_res = await session.execute(p_stmt)
            p_cat = p_res.scalars().first()
            if not p_cat:
                break
            if p_cat.parent_id == category_id:
                raise HTTPException(
                    status_code=400,
                    detail="Обнаружена циклическая зависимость: категория не может стать дочерней для собственного потомка."
                )
            curr_parent = p_cat.parent_id

    for key, value in data.items():
        if hasattr(category, key):
            setattr(category, key, value)
    await session.flush()
    return MenuCategoryRead.model_validate(category)

async def delete_category(session: AsyncSession, category_id: int, mode: str = "soft") -> dict:
    stmt = select(MenuCategory).where(MenuCategory.id == category_id)
    result = await session.execute(stmt)
    category = result.scalars().first()
    if not category:
        raise HTTPException(status_code=404, detail="Category not found")
        
    from app.pos.models import OrderItem
    from app.inventory.models.ingredient_models import Ingredient

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
        # Проверка истории заказов
        has_orders = False
        all_m_ids = [item.id for item in menu_items]
        if all_m_ids:
            order_stmt = select(OrderItem).where(OrderItem.menu_item_id.in_(all_m_ids)).limit(1)
            order_res = await session.execute(order_stmt)
            if order_res.scalars().first() is not None:
                has_orders = True

        if not has_orders and retail_products:
            rp_ids = [rp.id for rp in retail_products]
            m_stmt = select(MenuItem).where(MenuItem.retail_product_id.in_(rp_ids))
            m_res = await session.execute(m_stmt)
            rp_m_ids = [m.id for m in m_res.scalars().all()]
            if rp_m_ids:
                order_stmt = select(OrderItem).where(OrderItem.menu_item_id.in_(rp_m_ids)).limit(1)
                order_res = await session.execute(order_stmt)
                if order_res.scalars().first() is not None:
                    has_orders = True

        if has_orders:
            raise HTTPException(
                status_code=400,
                detail="Невозможно удалить категорию навсегда: по её товарам есть история продаж. Категория останется в архиве."
            )

        # Проверка складских проводок для товаров витрины
        if retail_products:
            rp_ids = [rp.id for rp in retail_products]
            txn_stmt = select(StockTransaction).where(StockTransaction.retail_product_id.in_(rp_ids)).limit(1)
            txn_res = await session.execute(txn_stmt)
            if txn_res.scalars().first() is not None:
                raise HTTPException(
                    status_code=400,
                    detail="Невозможно удалить категорию навсегда: по её товарам есть складские проводки. Категория останется в архиве."
                )

        # Отвязка сырья
        ing_stmt = select(Ingredient).where(Ingredient.category_id == category_id)
        ing_res = await session.execute(ing_stmt)
        for ing in ing_res.scalars().all():
            ing.category_id = None
            session.add(ing)

        # Удаление блюд, техкарт и вариаций
        for item in menu_items:
            recipe_stmt = select(Recipe).where(Recipe.menu_item_id == item.id)
            recipe_res = await session.execute(recipe_stmt)
            for r in recipe_res.scalars().all():
                await session.delete(r)

            child_stmt = select(MenuItem).where(MenuItem.parent_id == item.id)
            child_res = await session.execute(child_stmt)
            for c in child_res.scalars().all():
                c_r_stmt = select(Recipe).where(Recipe.menu_item_id == c.id)
                c_r_res = await session.execute(c_r_stmt)
                for cr in c_r_res.scalars().all():
                    await session.delete(cr)
                await session.delete(c)

            await session.delete(item)

        # Удаление товаров витрины без истории
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
        return {"status": "deleted", "message": "Категория успешно удалена навсегда."}

    # Soft Delete (Архивация - режим по умолчанию с любого рабочего экрана)
    ctype = category.category_type
    if ctype == "dish":
        for item in menu_items:
            item.is_available = False
            session.add(item)
    elif ctype == "retail":
        for rp in retail_products:
            m_stmt = select(MenuItem).where(MenuItem.retail_product_id == rp.id)
            m_res = await session.execute(m_stmt)
            for m in m_res.scalars().all():
                m.is_available = False
                session.add(m)
            rp.is_available = False
            session.add(rp)
    elif ctype == "ingredient":
        ing_stmt = select(Ingredient).where(Ingredient.category_id == category_id)
        ing_res = await session.execute(ing_stmt)
        for ing in ing_res.scalars().all():
            ing.is_archived = True
            session.add(ing)

    for sub in subcategories:
        await delete_category(session, sub.id, mode="soft")

    category.is_archived = True
    session.add(category)
    await session.flush()
    return {"status": "archived", "message": "Категория заархивирована."}


async def bulk_delete_categories(session: AsyncSession, category_ids: list[int], mode: str = "soft") -> dict:
    results = []
    for cat_id in category_ids:
        try:
            res = await delete_category(session, cat_id, mode=mode)
            results.append(res)
        except Exception:
            pass
    return {"status": "ok", "deleted_count": len(results)}

async def restore_category(session: AsyncSession, category_id: int) -> MenuCategoryRead:
    """
    Восстанавливает категорию из архива с защитой от коллизий дубликатов.
    
    [ИНВАРИАНТ]  Запрещено восстанавливать категорию, если на том же уровне уже есть активная категория с таким же именем.
    """
    stmt = select(MenuCategory).where(MenuCategory.id == category_id)
    result = await session.execute(stmt)
    category = result.scalars().first()
    if not category:
        raise HTTPException(status_code=404, detail="Category not found")

    # Проверка наличия активного дубликата на том же уровне
    dup_stmt = select(MenuCategory).where(
        MenuCategory.category_type == category.category_type,
        MenuCategory.parent_id == category.parent_id,
        MenuCategory.is_archived == False,
        MenuCategory.id != category.id
    )
    dup_res = await session.execute(dup_stmt)
    for existing in dup_res.scalars().all():
        if existing.name.strip().lower() == category.name.strip().lower():
            raise HTTPException(
                status_code=400,
                detail=f"Активная категория «{existing.name}» уже существует на этом уровне. Переименуйте или удалите её перед разархивацией."
            )

    category.is_archived = False
    session.add(category)

    ctype = category.category_type
    if ctype == "dish":
        item_stmt = select(MenuItem).where(MenuItem.category_id == category_id)
        item_res = await session.execute(item_stmt)
        for item in item_res.scalars().all():
            item.is_available = True
            session.add(item)
            child_stmt = select(MenuItem).where(MenuItem.parent_id == item.id)
            child_res = await session.execute(child_stmt)
            for child in child_res.scalars().all():
                child.is_available = True
                session.add(child)
    elif ctype == "retail":
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
    elif ctype == "ingredient":
        ing_stmt = select(Ingredient).where(Ingredient.category_id == category_id)
        ing_res = await session.execute(ing_stmt)
        for ing in ing_res.scalars().all():
            ing.is_archived = False
            session.add(ing)

    sub_stmt = select(MenuCategory).where(MenuCategory.parent_id == category_id)
    sub_res = await session.execute(sub_stmt)
    for sub in sub_res.scalars().all():
        await restore_category(session, sub.id)

    await session.flush()
    return MenuCategoryRead.model_validate(category)
