import pytest
from httpx import AsyncClient
from sqlmodel import select
from app.inventory.models import MenuItem, RetailProduct, MenuCategory
from app.inventory.services.retail_service import bulk_create_retail_products
from app.pos.models import Shift
from datetime import datetime, timezone

@pytest.mark.asyncio
async def test_retail_multi_variations_creation_and_stock(async_client: AsyncClient, db_session):
    # 1. Create a category
    cat = MenuCategory(name="Шоколад", category_type="retail", is_visible=True)
    db_session.add(cat)
    await db_session.commit()
    await db_session.refresh(cat)

    # 2. Bulk create a retail item with 3 variations (Snickers: 50g, 200g, 300g)
    items_payload = [{
        "name": "Сникерс",
        "category_id": cat.id,
        "selling_price": 10.0,
        "purchase_price": 6.0,
        "unit": "pcs",
        "attributes": {
            "flavor": "Классик",
            "variations": [
                {
                    "name": "Сникерс Классик 50 г",
                    "price": 10.0,
                    "purchase_price": 6.0,
                    "unit": "pcs",
                    "barcode": "SNK50",
                    "initial_stock": 20.0,
                },
                {
                    "name": "Сникерс Классик 200 г",
                    "price": 20.0,
                    "purchase_price": 12.0,
                    "unit": "pcs",
                    "barcode": "SNK200",
                    "initial_stock": 10.0,
                },
                {
                    "name": "Сникерс Классик 300 г",
                    "price": 40.0,
                    "purchase_price": 24.0,
                    "unit": "pcs",
                    "barcode": "SNK300",
                    "initial_stock": 5.0,
                },
            ]
        }
    }]

    created_retails = await bulk_create_retail_products(db_session, items_payload, user_id=1)
    await db_session.commit()

    # 3. Verify created parent and child items
    parent_menu_res = await db_session.execute(select(MenuItem).where(MenuItem.name == "Сникерс", MenuItem.parent_id == None))
    parent_menu = parent_menu_res.scalars().first()
    assert parent_menu is not None
    assert parent_menu.type == "retail"

    # Child MenuItems
    children_res = await db_session.execute(select(MenuItem).where(MenuItem.parent_id == parent_menu.id))
    children = children_res.scalars().all()
    assert len(children) == 3

    for child in children:
        assert child.type == "retail"
        assert child.retail_product_id is not None
        child_ret = await db_session.get(RetailProduct, child.retail_product_id)
        assert child_ret is not None
        assert child_ret.unit == "pcs"
        if "50 г" in child.name:
            assert child.price == 10.0
            assert child.barcode == "SNK50"
            assert child_ret.current_stock == 20.0
        elif "200 г" in child.name:
            assert child.price == 20.0
            assert child.barcode == "SNK200"
            assert child_ret.current_stock == 10.0
        elif "300 г" in child.name:
            assert child.price == 40.0
            assert child.barcode == "SNK300"
            assert child_ret.current_stock == 5.0

    print("Retail variations test passed successfully!")

@pytest.mark.asyncio
async def test_retail_single_variation_collapses_to_flat_product(async_client: AsyncClient, db_session):
    cat = MenuCategory(name="Напитки", category_type="retail", is_visible=True)
    db_session.add(cat)
    await db_session.commit()
    await db_session.refresh(cat)

    items_payload = [{
        "name": "Фанта Слайм",
        "category_id": cat.id,
        "selling_price": 30.0,
        "purchase_price": 15.0,
        "unit": "l",
        "attributes": {
            "flavor": "Слайм",
            "variations": [
                {
                    "name": "Фанта Слайм 1 л",
                    "price": 30.0,
                    "purchase_price": 15.0,
                    "unit": "l",
                    "barcode": "FANTA1L",
                }
            ]
        }
    }]

    created_retails = await bulk_create_retail_products(db_session, items_payload, user_id=1)
    await db_session.commit()

    assert len(created_retails) == 1
    flat_rp = created_retails[0]
    assert "Фанта Слайм" in flat_rp.name
    assert flat_rp.price == 30.0
    assert flat_rp.unit in ("l", "pcs")
    assert flat_rp.barcode == "FANTA1L"

    # [ИНВАРИАНТ] Должен быть ровно 1 root MenuItem с привязкой retail_product_id и 0 children
    menu_res = await db_session.execute(select(MenuItem).where(MenuItem.name == "Фанта Слайм"))
    root_item = menu_res.scalars().first()
    assert root_item is not None
    assert root_item.retail_product_id == flat_rp.id
    assert root_item.parent_id is None
    # Атрибуты не должны содержать variations
    assert not root_item.attributes or "variations" not in root_item.attributes

    # Children count must be 0
    children_res = await db_session.execute(select(MenuItem).where(MenuItem.parent_id == root_item.id))
    children = children_res.scalars().all()
    assert len(children) == 0


