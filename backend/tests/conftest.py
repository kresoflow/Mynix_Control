import pytest
import pytest_asyncio
from httpx import AsyncClient, ASGITransport
from sqlmodel import SQLModel
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy import event
from sqlalchemy.pool import StaticPool
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.ext.compiler import compiles

from app.main import app
from app.database import get_session
from app.users.models import Tenant, User, Role, Permission
from app.inventory.models import Ingredient, MenuItem, Recipe, StockTransaction
from app.pos.models import Order, OrderItem

# Compile PostgreSQL JSONB as JSON for SQLite tests
@compiles(JSONB, "sqlite")
def compile_jsonb_sqlite(type_, compiler, **kw):
    return "JSON"


TEST_DATABASE_URL = "sqlite+aiosqlite:///file:testdb?mode=memory&cache=shared&uri=true"

test_engine = create_async_engine(
    TEST_DATABASE_URL,
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)


@event.listens_for(test_engine.sync_engine, "connect")
def on_connect(dbapi_connection, connection_record):
    """Attach 'public' in-memory DB so SQLite handles PostgreSQL public schema."""
    cursor = dbapi_connection.cursor()
    cursor.execute("ATTACH DATABASE ':memory:' AS public;")
    cursor.close()


TestingSessionLocal = sessionmaker(
    bind=test_engine, class_=AsyncSession, expire_on_commit=False
)


from app.dependencies import get_tenant_session

async def override_get_session():
    async with TestingSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise


async def override_get_tenant_session():
    async with TestingSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise


app.dependency_overrides[get_session] = override_get_session
app.dependency_overrides[get_tenant_session] = override_get_tenant_session


@pytest_asyncio.fixture(scope="function", autouse=True)
async def init_db():
    async with test_engine.begin() as conn:
        await conn.run_sync(SQLModel.metadata.drop_all)
        await conn.run_sync(SQLModel.metadata.create_all)
    yield
    async with test_engine.begin() as conn:
        await conn.run_sync(SQLModel.metadata.drop_all)


@pytest_asyncio.fixture(scope="function")
async def db_session():
    async with TestingSessionLocal() as session:
        yield session


@pytest_asyncio.fixture(scope="function")
async def async_client():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        yield ac
