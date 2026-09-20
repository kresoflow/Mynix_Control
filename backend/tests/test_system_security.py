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
