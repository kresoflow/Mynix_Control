# ==============================================================================
#  Kreso Flow — Tests: PBAC 3-Role Matrix & Architectural Core Guards
#  [БЕЗОПАСНОСТЬ] [PBAC] 3 роли: Owner (100%), Manager (no Analytics), Cashier (POS/Shift).
#  [ИНВАРИАНТ] Идемпотентность кассы, блокировка расчетов, защита системных логов.
# ==============================================================================

import pytest
from httpx import AsyncClient
from sqlmodel import select

from app.users.models import Tenant, Role, User, UserRole, Permission, RolePermission
from app.users import services as user_svc
from app.users.seed import ROLE_TEMPLATES
from app.pos.models import Shift, Order, OrderStatus, CashOperationCreate, CashOperationType
from app.pos.services.order_table_service import settle_table_order
from app.pos.services.cash_operation_service import create_cash_operation
from app.exceptions import ConflictError


# ──────────────────────────────────────────────────────────────────────────────
#  1. Проверка структуры матрицы ролей в seed
# ──────────────────────────────────────────────────────────────────────────────

def test_role_seed_three_roles_only():
    """Матрица ролей содержит ровно 3 роли: owner, manager, cashier."""
    assert set(ROLE_TEMPLATES.keys()) == {"owner", "manager", "cashier"}
    
    manager_perms = ROLE_TEMPLATES["manager"]["permissions"]
    assert "analytics:view" not in manager_perms
    assert "roles:manage" not in manager_perms
    assert "users:manage" in manager_perms

    cashier_perms = ROLE_TEMPLATES["cashier"]["permissions"]
    assert "analytics:view" not in cashier_perms
    assert "users:manage" not in cashier_perms
    assert "orders:create" in cashier_perms


# ──────────────────────────────────────────────────────────────────────────────
#  2. Защита аналитики от Управляющего (Manager -> 403)
# ──────────────────────────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_manager_cannot_access_analytics(async_client: AsyncClient, db_session):
    """Управляющий не имеет доступа к аналитике (Perm.ANALYTICS_VIEW)."""
    tenant = Tenant(name="PBAC Cafe", schema_name="public", is_active=True)
    db_session.add(tenant)
    await db_session.commit()
    await db_session.refresh(tenant)

    role_manager = Role(name="manager", is_superuser=False)
    db_session.add(role_manager)
    await db_session.commit()
    await db_session.refresh(role_manager)

    manager_user = User(
        tenant_id=tenant.id,
        username="manager_alex",
        full_name="Alex Manager",
        hashed_password="hash",
        is_active=True,
    )
    db_session.add(manager_user)
    await db_session.commit()
    await db_session.refresh(manager_user)
    db_session.add(UserRole(user_id=manager_user.id, role_id=role_manager.id))
    await db_session.commit()

    token = user_svc.create_access_token(
        user_id=manager_user.id,
        tenant_id=tenant.id,
        permissions=ROLE_TEMPLATES["manager"]["permissions"],
        is_superuser=False,
    )
    headers = {"Authorization": f"Bearer {token}"}

    resp = await async_client.get("/api/v1/analytics/metrics", headers=headers)
    assert resp.status_code == 403
    assert "analytics:view" in resp.json()["detail"].lower()


