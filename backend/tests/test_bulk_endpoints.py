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
    tenant = Tenant(name="Bulk Test Tenant", schema_name="public", is_active=True)
    db_session.add(tenant)
    await db_session.commit()
    await db_session.refresh(tenant)

    role = Role(name="Admin", is_superuser=True, tenant_id=tenant.id)
    db_session.add(role)
    await db_session.commit()
    await db_session.refresh(role)

    user = User(
        tenant_id=tenant.id,
        username="bulk_admin",
        full_name="Bulk Admin",
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
        permissions=["menu:create", "menu:manage", "menu:view", "inventory:create", "inventory:manage", "inventory:view"],
        is_superuser=True,
    )

    # Regular staff token without create permissions
    staff_user = User(
        tenant_id=tenant.id,
        username="staff_user",
        full_name="Staff User",
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

@pytest.mark.asyncio
async def test_bulk_create_menu_items_pbac_and_variations(async_client: AsyncClient, db_session, auth_setup):
    admin_headers = auth_setup["admin_headers"]
    staff_headers = auth_setup["staff_headers"]

    payload = [
        {
            "name": "Капучино",
            "price": 200.0,
            "type": "dish",
            "attributes": {
                "variations": [
                    {"name": "0.3л", "price": 200.0},
                    {"name": "0.5л", "price": 250.0},
                ]
            }
        },
        {
            "name": "Американо",
            "price": 150.0,
            "type": "dish",
        }
    ]

    # 1. PBAC Test: staff without menu:create is rejected with 403
    forbidden_resp = await async_client.post("/api/v1/menu/bulk", json=payload, headers=staff_headers)
    assert forbidden_resp.status_code == 403

    # 2. Success Test: admin creates batch in single request
    resp = await async_client.post("/api/v1/menu/bulk", json=payload, headers=admin_headers)
    assert resp.status_code == 201, resp.text
    data = resp.json()
    assert len(data) == 2
    assert data[0]["name"] == "Капучино"
    assert data[1]["name"] == "Американо"

    # 3. Verify in DB including child variations
    db_items = (await db_session.execute(select(MenuItem).where(MenuItem.parent_id.is_(None)))).scalars().all()
    assert len(db_items) == 2

    cappuccino = next(i for i in db_items if i.name == "Капучино")
    children = (await db_session.execute(select(MenuItem).where(MenuItem.parent_id == cappuccino.id))).scalars().all()
    assert len(children) == 2
    child_names = {c.name for c in children}
    assert "Капучино (0.3л)" in child_names
    assert "Капучино (0.5л)" in child_names

@pytest.mark.asyncio
async def test_bulk_create_retail_products_prohibits_phantom_stock(async_client: AsyncClient, db_session, auth_setup):
    admin_headers = auth_setup["admin_headers"]
    staff_headers = auth_setup["staff_headers"]

    payload = [
        {
            "name": "Coca-Cola 0.5L",
            "unit": "pcs",
            "purchase_price": 50.0,
            "selling_price": 100.0,
            "initial_stock": 99.0, # Attempt to inject phantom stock
        },
        {
            "name": "Snickers Super",
            "unit": "pcs",
            "purchase_price": 40.0,
            "selling_price": 80.0,
            "initial_stock": 50.0, # Attempt to inject phantom stock
        }
    ]

    # PBAC Check
    forbidden_resp = await async_client.post("/api/v1/retail-product/bulk", json=payload, headers=staff_headers)
    assert forbidden_resp.status_code == 403

    # Batch Create
    resp = await async_client.post("/api/v1/retail-product/bulk", json=payload, headers=admin_headers)
    assert resp.status_code == 201, resp.text
    items = resp.json()
    assert len(items) == 2

    # Stock Integrity Check: initial_stock in request MUST NOT set physical stock
    for item in items:
        assert item["current_stock"] == 0.0

    # DB Integrity Check: zero StockTransactions created
    txns = (await db_session.execute(select(StockTransaction))).scalars().all()
    assert len(txns) == 0

    # Matching retail MenuItems must exist
    menu_items = (await db_session.execute(select(MenuItem).where(MenuItem.type == "retail"))).scalars().all()
    assert len(menu_items) == 2
    assert {m.name for m in menu_items} == {"Coca-Cola 0.5L", "Snickers Super"}

@pytest.mark.asyncio
async def test_bulk_create_ingredients_prohibits_phantom_stock(async_client: AsyncClient, db_session, auth_setup):
    admin_headers = auth_setup["admin_headers"]
    staff_headers = auth_setup["staff_headers"]

    payload = [
        {
            "name": "Молоко 3.2%",
            "unit": "l",
            "cost_per_unit": 70.0,
            "initial_stock": 20.0, # Attempt to inject phantom stock
        },
        {
            "name": "Зерно Кофе Espresso",
            "unit": "kg",
            "cost_per_unit": 1200.0,
            "initial_stock": 5.0, # Attempt to inject phantom stock
        }
    ]

    # PBAC Check
    forbidden_resp = await async_client.post("/api/v1/ingredients/bulk", json=payload, headers=staff_headers)
    assert forbidden_resp.status_code == 403

    # Batch Create
    resp = await async_client.post("/api/v1/ingredients/bulk", json=payload, headers=admin_headers)
    assert resp.status_code == 201, resp.text
    items = resp.json()
    assert len(items) == 2

    for item in items:
        assert item["current_stock"] == 0.0

    # Zero transactions created
    txns = (await db_session.execute(select(StockTransaction))).scalars().all()
    assert len(txns) == 0

@pytest.mark.asyncio
async def test_single_catalog_card_creation_prohibits_phantom_stock(async_client: AsyncClient, db_session, auth_setup):
    admin_headers = auth_setup["admin_headers"]

    # Single ingredient
    resp_ing = await async_client.post("/api/v1/ingredients/", json={
        "name": "Сахар белый",
        "unit": "kg",
        "cost_per_unit": 50.0,
        "initial_stock": 10.0,
    }, headers=admin_headers)
    assert resp_ing.status_code == 201
    assert resp_ing.json()["current_stock"] == 0.0

    # Single retail product
    resp_ret = await async_client.post("/api/v1/retail-product/", json={
        "name": "Вода без газа",
        "unit": "pcs",
        "purchase_price": 20.0,
        "selling_price": 50.0,
        "initial_stock": 24.0,
    }, headers=admin_headers)
    assert resp_ret.status_code == 201

    # Zero stock transactions created
    txns = (await db_session.execute(select(StockTransaction))).scalars().all()
    assert len(txns) == 0

@pytest.mark.asyncio
async def test_document_completion_rejects_bogus_item_ids(async_client: AsyncClient, db_session, auth_setup):
    admin_headers = auth_setup["admin_headers"]

    # 1. Create a draft receipt document with a non-existent ingredient_id (e.g. fake timestamp ID 999999)
    doc_payload = {
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
    create_resp = await async_client.post("/api/v1/documents/", json=doc_payload, headers=admin_headers)
    assert create_resp.status_code == 200, create_resp.text
    doc_id = create_resp.json()["id"]

    # 2. Attempt to complete document: MUST fail with 400 Bad Request
    complete_resp = await async_client.post(f"/api/v1/documents/{doc_id}/complete", headers=admin_headers)
    assert complete_resp.status_code == 400
    assert "999999" in complete_resp.text or "not found" in complete_resp.text

    # 3. Create real ingredient and complete valid document
    ing_resp = await async_client.post("/api/v1/ingredients/", json={
        "name": "Чай черный",
        "unit": "g",
        "cost_per_unit": 1.0,
    }, headers=admin_headers)
    real_ing_id = ing_resp.json()["id"]

    valid_doc_payload = {
        "type": "receipt",
        "status": "draft",
        "date": "2026-09-14",
        "items": [
            {
                "ingredient_id": real_ing_id,
                "quantity": 100.0,
                "price_per_unit": 2.0,
                "total_price": 200.0,
            }
        ]
    }
    valid_create_resp = await async_client.post("/api/v1/documents/", json=valid_doc_payload, headers=admin_headers)
    valid_doc_id = valid_create_resp.json()["id"]

    valid_complete_resp = await async_client.post(f"/api/v1/documents/{valid_doc_id}/complete", headers=admin_headers)
    assert valid_complete_resp.status_code == 200

    # Stock correctly updated to 100.0 via document
    ing = await db_session.get(Ingredient, real_ing_id)
    await db_session.refresh(ing)
    assert ing.current_stock == 100.0

    # Audit transaction recorded
    txns = (await db_session.execute(select(StockTransaction).where(StockTransaction.ingredient_id == real_ing_id))).scalars().all()
    assert len(txns) == 1
    assert txns[0].quantity == 100.0

@pytest.mark.asyncio
async def test_bulk_delete_menu_items_and_categories_smart_purge(async_client: AsyncClient, db_session, auth_setup):
    admin_headers = auth_setup["admin_headers"]

    # 1. Create a category
    cat_resp = await async_client.post("/api/v1/categories/", json={"name": "Десерты", "category_type": "dish"}, headers=admin_headers)
    assert cat_resp.status_code == 200
    cat_id = cat_resp.json()["id"]

    # 2. Create menu items in this category
    item_resp = await async_client.post("/api/v1/menu/", json={
        "name": "Чизкейк Нью-Йорк",
        "price": 300.0,
        "category_id": cat_id,
        "type": "dish"
    }, headers=admin_headers)
    assert item_resp.status_code == 201
    item_id = item_resp.json()["id"]

    # 3. Bulk delete menu items in "hard" mode (no orders -> hard delete)
    del_resp = await async_client.post("/api/v1/menu/bulk-delete", json={"ids": [item_id], "mode": "hard"}, headers=admin_headers)
    assert del_resp.status_code == 200

    # Verify item is physically deleted
    db_item = await db_session.get(MenuItem, item_id)
    assert db_item is None

    # 4. Bulk delete category in "hard" mode (no orders -> hard delete)
    cat_del_resp = await async_client.post("/api/v1/categories/bulk-delete", json={"ids": [cat_id], "mode": "hard"}, headers=admin_headers)
    assert cat_del_resp.status_code == 200

    from app.inventory.models import MenuCategory
    db_cat = await db_session.get(MenuCategory, cat_id)
    assert db_cat is None

