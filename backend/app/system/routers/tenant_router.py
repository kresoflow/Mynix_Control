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
from app.system.schemas import (
    TenantCreateRequest,
    TenantRead,
    TenantStatusUpdate,
    TenantUpdateRequest,
)

router = APIRouter(tags=["System — Tenants"])


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
        currency=data.currency,
        use_kds=data.use_kds,
        use_orders=data.use_orders,
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
        phone=data.owner_phone,
        email=data.owner_email,
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
    """List all registered tenants with their configurations and owner info."""
    result = await session.execute(select(Tenant).order_by(Tenant.id.asc()))
    tenants = result.scalars().all()

    # Load owners in a single query
    owners_stmt = (
        select(User)
        .join(UserRole, User.id == UserRole.user_id)
        .join(Role, Role.id == UserRole.role_id)
        .where(Role.name == "owner")
    )
    owners_res = await session.execute(owners_stmt)
    owners_map = {u.tenant_id: u for u in owners_res.scalars().all()}

    items: List[TenantRead] = []
    for t in tenants:
        owner = owners_map.get(t.id)
        items.append(
            TenantRead(
                id=t.id,
                name=t.name,
                schema_name=t.schema_name,
                address=t.address or "",
                currency=t.currency or "сом",
                is_active=t.is_active,
                use_kds=t.use_kds,
                use_orders=t.use_orders,
                enable_inventory_deduction=t.enable_inventory_deduction,
                created_at=t.created_at.isoformat() if t.created_at else "",
                owner_id=owner.id if owner else None,
                owner_username=owner.username if owner else None,
                owner_full_name=owner.full_name if owner else None,
                owner_phone=owner.phone if owner else None,
                owner_email=owner.email if owner else None,
                owner_pin_code=owner.pin_code if owner else None,
            )
        )
    return items


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
@router.patch("/tenants/{tenant_id}", dependencies=[Depends(require_system_admin)])
async def update_tenant(
    tenant_id: int,
    data: TenantUpdateRequest,
    session: Annotated[AsyncSession, Depends(get_session)],
):
    """Update tenant configuration, metadata, and owner account."""
    tenant = await session.get(Tenant, tenant_id)
    if not tenant:
        raise HTTPException(status_code=404, detail="Tenant not found")

    if data.name is not None:
        tenant.name = data.name.strip()
    if data.address is not None:
        tenant.address = data.address.strip()
    if data.currency is not None:
        tenant.currency = data.currency.strip()
    if data.is_active is not None:
        tenant.is_active = data.is_active
    if data.use_kds is not None:
        tenant.use_kds = data.use_kds
    if data.use_orders is not None:
        tenant.use_orders = data.use_orders
    if data.enable_inventory_deduction is not None:
        tenant.enable_inventory_deduction = data.enable_inventory_deduction

    session.add(tenant)

    # Update owner user if any owner fields are provided
    has_owner_fields = any(
        x is not None for x in [
            data.owner_full_name,
            data.owner_phone,
            data.owner_email,
            data.owner_password,
            data.owner_pin_code,
        ]
    )
    if has_owner_fields:
        owner_stmt = (
            select(User)
            .join(UserRole, User.id == UserRole.user_id)
            .join(Role, Role.id == UserRole.role_id)
            .where(User.tenant_id == tenant_id, Role.name == "owner")
        )
        owner = (await session.execute(owner_stmt)).scalars().first()
        if not owner:
            owner = (await session.execute(
                select(User).where(User.tenant_id == tenant_id).order_by(User.id.asc())
            )).scalars().first()

        if owner:
            if data.owner_full_name is not None:
                owner.full_name = data.owner_full_name.strip()
            if data.owner_phone is not None:
                owner.phone = data.owner_phone.strip()
            if data.owner_email is not None:
                owner.email = data.owner_email.strip()
            if data.owner_pin_code is not None:
                owner.pin_code = data.owner_pin_code.strip()
            if data.owner_password is not None and data.owner_password.strip():
                owner.hashed_password = hash_password(data.owner_password.strip())
            session.add(owner)

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

