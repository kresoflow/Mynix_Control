import pytest
from httpx import AsyncClient
from sqlmodel import select
from app.users.models import Tenant, Role, User, UserRole, Permission, RolePermission
from app.users import services as user_svc
from app.inventory.models import (
    MenuItem, RetailProduct, Ingredient, StockTransaction,
    InventoryDocument, DocumentType, DocumentStatus
)

@pytest.fixture
async def adversarial_auth_setup(db_session):
    tenant = Tenant(name="Adversarial Test Tenant", schema_name="public", is_active=True)
    db_session.add(tenant)
    await db_session.commit()
    await db_session.refresh(tenant)

    async def create_user_bundle(username: str, perms: list[str], is_superuser: bool = False):
        user = User(
            tenant_id=tenant.id,
            username=username,
            full_name=username,
            hashed_password="hash",
            is_active=True,
        )
        db_session.add(user)
        await db_session.commit()
        await db_session.refresh(user)

        role = Role(
            name=f"Role_{username}",
            is_superuser=is_superuser,
            tenant_id=tenant.id,
        )
        db_session.add(role)
        await db_session.commit()
        await db_session.refresh(role)

        user_role = UserRole(user_id=user.id, role_id=role.id)
        db_session.add(user_role)

        for p_code in perms:
            p_stmt = select(Permission).where(Permission.code == p_code)
            p_res = await db_session.execute(p_stmt)
            perm = p_res.scalars().first()
            if not perm:
                perm = Permission(code=p_code, description=p_code)
                db_session.add(perm)
                await db_session.commit()
                await db_session.refresh(perm)
            rp = RolePermission(role_id=role.id, permission_id=perm.id)
            db_session.add(rp)

        await db_session.commit()

        token = user_svc.create_access_token(
            user_id=user.id,
            tenant_id=tenant.id,
            permissions=perms,
            is_superuser=is_superuser,
        )
        return {"Authorization": f"Bearer {token}"}

    admin_headers = await create_user_bundle(
        "adv_admin",
        ["menu:create", "menu:manage", "menu:view", "inventory:create", "inventory:manage", "inventory:view"],
        is_superuser=True,
    )
    view_headers = await create_user_bundle(
        "adv_viewer",
        ["menu:view", "inventory:view"],
        is_superuser=False,
    )
    menu_creator_headers = await create_user_bundle(
        "menu_creator",
        ["menu:create"],
        is_superuser=False,
    )
    inv_creator_headers = await create_user_bundle(
        "inv_creator",
        ["inventory:create"],
        is_superuser=False,
    )

    return {
        "tenant": tenant,
        "admin_headers": admin_headers,
        "view_headers": view_headers,
        "menu_creator_headers": menu_creator_headers,
        "inv_creator_headers": inv_creator_headers,
    }


# ============================================================================
# 1. ATOMIC ROLLBACK STRESS TESTS
# ============================================================================

@pytest.mark.asyncio
async def test_menu_bulk_atomic_rollback_on_pydantic_validation_failure(
    async_client: AsyncClient, db_session, adversarial_auth_setup
):
    headers = adversarial_auth_setup["admin_headers"]

    # Item 1 is valid, Item 2 fails Pydantic validation (missing required 'price')
    batch = [
        {"name": "Valid Dish 1", "price": 100.0, "type": "dish"},
        {"name": "Invalid Dish 2", "type": "dish"},  # Missing price
    ]

    resp = await async_client.post("/api/v1/menu/bulk", json=batch, headers=headers)
    assert resp.status_code == 422, f"Expected 422 Unprocessable Entity, got {resp.status_code}"

    # Verify zero items were persisted (atomic rollback)
    db_items = (await db_session.execute(select(MenuItem))).scalars().all()
    assert len(db_items) == 0, f"Expected 0 menu items after validation failure, found {len(db_items)}"


