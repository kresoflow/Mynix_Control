import pytest
from httpx import AsyncClient
from sqlmodel import select

from app.users.models import Tenant, Role, User, UserRole
from app.users import services as user_svc
from app.pos.models import Shift, CashTransaction, CashTransactionType, Order


@pytest.mark.asyncio
async def test_pos_shift_lifecycle_x_and_z_reports(async_client: AsyncClient, db_session):
    """
    E2E Test:
    1. Open cash shift with 500 c.
    2. Try to open second shift -> error (only 1 shift open).
    3. Record cash expense (50 c for cleaning supplies).
    4. Check X-Report statistics (opening cash, expenses, expected cash in drawer).
    5. Close shift with actual cash 440 c -> discrepancy of -10 c (shortage).
    6. Verify shift history returns correct aggregates.
    """
    # 1. Setup Tenant & Cashier User
    tenant = Tenant(name="Shift Cafe", schema_name="public", is_active=True)
    db_session.add(tenant)
    await db_session.commit()
    await db_session.refresh(tenant)

    role = Role(name="Admin", is_superuser=True, tenant_id=tenant.id)
    db_session.add(role)
    await db_session.commit()
    await db_session.refresh(role)

    user = User(
        tenant_id=tenant.id,
        username="cashier_alice",
        full_name="Alice Cashier",
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
        permissions=["shifts:open", "shifts:close", "shifts:view", "cashbox:expense"],
        is_superuser=True,
    )
    headers = {"Authorization": f"Bearer {token}"}

    # 2. Open Shift with 500 c
    resp = await async_client.post(
        "/api/v1/shifts/open",
        json={"opening_cash": 500.0},
        headers=headers,
    )
    assert resp.status_code == 200, resp.text
    open_data = resp.json()
    assert open_data["status"] == "ok"
    shift_id = open_data["shift_id"]

    # Try to open second shift while first is active -> 400
    resp_second = await async_client.post(
        "/api/v1/shifts/open",
        json={"opening_cash": 200.0},
        headers=headers,
    )
    assert resp_second.status_code == 400

    # 3. Get Current Shift
    resp_curr = await async_client.get("/api/v1/shifts/current", headers=headers)
    assert resp_curr.status_code == 200
    assert resp_curr.json()["shift"]["id"] == shift_id
    assert resp_curr.json()["shift"]["opening_cash"] == 500.0

    # 4. Record Expense (50 c)
    resp_exp = await async_client.post(
        "/api/v1/cash/expense",
        json={"amount": 50.0, "description": "Салфетки и стаканчики"},
        headers=headers,
    )
    assert resp_exp.status_code == 200, resp_exp.text
    assert resp_exp.json()["amount"] == 50.0

    # 5. Check X-Report
    resp_x = await async_client.get("/api/v1/shifts/x-report", headers=headers)
    assert resp_x.status_code == 200, resp_x.text
    x_report = resp_x.json()
    assert x_report["shift_id"] == shift_id
    assert x_report["is_open"] is True
    assert x_report["opening_cash"] == 500.0
    assert x_report["cash_expenses"] == 50.0
    # Expected in drawer: 500 - 50 = 450.0
    assert x_report["expected_cash"] == 450.0

    # 6. Close Shift with Actual Cash 440 c (10 c shortage)
    resp_close = await async_client.post(
        "/api/v1/shifts/close",
        json={"closing_cash_actual": 440.0},
        headers=headers,
    )
    assert resp_close.status_code == 200, resp_close.text
    close_data = resp_close.json()
    assert close_data["expected"] == 450.0
    assert close_data["actual"] == 440.0
    assert close_data["discrepancy"] == -10.0

    # 7. Check Shift History
    resp_hist = await async_client.get("/api/v1/shifts/history", headers=headers)
    assert resp_hist.status_code == 200
    hist_data = resp_hist.json()
    assert len(hist_data["history"]) >= 1
    closed_item = next(s for s in hist_data["history"] if s["id"] == shift_id)
    assert closed_item["is_open"] is False
    assert closed_item["discrepancy"] == -10.0
