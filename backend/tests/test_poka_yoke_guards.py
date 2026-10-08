import pytest
from httpx import AsyncClient
from sqlmodel import select

from app.users.models import Tenant, Role, User, UserRole
from app.users import services as user_svc
from app.pos.models import Shift, Order, OrderStatus, PaymentMethod
from app.inventory.models import Ingredient, StockTransaction, Recipe
from app.inventory.models.enums import UnitType, StockTransactionType
from app.inventory.services import ingredient_service as ing_svc

@pytest.mark.asyncio
async def test_cannot_close_shift_with_active_orders(async_client: AsyncClient, db_session):
    tenant = Tenant(name="Shift Guard Cafe", schema_name="public", is_active=True)
    db_session.add(tenant)
    await db_session.commit()
    await db_session.refresh(tenant)

    role = Role(name="Admin", is_superuser=True, tenant_id=tenant.id)
    db_session.add(role)
    await db_session.commit()
    await db_session.refresh(role)

    user = User(tenant_id=tenant.id, username="cashier_guard", full_name="Guard", hashed_password="h", is_active=True)
    db_session.add(user)
    await db_session.commit()
    await db_session.refresh(user)

    db_session.add(UserRole(user_id=user.id, role_id=role.id))
    await db_session.commit()

    token = user_svc.create_access_token(user_id=user.id, tenant_id=tenant.id, permissions=["shifts:open", "shifts:close"], is_superuser=True)
    headers = {"Authorization": f"Bearer {token}"}

    # 1. Open shift
    await async_client.post("/api/v1/shifts/open", json={"opening_cash": 100.0}, headers=headers)

    stmt = select(Shift).where(Shift.is_open == True)
    shift = (await db_session.execute(stmt)).scalar_one()

    # 2. Add active (NEW / COOKING) order
    active_order = Order(
        shift_id=shift.id,
        user_id=user.id,
        created_by=user.id,
        order_number=1,
        status=OrderStatus.COOKING.value,
        total_amount=250.0,
        payment_method=PaymentMethod.CASH.value,
    )
    db_session.add(active_order)
    await db_session.commit()

    # 3. Attempt to close shift -> must fail 400
    close_resp = await async_client.post("/api/v1/shifts/close", json={"closing_cash_actual": 100.0}, headers=headers)
    assert close_resp.status_code == 400
    assert "незакрытых" in close_resp.json()["detail"].lower()

    # 4. Complete order
    active_order.status = OrderStatus.COMPLETED.value
    db_session.add(active_order)
    await db_session.commit()

    # 5. Now close shift -> success_resp
    close_resp_2 = await async_client.post("/api/v1/shifts/close", json={"closing_cash_actual": 100.0}, headers=headers)
    assert close_resp_2.status_code == 200


@pytest.mark.asyncio
async def test_self_deletion_and_last_owner_deletion_blocked(async_client: AsyncClient, db_session):
    tenant = Tenant(name="User Guard Cafe", schema_name="public", is_active=True)
    db_session.add(tenant)
    await db_session.commit()
    await db_session.refresh(tenant)

    owner_role = Role(name="owner", is_superuser=True, tenant_id=tenant.id)
    db_session.add(owner_role)
    await db_session.commit()
    await db_session.refresh(owner_role)

    owner1 = User(tenant_id=tenant.id, username="owner1", full_name="Owner One", hashed_password="h", is_active=True)
    db_session.add(owner1)
    await db_session.commit()
    await db_session.refresh(owner1)
    db_session.add(UserRole(user_id=owner1.id, role_id=owner_role.id))
    await db_session.commit()

    token = user_svc.create_access_token(user_id=owner1.id, tenant_id=tenant.id, permissions=["users:manage"], is_superuser=True)
    headers = {"Authorization": f"Bearer {token}"}

    # 1. Attempt self-deletion -> must fail 400
    del_self = await async_client.delete(f"/api/v1/users/{owner1.id}", headers=headers)
    assert del_self.status_code == 400
    assert "собственную" in del_self.json()["detail"].lower()

    admin_role = Role(name="admin", is_superuser=True, tenant_id=tenant.id)
    db_session.add(admin_role)
    await db_session.commit()
    await db_session.refresh(admin_role)

    # 2. Create another admin who tries to delete the only owner
    admin2 = User(tenant_id=tenant.id, username="admin2", full_name="Admin Two", hashed_password="h", is_active=True)
    db_session.add(admin2)
    await db_session.commit()
    await db_session.refresh(admin2)
    db_session.add(UserRole(user_id=admin2.id, role_id=admin_role.id))
    await db_session.commit()

    token2 = user_svc.create_access_token(user_id=admin2.id, tenant_id=tenant.id, permissions=["users:manage"], is_superuser=True)
    headers2 = {"Authorization": f"Bearer {token2}"}

    del_last_owner = await async_client.delete(f"/api/v1/users/{owner1.id}", headers=headers2)
    assert del_last_owner.status_code == 400
    assert "единственного" in del_last_owner.json()["detail"].lower()


