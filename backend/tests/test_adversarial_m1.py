import pytest
from httpx import AsyncClient
from sqlmodel import select
from app.users.models import Tenant, Role, User, UserRole
from app.users import services as user_svc
from app.inventory.models import (
    MenuItem, RetailProduct, Ingredient, StockTransaction,
    InventoryDocument, InventoryDocumentItem, DocumentType, DocumentStatus
)

@pytest.fixture
async def auth_setup(db_session):
    tenant = Tenant(name="Adversarial Test Tenant", schema_name="public", is_active=True)
    db_session.add(tenant)
    await db_session.commit()
    await db_session.refresh(tenant)

    role = Role(name="Admin", is_superuser=True, tenant_id=tenant.id)
    db_session.add(role)
    await db_session.commit()
    await db_session.refresh(role)

    user = User(
        tenant_id=tenant.id,
        username="adv_admin",
        full_name="Adversarial Admin",
        hashed_password="hash",
        is_active=True,
    )
    db_session.add(user)
    await db_session.commit()
    await db_session.refresh(user)

    user_role = UserRole(user_id=user.id, role_id=role.id)
    db_session.add(user_role)
    await db_session.commit()

    admin_token = user_svc.create_access_token(
        user_id=user.id,
        tenant_id=tenant.id,
        permissions=[
            "menu:create", "menu:manage", "menu:view",
            "inventory:create", "inventory:manage", "inventory:view"
        ],
        is_superuser=True,
    )

    staff_user = User(
        tenant_id=tenant.id,
        username="adv_staff",
        full_name="Adversarial Staff",
        hashed_password="hash",
        is_active=True,
    )
    db_session.add(staff_user)
    await db_session.commit()
    await db_session.refresh(staff_user)

    staff_token = user_svc.create_access_token(
        user_id=staff_user.id,
        tenant_id=tenant.id,
        permissions=["menu:view", "inventory:view"],
        is_superuser=False,
    )

    return {
        "tenant": tenant,
        "user": user,
        "admin_headers": {"Authorization": f"Bearer {admin_token}"},
        "staff_headers": {"Authorization": f"Bearer {staff_token}"},
    }

# ---------------------------------------------------------------------------
# Edge Case 1: Empty list payload [] to bulk endpoints
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_bulk_endpoints_empty_list(async_client: AsyncClient, db_session, auth_setup):
    headers = auth_setup["admin_headers"]

    # 1. /menu/bulk with []
    resp = await async_client.post("/api/v1/menu/bulk", json=[], headers=headers)
    assert resp.status_code == 201, resp.text
    assert resp.json() == []

    # 2. /retail-product/bulk with []
    resp = await async_client.post("/api/v1/retail-product/bulk", json=[], headers=headers)
    assert resp.status_code == 201, resp.text
    assert resp.json() == []

    # 3. /ingredients/bulk with []
    resp = await async_client.post("/api/v1/ingredients/bulk", json=[], headers=headers)
    assert resp.status_code == 201, resp.text
    assert resp.json() == []

    # Verify zero records created in DB
    menu_count = len((await db_session.execute(select(MenuItem))).scalars().all())
    retail_count = len((await db_session.execute(select(RetailProduct))).scalars().all())
    ing_count = len((await db_session.execute(select(Ingredient))).scalars().all())
    txn_count = len((await db_session.execute(select(StockTransaction))).scalars().all())

    assert menu_count == 0
    assert retail_count == 0
    assert ing_count == 0
    assert txn_count == 0

