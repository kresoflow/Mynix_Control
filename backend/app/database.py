"""
Async database engine and session factory (SQLModel + asyncpg).
"""

from pathlib import Path
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


def _load_tenant_patches() -> list[tuple[str, str]]:
    """Load all .sql migration files from backend/migrations/tenant_patches."""
    migrations_dir = Path(__file__).resolve().parent.parent / "migrations" / "tenant_patches"
    if not migrations_dir.exists():
        return []
    patches = []
    for sql_file in sorted(migrations_dir.glob("*.sql")):
        patches.append((sql_file.name, sql_file.read_text(encoding="utf-8")))
    return patches


async def apply_tenant_patches(conn, schema: str) -> None:
    """Execute SQL migration patches for a specific tenant schema."""
    import re
    from sqlalchemy import text
    patches = _load_tenant_patches()
    is_sqlite = conn.dialect.name == "sqlite"
    for patch_name, sql_template in patches:
        if is_sqlite:
            formatted_sql = (
                sql_template
                .replace('"{schema}".', '')
                .replace('{schema}.', '')
                .replace('"{schema}"', '')
                .replace('{schema}', '')
            )
        else:
            formatted_sql = sql_template.replace('"{schema}"', f'"{schema}"').replace('{schema}', schema)
        statements = [s.strip() for s in formatted_sql.split(";") if s.strip()]
        for stmt in statements:
            if is_sqlite and "ADD COLUMN IF NOT EXISTS" in stmt.upper():
                stmt = re.sub(r'ADD\s+COLUMN\s+IF\s+NOT\s+EXISTS', 'ADD COLUMN', stmt, flags=re.IGNORECASE)
            try:
                await conn.execute(text(stmt))
            except Exception:
                pass


async def init_tenant_schema(schema_name: str) -> None:
    """Create a new tenant schema and initialize tenant-specific tables."""
    # Ensure all domain models are loaded into SQLModel.metadata
    import app.users.models  # noqa: F401
    import app.inventory.models  # noqa: F401
    import app.pos.models  # noqa: F401
    import app.crm.models  # noqa: F401
    import app.analytics.models  # noqa: F401
    import app.gift_cards.models  # noqa: F401

    async with async_engine.begin() as conn:
        from sqlalchemy import text
        await conn.execute(text(f'CREATE SCHEMA IF NOT EXISTS "{schema_name}"'))
        await conn.execute(text(f'SET search_path TO "{schema_name}"'))
        await conn.run_sync(SQLModel.metadata.create_all)
        await apply_tenant_patches(conn, schema_name)


async def auto_migrate_tenant_schemas() -> None:
    """Ensure all existing tenant schemas have latest columns on startup."""
    from sqlalchemy import text
    try:
        async with async_engine.begin() as conn:
            # Ensure public schema columns are up to date
            await conn.execute(text('ALTER TABLE public.tenants ADD COLUMN IF NOT EXISTS use_kds BOOLEAN DEFAULT TRUE'))
            await conn.execute(text('ALTER TABLE public.tenants ADD COLUMN IF NOT EXISTS use_orders BOOLEAN DEFAULT TRUE'))
            await conn.execute(text('ALTER TABLE public.tenants ADD COLUMN IF NOT EXISTS enable_inventory_deduction BOOLEAN DEFAULT TRUE'))
            await conn.execute(text("ALTER TABLE public.tenants ADD COLUMN IF NOT EXISTS currency VARCHAR(20) DEFAULT 'сом'"))
            await conn.execute(text("ALTER TABLE public.users ADD COLUMN IF NOT EXISTS pin_code VARCHAR(10) DEFAULT '1234'"))
            await conn.execute(text('ALTER TABLE public.users ADD COLUMN IF NOT EXISTS phone VARCHAR(50)'))
            await conn.execute(text('ALTER TABLE public.users ADD COLUMN IF NOT EXISTS email VARCHAR(255)'))
            
            # Ensure unique constraint on public.roles(name)
            res_uq = await conn.execute(text("SELECT 1 FROM pg_constraint WHERE conname = 'uq_roles_name'"))
            if not res_uq.scalar():
                await conn.execute(text("ALTER TABLE public.roles ADD CONSTRAINT uq_roles_name UNIQUE (name)"))

            # Ensure atomic permissions and roles exist in public schema
            from app.users.seed import PERMISSIONS, ROLE_TEMPLATES
            for code, desc in PERMISSIONS:
                escaped_desc = desc.replace("'", "''")
                await conn.execute(text(f'''
                    INSERT INTO public.permissions (code, description)
                    SELECT '{code}', '{escaped_desc}'
                    WHERE NOT EXISTS (SELECT 1 FROM public.permissions WHERE code = '{code}')
                '''))

            for role_name, template in ROLE_TEMPLATES.items():
                is_sup = 'TRUE' if template["is_superuser"] else 'FALSE'
                desc = template["description"].replace("'", "''")
                await conn.execute(text(f'''
                    INSERT INTO public.roles (name, description, is_superuser, created_at, updated_at)
                    SELECT '{role_name}', '{desc}', {is_sup}, NOW(), NOW()
                    WHERE NOT EXISTS (SELECT 1 FROM public.roles WHERE name = '{role_name}')
                '''))
                for perm_code in template["permissions"]:
                    await conn.execute(text(f'''
                        INSERT INTO public.role_permissions (role_id, permission_id)
                        SELECT r.id, p.id
                        FROM public.roles r, public.permissions p
                        WHERE r.name = '{role_name}' AND p.code = '{perm_code}'
                          AND NOT EXISTS (
                              SELECT 1 FROM public.role_permissions rp
                              WHERE rp.role_id = r.id AND rp.permission_id = p.id
                          )
                    '''))

        async with async_session_factory() as session:
            await session.execute(text("SET search_path TO public"))
            res = await session.execute(text("SELECT schema_name FROM public.tenants"))
            schemas = [r[0] for r in res.fetchall()]

        # Ensure all domain models are registered
        import app.users.models  # noqa: F401
        import app.inventory.models  # noqa: F401
        import app.pos.models  # noqa: F401
        import app.crm.models  # noqa: F401
        import app.analytics.models  # noqa: F401
        import app.gift_cards.models  # noqa: F401

        async with async_engine.begin() as conn:
            for schema in schemas:
                await conn.execute(text(f'CREATE SCHEMA IF NOT EXISTS "{schema}"'))
                await conn.execute(text(f'SET search_path TO "{schema}"'))
                await conn.run_sync(SQLModel.metadata.create_all)
                await apply_tenant_patches(conn, schema)
    except Exception as e:
        print(f"Tenant auto-migration notice: {e}")

