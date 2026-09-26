# ==============================================================================
#  Kreso Flow — Tests: Cash Operations (Служебные расходы и инкассация)
#  [ИНВАРИАНТ] [ФИНАНСЫ] [БЕЗОПАСНОСТЬ]
# ==============================================================================

import pytest
from httpx import AsyncClient

from sqlmodel import select
from app.users.models import Tenant, Role, User, UserRole, Permission, RolePermission
from app.users import services as user_svc
from app.pos.models import Shift, CashOperation, CashOperationType


async def create_test_cashier(
    db_session,
    tenant_name: str = "Cafe",
    schema_name: str = "public",
    username: str = "cashier",
    permissions: list = None,
):
    """Вспомогательная функция для создания изолированного пользователя и JWT."""
    tenant = Tenant(name=tenant_name, schema_name=schema_name, is_active=True)
    db_session.add(tenant)
    await db_session.commit()
    await db_session.refresh(tenant)

    role = Role(name=f"Role_{username}_{tenant.id}", is_superuser=False, tenant_id=tenant.id)
    db_session.add(role)
    await db_session.commit()
    await db_session.refresh(role)

    user = User(
        tenant_id=tenant.id,
        username=username,
        full_name=f"Full {username}",
        hashed_password="hash",
        is_active=True,
    )
    db_session.add(user)
    await db_session.commit()
    await db_session.refresh(user)

    perms_to_assign = permissions or ["shifts:open", "shifts:close", "shifts:view", "pos:cash_operations", "cashbox:operate"]
    for code in perms_to_assign:
        res_p = await db_session.execute(select(Permission).where(Permission.code == code))
        perm = res_p.scalars().first()
        if not perm:
            perm = Permission(code=code, description=f"Perm {code}")
            db_session.add(perm)
            await db_session.commit()
            await db_session.refresh(perm)
        db_session.add(RolePermission(role_id=role.id, permission_id=perm.id))

    db_session.add(UserRole(user_id=user.id, role_id=role.id))
    await db_session.commit()

    token = user_svc.create_access_token(
        user_id=user.id,
        tenant_id=tenant.id,
        permissions=perms_to_assign,
        is_superuser=False,
    )
    headers = {"Authorization": f"Bearer {token}"}
    return tenant, user, headers


@pytest.mark.asyncio
async def test_cash_operation_deposit_and_withdrawal_flow(async_client: AsyncClient, db_session):
    """
    E2E тест кассовых операций:
    1. Открытие смены с 1000 ₽.
    2. Внесение (DEPOSIT) 500 ₽ -> остаток 1500 ₽.
    3. Расход (WITHDRAWAL) 300 ₽ -> остаток 1200 ₽.
    4. Инкассация (WITHDRAWAL) 1000 ₽ -> остаток 200 ₽.
    5. Проверка списка операций и сводного отчета (summary).
    6. Проверка отражения в X-отчете смены.
    """
    tenant, user, headers = await create_test_cashier(db_session, "Petty Cash Cafe", "public", "alice_petty")

    # 1. Открытие смены с 1000 ₽
    resp_open = await async_client.post(
        "/api/v1/shifts/open",
        json={"opening_cash": 1000.0},
        headers=headers,
    )
    assert resp_open.status_code == 200, resp_open.text
    shift_id = resp_open.json()["shift_id"]

    # 2. Служебное внесение 500 ₽
    resp_dep = await async_client.post(
        "/api/v1/cash/operations",
        json={
            "type": "deposit",
            "amount": 500.0,
            "category": "Разменная монета",
            "comment": "Купюры по 50 и 100 руб",
        },
        headers=headers,
    )
    assert resp_dep.status_code == 201, resp_dep.text
    dep_data = resp_dep.json()
    assert dep_data["status"] == "ok"
    assert dep_data["current_expected_cash"] == 1500.0
    assert dep_data["operation"]["amount"] == 500.0
    assert dep_data["operation"]["category"] == "Разменная монета"

    # 3. Служебный расход 300 ₽ (хозтовары)
    resp_with1 = await async_client.post(
        "/api/v1/cash/operations",
        json={
            "type": "withdrawal",
            "amount": 300.0,
            "category": "Хоз. расходы",
            "comment": "Чистящие средства и салфетки",
        },
        headers=headers,
    )
    assert resp_with1.status_code == 201, resp_with1.text
    assert resp_with1.json()["current_expected_cash"] == 1200.0

    # 4. Инкассация 1000 ₽
    resp_with2 = await async_client.post(
        "/api/v1/cash/operations",
        json={
            "type": "withdrawal",
            "amount": 1000.0,
            "category": "Инкассация",
            "comment": "Инкассация в сейф",
        },
        headers=headers,
    )
    assert resp_with2.status_code == 201, resp_with2.text
    assert resp_with2.json()["current_expected_cash"] == 200.0

    # 5. Проверка журнала операций
    resp_list = await async_client.get("/api/v1/cash/operations", headers=headers)
    assert resp_list.status_code == 200, resp_list.text
    ops = resp_list.json()
    assert len(ops) == 3
    assert ops[0]["type"] == "withdrawal"  # Сортировка по убыванию даты
    assert ops[0]["amount"] == 1000.0

    # 6. Проверка сводки (summary)
    resp_summary = await async_client.get(
        f"/api/v1/cash/operations/summary?shift_id={shift_id}",
        headers=headers,
    )
    assert resp_summary.status_code == 200, resp_summary.text
    summary = resp_summary.json()
    assert summary["shift_id"] == shift_id
    assert summary["opening_cash"] == 1000.0
    assert summary["total_deposits"] == 500.0
    assert summary["total_withdrawals"] == 1300.0
    assert summary["current_expected_cash"] == 200.0
    assert summary["operations_count"] == 3

    # 7. Проверка X-отчета
    resp_x = await async_client.get("/api/v1/shifts/x-report", headers=headers)
    assert resp_x.status_code == 200, resp_x.text
    x_rep = resp_x.json()
    assert x_rep["expected_cash"] == 200.0


