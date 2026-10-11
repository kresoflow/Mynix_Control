import pytest
from httpx import AsyncClient, ASGITransport
from app.main import app
from app.config import settings
from app.system.security import reset_rate_limiter, MAX_FAILED_ATTEMPTS
from app.system.routers.tenant_router import TenantCreateRequest
from pydantic import ValidationError


@pytest.mark.asyncio
async def test_superadmin_brute_force_protection():
    """Verify that multiple incorrect token attempts trigger rate limiting and 429 lockout."""
    reset_rate_limiter()
    transport = ASGITransport(app=app)

    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        # Send MAX_FAILED_ATTEMPTS incorrect requests
        for i in range(MAX_FAILED_ATTEMPTS):
            resp = await ac.get(
                "/api/v1/system/tenants",
                headers={"X-System-Token": f"wrong_token_{i}"},
            )
            assert resp.status_code == 403, f"Expected 403 on attempt {i+1}, got {resp.status_code}"

        # The subsequent request must trigger HTTP 429 Too Many Requests
        lockout_resp = await ac.get(
            "/api/v1/system/tenants",
            headers={"X-System-Token": "another_wrong_token"},
        )
        assert lockout_resp.status_code == 429
        assert "Too many failed attempts" in lockout_resp.json()["detail"]
        assert "retry-after" in lockout_resp.headers

        # Even a correct token is locked out during the ban period
        blocked_correct_resp = await ac.get(
            "/api/v1/system/tenants",
            headers={"X-System-Token": settings.system_admin_token},
        )
        assert blocked_correct_resp.status_code == 429
    reset_rate_limiter()


@pytest.mark.asyncio
async def test_superadmin_valid_token_success():
    """Verify that a valid token grants access and resets any previous failure counters."""
    reset_rate_limiter()
    transport = ASGITransport(app=app)

    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        # Send 2 bad attempts (below threshold)
        for _ in range(2):
            bad_resp = await ac.get(
                "/api/v1/system/tenants",
                headers={"X-System-Token": "bad_token"},
            )
            assert bad_resp.status_code == 403

        # Now send the valid token
        valid_resp = await ac.get(
            "/api/v1/system/tenants",
            headers={"X-System-Token": settings.system_admin_token},
        )
        assert valid_resp.status_code == 200
        assert isinstance(valid_resp.json(), list)


def test_schema_name_validation():
    """Verify that schema_name rejects illegal characters, spaces, and reserved schemas."""
    # Valid schema names
    valid_names = ["restaurant_01", "my_cafe", "tenant_xyz_2026", "branch1"]
    for s in valid_names:
        req = TenantCreateRequest(
            name="Test",
            schema_name=s,
            owner_username="admin",
            owner_password="password123",
            owner_full_name="Admin Admin",
        )
        assert req.schema_name == s

    # Invalid schema names
    invalid_names = [
        "ab",  # too short (<3)
        "this_schema_name_is_way_too_long_for_postgres_limit_123456",  # > 30 chars
        "cafe space",  # spaces
        "Cafe-Hyphen",  # hyphen and uppercase
        "ресторан",  # cyrillic
        "public",  # reserved
        "information_schema",  # reserved
        "pg_catalog",  # reserved
    ]
    for s in invalid_names:
        with pytest.raises(ValidationError):
            TenantCreateRequest(
                name="Test",
                schema_name=s,
                owner_username="admin",
                owner_password="password123",
                owner_full_name="Admin Admin",
            )


@pytest.mark.asyncio
async def test_tenant_full_update_and_owner_management(db_session):
    """
    Проверка комплексного обновления заведения:
    метаданные, валюта, флаги KDS/Orders/Inventory и данные владельца.
    """
    from app.users.models import Tenant, User, Role, UserRole
    from app.users.services import verify_password
    from sqlmodel import select

    # 1. Создаем тестовое заведение и владельца
    tenant = Tenant(
        name="Update Cafe",
        schema_name="tenant_upd_test",
        address="Old Address 1",
        currency="сом",
        use_kds=True,
        use_orders=True,
        enable_inventory_deduction=True,
    )
    db_session.add(tenant)
    await db_session.commit()
    await db_session.refresh(tenant)

    owner_role = (await db_session.execute(select(Role).where(Role.name == "owner"))).scalars().first()
    if not owner_role:
        owner_role = Role(name="owner", is_superuser=True)
        db_session.add(owner_role)
        await db_session.commit()
        await db_session.refresh(owner_role)

    owner = User(
        tenant_id=tenant.id,
        username=f"owner_{tenant.id}",
        full_name="Old Owner Name",
        hashed_password="old_hash",
        pin_code="1111",
        phone="+996555111111",
        email="old@test.com",
    )
    db_session.add(owner)
    await db_session.commit()
    await db_session.refresh(owner)

    db_session.add(UserRole(user_id=owner.id, role_id=owner_role.id))
    await db_session.commit()

    # 2. Вызываем эндпоинт обновления через AsyncClient
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        update_payload = {
            "name": "Updated Cafe & Lounge",
            "address": "New Broadway 42",
            "currency": "USD",
            "is_active": False,
            "use_kds": False,
            "use_orders": False,
            "enable_inventory_deduction": False,
            "owner_full_name": "New Owner Full Name",
            "owner_phone": "+996777999888",
            "owner_email": "new_owner@lounge.test",
            "owner_password": "NewSecretPassword123!",
            "owner_pin_code": "9876",
        }
        resp = await ac.put(
            f"/api/v1/system/tenants/{tenant.id}",
            json=update_payload,
            headers={"X-System-Token": settings.system_admin_token},
        )
        assert resp.status_code == 200, resp.text
        assert resp.json()["id"] == tenant.id

        # 3. Проверяем получение списка
        list_resp = await ac.get(
            "/api/v1/system/tenants",
            headers={"X-System-Token": settings.system_admin_token},
        )
        assert list_resp.status_code == 200
        tenants_data = list_resp.json()
        target = next((t for t in tenants_data if t["id"] == tenant.id), None)
        assert target is not None
        assert target["name"] == "Updated Cafe & Lounge"
        assert target["address"] == "New Broadway 42"
        assert target["currency"] == "USD"
        assert target["is_active"] is False
        assert target["use_kds"] is False
        assert target["use_orders"] is False
        assert target["enable_inventory_deduction"] is False
        assert target["owner_full_name"] == "New Owner Full Name"
        assert target["owner_phone"] == "+996777999888"
        assert target["owner_email"] == "new_owner@lounge.test"
        assert target["owner_pin_code"] == "9876"

        # 4. Проверяем авторизацию владельца с новым паролем
        login_resp = await ac.post(
            "/api/v1/auth/login",
            data={"username": f"owner_{tenant.id}", "password": "NewSecretPassword123!"},
        )
        assert login_resp.status_code == 200, login_resp.text
        assert "access_token" in login_resp.json()


@pytest.mark.asyncio
async def test_frontend_logs_endpoints_require_admin_token():
    """Эндпоинты frontend-logs защищены токеном системного администратора."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        # Без токена
        unauth_get = await ac.get("/api/v1/system/frontend-logs")
        assert unauth_get.status_code in (401, 403, 422)

        unauth_del = await ac.delete("/api/v1/system/frontend-logs")
        assert unauth_del.status_code in (401, 403, 422)

        # С валидным системным токеном
        auth_get = await ac.get(
            "/api/v1/system/frontend-logs",
            headers={"X-System-Token": settings.system_admin_token},
        )
        assert auth_get.status_code == 200
        assert "lines" in auth_get.json()

