"""
Async database engine and session factory (SQLModel + asyncpg).
"""

from sqlmodel import SQLModel
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker

from app.config import settings

# ── Async Engine (for FastAPI runtime) ───────────────────────────
async_engine = create_async_engine(
    settings.database_url,
    echo=settings.debug,
    future=True,
    connect_args={"statement_cache_size": 0, "prepared_statement_cache_size": 0},
)

# ── Async Session Factory ────────────────────────────────────────
async_session_factory = sessionmaker(
    bind=async_engine,
    class_=AsyncSession,
    expire_on_commit=False,
)


async def get_public_session() -> AsyncSession:  # type: ignore[misc]
    """
    FastAPI dependency — yields an async DB session for public schema.
    """
    async with async_session_factory() as session:
        try:
            from sqlalchemy import text
            await session.execute(text("SET search_path TO public"))
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise

get_session = get_public_session


async def init_db() -> None:
    """Run Alembic upgrade to create public schema tables."""
    import asyncio
    from pathlib import Path
    from alembic.config import Config
    from alembic import command

    def run_alembic():
        base_dir = Path(__file__).resolve().parent.parent
        ini_path = base_dir / "alembic.ini"
        if ini_path.exists():
            alembic_cfg = Config(str(ini_path))
            alembic_cfg.set_main_option("script_location", str(base_dir / "alembic"))
            try:
                command.upgrade(alembic_cfg, "head")
            except Exception as e:
                print(f"Alembic upgrade notice: {e}")

    await asyncio.to_thread(run_alembic)

async def init_tenant_schema(schema_name: str) -> None:
    """Create a new tenant schema and initialize tenant-specific tables."""
    async with async_engine.begin() as conn:
        from sqlalchemy import text
        await conn.execute(text(f'CREATE SCHEMA IF NOT EXISTS "{schema_name}"'))
        await conn.execute(text(f'SET search_path TO "{schema_name}"'))
        await conn.run_sync(SQLModel.metadata.create_all)
