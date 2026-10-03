import pytest
from httpx import AsyncClient
from sqlmodel import select
from app.users.models import Tenant, Role, User, UserRole
from app.users import services as user_svc
from app.pos.models import Shift
from app.inventory.models import (
    Ingredient, MenuItem, Recipe, RetailProduct, StockTransaction, StockTransactionType, MenuCategory
)

@pytest.mark.asyncio
async def test_dish_recipe_auto_deduction(async_client: AsyncClient, db_session):
    """
    E2E Test: Ordering a Dish with a Recipe auto-deducts raw ingredients from stock.
    """
    # 1. Setup Tenant & User
    tenant = Tenant(name="Test Cafe", schema_name="public", is_active=True, enable_inventory_deduction=True)
    db_session.add(tenant)
    await db_session.commit()
    await db_session.refresh(tenant)

    role = Role(name="Admin", is_superuser=True, tenant_id=tenant.id)
    db_session.add(role)
    await db_session.commit()
    await db_session.refresh(role)

    user = User(
        tenant_id=tenant.id,
        username="cashier_bob",
        full_name="Bob Cashier",
        hashed_password="hash",
        is_active=True,
    )
    db_session.add(user)
    await db_session.commit()
    await db_session.refresh(user)

    user_role = UserRole(user_id=user.id, role_id=role.id)
    db_session.add(user_role)
    await db_session.commit()

    token = user_svc.create_access_token(
        user_id=user.id,
        tenant_id=tenant.id,
        permissions=["orders:create", "orders:view", "inventory:view"],
        is_superuser=True,
    )
    headers = {"Authorization": f"Bearer {token}"}

    # 2. Setup Category & Ingredients (Beef: 10.0 kg, Bun: 50.0 pcs)
    cat = MenuCategory(name="Бургеры", category_type="dish")
    db_session.add(cat)
    await db_session.commit()
    await db_session.refresh(cat)

    beef = Ingredient(name="Говядина", unit="kg", current_stock=10.0, cost_per_unit=80.0)
    bun = Ingredient(name="Булочка", unit="pcs", current_stock=50.0, cost_per_unit=2.0)
    db_session.add(beef)
    db_session.add(bun)
    await db_session.commit()
    await db_session.refresh(beef)
    await db_session.refresh(bun)

    # 3. Setup Menu Dish & Recipe (Cheeseburger: 0.15kg Beef + 1 Bun)
    burger = MenuItem(name="Чизбургер", price=35.0, type="dish", is_available=True, category_id=cat.id)
    db_session.add(burger)
    await db_session.commit()
    await db_session.refresh(burger)

    r1 = Recipe(menu_item_id=burger.id, ingredient_id=beef.id, quantity_required=0.15)
    r2 = Recipe(menu_item_id=burger.id, ingredient_id=bun.id, quantity_required=1.0)
    db_session.add(r1)
    db_session.add(r2)

    # 4. Open Shift
    shift = Shift(opened_by=user.id, opening_cash=100.0)
    db_session.add(shift)
    await db_session.commit()

    # 5. Order 2 Cheeseburgers
    order_payload = {
        "payment_method": "cash",
        "items": [
            {
                "menu_item_id": burger.id,
                "quantity": 2,
            }
        ]
    }
    resp = await async_client.post("/api/v1/orders/", json=order_payload, headers=headers)
    assert resp.status_code == 201, f"Failed with {resp.status_code}: {resp.text}"
    order_data = resp.json()
    assert order_data["total"] == 70.0

    # 6. Verify Ingredient Stocks
    # Expected beef: 10.0 - (0.15 * 2) = 9.70 kg
    # Expected bun: 50.0 - (1.0 * 2) = 48.0 pcs
    await db_session.refresh(beef)
    await db_session.refresh(bun)
    assert round(beef.current_stock, 2) == 9.70
    assert bun.current_stock == 48.0

    # 7. Verify Audit Trail (StockTransaction)
    txns = (await db_session.execute(select(StockTransaction))).scalars().all()
    assert len(txns) == 2
    for t in txns:
        assert t.type == StockTransactionType.AUTO_DEDUCTION
        assert t.quantity < 0