# ---------------------------------------------------------------------------
# Edge Case 2: Batch of 50 items
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_bulk_create_50_items_batch(async_client: AsyncClient, db_session, auth_setup):
    headers = auth_setup["admin_headers"]

    # 1. 50 Dishes batch (some with variations)
    dish_payload = [
        {
            "name": f"Dish Batch Item {i:02d}",
            "price": 100.0 + i * 5,
            "type": "dish",
            "attributes": {
                "variations": [
                    {"name": "Standard", "price": 100.0 + i * 5},
                    {"name": "Large", "price": 150.0 + i * 5},
                ]
            } if i % 5 == 0 else {}
        }
        for i in range(1, 51)
    ]
    resp_dishes = await async_client.post("/api/v1/menu/bulk", json=dish_payload, headers=headers)
    assert resp_dishes.status_code == 201, resp_dishes.text
    dishes_data = resp_dishes.json()
    assert len(dishes_data) == 50

    # Verify DB has exactly 50 parent dishes
    parent_dishes = (await db_session.execute(
        select(MenuItem).where(MenuItem.parent_id.is_(None), MenuItem.type == "dish")
    )).scalars().all()
    assert len(parent_dishes) == 50

    # 2. 50 Retail Products batch
    retail_payload = [
        {
            "name": f"Retail Batch Item {i:02d}",
            "unit": "pcs",
            "purchase_price": 25.0 + i,
            "selling_price": 50.0 + i * 2,
            "barcode": f"460000000{i:03d}",
            "initial_stock": float(i * 10),  # Must be ignored!
        }
        for i in range(1, 51)
    ]
    resp_retail = await async_client.post("/api/v1/retail-product/bulk", json=retail_payload, headers=headers)
    assert resp_retail.status_code == 201, resp_retail.text
    retail_data = resp_retail.json()
    assert len(retail_data) == 50

    # Verify all 50 have current_stock == 0.0
    for item in retail_data:
        assert item["current_stock"] == 0.0

    retail_in_db = (await db_session.execute(select(RetailProduct))).scalars().all()
    assert len(retail_in_db) == 50
    for r in retail_in_db:
        assert r.current_stock == 0.0

    # Verify 50 matching retail MenuItems were created
    menu_retail = (await db_session.execute(select(MenuItem).where(MenuItem.type == "retail"))).scalars().all()
    assert len(menu_retail) == 50

    # 3. 50 Raw Ingredients batch
    ing_payload = [
        {
            "name": f"Raw Ingredient {i:02d}",
            "unit": "kg" if i % 2 == 0 else "l",
            "cost_per_unit": 50.0 + i * 3,
            "barcode": f"200000000{i:03d}",
            "initial_stock": float(i * 5),  # Must be ignored!
        }
        for i in range(1, 51)
    ]
    resp_ing = await async_client.post("/api/v1/ingredients/bulk", json=ing_payload, headers=headers)
    assert resp_ing.status_code == 201, resp_ing.text
    ing_data = resp_ing.json()
    assert len(ing_data) == 50

    for item in ing_data:
        assert item["current_stock"] == 0.0

    ing_in_db = (await db_session.execute(select(Ingredient))).scalars().all()
    assert len(ing_in_db) == 50
    for ing in ing_in_db:
        assert ing.current_stock == 0.0

    # Absolute stock transaction integrity: ZERO transactions created across all 150 items
    txns = (await db_session.execute(select(StockTransaction))).scalars().all()
    assert len(txns) == 0