@pytest.mark.asyncio
async def test_ingredient_deletion_ledger_guard(db_session):
    ing = Ingredient(name="Protected Cheese", unit=UnitType.KG, current_stock=10.0)
    db_session.add(ing)
    await db_session.flush()

    txn = StockTransaction(ingredient_id=ing.id, type=StockTransactionType.RECEIPT, quantity=10.0, cost_per_unit=500.0)
    db_session.add(txn)
    await db_session.flush()

    # 1. Hard delete blocked by poka-yoke
    with pytest.raises(ValueError) as exc_info:
        await ing_svc.delete_ingredient(db_session, ing.id, mode="hard")
    assert "проводок" in str(exc_info.value)

    # 2. Soft delete archives the ingredient
    await ing_svc.delete_ingredient(db_session, ing.id, mode="soft")
    assert ing.is_archived is True

    # 3. Filtered list excludes it
    active_items = await ing_svc.list_ingredients(db_session, include_archived=False)
    assert not any(i.id == ing.id for i in active_items)

    # 4. Include archived list includes it
    all_items = await ing_svc.list_ingredients(db_session, include_archived=True)
    assert any(i.id == ing.id and i.is_archived for i in all_items)

    # 5. Restore unarchives the ingredient
    await ing_svc.restore_ingredient(db_session, ing.id)
    assert ing.is_archived is False


@pytest.mark.asyncio
async def test_pin_bruteforce_protection(async_client: AsyncClient, db_session):
    from app.users.routers.auth_router import _pin_failed_attempts, _pin_locked_keys
    _pin_failed_attempts.clear()
    _pin_locked_keys.clear()

    tenant = Tenant(name="PIN Guard Cafe", schema_name="public", is_active=True)
    db_session.add(tenant)
    await db_session.commit()
    await db_session.refresh(tenant)

    user = User(tenant_id=tenant.id, username="pin_tester", full_name="Tester", hashed_password="h", pin_code="1234", is_active=True)
    db_session.add(user)
    await db_session.commit()

    # 4 invalid attempts -> 401
    for _ in range(4):
        resp = await async_client.post("/api/v1/auth/pin", json={"pin_code": "0000", "tenant_id": tenant.id})
        assert resp.status_code == 401

    # 5th invalid attempt -> 429 Too Many Requests
    resp_5 = await async_client.post("/api/v1/auth/pin", json={"pin_code": "0000", "tenant_id": tenant.id})
    assert resp_5.status_code == 429
    assert "лимит" in resp_5.json()["detail"].lower() or "заблокирован" in resp_5.json()["detail"].lower()


@pytest.mark.asyncio
async def test_analytics_date_guards(async_client: AsyncClient, db_session):
    tenant = Tenant(name="Analytics Guard Cafe", schema_name="public", is_active=True)
    db_session.add(tenant)
    await db_session.commit()
    await db_session.refresh(tenant)

    role = Role(name="Admin", is_superuser=True, tenant_id=tenant.id)
    db_session.add(role)
    await db_session.commit()
    await db_session.refresh(role)

    user = User(tenant_id=tenant.id, username="analyst", full_name="Analyst", hashed_password="h", is_active=True)
    db_session.add(user)
    await db_session.commit()
    await db_session.refresh(user)

    db_session.add(UserRole(user_id=user.id, role_id=role.id))
    await db_session.commit()

    token = user_svc.create_access_token(user_id=user.id, tenant_id=tenant.id, permissions=["analytics:view"], is_superuser=True)
    headers = {"Authorization": f"Bearer {token}"}

    # 1. Start > End must fail 400
    resp_inv = await async_client.get("/api/v1/analytics/metrics?period=custom&start=2026-05-10&end=2026-05-01", headers=headers)
    assert resp_inv.status_code == 400
    assert "не может быть позже" in resp_inv.json()["detail"].lower()

    # 2. Over 366 days must fail 400
    resp_over = await async_client.get("/api/v1/analytics/metrics?period=custom&start=2024-01-01&end=2026-01-01", headers=headers)
    assert resp_over.status_code == 400
    assert "366 дней" in resp_over.json()["detail"].lower()