# ──────────────────────────────────────────────────────────────────────────────
#  3. Ограничения Управляющего при управлении персоналом
# ──────────────────────────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_manager_staff_restrictions(async_client: AsyncClient, db_session):
    """
    Управляющий:
      - НЕ может создавать Владельца или Управляющего (403)
      - МОЖЕТ создавать Кассира (201)
      - НЕ может редактировать или удалять Владельца / Управляющего (403)
    """
    tenant = Tenant(name="Staff Guard Cafe", schema_name="public", is_active=True)
    db_session.add(tenant)
    await db_session.commit()
    await db_session.refresh(tenant)

    # Права
    perm_users = Permission(code="users:manage", description="Manage users")
    db_session.add(perm_users)
    await db_session.commit()
    await db_session.refresh(perm_users)

    # Роли
    r_owner = Role(name="owner", is_superuser=True)
    r_mgr = Role(name="manager", is_superuser=False)
    r_cashier = Role(name="cashier", is_superuser=False)
    db_session.add_all([r_owner, r_mgr, r_cashier])
    await db_session.commit()
    await db_session.refresh(r_owner)
    await db_session.refresh(r_mgr)
    await db_session.refresh(r_cashier)

    # Привязка права к роли управляющего
    db_session.add(RolePermission(role_id=r_mgr.id, permission_id=perm_users.id))
    await db_session.commit()

    # Пользователи: Owner и Manager
    u_owner = User(tenant_id=tenant.id, username="owner_boss", full_name="Boss", hashed_password="h", is_active=True)
    u_mgr = User(tenant_id=tenant.id, username="mgr_sam", full_name="Sam", hashed_password="h", is_active=True)
    db_session.add_all([u_owner, u_mgr])
    await db_session.commit()
    await db_session.refresh(u_owner)
    await db_session.refresh(u_mgr)

    db_session.add(UserRole(user_id=u_owner.id, role_id=r_owner.id))
    db_session.add(UserRole(user_id=u_mgr.id, role_id=r_mgr.id))
    await db_session.commit()

    mgr_token = user_svc.create_access_token(
        user_id=u_mgr.id,
        tenant_id=tenant.id,
        permissions=["users:manage"],
        is_superuser=False,
    )
    headers = {"Authorization": f"Bearer {mgr_token}"}

    # 1. Попытка создать Owner -> 403
    resp_create_owner = await async_client.post(
        "/api/v1/users/",
        json={"username": "fake_owner", "full_name": "Fake", "password": "123", "role_ids": [r_owner.id]},
        headers=headers,
    )
    assert resp_create_owner.status_code == 403

    # 2. Попытка создать другого Manager -> 403
    resp_create_mgr = await async_client.post(
        "/api/v1/users/",
        json={"username": "fake_mgr", "full_name": "Fake", "password": "123", "role_ids": [r_mgr.id]},
        headers=headers,
    )
    assert resp_create_mgr.status_code == 403

    # 3. Создание кассира -> 201 Успех
    resp_create_cashier = await async_client.post(
        "/api/v1/users/",
        json={"username": "cashier_katya", "full_name": "Katya", "password": "123", "role_ids": [r_cashier.id]},
        headers=headers,
    )
    assert resp_create_cashier.status_code == 201

    # 4. Попытка изменить владельца -> 403
    resp_edit_owner = await async_client.put(
        f"/api/v1/users/{u_owner.id}",
        json={"full_name": "Hacked Boss"},
        headers=headers,
    )
    assert resp_edit_owner.status_code == 403

    # 5. Попытка удалить владельца -> 403
    resp_del_owner = await async_client.delete(f"/api/v1/users/{u_owner.id}", headers=headers)
    assert resp_del_owner.status_code == 403


# ──────────────────────────────────────────────────────────────────────────────
#  4. Серверное ограничение списка заказов для Кассира (только открытая смена)
# ──────────────────────────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_cashier_orders_limited_to_open_shift(async_client: AsyncClient, db_session):
    """Кассир видит заказы строго текущей открытой смены, без открытой смены — []."""
    tenant = Tenant(name="Shift Orders Cafe", schema_name="public", is_active=True)
    db_session.add(tenant)
    await db_session.commit()
    await db_session.refresh(tenant)

    perm_orders = Permission(code="orders:view", description="View orders")
    db_session.add(perm_orders)
    await db_session.commit()
    await db_session.refresh(perm_orders)

    role_cashier = Role(name="cashier", is_superuser=False)
    role_owner = Role(name="owner", is_superuser=True)
    db_session.add_all([role_cashier, role_owner])
    await db_session.commit()
    await db_session.refresh(role_cashier)
    await db_session.refresh(role_owner)

    db_session.add(RolePermission(role_id=role_cashier.id, permission_id=perm_orders.id))
    await db_session.commit()

    cashier_user = User(tenant_id=tenant.id, username="cashier_ivan", full_name="Ivan", hashed_password="h", is_active=True)
    owner_user = User(tenant_id=tenant.id, username="owner_max", full_name="Max", hashed_password="h", is_active=True)
    db_session.add_all([cashier_user, owner_user])
    await db_session.commit()
    await db_session.refresh(cashier_user)
    await db_session.refresh(owner_user)

    db_session.add(UserRole(user_id=cashier_user.id, role_id=role_cashier.id))
    db_session.add(UserRole(user_id=owner_user.id, role_id=role_owner.id))
    await db_session.commit()

    c_token = user_svc.create_access_token(user_id=cashier_user.id, tenant_id=tenant.id, permissions=["orders:view"], is_superuser=False)
    o_token = user_svc.create_access_token(user_id=owner_user.id, tenant_id=tenant.id, permissions=[], is_superuser=True)
    c_headers = {"Authorization": f"Bearer {c_token}"}
    o_headers = {"Authorization": f"Bearer {o_token}"}

    # Без открытой смены -> кассир получает []
    res_no_shift = await async_client.get("/api/v1/orders/", headers=c_headers)
    assert res_no_shift.status_code == 200
    assert res_no_shift.json() == []

    # Создаем закрытую смену #1 с заказом #101
    shift1 = Shift(opened_by=cashier_user.id, opening_cash=100.0, is_open=False)
    db_session.add(shift1)
    await db_session.commit()
    await db_session.refresh(shift1)

    order1 = Order(shift_id=shift1.id, created_by=cashier_user.id, order_number=101, status=OrderStatus.COMPLETED, total=500.0)
    db_session.add(order1)

    # Создаем текущую открытую смену #2 с заказом #102
    shift2 = Shift(opened_by=cashier_user.id, opening_cash=200.0, is_open=True)
    db_session.add(shift2)
    await db_session.commit()
    await db_session.refresh(shift2)

    order2 = Order(shift_id=shift2.id, created_by=cashier_user.id, order_number=102, status=OrderStatus.NEW, total=300.0)
    db_session.add(order2)
    await db_session.commit()

    # Кассир запрашивает заказы -> видит ТОЛЬКО заказ #102 из текущей смены
    res_cashier = await async_client.get("/api/v1/orders/", headers=c_headers)
    assert res_cashier.status_code == 200
    data_c = res_cashier.json()
    assert len(data_c) == 1
    assert data_c[0]["order_number"] == 102

    # Владелец видит все заказы
    res_owner = await async_client.get("/api/v1/orders/", headers=o_headers)
    assert res_owner.status_code == 200
    data_o = res_owner.json()
    assert len(data_o) == 2