@pytest.mark.asyncio
async def test_retail_product_auto_deduction(async_client: AsyncClient, db_session):
    """
    E2E Test: Ordering a Retail piece product auto-deducts its stock directly.
    """
    # 1. Setup Tenant & User
    tenant = Tenant(name="Snack Bar", schema_name="public", is_active=True, enable_inventory_deduction=True)
    db_session.add(tenant)
    await db_session.commit()
    await db_session.refresh(tenant)

    role = Role(name="Admin", is_superuser=True, tenant_id=tenant.id)
    db_session.add(role)
    await db_session.commit()
    await db_session.refresh(role)

    user = User(
        tenant_id=tenant.id,
        username="cashier_alice",
        full_name="Alice Cashier",
        hashed_password="hash",
        is_active=True,
    )
    db_session.add(user)
    await db_session.commit()
    await db_session.refresh(user)

    user_role = UserRole(user_id=user.id, role_id=role.id)
    db_session.add(user_role)
    await db_session.commit()

    token = user_svc.create_access_token(
        user_id=user.id,
        tenant_id=tenant.id,
        permissions=["orders:create", "orders:view"],
        is_superuser=True,
    )
    headers = {"Authorization": f"Bearer {token}"}

    # 2. Setup Category & Retail Product (Coca Cola: 24 cans in stock)
    cat = MenuCategory(name="Напитки", category_type="retail")
    db_session.add(cat)
    await db_session.commit()
    await db_session.refresh(cat)

    retail_cola = RetailProduct(name="Coca-Cola 0.5", category_id=cat.id, current_stock=24.0, cost=5.0, price=10.0, unit="pcs")
    db_session.add(retail_cola)
    await db_session.commit()
    await db_session.refresh(retail_cola)

    menu_cola = MenuItem(
        name="Coca-Cola 0.5",
        price=10.0,
        type="retail",
        category_id=cat.id,
        retail_product_id=retail_cola.id,
        is_available=True
    )
    db_session.add(menu_cola)
    await db_session.commit()
    await db_session.refresh(menu_cola)

    # 3. Open Shift
    shift = Shift(opened_by=user.id, opening_cash=50.0)
    db_session.add(shift)
    await db_session.commit()

    # 4. Checkout 3 cans of Cola
    order_payload = {
        "payment_method": "card",
        "items": [
            {
                "menu_item_id": menu_cola.id,
                "quantity": 3,
            }
        ]
    }
    resp = await async_client.post("/api/v1/orders/", json=order_payload, headers=headers)
    assert resp.status_code == 201, f"Failed with {resp.status_code}: {resp.text}"

    # 5. Verify Stock Reduction (24.0 - 3 = 21.0)
    await db_session.refresh(retail_cola)
    assert retail_cola.current_stock == 21.0

    # 6. Verify Transaction
    txns = (await db_session.execute(
        select(StockTransaction).where(StockTransaction.retail_product_id == retail_cola.id)
    )).scalars().all()
    assert len(txns) == 1
    assert txns[0].quantity == -3.0
    assert txns[0].type == StockTransactionType.AUTO_DEDUCTION

    # 7. Verify GET /api/v1/inventory/retail/ endpoint
    retail_resp = await async_client.get("/api/v1/inventory/retail/", headers=headers)
    assert retail_resp.status_code == 200
    retail_list = retail_resp.json()
    assert any(p["name"] == "Coca-Cola 0.5" and p["current_stock"] == 21.0 for p in retail_list)


