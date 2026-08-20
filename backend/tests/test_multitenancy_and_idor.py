import pytest
from httpx import AsyncClient

from app.users.models import Tenant, Role, User, UserRole
from app.users import services as user_svc


@pytest.mark.asyncio
async def test_cross_tenant_idor_isolation(async_client: AsyncClient, db_session):
    """
    Security E2E Test:
    1. Create Tenant A and Tenant B.
    2. User from Tenant B tries to modify User from Tenant A via PUT /api/v1/users/{id}.
    3. Verify system blocks cross-tenant access with 404 (IDOR prevention).
    """
    # 1. Setup Tenant A and User A
    tenant_a = Tenant(name="Tenant Alpha", schema_name="tenant_alpha", is_active=True)
    tenant_b = Tenant(name="Tenant Beta", schema_name="tenant_beta", is_active=True)
    db_session.add(tenant_a)
    db_session.add(tenant_b)
    await db_session.commit()
    await db_session.refresh(tenant_a)
    await db_session.refresh(tenant_b)

    # Roles
    role_a = Role(name="Manager A", is_superuser=True, tenant_id=tenant_a.id)
    role_b = Role(name="Manager B", is_superuser=True, tenant_id=tenant_b.id)
    db_session.add(role_a)
    db_session.add(role_b)
    await db_session.commit()
    await db_session.refresh(role_a)
    await db_session.refresh(role_b)

    # User A in Tenant A
    user_a = User(
        tenant_id=tenant_a.id,
        username="user_alpha",
        full_name="User Alpha",
        hashed_password="hash",
        is_active=True,
    )
    # User B in Tenant B
    user_b = User(
        tenant_id=tenant_b.id,
        username="user_beta",
        full_name="User Beta",
        hashed_password="hash",
        is_active=True,
    )
    db_session.add(user_a)
    db_session.add(user_b)
    await db_session.commit()
    await db_session.refresh(user_a)
    await db_session.refresh(user_b)

    db_session.add(UserRole(user_id=user_a.id, role_id=role_a.id))
    db_session.add(UserRole(user_id=user_b.id, role_id=role_b.id))
    await db_session.commit()

    # Generate token for User B (Tenant B)
    token_b = user_svc.create_access_token(
        user_id=user_b.id,
        tenant_id=tenant_b.id,
        permissions=["users:manage"],
        is_superuser=False,
    )
    headers_b = {"Authorization": f"Bearer {token_b}"}

    # 2. User B tries to update User A (Tenant A) -> must return 404 (IDOR blocked)
    resp = await async_client.put(
        f"/api/v1/users/{user_a.id}",
        json={"full_name": "Hacked Alpha Name"},
        headers=headers_b,
    )
    assert resp.status_code == 404, f"IDOR Vulnerability detected! Expected 404, got {resp.status_code}: {resp.text}"

    # 3. Verify User A was not changed
    await db_session.refresh(user_a)
    assert user_a.full_name == "User Alpha"
