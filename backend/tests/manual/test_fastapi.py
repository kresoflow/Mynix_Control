from fastapi.testclient import TestClient
import sys
import json
sys.stdout.reconfigure(encoding='utf-8')

from app.main import app
from app.users.models import User
from app.dependencies import get_current_user, get_tenant_session
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from app.database import async_session_factory

# Mock get_current_user to be superuser to bypass permissions
async def mock_get_current_user():
    user = User(id=1, username="owner", role="owner", tenant_id="tenant_1")
    # if require_permission checks user_svc.is_superuser, owner might be it.
    # Let's just monkeypatch the check
    return user

async def mock_get_tenant_session():
    async with async_session_factory() as session:
        await session.execute(text("SET search_path TO tenant_1"))
        yield session

import app.users.services as user_svc
user_svc.is_superuser = lambda u: True

app.dependency_overrides[get_current_user] = mock_get_current_user
app.dependency_overrides[get_tenant_session] = mock_get_tenant_session

client = TestClient(app)
response = client.get("/api/v1/menu/")
print("Status:", response.status_code)
if response.status_code == 200:
    items = response.json()
    for item in items[-3:]:
        print(json.dumps(item, ensure_ascii=False))
else:
    print(response.json())
