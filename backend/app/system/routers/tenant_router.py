import re
from typing import Annotated, List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select
from pydantic import BaseModel, Field, field_validator

from app.database import get_session, init_tenant_schema
from app.users.models import Tenant, User, UserRole, Role
from app.users.services import hash_password
from app.system.security import require_system_admin

router = APIRouter(tags=["System — Tenants"])

SCHEMA_NAME_REGEX = re.compile(r"^[a-z0-9_]{3,30}$")
RESERVED_SCHEMAS = {"public", "information_schema", "pg_catalog", "pg_toast", "system"}


class TenantCreateRequest(BaseModel):
    name: str
    schema_name: str = Field(..., description="PostgreSQL schema name (lowercase letters, digits, underscore, 3-30 chars)")
    address: str = ""
    owner_username: str
    owner_password: str
    owner_full_name: str
    owner_pin_code: str = "1234"
    owner_phone: Optional[str] = None
    owner_email: Optional[str] = None
    use_kds: bool = True
    enable_inventory_deduction: bool = True

    @field_validator("schema_name")
    @classmethod
    def validate_schema_name(cls, v: str) -> str:
        clean = v.strip().lower()
        if not SCHEMA_NAME_REGEX.match(clean):
            raise ValueError(
                "schema_name must be 3-30 characters long and contain only lowercase letters, digits, and underscores"
            )
        if clean in RESERVED_SCHEMAS:
            raise ValueError(f"'{clean}' is a reserved PostgreSQL schema name")
        return clean


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
    existing = await session.execute(select(Tenant).where(Tenant.schema_name == data.schema_name))
    if existing.scalars().first():
        raise HTTPException(status_code=400, detail="Tenant with this schema_name already exists")

    new_tenant = Tenant(
        name=data.name,
        schema_name=data.schema_name,
        address=data.address,
        use_kds=data.use_kds,
        enable_inventory_deduction=data.enable_inventory_deduction,
    )
    session.add(new_tenant)
    await session.flush()

    try:
        await init_tenant_schema(new_tenant.schema_name)
    except Exception as e:
        await session.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to create schema: {str(e)}")

    owner_role_res = await session.execute(select(Role).where(Role.name == "owner"))
    owner_role = owner_role_res.scalars().first()

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
    result = await session.execute(select(Tenant).order_by(Tenant.id.asc()))
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
            created_at=t.created_at.isoformat(),
        ) for t in tenants
    ]


class TenantStatusUpdate(BaseModel):
    is_active: bool


class TenantUpdateRequest(BaseModel):
    name: Optional[str] = None
    address: Optional[str] = None
    use_kds: Optional[bool] = None
    enable_inventory_deduction: Optional[bool] = None


@router.patch("/tenants/{tenant_id}/status", dependencies=[Depends(require_system_admin)])
async def toggle_tenant_status(
    tenant_id: int,
    data: TenantStatusUpdate,
    session: Annotated[AsyncSession, Depends(get_session)],
):
    """Toggle tenant active status (freeze/unfreeze restaurant schema access)."""
    tenant = await session.get(Tenant, tenant_id)
    if not tenant:
        raise HTTPException(status_code=404, detail="Tenant not found")

    tenant.is_active = data.is_active
    session.add(tenant)
    await session.commit()
    await session.refresh(tenant)
    return {
        "message": f"Tenant '{tenant.name}' is now {'active' if tenant.is_active else 'suspended'}",
        "id": tenant.id,
        "is_active": tenant.is_active,
    }


@router.put("/tenants/{tenant_id}", dependencies=[Depends(require_system_admin)])
async def update_tenant(
    tenant_id: int,
    data: TenantUpdateRequest,
    session: Annotated[AsyncSession, Depends(get_session)],
):
    """Update tenant configuration and metadata."""
    tenant = await session.get(Tenant, tenant_id)
    if not tenant:
        raise HTTPException(status_code=404, detail="Tenant not found")

    if data.name is not None:
        tenant.name = data.name.strip()
    if data.address is not None:
        tenant.address = data.address.strip()
    if data.use_kds is not None:
        tenant.use_kds = data.use_kds
    if data.enable_inventory_deduction is not None:
        tenant.enable_inventory_deduction = data.enable_inventory_deduction

    session.add(tenant)
    await session.commit()
    await session.refresh(tenant)
    return {"message": "Tenant updated successfully", "id": tenant.id}


@router.delete("/tenants/{tenant_id}", dependencies=[Depends(require_system_admin)])
async def delete_tenant(
    tenant_id: int,
    session: Annotated[AsyncSession, Depends(get_session)],
):
    """
    Permanently deletes a tenant:
    1. Drops the dedicated PostgreSQL schema (CASCADE).
    2. Removes associated users and roles from public schema.
    3. Removes tenant record from public.tenants.
    """
    from sqlalchemy import text

    tenant = await session.get(Tenant, tenant_id)
    if not tenant:
        raise HTTPException(status_code=404, detail="Tenant not found")

    schema_to_drop = tenant.schema_name
    tenant_name = tenant.name

    try:
        await session.execute(text(f'DROP SCHEMA IF EXISTS "{schema_to_drop}" CASCADE'))
    except Exception as e:
        await session.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to drop schema '{schema_to_drop}': {str(e)}")

    users_result = await session.execute(select(User).where(User.tenant_id == tenant_id))
    users = users_result.scalars().all()
    user_ids = [u.id for u in users]
    if user_ids:
        ids_str = ",".join(str(i) for i in user_ids)
        await session.execute(text(f"DELETE FROM public.user_roles WHERE user_id IN ({ids_str})"))
        await session.execute(text(f"DELETE FROM public.users WHERE tenant_id = {tenant_id}"))

    await session.delete(tenant)
    await session.commit()

    return {
        "message": f"Tenant '{tenant_name}' and schema '{schema_to_drop}' permanently deleted",
        "id": tenant_id,
    }

