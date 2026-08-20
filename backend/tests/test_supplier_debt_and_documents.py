import pytest
from httpx import AsyncClient
from sqlmodel import select
from app.users.models import Tenant, Role, User, UserRole
from app.users import services as user_svc
from app.inventory.models import (
    Supplier, InventoryDocument, Ingredient, DocumentType, DocumentStatus
)

@pytest.mark.asyncio
async def test_supplier_debt_lifecycle_and_payments(async_client: AsyncClient, db_session):
    """
    E2E Test:
    1. Create supplier
    2. Create & complete receive document with payment_status="unpaid" -> supplier balance becomes negative (debt).
    3. Record supplier payment -> supplier debt is reduced/cleared.
    4. Create & complete receive document with payment_status="paid" -> supplier balance unchanged.
    5. Create & complete receive document with payment_status="partial" -> only unpaid portion is added to debt.
    """
    # 1. Setup Tenant, Role, User & Auth Headers
    tenant = Tenant(name="Test Cafe", schema_name="public", is_active=True)
    db_session.add(tenant)
    await db_session.commit()
    await db_session.refresh(tenant)

    role = Role(name="Admin", is_superuser=True, tenant_id=tenant.id)
    db_session.add(role)
    await db_session.commit()
    await db_session.refresh(role)

    user = User(
        tenant_id=tenant.id,
        username="admin_test",
        full_name="Admin Test",
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
        permissions=["inventory:view", "inventory:manage"],
        is_superuser=True,
    )
    headers = {"Authorization": f"Bearer {token}"}

    # 2. Test Create Supplier
    resp = await async_client.post(
        "/api/v1/suppliers/",
        json={"name": "ООО Мясной Двор", "contact_info": "+996 555 123456"},
        headers=headers,
    )
    assert resp.status_code == 200, resp.text
    supplier_data = resp.json()
    supplier_id = supplier_data["id"]
    assert supplier_data["name"] == "ООО Мясной Двор"
    assert supplier_data["balance"] == 0.0

    # 3. Test Get Suppliers
    resp = await async_client.get("/api/v1/suppliers/", headers=headers)
    assert resp.status_code == 200
    suppliers = resp.json()
    assert len(suppliers) == 1
    assert suppliers[0]["id"] == supplier_id

    # 4. Setup Ingredient
    ing = Ingredient(name="Мясо говядина", unit="kg", current_stock=0.0, cost_per_unit=0.0)
    db_session.add(ing)
    await db_session.commit()
    await db_session.refresh(ing)

    # 5. Create Receive Document with "unpaid" (50 kg * 400 c = 20,000 c)
    doc_payload = {
        "type": "receipt",
        "supplier_id": supplier_id,
        "invoice_number": "INV-1001",
        "payment_status": "unpaid",
        "paid_amount": 0.0,
        "payment_method": "cash",
        "items": [
            {
                "ingredient_id": ing.id,
                "quantity": 50.0,
                "price_per_unit": 400.0,
                "total_price": 20000.0,
            }
        ],
    }
    resp = await async_client.post("/api/v1/documents/", json=doc_payload, headers=headers)
    assert resp.status_code == 200, resp.text
    doc_data = resp.json()
    doc_id = doc_data["id"]
    assert doc_data["total_amount"] == 20000.0
    assert doc_data["payment_status"] == "unpaid"

    # Complete Document -> Balance must decrease by 20,000
    resp = await async_client.post(f"/api/v1/documents/{doc_id}/complete", headers=headers)
    assert resp.status_code == 200, resp.text

    # Check Supplier Balance -> should be -20000.0
    resp = await async_client.get("/api/v1/suppliers/", headers=headers)
    suppliers = resp.json()
    sup = next(s for s in suppliers if s["id"] == supplier_id)
    assert sup["balance"] == -20000.0

    # 6. Record Supplier Payment (Pay 15,000 c)
    resp = await async_client.post(
        f"/api/v1/suppliers/{supplier_id}/payments",
        json={"amount": 15000.0, "payment_method": "cash", "comment": "Частичная оплата по накладной INV-1001"},
        headers=headers,
    )
    assert resp.status_code == 200, resp.text
    assert resp.json()["amount"] == 15000.0

    # Verify Supplier balance is now -5,000 c
    resp = await async_client.get("/api/v1/suppliers/", headers=headers)
    suppliers = resp.json()
    sup = next(s for s in suppliers if s["id"] == supplier_id)
    assert sup["balance"] == -5000.0

    # 7. Create Receive Document with "paid" in full (10 kg * 400 c = 4,000 c)
    doc_paid_payload = {
        "type": "receipt",
        "supplier_id": supplier_id,
        "invoice_number": "INV-1002",
        "payment_status": "paid",
        "paid_amount": 4000.0,
        "payment_method": "bank_transfer",
        "items": [
            {
                "ingredient_id": ing.id,
                "quantity": 10.0,
                "price_per_unit": 400.0,
                "total_price": 4000.0,
            }
        ],
    }
    resp = await async_client.post("/api/v1/documents/", json=doc_paid_payload, headers=headers)
    assert resp.status_code == 200
    paid_doc_id = resp.json()["id"]

    await async_client.post(f"/api/v1/documents/{paid_doc_id}/complete", headers=headers)

    # Balance should still be -5000.0 because it was paid in full
    resp = await async_client.get("/api/v1/suppliers/", headers=headers)
    sup = next(s for s in resp.json() if s["id"] == supplier_id)
    assert sup["balance"] == -5000.0

    # 8. Create Receive Document with "partial" payment (10,000 c total, 3,000 c paid, 7,000 c debt)
    doc_partial_payload = {
        "type": "receipt",
        "supplier_id": supplier_id,
        "invoice_number": "INV-1003",
        "payment_status": "partial",
        "paid_amount": 3000.0,
        "payment_method": "card",
        "items": [
            {
                "ingredient_id": ing.id,
                "quantity": 25.0,
                "price_per_unit": 400.0,
                "total_price": 10000.0,
            }
        ],
    }
    resp = await async_client.post("/api/v1/documents/", json=doc_partial_payload, headers=headers)
    assert resp.status_code == 200
    partial_doc_id = resp.json()["id"]

    await async_client.post(f"/api/v1/documents/{partial_doc_id}/complete", headers=headers)

    # Balance: -5000 - 7000 = -12000.0
    resp = await async_client.get("/api/v1/suppliers/", headers=headers)
    sup = next(s for s in resp.json() if s["id"] == supplier_id)
    assert sup["balance"] == -12000.0

    # 9. Pay remaining 12,000 c to clear debt completely
    resp = await async_client.post(
        f"/api/v1/suppliers/{supplier_id}/payments",
        json={"amount": 12000.0, "payment_method": "bank_transfer"},
        headers=headers,
    )
    assert resp.status_code == 200
    assert resp.json()["amount"] == 12000.0

    resp = await async_client.get("/api/v1/suppliers/", headers=headers)
    sup = next(s for s in resp.json() if s["id"] == supplier_id)
    assert sup["balance"] == 0.0
