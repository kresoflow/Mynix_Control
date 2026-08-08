from typing import Annotated, List

from fastapi import APIRouter, Depends, HTTPException, status, Header
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select
from sqlalchemy import MetaData, Table, inspect, text
from pydantic import BaseModel
from typing import Any, Dict

from app.config import settings
from app.database import get_session, init_tenant_schema
from app.users.models import Tenant, User, UserRole, Role
from app.users.services import hash_password

router = APIRouter(tags=["System Superadmin"])


def require_system_admin(x_system_token: str = Header(..., description="System Admin Secret Token")):
    """Dependency to check the static system admin token."""
    if x_system_token != settings.system_admin_token:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Invalid System Admin Token"
        )
    return True


class TenantCreateRequest(BaseModel):
    name: str
    schema_name: str
    address: str
    owner_username: str
    owner_password: str
    owner_full_name: str
    owner_pin_code: str = "0000"


class TenantRead(BaseModel):
    id: int
    name: str
    schema_name: str
    address: str
    is_active: bool
    use_kds: bool
    enable_inventory_deduction: bool
    created_at: str


@router.post("/tenants", status_code=status.HTTP_201_CREATED, dependencies=[Depends(require_system_admin)])
async def create_tenant(
    data: TenantCreateRequest,
    session: Annotated[AsyncSession, Depends(get_session)],
):
    """
    Creates a new Tenant (Restaurant).
    1. Adds tenant to public.tenants
    2. Creates the PostgreSQL schema
    3. Creates the owner user
    """
    # Check if schema exists
    existing = await session.execute(select(Tenant).where(Tenant.schema_name == data.schema_name))
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Tenant with this schema_name already exists")

    # 1. Create Tenant
    new_tenant = Tenant(
        name=data.name,
        schema_name=data.schema_name,
        address=data.address,
    )
    session.add(new_tenant)
    await session.flush()  # to get new_tenant.id

    # 2. Init DB schema
    try:
        await init_tenant_schema(new_tenant.schema_name)
    except Exception as e:
        # Rollback and raise
        await session.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to create schema: {str(e)}")

    # 3. Create owner user
    owner_role = await session.execute(select(Role).where(Role.name == "owner"))
    owner_role = owner_role.scalar_one_or_none()
    
    if not owner_role:
        raise HTTPException(status_code=500, detail="Owner role not found in system")

    hashed = hash_password(data.owner_password)
    new_owner = User(
        tenant_id=new_tenant.id,
        username=data.owner_username,
        full_name=data.owner_full_name,
        hashed_password=hashed,
        pin_code=data.owner_pin_code,
    )
    session.add(new_owner)
    await session.flush()

    session.add(UserRole(
        user_id=new_owner.id,
        role_id=owner_role.id,
    ))
    
    await session.commit()
    
    return {"message": "Tenant created successfully", "tenant_id": new_tenant.id}


@router.get("/tenants", response_model=List[TenantRead], dependencies=[Depends(require_system_admin)])
async def list_tenants(
    session: Annotated[AsyncSession, Depends(get_session)],
):
    """List all registered tenants in the system."""
    result = await session.execute(select(Tenant))
    tenants = result.scalars().all()
    
    return [
        TenantRead(
            id=t.id,
            name=t.name,
            schema_name=t.schema_name,
            address=t.address,
            is_active=t.is_active,
            use_kds=t.use_kds,
            enable_inventory_deduction=t.enable_inventory_deduction,
            created_at=t.created_at.isoformat()
        ) for t in tenants
    ]


# ── Generic DBeaver CRUD Endpoints ─────────────────────────────────────

@router.get("/tenants/{schema_name}/tables", dependencies=[Depends(require_system_admin)])
async def list_schema_tables(
    schema_name: str,
    session: Annotated[AsyncSession, Depends(get_session)],
):
    """List all base tables in a specific tenant schema."""
    query = text("""
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = :schema AND table_type = 'BASE TABLE'
    """)
    result = await session.execute(query, {"schema": schema_name})
    tables = [row[0] for row in result.fetchall()]
    return {"schema": schema_name, "tables": tables}


def _reflect_table(conn, schema_name: str, table_name: str):
    """Synchronous reflection of table metadata."""
    conn.execute(text(f'SET search_path TO "{schema_name}"'))
    metadata = MetaData(schema=schema_name)
    table = Table(table_name, metadata, autoload_with=conn)
    
    columns = [
        {
            "name": c.name, 
            "type": str(c.type), 
            "nullable": c.nullable,
            "primary_key": c.primary_key
        } 
        for c in table.columns
    ]
    pk_columns = [c.name for c in table.primary_key.columns]
    
    return table, columns, pk_columns

def _cast_payload(payload: dict, table_def) -> dict:
    """Cast string payloads to Python types suitable for asyncpg based on SQLAlchemy table metadata."""
    res = {}
    for k, v in payload.items():
        if v is None or str(v) == "":
            res[k] = None
            continue
        col = table_def.columns.get(k)
        if col is None:
            res[k] = v
            continue
            
        col_type = str(col.type).upper()
        try:
            if 'INT' in col_type:
                res[k] = int(v)
            elif 'FLOAT' in col_type or 'NUMERIC' in col_type or 'DECIMAL' in col_type or 'REAL' in col_type or 'DOUBLE' in col_type:
                res[k] = float(v)
            elif 'BOOLEAN' in col_type:
                res[k] = str(v).lower() in ('true', '1', 't', 'yes', 'y')
            else:
                res[k] = v
        except Exception:
            res[k] = v
    return res


