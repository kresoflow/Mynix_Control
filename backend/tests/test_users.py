import pytest
from httpx import AsyncClient
from sqlmodel import select
from app.users.models import Tenant, Role, User, Permission
from app.users import services as svc

@pytest.mark.asyncio
async def test_user_creation_and_login(async_client: AsyncClient, db_session):
    # 1. Setup Tenant and Superuser Role directly in DB
    tenant = Tenant(name="Test Cafe", is_active=True)
    db_session.add(tenant)
    await db_session.commit()
    await db_session.refresh(tenant)

    role = Role(name="Owner", is_superuser=True, tenant_id=tenant.id)
    db_session.add(role)
    await db_session.commit()
    await db_session.refresh(role)

    # 2. Create User using service
    user_data = type("UserCreate", (), {
        "username": "admin",
        "full_name": "Admin",
        "password": "password123",
        "pin_code": "1234",
        "tenant_id": tenant.id,
        "role_ids": [role.id]
    })()
    
    # We bypass Pydantic model for test simplicity or use the actual schema
    from app.users.models import UserCreate
    user_create = UserCreate(
        username="admin",
        full_name="Admin",
        password="password123",
        pin_code="1234",
        tenant_id=tenant.id,
        role_ids=[role.id]
    )
    
    user = await svc.create_user(db_session, user_create)
    await db_session.commit()
    assert user.id is not None

    # 3. Test Login API
    login_data = {
        "username": "admin",
        "password": "password123"
    }
    response = await async_client.post("/api/v1/auth/login", data=login_data)
    assert response.status_code == 200
    token_data = response.json()
    assert "access_token" in token_data
    token = token_data["access_token"]

    # 4. Test /auth/me API
    headers = {"Authorization": f"Bearer {token}"}
    me_response = await async_client.get("/api/v1/auth/me", headers=headers)
    assert me_response.status_code == 200
    me_data = me_response.json()
    assert me_data["username"] == "admin"
    assert "Owner" in me_data["roles"]

@pytest.mark.asyncio
async def test_pin_login(async_client: AsyncClient, db_session):
    tenant = Tenant(name="Test Cafe")
    db_session.add(tenant)
    await db_session.commit()

    from app.users.models import UserCreate
    user_create = UserCreate(
        username="cashier",
        full_name="Cashier",
        password="pwd",
        pin_code="9999",
        tenant_id=tenant.id,
        role_ids=[]
    )
    await svc.create_user(db_session, user_create)

    # Login with PIN
    response = await async_client.post("/api/v1/auth/pin", json={
        "pin_code": "9999",
        "tenant_id": tenant.id
    })
    assert response.status_code == 200
    assert "access_token" in response.json()
