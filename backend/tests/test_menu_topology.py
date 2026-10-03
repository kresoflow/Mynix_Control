# ==============================================================================
# ТЕСТЫ: Каталог — Динамическая топология (Merge, Split, Unbundle, Poka-Yoke)
# ДОМЕН: backend/tests/test_menu_topology.py
# ==============================================================================

import pytest
from sqlmodel import select
from app.inventory.models import MenuItem, RetailProduct, MenuCategory
from app.inventory.services import menu_topology_service


@pytest.mark.asyncio
async def test_merge_two_standalone_items_into_single_card(db_session):
    """
    [ТЕСТ] Проверка объединения двух независимых одиночных товаров в одну
    карточку с вариациями. Складские товары (RetailProduct) сохраняются.
    """
    cat = MenuCategory(name="Соки Топология", category_type="retail", is_visible=True)
    db_session.add(cat)
    await db_session.commit()
    await db_session.refresh(cat)

    # 1. Создаем первый одиночный товар со складом
    rp1 = RetailProduct(name="Добрый яблоко 1 л", category_id=cat.id, price=20.0, cost=10.0, unit="pcs", is_available=True)
    db_session.add(rp1)
    await db_session.commit()
    await db_session.refresh(rp1)

    item1 = MenuItem(
        name="Добрый яблоко 1 л",
        category_id=cat.id,
        price=20.0,
        type="retail",
        retail_product_id=rp1.id,
        attributes={"volume": "1 л", "unit": "pcs"},
        is_available=True,
    )
    db_session.add(item1)
    await db_session.commit()
    await db_session.refresh(item1)

    # 2. Создаем второй одиночный товар со складом
    rp2 = RetailProduct(name="Добрый яблоко 2 л", category_id=cat.id, price=35.0, cost=18.0, unit="pcs", is_available=True)
    db_session.add(rp2)
    await db_session.commit()
    await db_session.refresh(rp2)

    item2 = MenuItem(
        name="Добрый яблоко 2 л",
        category_id=cat.id,
        price=35.0,
        type="retail",
        retail_product_id=rp2.id,
        attributes={"volume": "2 л", "unit": "pcs"},
        is_available=True,
    )
    db_session.add(item2)
    await db_session.commit()
    await db_session.refresh(item2)

    # 3. Объединяем item1 и item2 в одну карточку "Добрый яблоко"
    target = await menu_topology_service.merge_menu_items(
        db_session,
        target_item_id=item1.id,
        source_item_ids=[item2.id],
        target_name="Добрый яблоко",
    )
    await db_session.commit()
    await db_session.refresh(target)

    # 4. Проверяем структуру родителя
    assert target.id == item1.id
    assert target.name == "Добрый яблоко"
    assert target.price == 20.0  # min price
    assert target.parent_id is None
    assert "variations" in target.attributes
    assert len(target.attributes["variations"]) == 2

    # 5. Проверяем дочерние элементы
    children_res = await db_session.execute(
        select(MenuItem).where(MenuItem.parent_id == target.id)
    )
    children = children_res.scalars().all()
    assert len(children) == 2

    child_rp_ids = {c.retail_product_id for c in children}
    assert rp1.id in child_rp_ids
    assert rp2.id in child_rp_ids