@pytest.mark.asyncio
async def test_retail_bulk_atomic_rollback_on_pydantic_validation_failure(
    async_client: AsyncClient, db_session, adversarial_auth_setup
):
    headers = adversarial_auth_setup["admin_headers"]

    # Item 1 is valid, Item 2 fails Pydantic validation (negative price violating ge=0.0)
    batch = [
        {
            "name": "Valid Retail 1",
            "unit": "pcs",
            "purchase_price": 30.0,
            "selling_price": 60.0,
        },
        {
            "name": "Invalid Retail 2",
            "unit": "pcs",
            "purchase_price": -10.0,  # ge=0.0 violation
            "selling_price": 50.0,
        },
    ]

    resp = await async_client.post("/api/v1/retail-product/bulk", json=batch, headers=headers)
    assert resp.status_code == 422

    db_retail = (await db_session.execute(select(RetailProduct))).scalars().all()
    db_menu = (await db_session.execute(select(MenuItem))).scalars().all()
    assert len(db_retail) == 0
    assert len(db_menu) == 0


@pytest.mark.asyncio
async def test_ingredients_bulk_atomic_rollback_on_pydantic_validation_failure(
    async_client: AsyncClient, db_session, adversarial_auth_setup
):
    headers = adversarial_auth_setup["admin_headers"]

    # Item 1 valid, Item 2 missing required 'name'
    batch = [
        {"name": "Valid Salt", "unit": "g", "cost_per_unit": 0.05},
        {"unit": "g", "cost_per_unit": 0.10},  # Missing name
    ]

    resp = await async_client.post("/api/v1/ingredients/bulk", json=batch, headers=headers)
    assert resp.status_code == 422

    db_ing = (await db_session.execute(select(Ingredient))).scalars().all()
    assert len(db_ing) == 0


@pytest.mark.asyncio
async def test_menu_bulk_atomic_rollback_on_midway_service_failure(
    async_client: AsyncClient, db_session, adversarial_auth_setup
):
    headers = adversarial_auth_setup["admin_headers"]

    # Item 1 is valid.
    # Item 2 passes Pydantic schema validation (attributes is freeform dict),
    # but triggers ValueError during variation price conversion in _sync_child_variations.
    batch = [
        {"name": "Valid Rollback Dish 1", "price": 100.0, "type": "dish"},
        {
            "name": "Crash Dish 2",
            "price": 150.0,
            "type": "dish",
            "attributes": {
                "variations": [
                    {"name": "Crash Size", "price": "invalid_not_a_number"}
                ]
            }
        },
    ]

    resp = await async_client.post("/api/v1/menu/bulk", json=batch, headers=headers)
    # The server raises unhandled ValueError during service execution -> 500
    assert resp.status_code >= 400

    # ATOMICITY VERIFICATION: Item 1 was added/flushed before Item 2 crashed,
    # but transaction rollback MUST roll back Item 1 completely.
    db_items = (await db_session.execute(select(MenuItem))).scalars().all()
    assert len(db_items) == 0, f"Expected complete atomic rollback, but found {len(db_items)} items in DB"


# ============================================================================
# 2. VARIATIONS GENERATION STRESS TESTS
# ============================================================================

