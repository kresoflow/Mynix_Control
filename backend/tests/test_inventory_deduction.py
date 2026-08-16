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
