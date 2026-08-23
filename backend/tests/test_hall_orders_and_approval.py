import pytest
from httpx import AsyncClient
from sqlmodel import select

from app.users.models import Tenant, Role, User, UserRole
from app.users import services as user_svc
from app.inventory.models import MenuItem, Ingredient, Recipe, MenuCategory
from app.pos.models import Shift, Order, OrderStatus


@pytest.mark.asyncio
async def test_hall_orders_approval_and_deferred_deduction(async_client: AsyncClient, db_session):
    """
    E2E Test:
    1. Waiter submits order from Table 4 (order_source='waiter', table_number='Стол 4').
    2. Check that order status is PENDING_APPROVAL and stock is NOT deducted yet.
    3. Cashier calls POST /api/v1/orders/{id}/approve.
    4. Verify status becomes COOKING/COMPLETED and stock is now deducted.
    5. Waiter submits second order from Table 5.
    6. Cashier calls POST /api/v1/orders/{id}/reject -> status CANCELLED, stock NOT deducted.
    """
    # 1. Setup Tenant & Users
    tenant = Tenant(name="Café Hall", schema_name="public", is_active=True, use_kds=False, enable_inventory_deduction=True)
    db_session.add(tenant)
    await db_session.commit()
    await db_session.refresh(tenant)

    role = Role(name="Super Admin", is_superuser=True, tenant_id=tenant.id)
    db_session.add(role)
    await db_session.commit()
    await db_session.refresh(role)

    cashier = User(tenant_id=tenant.id, username="cashier_alice", full_name="Alice Cashier", hashed_password="hash", is_active=True)
    db_session.add(cashier)
    await db_session.commit()
    await db_session.refresh(cashier)

    db_session.add(UserRole(user_id=cashier.id, role_id=role.id))
    await db_session.commit()

    token = user_svc.create_access_token(
        user_id=cashier.id,
        tenant_id=tenant.id,
        permissions=["shifts:open", "orders:create", "orders:view", "orders:edit", "orders:cancel", "inventory:view"],
        is_superuser=True,
    )
    headers = {"Authorization": f"Bearer {token}"}

    # 2. Open Shift
    shift = Shift(opened_by=cashier.id, opening_cash=500.0, is_open=True)
    db_session.add(shift)
    await db_session.commit()
    await db_session.refresh(shift)

    # 3. Setup Dish with Ingredient
    cat = MenuCategory(name="Горячее", icon="ramen_dining")
    db_session.add(cat)
    await db_session.commit()
    await db_session.refresh(cat)

    from app.inventory.models.enums import UnitType
    meat = Ingredient(name="Говядина", unit=UnitType.KG, current_stock=10.0, cost_per_unit=400.0, min_stock_alert=2.0)
    db_session.add(meat)
    await db_session.commit()
    await db_session.refresh(meat)

    steak = MenuItem(category_id=cat.id, name="Стейк Рибай", price=850.0, type="dish", is_available=True)
    db_session.add(steak)
    await db_session.commit()
    await db_session.refresh(steak)

    db_session.add(Recipe(menu_item_id=steak.id, ingredient_id=meat.id, quantity_required=0.3)) # 300g per steak
    await db_session.commit()

    # 4. Waiter submits order from Table 4 (order_source = 'waiter')
    order_payload = {
        "items": [{"menu_item_id": steak.id, "quantity": 2}],
        "payment_method": "cash",
        "table_number": "Стол 4",
        "order_source": "waiter",
        "note": "Без соли, прожарка Medium",
    }
    resp = await async_client.post("/api/v1/orders/", json=order_payload, headers=headers)
    assert resp.status_code == 201, resp.text
    order_data = resp.json()
    order_id = order_data["id"]
    assert order_data["status"] == OrderStatus.PENDING_APPROVAL.value
    assert order_data["table_number"] == "Стол 4"
    assert order_data["order_source"] == "waiter"

    # Verify stock is still 10.0 (NOT deducted yet)
    await db_session.refresh(meat)
    assert meat.current_stock == 10.0

    # 5. Cashier approves order
    approve_resp = await async_client.post(f"/api/v1/orders/{order_id}/approve", json={"is_paid": True}, headers=headers)
    assert approve_resp.status_code == 200, approve_resp.text
    approved_data = approve_resp.json()
    assert approved_data["status"] in (OrderStatus.COOKING.value, OrderStatus.COMPLETED.value)

    # Verify stock is now deducted (10.0 - 2 * 0.3 = 9.4)
    await db_session.refresh(meat)
    assert round(meat.current_stock, 2) == 9.40

    # 6. Waiter submits second order from Table 5
    order_payload_2 = {
        "items": [{"menu_item_id": steak.id, "quantity": 1}],
        "payment_method": "card",
        "table_number": "Стол 5",
        "order_source": "waiter",
    }
    resp2 = await async_client.post("/api/v1/orders/", json=order_payload_2, headers=headers)
    assert resp2.status_code == 201
    order_2_id = resp2.json()["id"]

    # Cashier rejects second order
    reject_resp = await async_client.post(f"/api/v1/orders/{order_2_id}/reject", json={"reason": "Мясо закончилось"}, headers=headers)
    assert reject_resp.status_code == 200
    rejected_data = reject_resp.json()
    assert rejected_data["status"] == OrderStatus.CANCELLED.value

    # Verify stock remains 9.40 (no deduction)
    await db_session.refresh(meat)
    assert round(meat.current_stock, 2) == 9.40
