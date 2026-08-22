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

async def auto_migrate_tenant_schemas() -> None:
    """Ensure all existing tenant schemas have latest columns on startup."""
    from sqlalchemy import text
    try:
        async with async_engine.begin() as conn:
            # Ensure public schema columns are up to date
            await conn.execute(text('ALTER TABLE public.tenants ADD COLUMN IF NOT EXISTS use_kds BOOLEAN DEFAULT TRUE'))
            await conn.execute(text('ALTER TABLE public.tenants ADD COLUMN IF NOT EXISTS use_orders BOOLEAN DEFAULT TRUE'))
            await conn.execute(text('ALTER TABLE public.tenants ADD COLUMN IF NOT EXISTS enable_inventory_deduction BOOLEAN DEFAULT TRUE'))
            await conn.execute(text('ALTER TABLE public.users ADD COLUMN IF NOT EXISTS pin_code VARCHAR(10) DEFAULT \'1234\''))
            await conn.execute(text('ALTER TABLE public.users ADD COLUMN IF NOT EXISTS phone VARCHAR(50)'))
            await conn.execute(text('ALTER TABLE public.users ADD COLUMN IF NOT EXISTS email VARCHAR(255)'))

        async with async_session_factory() as session:
            await session.execute(text("SET search_path TO public"))
            res = await session.execute(text("SELECT schema_name FROM public.tenants"))
            schemas = [r[0] for r in res.fetchall()]
        
        async with async_engine.begin() as conn:
            for schema in schemas:
                await conn.execute(text(f'CREATE SCHEMA IF NOT EXISTS "{schema}"'))
                # suppliers.balance
                await conn.execute(text(f'ALTER TABLE "{schema}".suppliers ADD COLUMN IF NOT EXISTS balance FLOAT DEFAULT 0.0 NOT NULL'))
                # inventory_documents payment fields
                await conn.execute(text(f'ALTER TABLE "{schema}".inventory_documents ADD COLUMN IF NOT EXISTS payment_status VARCHAR(20) DEFAULT \'unpaid\''))
                await conn.execute(text(f'ALTER TABLE "{schema}".inventory_documents ADD COLUMN IF NOT EXISTS paid_amount FLOAT DEFAULT 0.0 NOT NULL'))
                await conn.execute(text(f'ALTER TABLE "{schema}".inventory_documents ADD COLUMN IF NOT EXISTS payment_method VARCHAR(30) DEFAULT \'cash\''))
                await conn.execute(text(f'ALTER TABLE "{schema}".inventory_document_items ADD COLUMN IF NOT EXISTS expected_quantity DOUBLE PRECISION'))
                try:
                    await conn.execute(text(f'ALTER TABLE "{schema}".orders ALTER COLUMN payment_method TYPE VARCHAR(30) USING payment_method::VARCHAR'))
                    await conn.execute(text(f'UPDATE "{schema}".orders SET payment_method = LOWER(payment_method) WHERE payment_method IS NOT NULL'))
                except Exception:
                    pass
                try:
                    await conn.execute(text(f'ALTER TABLE "{schema}".orders ALTER COLUMN status TYPE VARCHAR(30) USING status::VARCHAR'))
                    await conn.execute(text(f'UPDATE "{schema}".orders SET status = LOWER(status) WHERE status IS NOT NULL'))
                except Exception:
                    pass
                # supplier_transactions table
                await conn.execute(text(f'''
                    CREATE TABLE IF NOT EXISTS "{schema}".supplier_transactions (
                        id SERIAL PRIMARY KEY,
                        supplier_id INTEGER NOT NULL REFERENCES "{schema}".suppliers(id) ON DELETE CASCADE,
                        document_id INTEGER REFERENCES "{schema}".inventory_documents(id) ON DELETE SET NULL,
                        type VARCHAR(30) NOT NULL,
                        amount DOUBLE PRECISION NOT NULL DEFAULT 0.0,
                        payment_method VARCHAR(30) DEFAULT 'cash',
                        comment VARCHAR(255),
                        date TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT (now() AT TIME ZONE 'utc'),
                        created_by INTEGER REFERENCES public.users(id) ON DELETE SET NULL,
                        created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT (now() AT TIME ZONE 'utc'),
                        updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT NULL
                    )
                '''))
                await conn.execute(text(f'CREATE INDEX IF NOT EXISTS ix_{schema}_supplier_transactions_supplier_id ON "{schema}".supplier_transactions(supplier_id)'))
                await conn.execute(text(f'CREATE INDEX IF NOT EXISTS ix_{schema}_supplier_transactions_document_id ON "{schema}".supplier_transactions(document_id)'))

                # customers table
                await conn.execute(text(f'''
                    CREATE TABLE IF NOT EXISTS "{schema}".customers (
                        id SERIAL PRIMARY KEY,
                        name VARCHAR(150) NOT NULL,
                        phone VARCHAR(50),
                        email VARCHAR(100),
                        address VARCHAR(255),
                        balance DOUBLE PRECISION NOT NULL DEFAULT 0.0,
                        credit_limit DOUBLE PRECISION NOT NULL DEFAULT 0.0,
                        discount_percent DOUBLE PRECISION NOT NULL DEFAULT 0.0,
                        notes VARCHAR(500),
                        is_active BOOLEAN NOT NULL DEFAULT true,
                        total_spent DOUBLE PRECISION NOT NULL DEFAULT 0.0,
                        orders_count INTEGER NOT NULL DEFAULT 0,
                        average_check DOUBLE PRECISION NOT NULL DEFAULT 0.0,
                        last_visit_at TIMESTAMP WITHOUT TIME ZONE DEFAULT NULL,
                        bonus_balance DOUBLE PRECISION NOT NULL DEFAULT 0.0,
                        tier_level VARCHAR(30) NOT NULL DEFAULT 'standard',
                        birth_date DATE DEFAULT NULL,
                        created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT (now() AT TIME ZONE 'utc'),
                        updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT NULL
                    )
                '''))
                await conn.execute(text(f'CREATE INDEX IF NOT EXISTS ix_{schema}_customers_name ON "{schema}".customers(name)'))
                await conn.execute(text(f'CREATE INDEX IF NOT EXISTS ix_{schema}_customers_phone ON "{schema}".customers(phone)'))

                # LTV and loyalty columns in customers if table existed previously
                await conn.execute(text(f'ALTER TABLE "{schema}".customers ADD COLUMN IF NOT EXISTS total_spent DOUBLE PRECISION NOT NULL DEFAULT 0.0'))
                await conn.execute(text(f'ALTER TABLE "{schema}".customers ADD COLUMN IF NOT EXISTS orders_count INTEGER NOT NULL DEFAULT 0'))
                await conn.execute(text(f'ALTER TABLE "{schema}".customers ADD COLUMN IF NOT EXISTS average_check DOUBLE PRECISION NOT NULL DEFAULT 0.0'))
                await conn.execute(text(f'ALTER TABLE "{schema}".customers ADD COLUMN IF NOT EXISTS last_visit_at TIMESTAMP WITHOUT TIME ZONE DEFAULT NULL'))
                await conn.execute(text(f'ALTER TABLE "{schema}".customers ADD COLUMN IF NOT EXISTS bonus_balance DOUBLE PRECISION NOT NULL DEFAULT 0.0'))
                await conn.execute(text(f'ALTER TABLE "{schema}".customers ADD COLUMN IF NOT EXISTS tier_level VARCHAR(30) NOT NULL DEFAULT \'standard\''))
                await conn.execute(text(f'ALTER TABLE "{schema}".customers ADD COLUMN IF NOT EXISTS birth_date DATE DEFAULT NULL'))

                # orders.customer_id & orders.bonus_spent & orders.client_uuid
                await conn.execute(text(f'ALTER TABLE "{schema}".orders ADD COLUMN IF NOT EXISTS customer_id INTEGER REFERENCES "{schema}".customers(id) ON DELETE SET NULL'))
                await conn.execute(text(f'ALTER TABLE "{schema}".orders ADD COLUMN IF NOT EXISTS bonus_spent DOUBLE PRECISION NOT NULL DEFAULT 0.0'))
                await conn.execute(text(f'ALTER TABLE "{schema}".orders ADD COLUMN IF NOT EXISTS client_uuid VARCHAR(64)'))
                await conn.execute(text(f'CREATE INDEX IF NOT EXISTS ix_{schema}_orders_client_uuid ON "{schema}".orders(client_uuid)'))

                # order_items columns
                await conn.execute(text(f'ALTER TABLE "{schema}".order_items ADD COLUMN IF NOT EXISTS unit_cost DOUBLE PRECISION NOT NULL DEFAULT 0.0'))
                await conn.execute(text(f'ALTER TABLE "{schema}".order_items ADD COLUMN IF NOT EXISTS item_type VARCHAR(50) DEFAULT \'dish\''))
                await conn.execute(text(f'ALTER TABLE "{schema}".order_items ADD COLUMN IF NOT EXISTS selected_options JSONB DEFAULT \'{{\}}\'::jsonb'))

                # customer_transactions table
                await conn.execute(text(f'''
                    CREATE TABLE IF NOT EXISTS "{schema}".customer_transactions (
                        id SERIAL PRIMARY KEY,
                        customer_id INTEGER NOT NULL REFERENCES "{schema}".customers(id) ON DELETE CASCADE,
                        order_id INTEGER REFERENCES "{schema}".orders(id) ON DELETE SET NULL,
                        type VARCHAR(30) NOT NULL,
                        amount DOUBLE PRECISION NOT NULL DEFAULT 0.0,
                        payment_method VARCHAR(30) DEFAULT 'cash',
                        comment VARCHAR(255),
                        date TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT (now() AT TIME ZONE 'utc'),
                        created_by INTEGER REFERENCES public.users(id) ON DELETE SET NULL,
                        created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT (now() AT TIME ZONE 'utc'),
                        updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT NULL
                    )
                '''))
                await conn.execute(text(f'CREATE INDEX IF NOT EXISTS ix_{schema}_customer_transactions_customer_id ON "{schema}".customer_transactions(customer_id)'))
                await conn.execute(text(f'CREATE INDEX IF NOT EXISTS ix_{schema}_customer_transactions_order_id ON "{schema}".customer_transactions(order_id)'))

                # bonus_transactions table
                await conn.execute(text(f'''
                    CREATE TABLE IF NOT EXISTS "{schema}".bonus_transactions (
                        id SERIAL PRIMARY KEY,
                        customer_id INTEGER NOT NULL REFERENCES "{schema}".customers(id) ON DELETE CASCADE,
                        order_id INTEGER REFERENCES "{schema}".orders(id) ON DELETE SET NULL,
                        type VARCHAR(30) NOT NULL,
                        amount DOUBLE PRECISION NOT NULL DEFAULT 0.0,
                        comment VARCHAR(255),
                        date TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT (now() AT TIME ZONE 'utc'),
                        created_by INTEGER REFERENCES public.users(id) ON DELETE SET NULL,
                        created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT (now() AT TIME ZONE 'utc'),
                        updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT NULL
                    )
                '''))
                await conn.execute(text(f'CREATE INDEX IF NOT EXISTS ix_{schema}_bonus_transactions_customer_id ON "{schema}".bonus_transactions(customer_id)'))
                await conn.execute(text(f'CREATE INDEX IF NOT EXISTS ix_{schema}_bonus_transactions_order_id ON "{schema}".bonus_transactions(order_id)'))
    except Exception as e:
        print(f"Tenant auto-migration notice: {e}")