@pytest.mark.asyncio
async def test_disabled_inventory_deduction_flag(async_client: AsyncClient, db_session):
    """
    E2E Test: When enable_inventory_deduction is False, orders process without altering stock.
    """
    # 1. Setup Tenant with enable_inventory_deduction=False
    tenant = Tenant(name="Test Cafe", schema_name="public", is_active=True, enable_inventory_deduction=False)
    db_session.add(tenant)
    await db_session.commit()
    await db_session.refresh(tenant)

    role = Role(name="Admin", is_superuser=True, tenant_id=tenant.id)
    db_session.add(role)
    await db_session.commit()
    await db_session.refresh(role)

    user = User(
        tenant_id=tenant.id,
        username="cashier_charlie",
        full_name="Charlie Cashier",
        hashed_password="hash",
        is_active=True,
    )
    db_session.add(user)
    await db_session.commit()
    await db_session.refresh(user)

    user_role = UserRole(user_id=user.id, role_id=role.id)
    db_session.add(user_role)
    await db_session.commit()

    token = user_svc.create_access_token(
        user_id=user.id,
        tenant_id=tenant.id,
        permissions=["orders:create", "orders:view"],
        is_superuser=True,
    )
    headers = {"Authorization": f"Bearer {token}"}

    # 2. Setup Category, Ingredient & Dish
    cat = MenuCategory(name="Кофе", category_type="dish")
    db_session.add(cat)
    await db_session.commit()
    await db_session.refresh(cat)

    coffee_beans = Ingredient(name="Кофе зерновой", unit="kg", current_stock=5.0, cost_per_unit=120.0)
    db_session.add(coffee_beans)
    await db_session.commit()
    await db_session.refresh(coffee_beans)

    espresso = MenuItem(name="Эспрессо", price=12.0, type="dish", is_available=True, category_id=cat.id)
    db_session.add(espresso)
    await db_session.commit()
    await db_session.refresh(espresso)

    rec = Recipe(menu_item_id=espresso.id, ingredient_id=coffee_beans.id, quantity_required=0.018)
    db_session.add(rec)

    shift = Shift(opened_by=user.id, opening_cash=0.0)
    db_session.add(shift)
    await db_session.commit()

    # 3. Order 5 espressos
    order_payload = {
        "payment_method": "cash",
        "items": [{"menu_item_id": espresso.id, "quantity": 5}]
    }
    resp = await async_client.post("/api/v1/orders/", json=order_payload, headers=headers)
    assert resp.status_code == 201, f"Failed with {resp.status_code}: {resp.text}"

    # 4. Stock should NOT change
    await db_session.refresh(coffee_beans)
    assert coffee_beans.current_stock == 5.0

@pytest.mark.asyncio
async def test_get_recipes_summary(async_client: AsyncClient, db_session):
    """
    Test: GET /api/v1/inventory/recipes/summary returns correct aggregation.
    """
    tenant = Tenant(name="Recipe Summary Cafe", schema_name="public", is_active=True)
    db_session.add(tenant)
    await db_session.commit()
    await db_session.refresh(tenant)

    role = Role(name="Admin", is_superuser=True, tenant_id=tenant.id)
    db_session.add(role)
    await db_session.commit()
    await db_session.refresh(role)

    user = User(tenant_id=tenant.id, username="chef_summary", full_name="Chef", hashed_password="h", is_active=True)
    db_session.add(user)
    await db_session.commit()
    await db_session.refresh(user)

    user_role = UserRole(user_id=user.id, role_id=role.id)
    db_session.add(user_role)
    await db_session.commit()

    token = user_svc.create_access_token(
        user_id=user.id,
        tenant_id=tenant.id,
        permissions=["menu:view"],
        is_superuser=True,
    )
    headers = {"Authorization": f"Bearer {token}"}

    cat = MenuCategory(name="Бургеры", category_type="dish")
    db_session.add(cat)
    await db_session.commit()
    await db_session.refresh(cat)

    meat = Ingredient(name="Мясо", unit="kg", current_stock=10.0, cost_per_unit=50.0)
    db_session.add(meat)
    await db_session.commit()
    await db_session.refresh(meat)

    burger = MenuItem(name="Чизбургер", price=200.0, type="dish", is_available=True, category_id=cat.id)
    db_session.add(burger)
    await db_session.commit()
    await db_session.refresh(burger)

    rec = Recipe(menu_item_id=burger.id, ingredient_id=meat.id, quantity_required=0.2)
    db_session.add(rec)
    await db_session.commit()

    resp = await async_client.get("/api/v1/recipes/summary", headers=headers)
    assert resp.status_code == 200
    data = resp.json()
    assert len(data) >= 1
    found = next((x for x in data if x["menu_item_id"] == burger.id), None)
    assert found is not None
    assert found["has_recipe"] is True
    assert found["ingredients_count"] == 1
    assert found["total_cost"] == 10.0