@pytest.mark.asyncio
async def test_extract_variation_to_standalone(db_session):
    """
    [ТЕСТ] Проверка отсоединения вариации в отдельную карточку (Split/Extract).
    """
    cat = MenuCategory(name="Газировка", category_type="retail", is_visible=True)
    db_session.add(cat)
    await db_session.commit()
    await db_session.refresh(cat)

    parent = MenuItem(
        name="Фиеста",
        category_id=cat.id,
        price=10.0,
        type="retail",
        is_available=True,
        attributes={"variations": [
            {"id": 999, "name": "Фиеста 0.5 л", "price": 10.0},
            {"id": 1000, "name": "Фиеста 1 л", "price": 20.0},
        ]},
    )
    db_session.add(parent)
    await db_session.commit()
    await db_session.refresh(parent)

    rp = RetailProduct(name="Фиеста 1 л", category_id=cat.id, price=20.0, unit="pcs", is_available=True)
    db_session.add(rp)
    await db_session.commit()
    await db_session.refresh(rp)

    child = MenuItem(
        name="Фиеста 1 л",
        category_id=cat.id,
        price=20.0,
        type="retail",
        parent_id=parent.id,
        retail_product_id=rp.id,
        is_available=True,
    )
    db_session.add(child)
    await db_session.commit()
    await db_session.refresh(child)

    # Привязываем реальный id ребенка в массив вариаций
    parent.attributes["variations"][1]["id"] = child.id
    db_session.add(parent)
    await db_session.commit()

    # Отсоединяем ребенка
    extracted = await menu_topology_service.extract_variation_to_standalone(db_session, child.id)
    await db_session.commit()
    await db_session.refresh(extracted)
    await db_session.refresh(parent)

    assert extracted.parent_id is None
    assert extracted.retail_product_id == rp.id
    assert extracted.is_available is True

    # Проверяем, что из родителя вариация удалена
    parent_vars = parent.attributes.get("variations") or []
    assert len(parent_vars) == 1
    assert parent_vars[0]["name"] == "Фиеста 0.5 л"


@pytest.mark.asyncio
async def test_unbundle_menu_item(db_session):
    """
    [ТЕСТ] Проверка полной распаковки всех вариаций карточки в отдельные товары.
    """
    cat = MenuCategory(name="Чай", category_type="retail", is_visible=True)
    db_session.add(cat)
    await db_session.commit()
    await db_session.refresh(cat)

    parent = MenuItem(name="Липтон", category_id=cat.id, price=15.0, type="retail", is_available=True)
    db_session.add(parent)
    await db_session.commit()
    await db_session.refresh(parent)

    c1 = MenuItem(name="Липтон Лимон 0.5", category_id=cat.id, price=15.0, parent_id=parent.id, is_available=True)
    c2 = MenuItem(name="Липтон Персик 0.5", category_id=cat.id, price=15.0, parent_id=parent.id, is_available=True)
    db_session.add(c1)
    db_session.add(c2)
    await db_session.commit()

    detached = await menu_topology_service.unbundle_menu_item(db_session, parent.id)
    await db_session.commit()

    assert len(detached) == 2
    for d in detached:
        await db_session.refresh(d)
        assert d.parent_id is None
        assert d.is_available is True

    await db_session.refresh(parent)
    assert parent.attributes.get("variations") is None


@pytest.mark.asyncio
async def test_delete_policy_archive_menu_only_preserves_warehouse(db_session):
    """
    [ТЕСТ] Poka-Yoke политика 'archive_menu_only': скрывает карточку с кассы,
    но оставляет складские товары активными.
    """
    cat = MenuCategory(name="Вода", category_type="retail", is_visible=True)
    db_session.add(cat)
    await db_session.commit()
    await db_session.refresh(cat)

    rp = RetailProduct(name="Боржоми 0.5", category_id=cat.id, price=25.0, unit="pcs", is_available=True)
    db_session.add(rp)
    await db_session.commit()
    await db_session.refresh(rp)

    item = MenuItem(name="Боржоми", category_id=cat.id, price=25.0, retail_product_id=rp.id, is_available=True)
    db_session.add(item)
    await db_session.commit()
    await db_session.refresh(item)

    # Применяем политику archive_menu_only
    res = await menu_topology_service.delete_menu_item_with_policy(
        db_session, item.id, policy="archive_menu_only"
    )
    await db_session.commit()
    await db_session.refresh(item)
    await db_session.refresh(rp)

    assert res["status"] == "archived_menu_only"
    assert item.is_available is False  # с кассы скрыт
    assert rp.is_available is True     # на складе ОСТАЛСЯ активным!
