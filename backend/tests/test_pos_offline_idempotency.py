import pytest
from httpx import AsyncClient
from sqlmodel import select

from app.users.models import Tenant, Role, User, UserRole
from app.users import services as user_svc
from app.inventory.models import MenuItem, Ingredient, Recipe, MenuCategory
from app.pos.models import Shift, Order


@pytest.mark.asyncio
async def test_pos_checkout_idempotency_and_offline_client_uuid(async_client: AsyncClient, db_session):
    """
    E2E Test:
    1. Create tenant, open cash shift, create burger with recipe (2.0 pcs patty).
    2. Submit offline order with client_uuid = "offline-uuid-1".
    3. Verify order is created, cash is recorded, 2.0 patty deducted from stock.
    4. Re-submit the exact same order with client_uuid = "offline-uuid-1" (simulating network retry).
    5. Verify server returns 200/201 without creating a second order or double deducting ingredients/cash!
    6. Submit different order with client_uuid = "offline-uuid-2" -> successfully creates second order.
    """
    # 1. Setup Tenant & User
    tenant = Tenant(name="Burger Fastfood", schema_name="public", is_active=True, use_kds=False, enable_inventory_deduction=True)
    db_session.add(tenant)
    await db_session.commit()
    await db_session.refresh(tenant)

    role = Role(name="Cashier Admin", is_superuser=True, tenant_id=tenant.id)
    db_session.add(role)
    await db_session.commit()
    await db_session.refresh(role)

    user = User(
        tenant_id=tenant.id,
        username="fastfood_cashier",
        full_name="Cashier Bob",
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
        permissions=["shifts:open", "orders:create", "orders:view", "inventory:view"],
        is_superuser=True,
    )
    headers = {"Authorization": f"Bearer {token}"}

    # 2. Open Cash Shift
    shift = Shift(opened_by=user.id, opening_cash=1000.0, is_open=True)
    db_session.add(shift)
    await db_session.commit()
    await db_session.refresh(shift)

    # 3. Create Ingredient & Menu Item
    cat = MenuCategory(name="Meat", category_type="dish", is_visible=True)
    db_session.add(cat)
    await db_session.commit()
    await db_session.refresh(cat)

    patty = Ingredient(name="Beef Patty", unit="pcs", current_stock=50.0, cost_per_unit=100.0)
    db_session.add(patty)
    await db_session.commit()
    await db_session.refresh(patty)

    burger = MenuItem(name="Double Beef Burger", price=250.0, is_available=True, type="dish", category_id=cat.id)
    db_session.add(burger)
    await db_session.commit()
    await db_session.refresh(burger)

    recipe = Recipe(menu_item_id=burger.id, ingredient_id=patty.id, quantity_required=2.0)
    db_session.add(recipe)
    await db_session.commit()

    # 4. First checkout with client_uuid = "offline-uuid-101"
    client_uuid_1 = "offline-uuid-101"
    order_payload = {
        "client_uuid": client_uuid_1,
        "items": [
            {"menu_item_id": burger.id, "quantity": 1}
        ],
        "payment_method": "cash",
        "note": "Fastfood takeaway",
    }

    resp1 = await async_client.post(
        "/api/v1/orders/",
        json=order_payload,
        headers=headers,
    )
    assert resp1.status_code == 201, resp1.text
    data1 = resp1.json()
    order1_id = data1["id"]
    assert data1["client_uuid"] == client_uuid_1
    assert data1["total"] == 250.0

    # Verify inventory was deducted: 50.0 - 2.0 = 48.0
    await db_session.refresh(patty)
    assert patty.current_stock == 48.0

    # 5. Retry the exact same checkout with client_uuid = "offline-uuid-101" (Network Retry)
    resp2 = await async_client.post(
        "/api/v1/orders/",
        json=order_payload,
        headers=headers,
    )
    assert resp2.status_code == 201, resp2.text
    data2 = resp2.json()
    # MUST return the same existing order ID!
    assert data2["id"] == order1_id
    assert data2["client_uuid"] == client_uuid_1

    # Verify inventory WAS NOT double deducted (still 48.0)
    await db_session.refresh(patty)
    assert patty.current_stock == 48.0

    # Verify total orders in DB is 1, not 2
    orders = (await db_session.execute(select(Order))).scalars().all()
    assert len(orders) == 1

    # 6. Now create a SECOND distinct order with client_uuid = "offline-uuid-102"
    client_uuid_2 = "offline-uuid-102"
    order_payload_2 = {
        "client_uuid": client_uuid_2,
        "items": [
            {"menu_item_id": burger.id, "quantity": 2}
        ],
        "payment_method": "cash",
    }

    resp3 = await async_client.post(
        "/api/v1/orders/",
        json=order_payload_2,
        headers=headers,
    )
    assert resp3.status_code == 201, resp3.text
    data3 = resp3.json()
    assert data3["id"] != order1_id
    assert data3["client_uuid"] == client_uuid_2
    assert data3["total"] == 500.0

    # Inventory deducted again: 48.0 - (2 * 2.0) = 44.0
    await db_session.refresh(patty)
    assert patty.current_stock == 44.0

    # Total orders in DB is now 2
    orders_final = (await db_session.execute(select(Order))).scalars().all()
    assert len(orders_final) == 2
