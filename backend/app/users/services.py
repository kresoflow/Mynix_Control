"""
Users module — business logic services.

Handles authentication, JWT generation, password hashing,
and permission aggregation.
"""

from datetime import datetime, timezone, timedelta
from typing import Optional

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload
from sqlmodel import select

from jose import jwt
from passlib.context import CryptContext

from app.config import settings
from app.users.models import (
    User, Role, Permission, UserRole, RolePermission,
    Tenant, UserCreate, UserUpdate,
)

import bcrypt

# ── Password hashing ────────────────────────────────────────────

def hash_password(plain: str) -> str:
    salt = bcrypt.gensalt()
    return bcrypt.hashpw(plain.encode('utf-8'), salt).decode('utf-8')


def verify_password(plain: str, hashed: str) -> bool:
    try:
        return bcrypt.checkpw(plain.encode('utf-8'), hashed.encode('utf-8'))
    except Exception:
        return False


# ── JWT tokens ───────────────────────────────────────────────────

def create_access_token(
    user_id: int,
    tenant_id: int,
    permissions: list[str],
    is_superuser: bool = False,
    expires_delta: Optional[timedelta] = None,
) -> str:
    """
    Generate a JWT containing user identity, tenant scope,
    and a flat list of permission codes.
    """
    expire = datetime.now(timezone.utc) + (
        expires_delta or timedelta(minutes=settings.access_token_expire_minutes)
    )
    payload = {
        "sub": str(user_id),
        "tenant_id": tenant_id,
        "permissions": permissions,
        "is_superuser": is_superuser,
        "exp": expire,
    }
    return jwt.encode(payload, settings.secret_key, algorithm=settings.jwt_algorithm)


# ── Authentication ───────────────────────────────────────────────

async def authenticate_by_password(
    session: AsyncSession,
    username: str,
    password: str,
) -> Optional[User]:
    """Verify username + password, return User or None."""
    stmt = (
        select(User)
        .where(User.username == username, User.is_active == True)
        .options(
            selectinload(User.roles).selectinload(Role.permissions)
        )
    )
    result = await session.execute(stmt)
    user = result.scalars().first()

    if user is None or not verify_password(password, user.hashed_password):
        return None
    return user


async def authenticate_by_pin(
    session: AsyncSession,
    pin_code: str,
    tenant_id: int,
) -> Optional[User]:
    """Quick PIN login — scoped to a specific tenant."""
    stmt = (
        select(User)
        .where(
            User.pin_code == pin_code,
            User.tenant_id == tenant_id,
            User.is_active == True,
        )
        .options(
            selectinload(User.roles).selectinload(Role.permissions)
        )
    )
    result = await session.execute(stmt)
    return result.scalars().first()


# ── Permission helpers ───────────────────────────────────────────

def collect_permissions(user: User) -> list[str]:
    """
    Gather all unique permission codes from all user's roles.
    Returns a flat deduplicated list like:
      ["orders:create", "cashbox:operate", "kitchen:view"]
    """
    perms: set[str] = set()
    for role in user.roles:
        for perm in role.permissions:
            perms.add(perm.code)
    return sorted(perms)


def is_superuser(user: User) -> bool:
    """Check if any of the user's roles has superuser bypass."""
    return any(role.is_superuser for role in user.roles)


# ── User CRUD ────────────────────────────────────────────────────

async def get_user_by_id(
    session: AsyncSession,
    user_id: int,
) -> Optional[User]:
    """Fetch user with roles and permissions eagerly loaded."""
    stmt = (
        select(User)
        .where(User.id == user_id)
        .options(
            selectinload(User.roles).selectinload(Role.permissions)
        )
    )
    result = await session.execute(stmt)
    return result.scalar_one_or_none()


get_user = get_user_by_id


async def list_users(
    session: AsyncSession,
    tenant_id: int,
) -> list[User]:
    """List all users in a tenant."""
    stmt = (
        select(User)
        .where(User.tenant_id == tenant_id)
        .options(selectinload(User.roles))
    )
    result = await session.execute(stmt)
    return list(result.scalars().all())


async def create_user(
    session: AsyncSession,
    data: UserCreate,
) -> User:
    """Create a new user and assign roles."""
    user = User(
        tenant_id=data.tenant_id,
        username=data.username,
        full_name=data.full_name,
        hashed_password=hash_password(data.password),
        pin_code=data.pin_code,
    )
    session.add(user)
    await session.flush()  # get user.id

    # Assign roles
    if data.role_ids:
        for role_id in data.role_ids:
            link = UserRole(user_id=user.id, role_id=role_id)
            session.add(link)

    return user


async def update_user(
    session: AsyncSession,
    user: User,
    data: UserUpdate,
) -> User:
    """Update a user's details and roles."""
    if data.username is not None:
        user.username = data.username
    if data.full_name is not None:
        user.full_name = data.full_name
    if data.password is not None and data.password.strip():
        user.hashed_password = hash_password(data.password)
    if data.pin_code is not None:
        user.pin_code = data.pin_code

    if data.role_ids is not None:
        # Delete existing links
        from sqlmodel import delete
        await session.execute(delete(UserRole).where(UserRole.user_id == user.id))
        
        # Add new links
        for role_id in data.role_ids:
            link = UserRole(user_id=user.id, role_id=role_id)
            session.add(link)

    await session.flush()
    return user


async def delete_user(
    session: AsyncSession,
    user: User,
) -> None:
    """Soft or hard delete a user."""
    # For now, we will do a soft delete or just delete
    # Usually soft delete is better: user.is_active = False
    user.is_active = False
    await session.flush()


# ── Role & Permission CRUD ───────────────────────────────────────

async def list_roles(
    session: AsyncSession,
) -> list[Role]:
    """List all roles (shared across all tenants)."""
    stmt = (
        select(Role)
        .options(selectinload(Role.permissions))
    )
    result = await session.execute(stmt)
    return list(result.scalars().all())


async def list_permissions(session: AsyncSession) -> list[Permission]:
    """List all available permissions (global, not tenant-scoped)."""
    result = await session.execute(select(Permission))
    return list(result.scalars().all())