# ---------------------------------------------------------------------------
# Edge Case 3: Sending initial_stock: 500 — verify physical stock remains 0.0
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_initial_stock_500_prohibited(async_client: AsyncClient, db_session, auth_setup):
    headers = auth_setup["admin_headers"]

    # 1. Retail Product bulk create with initial_stock: 500
    retail_payload = [
        {
            "name": "Super Juice 1L",
            "unit": "pcs",
            "purchase_price": 80.0,
            "selling_price": 160.0,
            "initial_stock": 500.0,
        },
        {
            "name": "Energy Drink 0.5L",
            "unit": "pcs",
            "purchase_price": 60.0,
            "selling_price": 120.0,
            "initial_stock": 500.0,
        }
    ]
    resp = await async_client.post("/api/v1/retail-product/bulk", json=retail_payload, headers=headers)
    assert resp.status_code == 201, resp.text
    for item in resp.json():
        assert item["current_stock"] == 0.0
        # Check DB directly
        rp_db = await db_session.get(RetailProduct, item["id"])
        await db_session.refresh(rp_db)
        assert rp_db.current_stock == 0.0

    # 2. Ingredient bulk create with initial_stock: 500
    ing_payload = [
        {
            "name": "Coffee Beans Arabica",
            "unit": "kg",
            "cost_per_unit": 1500.0,
            "initial_stock": 500.0,
        },
        {
            "name": "Organic Milk",
            "unit": "l",
            "cost_per_unit": 85.0,
            "initial_stock": 500.0,
        }
    ]
    resp_ing = await async_client.post("/api/v1/ingredients/bulk", json=ing_payload, headers=headers)
    assert resp_ing.status_code == 201, resp_ing.text
    for item in resp_ing.json():
        assert item["current_stock"] == 0.0
        ing_db = await db_session.get(Ingredient, item["id"])
        await db_session.refresh(ing_db)
        assert ing_db.current_stock == 0.0

    # 3. Verify zero StockTransactions exist in database
    txns = (await db_session.execute(select(StockTransaction))).scalars().all()
    assert len(txns) == 0

# ---------------------------------------------------------------------------
# Edge Case 4: Document completion with non-existent item IDs (400 Bad Request)
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_document_completion_with_nonexistent_ids(async_client: AsyncClient, db_session, auth_setup):
    headers = auth_setup["admin_headers"]

    # Test Case 4A: Receipt document with non-existent ingredient_id
    receipt_doc_ing = {
        "type": "receipt",
        "status": "draft",
        "date": "2026-09-14",
        "items": [
            {
                "ingredient_id": 999999,
                "quantity": 10.0,
                "price_per_unit": 50.0,
                "total_price": 500.0,
            }
        ]
    }
    r_resp = await async_client.post("/api/v1/documents/", json=receipt_doc_ing, headers=headers)
    assert r_resp.status_code == 200
    doc_id = r_resp.json()["id"]

    complete_resp = await async_client.post(f"/api/v1/documents/{doc_id}/complete", headers=headers)
    assert complete_resp.status_code == 400
    assert "999999" in complete_resp.text or "not found" in complete_resp.text.lower()

    # Test Case 4B: Receipt document with non-existent retail_product_id
    receipt_doc_ret = {
        "type": "receipt",
        "status": "draft",
        "date": "2026-09-14",
        "items": [
            {
                "retail_product_id": 888888,
                "quantity": 5.0,
                "price_per_unit": 100.0,
                "total_price": 500.0,
            }
        ]
    }
    r_resp2 = await async_client.post("/api/v1/documents/", json=receipt_doc_ret, headers=headers)
    assert r_resp2.status_code == 200
    doc_id2 = r_resp2.json()["id"]

    complete_resp2 = await async_client.post(f"/api/v1/documents/{doc_id2}/complete", headers=headers)
    assert complete_resp2.status_code == 400
    assert "888888" in complete_resp2.text or "not found" in complete_resp2.text.lower()

    # Test Case 4C: Write-off document with non-existent ingredient_id
    writeoff_doc = {
        "type": "write_off",
        "status": "draft",
        "reason": "Expired items",
        "date": "2026-09-14",
        "items": [
            {
                "ingredient_id": 777777,
                "quantity": 2.0,
                "price_per_unit": 50.0,
            }
        ]
    }
    w_resp = await async_client.post("/api/v1/documents/", json=writeoff_doc, headers=headers)
    assert w_resp.status_code == 200
    doc_id3 = w_resp.json()["id"]

    complete_resp3 = await async_client.post(f"/api/v1/documents/{doc_id3}/complete", headers=headers)
    assert complete_resp3.status_code == 400
    assert "777777" in complete_resp3.text or "not found" in complete_resp3.text.lower()

    # Test Case 4D: Inventory audit document with non-existent retail_product_id
    inv_doc = {
        "type": "inventory",
        "status": "draft",
        "date": "2026-09-14",
        "items": [
            {
                "retail_product_id": 666666,
                "quantity": 15.0,
                "expected_quantity": 10.0,
            }
        ]
    }
    i_resp = await async_client.post("/api/v1/documents/", json=inv_doc, headers=headers)
    assert i_resp.status_code == 200
    doc_id4 = i_resp.json()["id"]

    complete_resp4 = await async_client.post(f"/api/v1/documents/{doc_id4}/complete", headers=headers)
    assert complete_resp4.status_code == 400
    assert "666666" in complete_resp4.text or "not found" in complete_resp4.text.lower()