@pytest.mark.asyncio
async def test_dish_variation_independent_recipe_deduction(async_client: AsyncClient, db_session):
    """
    E2E Test: Ordering a specific variation (e.g. S vs L) deducts the exact recipe
    configured for that variation's child MenuItem.
    """
    from app.inventory.services.menu_service import create_menu_item

    # 1. Setup Tenant & User
    tenant = Tenant(name="Coffee Shop", schema_name="public", is_active=True, enable_inventory_deduction=True)
    db_session.add(tenant)
    await db_session.commit()
    await db_session.refresh(tenant)

    role = Role(name="Admin", is_superuser=True, tenant_id=tenant.id)
    db_session.add(role)
    await db_session.commit()
    await db_session.refresh(role)

    user = User(tenant_id=tenant.id, username="barista_dan", full_name="Dan Barista", hashed_password="h", is_active=True)
    db_session.add(user)
    await db_session.commit()
    await db_session.refresh(user)

    user_role = UserRole(user_id=user.id, role_id=role.id)
    db_session.add(user_role)
    await db_session.commit()

    token = user_svc.create_access_token(
        user_id=user.id,
        tenant_id=tenant.id,
        permissions=["orders:create", "orders:view", "menu:view"],
        is_superuser=True,
    )
    headers = {"Authorization": f"Bearer {token}"}

    # 2. Setup Category & Raw Ingredients
    cat = MenuCategory(name="Кофе", category_type="dish")
    db_session.add(cat)
    await db_session.commit()
    await db_session.refresh(cat)

    coffee_beans = Ingredient(name="Зерно Бразилия", unit="kg", current_stock=10.0, cost_per_unit=100.0)
    milk = Ingredient(name="Молоко", unit="l", current_stock=10.0, cost_per_unit=10.0)
    db_session.add(coffee_beans)
    db_session.add(milk)
    await db_session.commit()
    await db_session.refresh(coffee_beans)
    await db_session.refresh(milk)

    # 3. Create Dish with Variations (S and L)
    parent_dish = await create_menu_item(db_session, {
        "name": "Капучино",
        "category_id": cat.id,
        "price": 15.0,
        "type": "dish",
        "attributes": {
            "variations": [
                {"name": "S", "price": 15.0},
                {"name": "L", "price": 25.0},
            ]
        }
    })
    await db_session.commit()
    await db_session.refresh(parent_dish)

    variations = parent_dish.attributes["variations"]
    assert len(variations) == 2
    s_child_id = variations[0]["id"]
    l_child_id = variations[1]["id"]
    assert s_child_id is not None
    assert l_child_id is not None

    # 4. Attach independent Recipes to child variations
    # S Recipe: 0.010 kg beans + 0.100 L milk
    r_s1 = Recipe(menu_item_id=s_child_id, ingredient_id=coffee_beans.id, quantity_required=0.01)
    r_s2 = Recipe(menu_item_id=s_child_id, ingredient_id=milk.id, quantity_required=0.10)
    # L Recipe: 0.020 kg beans + 0.250 L milk
    r_l1 = Recipe(menu_item_id=l_child_id, ingredient_id=coffee_beans.id, quantity_required=0.02)
    r_l2 = Recipe(menu_item_id=l_child_id, ingredient_id=milk.id, quantity_required=0.25)
    db_session.add_all([r_s1, r_s2, r_l1, r_l2])
    await db_session.commit()

    # 5. Open Shift
    shift = Shift(opened_by=user.id, opening_cash=50.0)
    db_session.add(shift)
    await db_session.commit()

    # 6. Order 2 Cappuccino L size
    import json
    order_payload = {
        "payment_method": "cash",
        "items": [
            {
                "menu_item_id": parent_dish.id,
                "quantity": 2,
                "options_json": json.dumps({
                    "variation": "L",
                    "child_item_id": l_child_id
                }),
                "unit_price_override": 25.0
            }
        ]
    }
    resp = await async_client.post("/api/v1/orders/", json=order_payload, headers=headers)
    assert resp.status_code == 201, f"Failed: {resp.text}"
    assert resp.json()["total"] == 50.0

    # 7. Verify Exact Stock Deduction for Size L:
    # Expected beans: 10.0 - (0.02 * 2) = 9.96 kg
    # Expected milk: 10.0 - (0.25 * 2) = 9.50 L
    await db_session.refresh(coffee_beans)
    await db_session.refresh(milk)
    assert round(coffee_beans.current_stock, 4) == 9.96
    assert round(milk.current_stock, 4) == 9.50

    # 8. Check Recipe Summary maps has_recipe: True to parent dish
    summary_resp = await async_client.get("/api/v1/recipes/summary", headers=headers)
    assert summary_resp.status_code == 200
    summary_list = summary_resp.json()
    parent_summary = next((x for x in summary_list if x["menu_item_id"] == parent_dish.id), None)
    assert parent_summary is not None
    assert parent_summary["has_recipe"] is True