@pytest.mark.asyncio
async def test_menu_bulk_dish_variations_multiple_options_and_prices(
    async_client: AsyncClient, db_session, adversarial_auth_setup
):
    headers = adversarial_auth_setup["admin_headers"]

    payload = [
        {
            "name": "Пицца Четыре Сыра",
            "price": 450.0,
            "type": "dish",
            "attributes": {
                "variations": [
                    {"name": "25 см / Тонкое тесто", "price": 450.0, "barcode": "BAR-25"},
                    {"name": "30 см / Тонкое тесто", "price": 600.0, "barcode": "BAR-30"},
                    {"name": "35 см / Пышное тесто", "price": 750.0, "barcode": "BAR-35"},
                    {"name": "40 см / Сырный борт", "price": 950.0, "barcode": "BAR-40"},
                ]
            }
        },
        {
            "name": "Чай Черный Ассам",
            "price": 120.0,
            "type": "dish",
            "attributes": {
                "variations": [
                    {"name": "Чашка 250мл", "price": 120.0},
                    {"name": "Чайник 600мл", "price": 280.0},
                ]
            }
        },
        {
            "name": "Простой круассан",
            "price": 90.0,
            "type": "dish",
            # No variations
        }
    ]

    resp = await async_client.post("/api/v1/menu/bulk", json=payload, headers=headers)
    assert resp.status_code == 201, resp.text
    created = resp.json()
    assert len(created) == 3

    # 1. Verify parent response structures
    pizza_resp = next(i for i in created if i["name"] == "Пицца Четыре Сыра")
    assert pizza_resp["attributes"] is not None
    assert "variations" in pizza_resp["attributes"]
    resp_vars = pizza_resp["attributes"]["variations"]
    assert len(resp_vars) == 4
    for v in resp_vars:
        assert "id" in v
        assert isinstance(v["id"], int)

    # 2. Verify in DB
    all_db_items = (await db_session.execute(select(MenuItem))).scalars().all()
    # 3 parents + 4 pizza children + 2 tea children = 9 total
    assert len(all_db_items) == 9

    pizza_parent = next(i for i in all_db_items if i.name == "Пицца Четыре Сыра")
    assert pizza_parent.parent_id is None

    pizza_children = [i for i in all_db_items if i.parent_id == pizza_parent.id]
    assert len(pizza_children) == 4

    child_map = {c.name: c for c in pizza_children}
    assert "Пицца Четыре Сыра (25 см / Тонкое тесто)" in child_map
    assert "Пицца Четыре Сыра (30 см / Тонкое тесто)" in child_map
    assert "Пицца Четыре Сыра (35 см / Пышное тесто)" in child_map
    assert "Пицца Четыре Сыра (40 см / Сырный борт)" in child_map

    assert child_map["Пицца Четыре Сыра (25 см / Тонкое тесто)"].price == 450.0
    assert child_map["Пицца Четыре Сыра (25 см / Тонкое тесто)"].barcode == "BAR-25"
    assert child_map["Пицца Четыре Сыра (30 см / Тонкое тесто)"].price == 600.0
    assert child_map["Пицца Четыре Сыра (30 см / Тонкое тесто)"].barcode == "BAR-30"
    assert child_map["Пицца Четыре Сыра (35 см / Пышное тесто)"].price == 750.0
    assert child_map["Пицца Четыре Сыра (35 см / Пышное тесто)"].barcode == "BAR-35"
    assert child_map["Пицца Четыре Сыра (40 см / Сырный борт)"].price == 950.0
    assert child_map["Пицца Четыре Сыра (40 см / Сырный борт)"].barcode == "BAR-40"


@pytest.mark.asyncio
async def test_menu_variations_update_lifecycle(
    async_client: AsyncClient, db_session, adversarial_auth_setup
):
    headers = adversarial_auth_setup["admin_headers"]

    # Create dish with 2 variations: Small (100) and Large (200)
    create_payload = [
        {
            "name": "Лимонад Цитрус",
            "price": 100.0,
            "type": "dish",
            "attributes": {
                "variations": [
                    {"name": "0.3л", "price": 100.0},
                    {"name": "0.5л", "price": 200.0},
                ]
            }
        }
    ]
    resp = await async_client.post("/api/v1/menu/bulk", json=create_payload, headers=headers)
    assert resp.status_code == 201
    parent_id = resp.json()[0]["id"]

    # Now update via PUT: change 0.3л price to 120, remove 0.5л, add 1.0л (350)
    update_data = {
        "name": "Лимонад Цитрус",
        "price": 120.0,
        "attributes": {
            "variations": [
                {"name": "0.3л", "price": 120.0},
                {"name": "1.0л", "price": 350.0},
            ]
        }
    }
    put_resp = await async_client.put(f"/api/v1/menu/{parent_id}", json=update_data, headers=headers)
    assert put_resp.status_code == 200, put_resp.text

    # Verify DB: 0.5л should be gone, 0.3л updated to 120, 1.0л created
    children = (await db_session.execute(select(MenuItem).where(MenuItem.parent_id == parent_id))).scalars().all()
    child_names = {c.name: c.price for c in children}
    assert "Лимонад Цитрус (0.3л)" in child_names
    assert child_names["Лимонад Цитрус (0.3л)"] == 120.0
    assert "Лимонад Цитрус (1.0л)" in child_names
    assert child_names["Лимонад Цитрус (1.0л)"] == 350.0
    assert "Лимонад Цитрус (0.5л)" not in child_names


# ============================================================================
# 3. PBAC AUTHORIZATION & AUTHENTICATION CHECKS
# ============================================================================