@pytest.mark.asyncio
async def test_retail_update_collapses_variations_to_flat(async_client: AsyncClient, db_session):
    cat = MenuCategory(name="Газировка", category_type="retail", is_visible=True)
    db_session.add(cat)
    await db_session.commit()
    await db_session.refresh(cat)

    # 1. Создаем товар с 2 вариациями (Кола 0.5л и 1л)
    items_payload = [{
        "name": "Кола Черри",
        "category_id": cat.id,
        "selling_price": 50.0,
        "purchase_price": 25.0,
        "unit": "l",
        "attributes": {
            "flavor": "Вишня",
            "variations": [
                {"name": "Кола Черри 0.5 л", "price": 40.0, "purchase_price": 20.0, "unit": "l", "barcode": "COLA05"},
                {"name": "Кола Черри 1.0 л", "price": 70.0, "purchase_price": 35.0, "unit": "l", "barcode": "COLA10"},
            ]
        }
    }]
    await bulk_create_retail_products(db_session, items_payload, user_id=1)
    await db_session.commit()

    parent_res = await db_session.execute(select(MenuItem).where(MenuItem.name == "Кола Черри", MenuItem.parent_id == None))
    parent = parent_res.scalars().first()
    assert parent is not None
    assert parent.retail_product_id is None

    children_res = await db_session.execute(select(MenuItem).where(MenuItem.parent_id == parent.id))
    children = children_res.scalars().all()
    assert len(children) == 2
    child_rp_ids = [c.retail_product_id for c in children]

    # 2. Обновляем товар через update_menu_item, убирая variations (переход в Flat SKU)
    from app.inventory.services.menu_service import update_menu_item
    await update_menu_item(
        db_session,
        parent.id,
        {
            "name": "Кола Черри",
            "price": 60.0,
            "attributes": {"flavor": "Вишня", "volume": "0.5 л"},
        }
    )
    await db_session.commit()

    # 3. Проверяем, что дочерние MenuItems и их RetailProducts удалены
    children_after = (await db_session.execute(select(MenuItem).where(MenuItem.parent_id == parent.id))).scalars().all()
    assert len(children_after) == 0

    for old_rp_id in child_rp_ids:
        assert (await db_session.get(RetailProduct, old_rp_id)) is None

    # 4. Проверяем, что parent теперь привязан к новому плоскому RetailProduct
    await db_session.refresh(parent)
    assert parent.retail_product_id is not None
    flat_rp = await db_session.get(RetailProduct, parent.retail_product_id)
    assert flat_rp is not None
    assert flat_rp.name == "Кола Черри"
    assert flat_rp.price == 60.0


