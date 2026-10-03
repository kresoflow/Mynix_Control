# ============================================================================
# KRESO FLOW — BACKEND RECIPE API INTEGRATION TESTS
# ============================================================================
#
# Файл: backend/tests/test_recipe_api.py
# Назначение: Интеграционные тесты HTTP API управления технологическими картами,
#             расчета себестоимости (фудкоста), расчета доступности и PBAC прав.
#
# ============================================================================

import pytest
from httpx import AsyncClient
from sqlmodel import select

from app.users.models import Tenant, Role, User, UserRole, Permission, RolePermission
from app.users import services as user_svc
from app.inventory.models import MenuCategory, MenuItem, Ingredient, Recipe

# ─── 1. Вспомогательная функция генерации тестового окружения ───────────────

async def _setup_recipe_test_context(db_session):
    """
    Создает тенанта, роли Admin и Staff, пользователей и токены авторизации.
    """
    tenant = Tenant(name="Recipe Test Cafe", schema_name="public", is_active=True)
    db_session.add(tenant)
    await db_session.commit()
    await db_session.refresh(tenant)

    # Роль администратора (полный доступ)
    admin_role = Role(name="Admin", is_superuser=True, tenant_id=tenant.id)
    db_session.add(admin_role)

    # Роль линейного сотрудника (только просмотр меню)
    staff_role = Role(name="Staff", is_superuser=False, tenant_id=tenant.id)
    db_session.add(staff_role)
    await db_session.commit()
    await db_session.refresh(admin_role)
    await db_session.refresh(staff_role)

    # Назначаем право menu:view для Staff роли
    res_p = await db_session.execute(select(Permission).where(Permission.code == "menu:view"))
    p_view = res_p.scalars().first()
    if not p_view:
        p_view = Permission(code="menu:view", description="View menu")
        db_session.add(p_view)
        await db_session.commit()
        await db_session.refresh(p_view)
    db_session.add(RolePermission(role_id=staff_role.id, permission_id=p_view.id))

    admin_user = User(
        tenant_id=tenant.id,
        username="admin_chef",
        full_name="Chef Admin",
        hashed_password="hash",
        is_active=True,
    )
    staff_user = User(
        tenant_id=tenant.id,
        username="waiter_tim",
        full_name="Tim Waiter",
        hashed_password="hash",
        is_active=True,
    )
    db_session.add(admin_user)
    db_session.add(staff_user)
    await db_session.commit()
    await db_session.refresh(admin_user)
    await db_session.refresh(staff_user)

    db_session.add(UserRole(user_id=admin_user.id, role_id=admin_role.id))
    db_session.add(UserRole(user_id=staff_user.id, role_id=staff_role.id))
    await db_session.commit()

    admin_token = user_svc.create_access_token(
        user_id=admin_user.id,
        tenant_id=tenant.id,
        permissions=["menu:view", "menu:manage", "inventory:view", "inventory:manage", "analytics:view"],
        is_superuser=True,
    )
    staff_token = user_svc.create_access_token(
        user_id=staff_user.id,
        tenant_id=tenant.id,
        permissions=["menu:view"],
        is_superuser=False,
    )

    return {
        "tenant": tenant,
        "admin_headers": {"Authorization": f"Bearer {admin_token}"},
        "staff_headers": {"Authorization": f"Bearer {staff_token}"},
    }


# ─── 2. Тест сквозного CRUD рецептуры и расчета фудкоста ────────────────────