@pytest.mark.asyncio
async def test_bulk_endpoints_reject_unauthenticated(async_client: AsyncClient):
    # 1. No Authorization header -> 401
    r_menu_noauth = await async_client.post("/api/v1/menu/bulk", json=[])
    assert r_menu_noauth.status_code == 401

    r_retail_noauth = await async_client.post("/api/v1/retail-product/bulk", json=[])
    assert r_retail_noauth.status_code == 401

    r_ing_noauth = await async_client.post("/api/v1/ingredients/bulk", json=[])
    assert r_ing_noauth.status_code == 401

    r_doc_noauth = await async_client.post("/api/v1/documents/1/complete")
    assert r_doc_noauth.status_code == 401

    # 2. Malformed / Fake token -> 401
    bad_headers = {"Authorization": "Bearer totally.invalid.token"}
    r_bad = await async_client.post("/api/v1/menu/bulk", json=[], headers=bad_headers)
    assert r_bad.status_code == 401


@pytest.mark.asyncio
async def test_bulk_endpoints_reject_insufficient_permissions(
    async_client: AsyncClient, adversarial_auth_setup
):
    view_headers = adversarial_auth_setup["view_headers"]

    # User with only menu:view, inventory:view must be rejected with 403 on all creation endpoints
    menu_resp = await async_client.post("/api/v1/menu/bulk", json=[{"name": "X", "price": 10}], headers=view_headers)
    assert menu_resp.status_code == 403
    assert "menu:create" in menu_resp.json()["detail"]

    retail_resp = await async_client.post("/api/v1/retail-product/bulk", json=[{"name": "X", "unit": "pcs", "purchase_price": 5, "selling_price": 10}], headers=view_headers)
    assert retail_resp.status_code == 403
    assert "menu:create" in retail_resp.json()["detail"]

    ing_resp = await async_client.post("/api/v1/ingredients/bulk", json=[{"name": "X", "unit": "g"}], headers=view_headers)
    assert ing_resp.status_code == 403
    assert "inventory:create" in ing_resp.json()["detail"]

    doc_resp = await async_client.post("/api/v1/documents/1/complete", headers=view_headers)
    assert doc_resp.status_code == 403
    assert "inventory:manage" in doc_resp.json()["detail"]


@pytest.mark.asyncio
async def test_bulk_endpoints_fine_grained_pbac_separation(
    async_client: AsyncClient, adversarial_auth_setup
):
    menu_creator_headers = adversarial_auth_setup["menu_creator_headers"]
    inv_creator_headers = adversarial_auth_setup["inv_creator_headers"]

    # 1. menu_creator has menu:create, but NOT inventory:create
    # Can create menu item
    m_ok = await async_client.post("/api/v1/menu/bulk", json=[{"name": "Allowed Menu", "price": 50}], headers=menu_creator_headers)
    assert m_ok.status_code == 201

    # Can create retail product
    r_ok = await async_client.post("/api/v1/retail-product/bulk", json=[{"name": "Allowed Retail", "unit": "pcs", "purchase_price": 10, "selling_price": 20}], headers=menu_creator_headers)
    assert r_ok.status_code == 201

    # CANNOT create ingredients
    i_fail = await async_client.post("/api/v1/ingredients/bulk", json=[{"name": "Forbidden Ing", "unit": "g"}], headers=menu_creator_headers)
    assert i_fail.status_code == 403
    assert "inventory:create" in i_fail.json()["detail"]

    # 2. inv_creator has inventory:create, but NOT menu:create
    # Can create ingredients
    i_ok = await async_client.post("/api/v1/ingredients/bulk", json=[{"name": "Allowed Ing", "unit": "g"}], headers=inv_creator_headers)
    assert i_ok.status_code == 201

    # CANNOT create menu item
    m_fail = await async_client.post("/api/v1/menu/bulk", json=[{"name": "Forbidden Menu", "price": 50}], headers=inv_creator_headers)
    assert m_fail.status_code == 403
    assert "menu:create" in m_fail.json()["detail"]

    # CANNOT create retail product
    r_fail = await async_client.post("/api/v1/retail-product/bulk", json=[{"name": "Forbidden Retail", "unit": "pcs", "purchase_price": 10, "selling_price": 20}], headers=inv_creator_headers)
    assert r_fail.status_code == 403
    assert "menu:create" in r_fail.json()["detail"]