@router.get("/tenants/{schema_name}/tables/{table_name}", dependencies=[Depends(require_system_admin)])
async def get_table_data(
    schema_name: str,
    table_name: str,
    session: Annotated[AsyncSession, Depends(get_session)],
    limit: int = 100,
    offset: int = 0
):
    """Get columns and rows from a specific table."""
    try:
        conn = await session.connection()
        table_def, columns, pk_columns = await conn.run_sync(_reflect_table, schema_name, table_name)
    except Exception as e:
        print(f"Exception during reflection: {e}")
        raise HTTPException(status_code=404, detail=f"Table {table_name} not found in schema {schema_name}")

    # Fetch data
    stmt = table_def.select().limit(limit).offset(offset)
    result = await session.execute(stmt)
    
    # We must convert values to something JSON serializable, mostly happens automatically in FastAPI, 
    # but datetime or UUID might need string casting. Let FastAPI handle standard types.
    rows = [dict(row._mapping) for row in result.fetchall()]

    return {
        "table": table_name,
        "columns": columns,
        "primary_keys": pk_columns,
        "rows": rows
    }


@router.post("/tenants/{schema_name}/tables/{table_name}", dependencies=[Depends(require_system_admin)])
async def create_table_row(
    schema_name: str,
    table_name: str,
    payload: Dict[str, Any],
    session: Annotated[AsyncSession, Depends(get_session)],
):
    """Insert a row into a specific table."""
    try:
        conn = await session.connection()
        table_def, _, _ = await conn.run_sync(_reflect_table, schema_name, table_name)
    except Exception as e:
        raise HTTPException(status_code=404, detail="Table not found")

    casted_payload = _cast_payload(payload, table_def)
    import datetime
    now = datetime.datetime.utcnow()
    if 'created_at' in table_def.columns and casted_payload.get('created_at') is None:
        casted_payload['created_at'] = now
    if 'updated_at' in table_def.columns and casted_payload.get('updated_at') is None:
        casted_payload['updated_at'] = now

    stmt = table_def.insert().values(**casted_payload).returning(table_def)
    try:
        result = await session.execute(stmt)
        await session.commit()
        inserted_row = dict(result.fetchone()._mapping)
        return {"message": "Row created", "data": inserted_row}
    except Exception as e:
        await session.rollback()
        raise HTTPException(status_code=400, detail=str(e))


@router.put("/tenants/{schema_name}/tables/{table_name}", dependencies=[Depends(require_system_admin)])
async def update_table_row(
    schema_name: str,
    table_name: str,
    payload: Dict[str, Any], # Must include PKs
    session: Annotated[AsyncSession, Depends(get_session)],
):
    """Update a row in a specific table. Payload must include the primary key(s)."""
    try:
        conn = await session.connection()
        table_def, _, pk_columns = await conn.run_sync(_reflect_table, schema_name, table_name)
    except Exception:
        raise HTTPException(status_code=404, detail="Table not found")

    if not pk_columns:
        raise HTTPException(status_code=400, detail="Table has no primary key, cannot update")

    # Build where clause
    casted_pk_payload = _cast_payload(payload, table_def)
    where_clauses = []
    for pk in pk_columns:
        pk_val = casted_pk_payload.get(pk)
        if pk_val is None:
            raise HTTPException(status_code=400, detail=f"Missing primary key: {pk}")
        where_clauses.append(table_def.c[pk] == pk_val)
        
    casted_payload = _cast_payload(payload, table_def)
    # Remove PKs from update values
    update_values = {k: v for k, v in casted_payload.items() if k not in pk_columns}
    
    if not update_values:
        raise HTTPException(status_code=400, detail="No fields to update")

    import datetime
    if 'updated_at' in table_def.columns and not update_values.get('updated_at'):
        update_values['updated_at'] = datetime.datetime.utcnow()

    stmt = table_def.update().where(*where_clauses).values(**update_values)
    try:
        result = await session.execute(stmt)
        if result.rowcount == 0:
            raise HTTPException(status_code=404, detail="Row not found")
        await session.commit()
        return {"message": "Row updated"}
    except Exception as e:
        await session.rollback()
        raise HTTPException(status_code=400, detail=str(e))


@router.delete("/tenants/{schema_name}/tables/{table_name}", dependencies=[Depends(require_system_admin)])
async def delete_table_row(
    schema_name: str,
    table_name: str,
    pk_payload: Dict[str, Any], # Pass PKs in request body for deletion
    session: Annotated[AsyncSession, Depends(get_session)],
):
    """Delete a row using its primary keys."""
    try:
        conn = await session.connection()
        table_def, _, pk_columns = await conn.run_sync(_reflect_table, schema_name, table_name)
    except Exception:
        raise HTTPException(status_code=404, detail="Table not found")

    if not pk_columns:
        raise HTTPException(status_code=400, detail="Table has no primary key, cannot delete")

    casted_pk_payload = _cast_payload(pk_payload, table_def)
    where_clauses = []
    for pk in pk_columns:
        pk_val = casted_pk_payload.get(pk)
        if pk_val is None:
            raise HTTPException(status_code=400, detail=f"Primary key '{pk}' missing from payload")
        where_clauses.append(getattr(table_def.c, pk) == pk_val)
        
    stmt = table_def.delete().where(*where_clauses)
    try:
        result = await session.execute(stmt)
        if result.rowcount == 0:
            raise HTTPException(status_code=404, detail="Row not found")
        await session.commit()
        return {"message": "Row deleted"}
    except Exception as e:
        await session.rollback()
        raise HTTPException(status_code=400, detail=str(e))