@pytest.mark.asyncio
async def test_bulk_create_consolidates_into_existing_flat_retail_product(async_client: AsyncClient, db_session):
    cat = MenuCategory(name="Соки", category_type="retail", is_visible=True)
    db_session.add(cat)
    await db_session.commit()
    await db_session.refresh(cat)

    # 1. Создаем одиночный Flat SKU (Добрый Лайм 0.5 л)
    initial_payload = [{
        "name": "Добрый Лайм",
        "category_id": cat.id,
        "selling_price": 15.0,
        "purchase_price": 8.0,
        "unit": "pcs",
        "barcode": "LIME05",
        "attributes": {
            "flavor": "Лайм",
            "volume": "0.5 л",
        }
    }]
    initial_retails = await bulk_create_retail_products(db_session, initial_payload, user_id=1)
    await db_session.commit()

    assert len(initial_retails) == 1
    orig_rp_id = initial_retails[0].id

    # 2. Через Bulk API добавляем новый объем того же товара (Добрый Лайм 1.0 л)
    second_payload = [{
        "name": "Добрый Лайм",
        "category_id": cat.id,
        "selling_price": 25.0,
        "purchase_price": 14.0,
        "unit": "pcs",
        "barcode": "LIME10",
        "attributes": {
            "flavor": "Лайм",
            "volume": "1.0 л",
        }
    }]
    second_retails = await bulk_create_retail_products(db_session, second_payload, user_id=1)
    await db_session.commit()

    # 3. Проверяем, что в системе осталась ровно ОДНА корневая карточка MenuItem
    parents = (await db_session.execute(
        select(MenuItem).where(MenuItem.name == "Добрый Лайм", MenuItem.parent_id == None)
    )).scalars().all()
    assert len(parents) == 1
    parent = parents[0]
    assert parent.retail_product_id is None
    assert parent.attributes is not None
    assert "variations" in parent.attributes
    assert len(parent.attributes["variations"]) == 2

    # 4. Проверяем наличие двух дочерних MenuItem с привязкой к RetailProduct
    children = (await db_session.execute(
        select(MenuItem).where(MenuItem.parent_id == parent.id).order_by(MenuItem.sort_order.asc())
    )).scalars().all()
    assert len(children) == 2

    # Проверяем перенос оригинального RetailProduct в первую вариацию
    assert children[0].retail_product_id == orig_rp_id
    orig_rp = await db_session.get(RetailProduct, orig_rp_id)
    assert orig_rp is not None
    assert orig_rp.price == 15.0

    # Вторая вариация получила свой новый RetailProduct
    assert children[1].retail_product_id is not None
    assert children[1].retail_product_id != orig_rp_id
    second_rp = await db_session.get(RetailProduct, children[1].retail_product_id)
    assert second_rp is not None
    assert second_rp.price == 25.0
    assert second_rp.barcode == "LIME10"


@pytest.mark.asyncio
async def test_bulk_create_consolidates_into_existing_series_retail_product(async_client: AsyncClient, db_session):
    cat = MenuCategory(name="Энергетики", category_type="retail", is_visible=True)
    db_session.add(cat)
    await db_session.commit()
    await db_session.refresh(cat)

    # 1. Создаем товар сразу с 2 вариациями
    initial_payload = [{
        "name": "Флэш Энерджи",
        "category_id": cat.id,
        "selling_price": 20.0,
        "purchase_price": 10.0,
        "unit": "pcs",
        "attributes": {
            "flavor": "Ягода",
            "variations": [
                {"name": "Флэш 0.33 л", "price": 20.0, "purchase_price": 10.0, "unit": "pcs", "barcode": "FL033"},
                {"name": "Флэш 0.5 л", "price": 30.0, "purchase_price": 15.0, "unit": "pcs", "barcode": "FL050"},
            ]
        }
    }]
    await bulk_create_retail_products(db_session, initial_payload, user_id=1)
    await db_session.commit()

    # 2. Добавляем 3-ю вариацию через Bulk API
    addon_payload = [{
        "name": "Флэш Энерджи",
        "category_id": cat.id,
        "selling_price": 50.0,
        "purchase_price": 25.0,
        "unit": "pcs",
        "barcode": "FL100",
        "attributes": {
            "flavor": "Ягода",
            "volume": "1.0 л",
        }
    }]
    await bulk_create_retail_products(db_session, addon_payload, user_id=1)
    await db_session.commit()

    # 3. Должен остаться один родитель с 3 дочерними элементами
    parents = (await db_session.execute(
        select(MenuItem).where(MenuItem.name == "Флэш Энерджи", MenuItem.parent_id == None)
    )).scalars().all()
    assert len(parents) == 1
    parent = parents[0]

    children = (await db_session.execute(
        select(MenuItem).where(MenuItem.parent_id == parent.id)
    )).scalars().all()
    assert len(children) == 3


