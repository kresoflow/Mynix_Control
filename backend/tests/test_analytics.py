import pytest
from httpx import AsyncClient
from sqlmodel import select
from app.users.models import Tenant, Role, User, Permission, RolePermission
from app.users import services as user_svc
from app.analytics.utils import format_selected_options
from app.analytics.models import DashboardTodayRead, AnalyticsMetrics, AnalyticsXRay

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 1. UNIT TESTS: format_selected_options (Edge Cases & Safety)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

def test_format_selected_options_none():
    assert format_selected_options(None) is None

def test_format_selected_options_empty():
    assert format_selected_options({}) is None
    assert format_selected_options({"variation": "", "modifiers": []}) is None

def test_format_selected_options_invalid_types():
    assert format_selected_options("not a dict") is None
    assert format_selected_options(123) is None
    assert format_selected_options([1, 2, 3]) is None

def test_format_selected_options_variation_only():
    data = {"variation": "0.5л"}
    assert format_selected_options(data) == "0.5л"

def test_format_selected_options_modifiers_dict():
    data = {
        "modifiers": [
            {"name": "Сырный соус", "price": 30},
            {"name": "Халапеньо", "price": 20},
            {"name": None},  # empty name check
        ]
    }
    assert format_selected_options(data) == "Сырный соус, Халапеньо"

def test_format_selected_options_modifiers_strings():
    data = {"modifiers": ["Кетчуп", "Майонез", ""]}
    assert format_selected_options(data) == "Кетчуп, Майонез"

def test_format_selected_options_combined():
    data = {
        "variation": "Большой",
        "modifiers": [{"name": "Двойной сыр"}, {"name": "Бекон"}]
    }
    assert format_selected_options(data) == "Большой, Двойной сыр, Бекон"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 2. INTEGRATION TESTS: Endpoints & Permissions (Regression Safety)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

@pytest.mark.asyncio
async def test_analytics_endpoints_and_permissions(async_client: AsyncClient, db_session):
    # 1. Setup Tenant and Role with 'analytics:view' permission
    tenant = Tenant(name="Analytics Cafe", schema_name="public", is_active=True)
    db_session.add(tenant)
    await db_session.commit()
    await db_session.refresh(tenant)

    # Permission
    perm = Permission(code="analytics:view", description="View analytics and dashboards")
    db_session.add(perm)
    await db_session.commit()
    await db_session.refresh(perm)

    role_manager = Role(name="Manager", is_superuser=False, tenant_id=tenant.id)
    db_session.add(role_manager)
    await db_session.commit()
    await db_session.refresh(role_manager)

    role_perm = RolePermission(role_id=role_manager.id, permission_id=perm.id)
    db_session.add(role_perm)
    await db_session.commit()

    # User with Manager Role
    user_create = type("UserCreate", (), {
        "username": "manager",
        "full_name": "Store Manager",
        "password": "managerpass",
        "pin_code": "1111",
        "tenant_id": tenant.id,
        "role_ids": [role_manager.id]
    })()
    from app.users.models import UserCreate
    user = await user_svc.create_user(db_session, UserCreate(
        username="manager",
        full_name="Store Manager",
        password="managerpass",
        pin_code="1111",
        tenant_id=tenant.id,
        role_ids=[role_manager.id]
    ))
    await db_session.commit()

    # User without Permissions (Cashier with no analytics)
    role_cashier = Role(name="Cashier", is_superuser=False, tenant_id=tenant.id)
    db_session.add(role_cashier)
    await db_session.commit()
    await db_session.refresh(role_cashier)

    cashier = await user_svc.create_user(db_session, UserCreate(
        username="cashier",
        full_name="Cashier User",
        password="cashierpass",
        pin_code="2222",
        tenant_id=tenant.id,
        role_ids=[role_cashier.id]
    ))
    await db_session.commit()

    # 2. Login Manager (Authorized)
    login_res = await async_client.post("/api/v1/auth/login", data={"username": "manager", "password": "managerpass"})
    assert login_res.status_code == 200
    manager_token = login_res.json()["access_token"]
    manager_headers = {"Authorization": f"Bearer {manager_token}"}

    # 3. Test /dashboard/today (Guarantees Fix #1: NOT 404)
    dash_res = await async_client.get("/api/v1/dashboard/today", headers=manager_headers)
    assert dash_res.status_code == 200, f"Failed with {dash_res.status_code}: {dash_res.text}"
    dash_data = dash_res.json()
    assert "total_revenue" in dash_data
    assert "total_orders" in dash_data
    assert "low_stock_alerts" in dash_data

    # 4. Test /analytics/metrics (Guarantees Fix #3: 'analytics:view' works)
    metrics_res = await async_client.get("/api/v1/analytics/metrics?period=today", headers=manager_headers)
    assert metrics_res.status_code == 200
    metrics_data = metrics_res.json()
    assert "total_revenue" in metrics_data
    assert "time_series" in metrics_data

    # 5. Test /analytics/xray (Guarantees Fix #3: 'analytics:view' works)
    xray_res = await async_client.get("/api/v1/analytics/xray?period=today", headers=manager_headers)
    assert xray_res.status_code == 200
    xray_data = xray_res.json()
    assert "categories" in xray_data
    assert "items" in xray_data

    # 6. Test Forbidden Access (Security check)
    login_cashier = await async_client.post("/api/v1/auth/login", data={"username": "cashier", "password": "cashierpass"})
    assert login_cashier.status_code == 200
    cashier_token = login_cashier.json()["access_token"]
    cashier_headers = {"Authorization": f"Bearer {cashier_token}"}

    forbidden_dash = await async_client.get("/api/v1/dashboard/today", headers=cashier_headers)
    assert forbidden_dash.status_code == 403

    forbidden_metrics = await async_client.get("/api/v1/analytics/metrics", headers=cashier_headers)
    assert forbidden_metrics.status_code == 403
