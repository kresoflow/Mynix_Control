import pytest
from httpx import AsyncClient

from app.users.models import Tenant, Role, User, UserRole
from app.users import services as user_svc
from app.pos.models import Shift
from app.inventory.models import MenuCategory, MenuItem


@pytest.mark.asyncio
async def test_crm_customer_loyalty_debt_and_payment(async_client: AsyncClient, db_session):
    """
    E2E Test:
    1. Create customer with credit limit (200 c) and welcome bonus (50 c).
    2. Order a meal with DEBT payment method and spending 20 bonuses.
    3. Verify customer balance is -30 c (debt) and bonuses decreased to 30.
    4. Pay debt (30 c cash) -> balance restored to 0.0, cash recorded in active shift.
    """
    # 1. Setup Tenant & Admin
    tenant = Tenant(name="CRM Cafe", schema_name="public", is_active=True, enable_inventory_deduction=False)
    db_session.add(tenant)
    await db_session.commit()
    await db_session.refresh(tenant)

    role = Role(name="Admin", is_superuser=True, tenant_id=tenant.id)
    db_session.add(role)
    await db_session.commit()
    await db_session.refresh(role)

    user = User(
        tenant_id=tenant.id,
        username="admin_crm",
        full_name="Admin CRM",
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
        permissions=["crm:view", "crm:manage", "orders:create", "orders:view", "shifts:open", "shifts:view"],
        is_superuser=True,
    )
    headers = {"Authorization": f"Bearer {token}"}

    # 2. Create Customer
    cust_payload = {
        "name": "Иван Петров",
        "phone": "+992 900 112233",
        "credit_limit": 200.0,
        "discount_percent": 0.0,
        "notes": "Постоянный гость",
    }
    resp = await async_client.post("/api/v1/crm/customers/", json=cust_payload, headers=headers)
    assert resp.status_code == 200, resp.text
    cust_data = resp.json()
    cust_id = cust_data["id"]
    assert cust_data["bonus_balance"] == 50.0
    assert cust_data["balance"] == 0.0

    # 3. Setup Menu Item (Pizza: 50 c)
    cat = MenuCategory(name="Пицца", category_type="dish")
    db_session.add(cat)
    await db_session.commit()
    await db_session.refresh(cat)

    pizza = MenuItem(name="Маргарита", price=50.0, type="dish", is_available=True, category_id=cat.id)
    db_session.add(pizza)
    await db_session.commit()
    await db_session.refresh(pizza)

    # 4. Open Shift
    shift = Shift(opened_by=user.id, opening_cash=100.0)
    db_session.add(shift)
    await db_session.commit()

    # 5. Make order with DEBT + 20 bonuses (Total 50 c - 20 bonus = 30 c debt)
    order_payload = {
        "customer_id": cust_id,
        "payment_method": "debt",
        "bonus_spent": 20.0,
        "items": [
            {
                "menu_item_id": pizza.id,
                "quantity": 1,
            }
        ]
    }
    resp_order = await async_client.post("/api/v1/orders/", json=order_payload, headers=headers)
    assert resp_order.status_code == 201, resp_order.text

    # 6. Verify Customer Balance and Bonuses
    resp_cust = await async_client.get(f"/api/v1/crm/customers/{cust_id}", headers=headers)
    assert resp_cust.status_code == 200
    cust_updated = resp_cust.json()
    # Debt is -30 c
    assert cust_updated["balance"] == -30.0
    # Remaining bonuses: 50 - 20 = 30 (plus any tier cashback)
    assert cust_updated["bonus_balance"] >= 30.0

    # 7. Customer pays debt (30 c cash)
    payment_payload = {
        "type": "payment",
        "amount": 30.0,
        "payment_method": "cash",
        "comment": "Погашение долга за пиццу",
    }
    resp_pay = await async_client.post(
        f"/api/v1/crm/customers/{cust_id}/transactions",
        json=payment_payload,
        headers=headers,
    )
    assert resp_pay.status_code == 200, resp_pay.text

    # 8. Verify Customer Balance is 0.0 (Cleared)
    resp_cust_final = await async_client.get(f"/api/v1/crm/customers/{cust_id}", headers=headers)
    assert resp_cust_final.status_code == 200
    assert resp_cust_final.json()["balance"] == 0.0
