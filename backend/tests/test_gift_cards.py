# ==============================================================================
# ТЕСТЫ: Подарочные карты и Cross-Tenant изоляция (Gift Cards Multi-Tenancy)
# ДОМЕН: backend.tests.test_gift_cards
# ==============================================================================
"""
E2E и интеграционные тесты модуля Подарочных карт:
  1. Cross-Tenant изоляция и многопользовательская безопасность.
  2. PBAC-авторизация и права доступа (giftcards:manage / giftcards:view).
  3. Финансовые инварианты: выпуск, списание, овердрафт, пополнение, аудит.
"""

import pytest
from httpx import AsyncClient

from app.gift_cards.models import GiftCardStatus, GiftCardTransactionType
from app.users import services as user_svc
from app.users.models import Permission, Role, RolePermission, Tenant, User, UserRole


@pytest.mark.asyncio
async def test_cross_tenant_gift_card_isolation(async_client: AsyncClient, db_session):
    """
    [БЕЗОПАСНОСТЬ] Проверка разделения операций и балансов между тенантами.
    """
    # Тенант 1 (Alpha)
    tenant_a = Tenant(name="Tenant Alpha", schema_name="tenant_alpha", is_active=True)
    tenant_b = Tenant(name="Tenant Beta", schema_name="tenant_beta", is_active=True)
    db_session.add_all([tenant_a, tenant_b])
    await db_session.commit()
    await db_session.refresh(tenant_a)
    await db_session.refresh(tenant_b)

    perm_m = Permission(code="giftcards:manage", description="Manage Gift Cards")
    perm_v = Permission(code="giftcards:view", description="View Gift Cards")
    db_session.add_all([perm_m, perm_v])
    await db_session.commit()
    await db_session.refresh(perm_m)
    await db_session.refresh(perm_v)

    role_a = Role(name="Manager A", is_superuser=False, tenant_id=tenant_a.id)
    role_b = Role(name="Manager B", is_superuser=False, tenant_id=tenant_b.id)
    db_session.add_all([role_a, role_b])
    await db_session.commit()
    await db_session.refresh(role_a)
    await db_session.refresh(role_b)

    db_session.add_all([
        RolePermission(role_id=role_a.id, permission_id=perm_m.id),
        RolePermission(role_id=role_a.id, permission_id=perm_v.id),
        RolePermission(role_id=role_b.id, permission_id=perm_m.id),
        RolePermission(role_id=role_b.id, permission_id=perm_v.id),
    ])
    await db_session.commit()

    user_a = User(tenant_id=tenant_a.id, username="mgr_alpha", full_name="Alpha", hashed_password="h", is_active=True)
    user_b = User(tenant_id=tenant_b.id, username="mgr_beta", full_name="Beta", hashed_password="h", is_active=True)
    db_session.add_all([user_a, user_b])
    await db_session.commit()
    await db_session.refresh(user_a)
    await db_session.refresh(user_b)

    db_session.add_all([
        UserRole(user_id=user_a.id, role_id=role_a.id),
        UserRole(user_id=user_b.id, role_id=role_b.id),
    ])
    await db_session.commit()

    token_a = user_svc.create_access_token(user_id=user_a.id, tenant_id=tenant_a.id, permissions=["giftcards:manage", "giftcards:view"], is_superuser=False)
    token_b = user_svc.create_access_token(user_id=user_b.id, tenant_id=tenant_b.id, permissions=["giftcards:manage", "giftcards:view"], is_superuser=False)
    headers_a = {"Authorization": f"Bearer {token_a}"}
    headers_b = {"Authorization": f"Bearer {token_b}"}

    # Выпуск карты в Alpha
    resp_a = await async_client.post("/api/v1/gift-cards", json={"code": "GC-ALPHA-01", "initial_balance": 5000.0}, headers=headers_a)
    assert resp_a.status_code == 201
    card_a = resp_a.json()

    # Выпуск карты в Beta
    resp_b = await async_client.post("/api/v1/gift-cards", json={"code": "GC-BETA-02", "initial_balance": 2000.0}, headers=headers_b)
    assert resp_b.status_code == 201
    card_b = resp_b.json()

    # Списание в Beta
    resp_redeem_b = await async_client.post(f"/api/v1/gift-cards/{card_b['id']}/redeem", json={"amount": 500.0}, headers=headers_b)
    assert resp_redeem_b.status_code == 200
    assert resp_redeem_b.json()["current_balance"] == 1500.0

    # Проверка, что баланс Alpha остался 5000
    resp_check_a = await async_client.get(f"/api/v1/gift-cards/{card_a['id']}", headers=headers_a)
    assert resp_check_a.status_code == 200
    assert resp_check_a.json()["current_balance"] == 5000.0