@pytest.mark.asyncio
async def test_category_circular_dependency_guard(async_client: AsyncClient, db_session):
    tenant = Tenant(name="Category Guard Cafe", schema_name="public", is_active=True)
    db_session.add(tenant)
    await db_session.commit()
    await db_session.refresh(tenant)

    role = Role(name="Admin", is_superuser=True, tenant_id=tenant.id)
    db_session.add(role)
    await db_session.commit()
    await db_session.refresh(role)

    user = User(tenant_id=tenant.id, username="cat_admin", full_name="Admin", hashed_password="h", is_active=True)
    db_session.add(user)
    await db_session.commit()
    await db_session.refresh(user)

    db_session.add(UserRole(user_id=user.id, role_id=role.id))
    await db_session.commit()

    token = user_svc.create_access_token(user_id=user.id, tenant_id=tenant.id, permissions=["menu:manage", "inventory:manage"], is_superuser=True)
    headers = {"Authorization": f"Bearer {token}"}

    # 1. Create Category A and B (A -> B)
    resp_a = await async_client.post("/api/v1/categories/", json={"name": "Drinks", "category_type": "dish"}, headers=headers)
    assert resp_a.status_code == 200
    cat_a_id = resp_a.json()["id"]

    resp_b = await async_client.post("/api/v1/categories/", json={"name": "Juices", "category_type": "dish", "parent_id": cat_a_id}, headers=headers)
    assert resp_b.status_code == 200
    cat_b_id = resp_b.json()["id"]

    # 2. Attempt self-parenting: A -> A -> 400
    resp_self = await async_client.put(f"/api/v1/categories/{cat_a_id}", json={"parent_id": cat_a_id}, headers=headers)
    assert resp_self.status_code == 400
    assert "для самой себя" in resp_self.json()["detail"].lower()

    # 3. Attempt cycle: A -> B (where B already has parent A) -> 400
    resp_cycle = await async_client.put(f"/api/v1/categories/{cat_a_id}", json={"parent_id": cat_b_id}, headers=headers)
    assert resp_cycle.status_code == 400
    assert "циклическая зависимость" in resp_cycle.json()["detail"].lower()


@pytest.mark.asyncio
async def test_numerical_range_guards(async_client: AsyncClient, db_session):
    tenant = Tenant(name="Range Guard Cafe", schema_name="public", is_active=True)
    db_session.add(tenant)
    await db_session.commit()
    await db_session.refresh(tenant)

    role = Role(name="Admin", is_superuser=True, tenant_id=tenant.id)
    db_session.add(role)
    await db_session.commit()
    await db_session.refresh(role)

    user = User(tenant_id=tenant.id, username="range_admin", full_name="Admin", hashed_password="h", is_active=True)
    db_session.add(user)
    await db_session.commit()
    await db_session.refresh(user)

    db_session.add(UserRole(user_id=user.id, role_id=role.id))
    await db_session.commit()

    token = user_svc.create_access_token(user_id=user.id, tenant_id=tenant.id, permissions=["inventory:manage"], is_superuser=True)
    headers = {"Authorization": f"Bearer {token}"}

    # 1. Supplier payment with negative amount -> 422
    resp_pay = await async_client.post("/api/v1/suppliers/1/payments", json={"amount": -100.0}, headers=headers)
    assert resp_pay.status_code == 422

    # 2. Supplier payment with 0 amount -> 422
    resp_pay_zero = await async_client.post("/api/v1/suppliers/1/payments", json={"amount": 0.0}, headers=headers)
    assert resp_pay_zero.status_code == 422

    # 3. Document item with negative quantity -> 422
    doc_payload = {
        "type": "receipt",
        "items": [{"ingredient_id": 1, "quantity": -5.0, "price_per_unit": 100.0}]
    }
    resp_doc = await async_client.post("/api/v1/documents/", json=doc_payload, headers=headers)
    assert resp_doc.status_code == 422


