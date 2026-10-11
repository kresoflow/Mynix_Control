from typing import Annotated
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select

from app.database import get_session
from app.dependencies import require_permission, CurrentUser
from app.users import services as svc
from app.users.models import (
    UserRead, UserCreate, UserUpdate, Role,
)

router = APIRouter(tags=["User Management"])


def _is_owner_or_superuser(user) -> bool:
    """Проверяет, является ли пользователь владельцем или суперюзером."""
    if svc.is_superuser(user):
        return True
    return any(r.name == "owner" for r in (getattr(user, "roles", None) or []))


async def _validate_manager_role_assignment(session: AsyncSession, role_ids: list[int]) -> None:
    """Менеджер имеет право назначать сотрудникам исключительно роль кассира."""
    if not role_ids:
        return
    res = await session.execute(select(Role).where(Role.id.in_(role_ids)))
    assigned_roles = res.scalars().all()
    for role in assigned_roles:
        if role.name != "cashier":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Управляющий может назначать только роль кассира.",
            )


@router.get(
    "/users/",
    response_model=list[UserRead],
    dependencies=[Depends(require_permission("users:manage"))],
)
async def list_users(
    current_user: CurrentUser,
    session: Annotated[AsyncSession, Depends(get_session)],
):
    """List all users in the current tenant."""
    users = await svc.list_users(session, current_user.tenant_id)
    result = []
    for u in users:
        result.append(UserRead(
            id=u.id,
            tenant_id=u.tenant_id,
            username=u.username,
            full_name=u.full_name,
            is_active=u.is_active,
            pin_code="****" if u.pin_code else None,
            roles=[r.name for r in u.roles],
            permissions=svc.collect_permissions(u),
        ))
    return result


@router.post(
    "/users/",
    response_model=UserRead,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(require_permission("users:manage"))],
)
async def create_user(
    data: UserCreate,
    current_user: CurrentUser,
    session: Annotated[AsyncSession, Depends(get_session)],
):
    """Create a new staff user in the current tenant."""
    if not _is_owner_or_superuser(current_user):
        await _validate_manager_role_assignment(session, data.role_ids)

    data.tenant_id = current_user.tenant_id
    user = await svc.create_user(session, data)
    created = await svc.get_user_by_id(session, user.id) or user
    return UserRead(
        id=created.id,
        tenant_id=created.tenant_id,
        username=created.username,
        full_name=created.full_name,
        is_active=created.is_active,
        pin_code="****" if created.pin_code else None,
        roles=[r.name for r in (created.roles or [])],
        permissions=svc.collect_permissions(created),
    )


@router.put(
    "/users/{user_id}",
    response_model=UserRead,
    dependencies=[Depends(require_permission("users:manage"))],
)
async def update_user(
    user_id: int,
    data: UserUpdate,
    current_user: CurrentUser,
    session: Annotated[AsyncSession, Depends(get_session)],
):
    """Update a staff user."""
    user = await svc.get_user_by_id(session, user_id)
    if not user or user.tenant_id != current_user.tenant_id:
        raise HTTPException(status_code=404, detail="User not found")

    target_is_privileged = any(
        r.name in ("owner", "manager") or r.is_superuser
        for r in (user.roles or [])
    )
    if not _is_owner_or_superuser(current_user):
        if target_is_privileged:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Управляющий не может редактировать учетные записи владельцев или управляющих.",
            )
        if data.role_ids is not None:
            await _validate_manager_role_assignment(session, data.role_ids)

    updated = await svc.update_user(session, user, data)
    return UserRead(
        id=updated.id,
        tenant_id=updated.tenant_id,
        username=updated.username,
        full_name=updated.full_name,
        is_active=updated.is_active,
        pin_code="****" if updated.pin_code else None,
        roles=[r.name for r in updated.roles] if getattr(updated, "roles", None) else [],
        permissions=svc.collect_permissions(updated) if getattr(updated, "roles", None) else [],
    )


@router.delete(
    "/users/{user_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    dependencies=[Depends(require_permission("users:manage"))],
)
async def delete_user(
    user_id: int,
    current_user: CurrentUser,
    session: Annotated[AsyncSession, Depends(get_session)],
):
    """Deactivate a staff user."""
    # Poka-yoke: Prevent self-deletion
    if user_id == current_user.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Нельзя удалить собственную учетную запись.",
        )

    user = await svc.get_user_by_id(session, user_id)
    if not user or user.tenant_id != current_user.tenant_id:
        raise HTTPException(status_code=404, detail="User not found")

    target_is_privileged = any(
        r.name in ("owner", "manager") or r.is_superuser
        for r in (user.roles or [])
    )
    if not _is_owner_or_superuser(current_user) and target_is_privileged:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Управляющий не может удалять учетные записи владельцев или управляющих.",
        )

    # Poka-yoke: Prevent deleting the last active owner of the tenant
    is_owner = any(r.name == "owner" for r in (user.roles or []))
    if is_owner:
        all_users = await svc.list_users(session, current_user.tenant_id)
        active_owners = [
            u for u in all_users
            if u.is_active and any(r.name == "owner" for r in (u.roles or []))
        ]
        if len(active_owners) <= 1:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Нельзя удалить единственного активного владельца заведения.",
            )

    await svc.delete_user(session, user)
    return None