# ---------------------------------------------------------------------------
# Edge Case 5: Document completion atomicity & double-completion protection
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_document_completion_atomicity_and_double_complete(async_client: AsyncClient, db_session, auth_setup):
    headers = auth_setup["admin_headers"]

    # 1. Create a real ingredient with current_stock = 0.0
    ing_resp = await async_client.post("/api/v1/ingredients/", json={
        "name": "Vanilla Syrup",
        "unit": "l",
        "cost_per_unit": 400.0,
    }, headers=headers)
    assert ing_resp.status_code == 201
    real_ing_id = ing_resp.json()["id"]

    # 2. Create document with 1 valid item AND 1 non-existent item (poison pill)
    poison_doc_payload = {
        "type": "receipt",
        "status": "draft",
        "date": "2026-09-14",
        "items": [
            {
                "ingredient_id": real_ing_id,
                "quantity": 10.0,
                "price_per_unit": 400.0,
                "total_price": 4000.0,
            },
            {
                "ingredient_id": 999111,  # Non-existent poison pill
                "quantity": 5.0,
                "price_per_unit": 200.0,
                "total_price": 1000.0,
            }
        ]
    }
    poison_doc = await async_client.post("/api/v1/documents/", json=poison_doc_payload, headers=headers)
    assert poison_doc.status_code == 200
    poison_doc_id = poison_doc.json()["id"]

    # Complete must fail with 400
    fail_complete = await async_client.post(f"/api/v1/documents/{poison_doc_id}/complete", headers=headers)
    assert fail_complete.status_code == 400

    # Atomicity check: Real ingredient stock must still be 0.0
    ing_check = await db_session.get(Ingredient, real_ing_id)
    await db_session.refresh(ing_check)
    assert ing_check.current_stock == 0.0

    # Document must NOT be marked COMPLETED
    doc_check = await db_session.get(InventoryDocument, poison_doc_id)
    await db_session.refresh(doc_check)
    assert doc_check.status == DocumentStatus.DRAFT

    # Zero stock transactions created
    txns = (await db_session.execute(select(StockTransaction))).scalars().all()
    assert len(txns) == 0

    # 3. Double-completion check: Complete a clean document, then attempt to complete it again
    clean_doc_payload = {
        "type": "receipt",
        "status": "draft",
        "date": "2026-09-14",
        "items": [
            {
                "ingredient_id": real_ing_id,
                "quantity": 10.0,
                "price_per_unit": 400.0,
                "total_price": 4000.0,
            }
        ]
    }
    clean_doc = await async_client.post("/api/v1/documents/", json=clean_doc_payload, headers=headers)
    clean_doc_id = clean_doc.json()["id"]

    first_complete = await async_client.post(f"/api/v1/documents/{clean_doc_id}/complete", headers=headers)
    assert first_complete.status_code == 200
    assert first_complete.json()["status"] == "completed"

    # Second completion attempt must raise 400 "already completed"
    second_complete = await async_client.post(f"/api/v1/documents/{clean_doc_id}/complete", headers=headers)
    assert second_complete.status_code == 400
    assert "already completed" in second_complete.text.lower()