@pytest.mark.asyncio
async def test_recipe_crud_and_food_cost_lifecycle(async_client: AsyncClient, db_session):
    """
    [ИНВАРИАНТ] Проверка полного жизненного цикла техкарты через HTTP API:
    1. Создание блюда и ингредиентов с учетной ценой.
    2. Добавление ингредиента в рецептуру (POST).
    3. Чтение рецептуры (GET).
    4. Пакетное обновление состава техкарты (PUT).
    5. Расчет фудкоста порции по актуальным ценам сырья (GET /food-cost).
    6. Удаление ингредиента из рецептуры (DELETE).
    """
    ctx = await _setup_recipe_test_context(db_session)
    admin_hdrs = ctx["admin_headers"]

    # 1. Создание категории, блюда и ингредиентов
    cat = MenuCategory(name="Горячие напитки", category_type="dish")
    db_session.add(cat)
    await db_session.commit()
    await db_session.refresh(cat)

    dish = MenuItem(name="Капучино", price=180.0, category_id=cat.id, type="dish", is_available=True)
    db_session.add(dish)

    # Зерно: 1000 руб/кг, Молоко: 80 руб/л
    coffee = Ingredient(name="Кофе зерно", unit="kg", current_stock=5.0, cost_per_unit=1000.0)
    milk = Ingredient(name="Молоко 3.2%", unit="l", current_stock=20.0, cost_per_unit=80.0)
    db_session.add(coffee)
    db_session.add(milk)
    await db_session.commit()
    await db_session.refresh(dish)
    await db_session.refresh(coffee)
    await db_session.refresh(milk)

    # 2. Добавление кофе в рецептуру через HTTP POST
    add_resp = await async_client.post(
        f"/api/v1/menu/{dish.id}/recipe",
        json={"ingredient_id": coffee.id, "quantity_required": 0.018},
        headers=admin_hdrs,
    )
    assert add_resp.status_code == 200
    assert add_resp.json()["status"] == "ok"

    # 3. Чтение рецептуры через HTTP GET
    get_resp = await async_client.get(f"/api/v1/menu/{dish.id}/recipe", headers=admin_hdrs)
    assert get_resp.status_code == 200
    recipe_items = get_resp.json()
    assert len(recipe_items) == 1
    assert recipe_items[0]["ingredient_id"] == coffee.id
    assert abs(recipe_items[0]["quantity_required"] - 0.018) < 1e-4

    # 4. Пакетное обновление рецептуры (кофе 0.020 кг + молоко 0.150 л) через HTTP PUT
    bulk_resp = await async_client.put(
        f"/api/v1/menu/{dish.id}/recipe",
        json={
            "recipes": [
                {"ingredient_id": coffee.id, "quantity_required": 0.020},
                {"ingredient_id": milk.id, "quantity_required": 0.150},
            ]
        },
        headers=admin_hdrs,
    )
    assert bulk_resp.status_code == 200

    # 5. Проверка расчета фудкоста через HTTP GET /food-cost
    # Ожидаемый фудкост: 0.020 * 1000.0 + 0.150 * 80.0 = 20.0 + 12.0 = 32.0 руб
    cost_resp = await async_client.get(f"/api/v1/menu/{dish.id}/food-cost", headers=admin_hdrs)
    assert cost_resp.status_code == 200
    cost_data = cost_resp.json()
    assert cost_data["menu_item_id"] == dish.id
    assert abs(cost_data["food_cost_rub"] - 32.0) < 1e-2

    # 6. Удаление молока из рецептуры через HTTP DELETE
    del_resp = await async_client.delete(
        f"/api/v1/menu/{dish.id}/recipe/{milk.id}",
        headers=admin_hdrs,
    )
    assert del_resp.status_code == 200

    # 7. Проверка, что осталось только зерно и фудкост пересчитался
    cost_after_resp = await async_client.get(f"/api/v1/menu/{dish.id}/food-cost", headers=admin_hdrs)
    assert cost_after_resp.status_code == 200
    assert abs(cost_after_resp.json()["food_cost_rub"] - 20.0) < 1e-2


# ─── 3. Тест расчета доступности блюда (Availability) и PBAC защит ──────────

@pytest.mark.asyncio
async def test_recipe_availability_and_pbac_guards(async_client: AsyncClient, db_session):
    """
    [БЕЗОПАСНОСТЬ] & [ИНВАРИАНТ]
    1. Проверка расчета остатка доступных порций по остаткам сырья.
    2. Проверка PBAC: попытка изменения рецептуры пользователем без прав (403).
    """
    ctx = await _setup_recipe_test_context(db_session)
    admin_hdrs = ctx["admin_headers"]
    staff_hdrs = ctx["staff_headers"]

    cat = MenuCategory(name="Бар", category_type="dish")
    db_session.add(cat)
    await db_session.commit()
    await db_session.refresh(cat)

    dish = MenuItem(name="Чай Малина", price=150.0, category_id=cat.id, type="dish", is_available=True)
    db_session.add(dish)

    # 1.5 кг ягод, норма 0.05 кг на порцию => доступно 30 порций
    berries = Ingredient(name="Малина", unit="kg", current_stock=1.5, cost_per_unit=500.0)
    db_session.add(berries)
    await db_session.commit()
    await db_session.refresh(dish)
    await db_session.refresh(berries)

    # Привязываем рецепт через базу
    recipe = Recipe(menu_item_id=dish.id, ingredient_id=berries.id, quantity_required=0.05)
    db_session.add(recipe)
    await db_session.commit()

    # Проверка доступности: запрашиваем 1 порцию
    avail_resp = await async_client.get(
        f"/api/v1/menu/{dish.id}/availability?quantity=1",
        headers=staff_hdrs,
    )
    assert avail_resp.status_code == 200
    avail_data = avail_resp.json()
    assert avail_data["available"] is True
    assert len(avail_data["missing"]) == 0

    # Запрашиваем 50 порций при остатке на 30 порций -> available == False
    avail_over_resp = await async_client.get(
        f"/api/v1/menu/{dish.id}/availability?quantity=50",
        headers=staff_hdrs,
    )
    assert avail_over_resp.status_code == 200
    over_data = avail_over_resp.json()
    assert over_data["available"] is False
    assert len(over_data["missing"]) == 1
    assert over_data["missing"][0]["ingredient"] == "Малина"

    # PBAC: Staff пытается изменить рецептуру -> 403 Forbidden
    pbac_forbidden_resp = await async_client.post(
        f"/api/v1/menu/{dish.id}/recipe",
        json={"ingredient_id": berries.id, "quantity_required": 0.10},
        headers=staff_hdrs,
    )
    assert pbac_forbidden_resp.status_code == 403