@pytest.mark.asyncio
async def test_two_stage_menu_item_and_category_deletion(async_client: AsyncClient, db_session):
    tenant = Tenant(name="Recycle Guard Cafe", schema_name="public", is_active=True)
    db_session.add(tenant)
    await db_session.commit()
    await db_session.refresh(tenant)

    role = Role(name="Admin", is_superuser=True, tenant_id=tenant.id)
    db_session.add(role)
    await db_session.commit()
    await db_session.refresh(role)

    user = User(tenant_id=tenant.id, username="recycle_admin", full_name="Admin", hashed_password="h", is_active=True)
    db_session.add(user)
    await db_session.commit()
    await db_session.refresh(user)

    db_session.add(UserRole(user_id=user.id, role_id=role.id))
    await db_session.commit()

    token = user_svc.create_access_token(user_id=user.id, tenant_id=tenant.id, permissions=["menu:manage", "pos:orders:create"], is_superuser=True)
    headers = {"Authorization": f"Bearer {token}"}

    # 1. Create Category
    resp_cat = await async_client.post("/api/v1/categories/", json={"name": "FastFood", "category_type": "dish"}, headers=headers)
    assert resp_cat.status_code == 200
    cat_id = resp_cat.json()["id"]

    # 2. Create Dish A (will have order history) and Dish B (no history)
    resp_dish_a = await async_client.post("/api/v1/menu/", json={"name": "Burger With History", "price": 300.0, "category_id": cat_id}, headers=headers)
    assert resp_dish_a.status_code in (200, 201)
    dish_a_id = resp_dish_a.json()["id"]

    resp_dish_b = await async_client.post("/api/v1/menu/", json={"name": "Burger Empty", "price": 250.0, "category_id": cat_id}, headers=headers)
    assert resp_dish_b.status_code in (200, 201)
    dish_b_id = resp_dish_b.json()["id"]

    # 3. Simulate Order for Dish A
    from app.pos.models import OrderItem
    order = Order(
        shift_id=1,
        user_id=user.id,
        created_by=user.id,
        order_number=501,
        status=OrderStatus.COMPLETED.value,
        total_amount=300.0,
        payment_method=PaymentMethod.CASH.value,
    )
    db_session.add(order)
    await db_session.flush()

    order_item = OrderItem(
        order_id=order.id,
        menu_item_id=dish_a_id,
        menu_item_name="Burger With History",
        quantity=1,
        unit_price=300.0,
        subtotal=300.0,
    )
    db_session.add(order_item)
    await db_session.commit()

    # 4. Standard Delete from Main Screen (defaults to mode="soft") -> ALWAYS Archives
    del_a_soft = await async_client.delete(f"/api/v1/menu/{dish_a_id}", headers=headers)
    assert del_a_soft.status_code == 200
    assert del_a_soft.json()["status"] == "archived"

    del_b_soft = await async_client.delete(f"/api/v1/menu/{dish_b_id}", headers=headers)
    assert del_b_soft.status_code == 200
    assert del_b_soft.json()["status"] == "archived"

    # 5. Inside Archive: Hard Delete on Dish A (has order history) -> FAILS 400
    del_a_hard = await async_client.delete(f"/api/v1/menu/{dish_a_id}?mode=hard", headers=headers)
    assert del_a_hard.status_code == 400
    assert "история продаж" in del_a_hard.json()["detail"].lower()

    # 6. Inside Archive: Hard Delete on Dish B (no history) -> SUCCEEDS (deleted)
    del_b_hard = await async_client.delete(f"/api/v1/menu/{dish_b_id}?mode=hard", headers=headers)
    assert del_b_hard.status_code == 200
    assert del_b_hard.json()["status"] == "deleted"

    # 7. Category Soft Delete (defaults to mode="soft") -> Archives
    cat_del_soft = await async_client.delete(f"/api/v1/categories/{cat_id}", headers=headers)
    assert cat_del_soft.status_code in (200, 204)

    # 8. Category Hard Delete with remaining Dish A (has history) -> FAILS 400
    cat_del_hard = await async_client.delete(f"/api/v1/categories/{cat_id}?mode=hard", headers=headers)
    assert cat_del_hard.status_code == 400
    assert "история продаж" in cat_del_hard.json()["detail"].lower()