@pytest.mark.asyncio
async def test_gift_cards_lifecycle_and_invariants(async_client: AsyncClient, db_session):
    """
    [ФИНАНСЫ] E2E тест жизненного цикла: выпуск, списание, овердрафт, пополнение, аудит.
    """
    tenant = Tenant(name="Gift Card Café", schema_name="tenant_gift", is_active=True)
    db_session.add(tenant)
    await db_session.commit()
    await db_session.refresh(tenant)

    perm_m = Permission(code="giftcards:manage", description="Manage Gift Cards")
    perm_v = Permission(code="giftcards:view", description="View Gift Cards")
    db_session.add_all([perm_m, perm_v])
    await db_session.commit()
    await db_session.refresh(perm_m)
    await db_session.refresh(perm_v)

    role = Role(name="Cashier Manager", is_superuser=False, tenant_id=tenant.id)
    db_session.add(role)
    await db_session.commit()
    await db_session.refresh(role)

    db_session.add_all([
        RolePermission(role_id=role.id, permission_id=perm_m.id),
        RolePermission(role_id=role.id, permission_id=perm_v.id),
    ])
    await db_session.commit()

    user = User(tenant_id=tenant.id, username="cashier_gift", full_name="Cashier Gift", hashed_password="h", is_active=True)
    db_session.add(user)
    await db_session.commit()
    await db_session.refresh(user)

    db_session.add(UserRole(user_id=user.id, role_id=role.id))
    await db_session.commit()

    token = user_svc.create_access_token(user_id=user.id, tenant_id=tenant.id, permissions=["giftcards:manage", "giftcards:view"], is_superuser=False)
    headers = {"Authorization": f"Bearer {token}"}

    # 1. Выпуск
    resp_create = await async_client.post("/api/v1/gift-cards", json={"code": "GC-2026-GOLD", "initial_balance": 3000.0, "notes": "VIP"}, headers=headers)
    assert resp_create.status_code == 201
    card_id = resp_create.json()["id"]

    # 2. Поиск
    resp_lookup = await async_client.get("/api/v1/gift-cards/lookup?code=GC-2026-GOLD", headers=headers)
    assert resp_lookup.status_code == 200
    assert resp_lookup.json()["id"] == card_id

    # 3. Частичное списание (1 200 сом)
    resp_redeem = await async_client.post(f"/api/v1/gift-cards/{card_id}/redeem", json={"amount": 1200.0}, headers=headers)
    assert resp_redeem.status_code == 200
    assert resp_redeem.json()["current_balance"] == 1800.0

    # 4. Овердрафт -> 400
    resp_overdraft = await async_client.post(f"/api/v1/gift-cards/{card_id}/redeem", json={"amount": 2500.0}, headers=headers)
    assert resp_overdraft.status_code == 400
    assert "Недостаточно средств" in resp_overdraft.json()["detail"]

    # 5. Пополнение (+500)
    resp_topup = await async_client.post(f"/api/v1/gift-cards/{card_id}/topup", json={"amount": 500.0}, headers=headers)
    assert resp_topup.status_code == 200
    assert resp_topup.json()["current_balance"] == 2300.0

    # 6. Полное списание -> статус EXHAUSTED
    resp_full = await async_client.post(f"/api/v1/gift-cards/{card_id}/redeem", json={"amount": 2300.0}, headers=headers)
    assert resp_full.status_code == 200
    assert resp_full.json()["current_balance"] == 0.0
    assert resp_full.json()["status"] == "exhausted"

    # 7. История транзакций
    resp_detail = await async_client.get(f"/api/v1/gift-cards/{card_id}", headers=headers)
    assert resp_detail.status_code == 200
    assert len(resp_detail.json()["transactions"]) == 4