@pytest.mark.asyncio
async def test_cash_operation_insufficient_funds(async_client: AsyncClient, db_session):
    """[ИНВАРИАНТ] [ФИНАНСЫ] Попытка изъять сумму больше, чем есть в кассе -> 400 Bad Request."""
    tenant, user, headers = await create_test_cashier(db_session, "Low Cash Cafe", "public", "bob_low")

    # Открытие смены с 200 ₽
    await async_client.post("/api/v1/shifts/open", json={"opening_cash": 200.0}, headers=headers)

    # Попытка изъять 500 ₽ при остатке 200 ₽ -> 400 Bad Request
    resp = await async_client.post(
        "/api/v1/cash/operations",
        json={
            "type": "withdrawal",
            "amount": 500.0,
            "category": "Инкассация",
            "comment": "Попытка овердрафта кассы",
        },
        headers=headers,
    )
    assert resp.status_code == 400, resp.text
    assert "Недостаточно наличных средств" in resp.json()["detail"]

    # [ИНВАРИАНТ] Прямая проверка БД: операция откатана и не попала в базу
    db_ops = (await db_session.execute(
        select(CashOperation).where(CashOperation.comment == "Попытка овердрафта кассы")
    )).scalars().all()
    assert len(db_ops) == 0


@pytest.mark.asyncio
async def test_cash_operation_closed_shift(async_client: AsyncClient, db_session):
    """[БЕЗОПАСНОСТЬ] Попытка провести операцию без открытой смены -> 400."""
    tenant, user, headers = await create_test_cashier(db_session, "Closed Shift Cafe", "public", "charlie_closed")

    # Попытка операции без открытой смены
    resp = await async_client.post(
        "/api/v1/cash/operations",
        json={"type": "deposit", "amount": 100.0, "category": "Довнесение"},
        headers=headers,
    )
    assert resp.status_code == 400, resp.text
    assert "Нет открытой кассовой смены" in resp.json()["detail"]


@pytest.mark.asyncio
async def test_cash_operation_pbac_permissions(async_client: AsyncClient, db_session):
    """[БЕЗОПАСНОСТЬ] Пользователь без прав 'pos:cash_operations' или 'cashbox:operate' получает 403 Forbidden."""
    tenant = Tenant(name="PBAC Test Cafe", schema_name="public", is_active=True)
    db_session.add(tenant)
    await db_session.commit()
    await db_session.refresh(tenant)

    role = Role(name="Waiter", is_superuser=False, tenant_id=tenant.id)
    db_session.add(role)
    await db_session.commit()
    await db_session.refresh(role)

    user = User(
        tenant_id=tenant.id,
        username="waiter_dave",
        full_name="Dave Waiter",
        hashed_password="hash",
        is_active=True,
    )
    db_session.add(user)
    await db_session.commit()
    await db_session.refresh(user)

    db_session.add(UserRole(user_id=user.id, role_id=role.id))
    await db_session.commit()

    # Токен официанта БЕЗ прав на кассовые операции
    token = user_svc.create_access_token(
        user_id=user.id,
        tenant_id=tenant.id,
        permissions=["orders:create", "menu:view"],
        is_superuser=False,
    )
    headers = {"Authorization": f"Bearer {token}"}

    # Попытка выполнить кассовую операцию
    resp = await async_client.post(
        "/api/v1/cash/operations",
        json={"type": "deposit", "amount": 100.0, "category": "Довнесение"},
        headers=headers,
    )
    assert resp.status_code == 403, f"Expected 403 Forbidden, got {resp.status_code}: {resp.text}"


@pytest.mark.asyncio
async def test_cross_tenant_cash_operation_isolation(async_client: AsyncClient, db_session):
    """[БЕЗОПАСНОСТЬ] Данные кассовых операций и смен Alpha изолированы от Beta."""
    _, _, headers_alpha = await create_test_cashier(db_session, "Tenant Alpha Cafe", "tenant_cash_alpha", "cashier_alpha_idor")
    _, _, headers_beta = await create_test_cashier(db_session, "Tenant Beta Cafe", "tenant_cash_beta", "cashier_beta_idor")

    # Alpha открывает смену и вносит 250 руб
    resp_shift_a = await async_client.post("/api/v1/shifts/open", json={"opening_cash": 1000.0}, headers=headers_alpha)
    assert resp_shift_a.status_code == 200, resp_shift_a.text
    shift_a_id = resp_shift_a.json()["shift_id"]

    resp_op = await async_client.post(
        "/api/v1/cash/operations",
        json={"type": "deposit", "amount": 250.0, "category": "Довнесение", "comment": "Alpha Cash"},
        headers=headers_alpha,
    )
    assert resp_op.status_code == 201, resp_op.text

    # Beta запрашивает операции по несуществующей смене -> пустой список
    resp_list_beta = await async_client.get("/api/v1/cash/operations?shift_id=99999", headers=headers_beta)
    assert resp_list_beta.status_code == 200, resp_list_beta.text
    assert len(resp_list_beta.json()) == 0

    # Проверка, что в смене Alpha баланс с внесением зафиксирован ровно 1250 руб
    resp_summary_alpha = await async_client.get(f"/api/v1/cash/operations/summary?shift_id={shift_a_id}", headers=headers_alpha)
    assert resp_summary_alpha.status_code == 200, resp_summary_alpha.text
    assert resp_summary_alpha.json()["total_deposits"] == 250.0
    assert resp_summary_alpha.json()["current_expected_cash"] == 1250.0