# ──────────────────────────────────────────────────────────────────────────────
#  5. Идемпотентность кассовых операций и блокировка столов
# ──────────────────────────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_cash_operation_idempotency(db_session):
    """Повторный запрос кассовой операции с тем же client_uuid не создает дубликата."""
    tenant = Tenant(name="Cash Idemp Cafe", schema_name="public", is_active=True)
    db_session.add(tenant)
    await db_session.commit()
    await db_session.refresh(tenant)

    user = User(tenant_id=tenant.id, username="cash_user", full_name="Cash User", hashed_password="h", is_active=True)
    db_session.add(user)
    await db_session.commit()
    await db_session.refresh(user)

    shift = Shift(opened_by=user.id, opening_cash=1000.0, is_open=True)
    db_session.add(shift)
    await db_session.commit()
    await db_session.refresh(shift)

    op_data = CashOperationCreate(
        client_uuid="uuid-cash-12345",
        shift_id=shift.id,
        type=CashOperationType.WITHDRAWAL,
        amount=150.0,
        category="Хозтовары",
        comment="Мыло и салфетки",
    )

    op1, bal1 = await create_cash_operation(db_session, user_id=user.id, data=op_data)
    await db_session.commit()
    assert op1.id is not None
    assert bal1 == 850.0

    # Повторный вызов с тем же client_uuid
    op2, bal2 = await create_cash_operation(db_session, user_id=user.id, data=op_data)
    assert op2.id == op1.id
    assert bal2 == 850.0


@pytest.mark.asyncio
async def test_settle_table_order_duplicate_guard(db_session):
    """Попытка повторного расчета уже закрытого столика бросает ConflictError."""
    tenant = Tenant(name="Settle Guard Cafe", schema_name="public", is_active=True)
    db_session.add(tenant)
    await db_session.commit()
    await db_session.refresh(tenant)

    user = User(tenant_id=tenant.id, username="settle_user", full_name="Settle User", hashed_password="h", is_active=True)
    db_session.add(user)
    await db_session.commit()
    await db_session.refresh(user)

    shift = Shift(opened_by=user.id, opening_cash=500.0, is_open=True)
    db_session.add(shift)
    await db_session.commit()
    await db_session.refresh(shift)

    order = Order(
        shift_id=shift.id,
        created_by=user.id,
        order_number=505,
        status=OrderStatus.COMPLETED,
        total=1200.0,
        table_number="Стол 7",
    )
    db_session.add(order)
    await db_session.commit()
    await db_session.refresh(order)

    with pytest.raises(ConflictError) as exc_info:
        await settle_table_order(db_session, user, order.id, payment_method="cash")
    assert "уже был оплачен" in exc_info.value.detail


@pytest.mark.asyncio
async def test_system_logs_require_admin_token(async_client: AsyncClient):
    """Системные логи недоступны без валидного x-system-token."""
    resp = await async_client.get("/system/logs")
    assert resp.status_code in (422, 403)


@pytest.mark.asyncio
async def test_list_roles_filters_canonical_only(db_session):
    """Проверяем, что list_roles возвращает строго 3 канонические роли (owner, manager, cashier)."""
    # Добавляем устаревшие и канонические роли в БД
    r_owner = Role(name="owner", description="Владелец")
    r_manager = Role(name="manager", description="Управляющий")
    r_cashier = Role(name="cashier", description="Кассир")
    r_cook = Role(name="cook", description="Повар (legacy)")
    r_waiter = Role(name="waiter", description="Официант (legacy)")

    db_session.add_all([r_owner, r_manager, r_cashier, r_cook, r_waiter])
    await db_session.commit()

    roles = await user_svc.list_roles(db_session)
    names = {r.name for r in roles}

    # Строго канонические роли
    assert "owner" in names
    assert "manager" in names
    assert "cashier" in names
    # Устаревшие роли отсекаются
    assert "cook" not in names
    assert "waiter" not in names