@pytest.mark.asyncio
async def test_gift_card_pbac_permissions(async_client: AsyncClient, db_session):
    """[БЕЗОПАСНОСТЬ] Проверка защиты эндпоинтов правами доступа PBAC."""
    tenant = Tenant(name="Test Tenant", schema_name="tenant_test", is_active=True)
    db_session.add(tenant)
    await db_session.commit()
    await db_session.refresh(tenant)

    role_no_perm = Role(name="Waiter", is_superuser=False, tenant_id=tenant.id)
    db_session.add(role_no_perm)
    await db_session.commit()
    await db_session.refresh(role_no_perm)

    user_no_perm = User(tenant_id=tenant.id, username="no_perm_user", full_name="No Perm", hashed_password="h", is_active=True)
    db_session.add(user_no_perm)
    await db_session.commit()
    await db_session.refresh(user_no_perm)

    db_session.add(UserRole(user_id=user_no_perm.id, role_id=role_no_perm.id))
    await db_session.commit()

    token = user_svc.create_access_token(user_id=user_no_perm.id, tenant_id=tenant.id, permissions=[], is_superuser=False)
    headers = {"Authorization": f"Bearer {token}"}

    resp = await async_client.post("/api/v1/gift-cards", json={"initial_balance": 1000.0}, headers=headers)
    assert resp.status_code == 403
    assert "Missing permissions" in resp.json()["detail"]


@pytest.mark.asyncio
async def test_gift_card_validation_errors(async_client: AsyncClient, db_session):
    """[ИНВАРИАНТ] Проверка валидации нулевого баланса и дубликата кода."""
    tenant = Tenant(name="Admin Tenant", schema_name="tenant_admin", is_active=True)
    db_session.add(tenant)
    await db_session.commit()
    await db_session.refresh(tenant)

    admin_role = Role(name="Owner", is_superuser=True, tenant_id=tenant.id)
    db_session.add(admin_role)
    await db_session.commit()
    await db_session.refresh(admin_role)

    admin_user = User(tenant_id=tenant.id, username="admin_gift", full_name="Admin Gift", hashed_password="h", is_active=True)
    db_session.add(admin_user)
    await db_session.commit()
    await db_session.refresh(admin_user)

    db_session.add(UserRole(user_id=admin_user.id, role_id=admin_role.id))
    await db_session.commit()

    token = user_svc.create_access_token(user_id=admin_user.id, tenant_id=tenant.id, permissions=[], is_superuser=True)
    headers = {"Authorization": f"Bearer {token}"}

    # Нулевой баланс
    resp_zero = await async_client.post("/api/v1/gift-cards", json={"initial_balance": 0.0}, headers=headers)
    assert resp_zero.status_code in (400, 422)

    # Уникальный код
    resp_ok = await async_client.post("/api/v1/gift-cards", json={"code": "GC-UNIQUE-01", "initial_balance": 500.0}, headers=headers)
    assert resp_ok.status_code == 201

    # Дубликат
    resp_dup = await async_client.post("/api/v1/gift-cards", json={"code": "GC-UNIQUE-01", "initial_balance": 1000.0}, headers=headers)
    assert resp_dup.status_code == 400
    assert "уже зарегистрирована" in resp_dup.json()["detail"]