@pytest.mark.asyncio
async def test_restore_duplicate_collision_guards(async_client: AsyncClient, db_session):
    tenant = Tenant(name="Restore Guard Cafe", schema_name="public", is_active=True)
    db_session.add(tenant)
    await db_session.commit()
    await db_session.refresh(tenant)

    role = Role(name="Admin", is_superuser=True, tenant_id=tenant.id)
    db_session.add(role)
    await db_session.commit()
    await db_session.refresh(role)

    user = User(tenant_id=tenant.id, username="restore_admin", full_name="Admin", hashed_password="h", is_active=True)
    db_session.add(user)
    await db_session.commit()
    await db_session.refresh(user)

    db_session.add(UserRole(user_id=user.id, role_id=role.id))
    await db_session.commit()

    token = user_svc.create_access_token(user_id=user.id, tenant_id=tenant.id, permissions=["menu:manage"], is_superuser=True)
    headers = {"Authorization": f"Bearer {token}"}

    # 1. Create Category
    resp_cat = await async_client.post("/api/v1/categories/", json={"name": "Pizzas", "category_type": "dish"}, headers=headers)
    assert resp_cat.status_code == 200
    cat_id = resp_cat.json()["id"]

    # 2. Create Item 1: "Пепперони", then archive it
    resp_item_1 = await async_client.post("/api/v1/menu/", json={"name": "Пепперони", "price": 500.0, "category_id": cat_id}, headers=headers)
    assert resp_item_1.status_code in (200, 201)
    item_1_id = resp_item_1.json()["id"]

    await async_client.delete(f"/api/v1/menu/{item_1_id}?mode=soft", headers=headers)

    # 3. Create Item 2 with same name: "Пепперони" in the same category
    resp_item_2 = await async_client.post("/api/v1/menu/", json={"name": "Пепперони", "price": 550.0, "category_id": cat_id}, headers=headers)
    assert resp_item_2.status_code in (200, 201)
    item_2_id = resp_item_2.json()["id"]

    # 4. Attempt to restore Item 1 while Item 2 is active -> must FAIL 400 (Collision Guard)
    resp_restore = await async_client.post(f"/api/v1/menu/{item_1_id}/restore", headers=headers)
    assert resp_restore.status_code == 400
    assert "активная позиция" in resp_restore.json()["detail"].lower()

    # 5. Archive Item 2, then restore Item 1 -> now SUCCEEDS
    await async_client.delete(f"/api/v1/menu/{item_2_id}?mode=soft", headers=headers)
    resp_restore_ok = await async_client.post(f"/api/v1/menu/{item_1_id}/restore", headers=headers)
    assert resp_restore_ok.status_code == 200

    # 6. Test Category Restore Collision Guard
    resp_cat_a = await async_client.post("/api/v1/categories/", json={"name": "Soups", "category_type": "dish"}, headers=headers)
    assert resp_cat_a.status_code == 200
    cat_a_id = resp_cat_a.json()["id"]
    await async_client.delete(f"/api/v1/categories/{cat_a_id}?mode=soft", headers=headers)

    resp_cat_b = await async_client.post("/api/v1/categories/", json={"name": "Soups", "category_type": "dish"}, headers=headers)
    assert resp_cat_b.status_code == 200

    resp_cat_restore = await async_client.post(f"/api/v1/categories/{cat_a_id}/restore", headers=headers)
    assert resp_cat_restore.status_code == 400
    assert "активная категория" in resp_cat_restore.json()["detail"].lower()

    # 7. Delete duplicate Cat B, then restore Cat A -> now SUCCEEDS
    await async_client.delete(f"/api/v1/categories/{resp_cat_b.json()['id']}?mode=hard", headers=headers)
    resp_cat_restore_ok = await async_client.post(f"/api/v1/categories/{cat_a_id}/restore", headers=headers)
    assert resp_cat_restore_ok.status_code == 200
    assert resp_cat_restore_ok.json()["is_archived"] is False






