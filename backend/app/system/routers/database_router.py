from typing import Annotated, Any, Dict
import datetime
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import MetaData, Table, text

from app.database import get_session
from .tenant_router import require_system_admin

router = APIRouter(tags=["System — DB Inspector"])


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
            "primary_key": c.primary_key,
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
            if "INT" in col_type:
                res[k] = int(v)
            elif any(t in col_type for t in ("FLOAT", "NUMERIC", "DECIMAL", "REAL", "DOUBLE")):
                res[k] = float(v)
            elif "BOOLEAN" in col_type:
                res[k] = str(v).lower() in ("true", "1", "t", "yes", "y")
            else:
                res[k] = v
        except Exception:
            res[k] = v
    return res


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


@router.get("/tenants/{schema_name}/tables/{table_name}", dependencies=[Depends(require_system_admin)])
async def get_table_data(
    schema_name: str,
    table_name: str,
    session: Annotated[AsyncSession, Depends(get_session)],
    limit: int = 100,
    offset: int = 0,
):
    """Get columns and rows from a specific table."""
    try:
        conn = await session.connection()
        table_def, columns, pk_columns = await conn.run_sync(_reflect_table, schema_name, table_name)
    except Exception as e:
        print(f"Exception during reflection: {e}")
        raise HTTPException(status_code=404, detail=f"Table {table_name} not found in schema {schema_name}")

    stmt = table_def.select().limit(limit).offset(offset)
    result = await session.execute(stmt)
    rows = [dict(row._mapping) for row in result.fetchall()]

    return {
        "table": table_name,
        "columns": columns,
        "primary_keys": pk_columns,
        "rows": rows,
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
    except Exception:
        raise HTTPException(status_code=404, detail="Table not found")

    casted_payload = _cast_payload(payload, table_def)
    now = datetime.datetime.utcnow()
    if "created_at" in table_def.columns and casted_payload.get("created_at") is None:
        casted_payload["created_at"] = now
    if "updated_at" in table_def.columns and casted_payload.get("updated_at") is None:
        casted_payload["updated_at"] = now

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
    payload: Dict[str, Any],
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

    casted_pk_payload = _cast_payload(payload, table_def)
    where_clauses = []
    for pk in pk_columns:
        pk_val = casted_pk_payload.get(pk)
        if pk_val is None:
            raise HTTPException(status_code=400, detail=f"Missing primary key: {pk}")
        where_clauses.append(table_def.c[pk] == pk_val)

    casted_payload = _cast_payload(payload, table_def)
    update_values = {k: v for k, v in casted_payload.items() if k not in pk_columns}

    if not update_values:
        raise HTTPException(status_code=400, detail="No fields to update")

    if "updated_at" in table_def.columns and not update_values.get("updated_at"):
        update_values["updated_at"] = datetime.datetime.utcnow()

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
    pk_payload: Dict[str, Any],
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