@pytest.mark.asyncio
async def test_lock_stale_read_inventory_deduction(async_client: AsyncClient, db_session):
    """
    [LOCK-STALE-READ] Регрессионный тест: проверка выявления устаревшего чтения
    из Identity Map при параллельном изменении остатка.
    Ингредиент stock=10 + рецепт. В сессии A загружаем ингредиент и удерживаем ссылку.
    В отдельной сессии B ставим stock=8 и коммитим.
    В сессии A вызываем deduct_ingredients на 3 единицы.
    Ожидание: итоговый stock == 5 (а не 7).
    """
    from sqlalchemy.ext.asyncio import AsyncSession
    from app.inventory.services import deduct_ingredients

    # 1. Setup MenuCategory, Ingredient, MenuItem, Recipe
    cat = MenuCategory(name="Кухня", category_type="dish")
    db_session.add(cat)
    await db_session.commit()
    await db_session.refresh(cat)

    beef = Ingredient(name="Говядина", unit="kg", current_stock=10.0, cost_per_unit=80.0)
    db_session.add(beef)
    await db_session.commit()
    await db_session.refresh(beef)

    dish = MenuItem(name="Стейк", price=50.0, type="dish", is_available=True, category_id=cat.id)
    db_session.add(dish)
    await db_session.commit()
    await db_session.refresh(dish)

    recipe = Recipe(menu_item_id=dish.id, ingredient_id=beef.id, quantity_required=1.0)
    db_session.add(recipe)
    await db_session.commit()

    # 2. Сессия A: загружаем ингредиент и удерживаем ссылку (Identity Map)
    session_a = db_session
    ing_a = await session_a.get(Ingredient, beef.id)
    assert ing_a is not None
    assert ing_a.current_stock == 10.0
    await session_a.commit()

    # 3. Отдельная сессия B: ставим stock=8 и коммитим
    async with AsyncSession(bind=session_a.bind, expire_on_commit=False) as session_b:
        ing_b = await session_b.get(Ingredient, beef.id)
        assert ing_b is not None
        ing_b.current_stock = 8.0
        session_b.add(ing_b)
        await session_b.commit()

    # 4. В сессии A вызываем deduct_ingredients на 3 единицы
    order_items = [{"menu_item_id": dish.id, "quantity": 3}]
    await deduct_ingredients(session_a, order_items)
    await session_a.commit()

    # 5. Ожидание: итоговый stock == 5 (а не 7)
    await session_a.refresh(ing_a)
    assert ing_a.current_stock == 5.0
