from typing import Annotated, List
from fastapi import APIRouter, Depends, HTTPException, status, Header
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select
from pydantic import BaseModel

from app.config import settings
from app.database import get_session, init_tenant_schema
from app.users.models import Tenant, User, UserRole, Role
from app.users.services import hash_password

router = APIRouter(tags=["System — Tenants"])


def require_system_admin(x_system_token: str = Header(..., description="System Admin Secret Token")):
    """Dependency to check the static system admin token."""
    if x_system_token != settings.system_admin_token:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Invalid System Admin Token",
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
    existing = await session.execute(select(Tenant).where(Tenant.schema_name == data.schema_name))
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Tenant with this schema_name already exists")

    new_tenant = Tenant(
        name=data.name,
        schema_name=data.schema_name,
        address=data.address,
    )
    session.add(new_tenant)
    await session.flush()

    try:
        await init_tenant_schema(new_tenant.schema_name)
    except Exception as e:
        await session.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to create schema: {str(e)}")

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
            created_at=t.created_at.isoformat(),
        ) for t in tenants
    ]
