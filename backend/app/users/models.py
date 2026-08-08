"""
Users module — PBAC (Permission-Based Access Control) models.

Schema:  User ◄─► UserRole ◄─► Role ◄─► RolePermission ◄─► Permission

Supports:
  - Multiple roles per user (universal worker = cashier + cook)
  - Atomic permissions checked on every endpoint
  - Owner superuser bypass
  - PIN-based quick login for booth workers
"""

from typing import Optional, List
from datetime import datetime, timezone

from sqlmodel import SQLModel, Field, Relationship

from app.base_model import TenantModel, TimestampMixin


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  LINK TABLES (Many-to-Many)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


class UserRole(SQLModel, table=True):
    """Link: User ◄─► Role"""
    __tablename__ = "user_roles"
    __table_args__ = {"schema": "public"}

    user_id: int = Field(foreign_key="public.users.id", primary_key=True)
    role_id: int = Field(foreign_key="public.roles.id", primary_key=True)


class RolePermission(SQLModel, table=True):
    """Link: Role ◄─► Permission"""
    __tablename__ = "role_permissions"
    __table_args__ = {"schema": "public"}

    role_id: int = Field(foreign_key="public.roles.id", primary_key=True)
    permission_id: int = Field(foreign_key="public.permissions.id", primary_key=True)


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  PERMISSION — atomic access right
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


class Permission(SQLModel, table=True):
    """
    Atomic permission.  Example codes:
      orders:create, orders:view, orders:cancel
      cashbox:operate, cashbox:view
      kitchen:view
      inventory:manage, inventory:view
      shifts:open, shifts:close
      users:manage, roles:manage
      analytics:view
    """
    __tablename__ = "permissions"
    __table_args__ = {"schema": "public"}

    id: Optional[int] = Field(default=None, primary_key=True)
    code: str = Field(unique=True, index=True, max_length=100)
    description: str = Field(default="", max_length=255)

    # Reverse relationship
    roles: List["Role"] = Relationship(
        back_populates="permissions",
        link_model=RolePermission,
    )


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  ROLE — named set of permissions
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


class Role(TimestampMixin, table=True):
    """
    Named role with a set of permissions.
    Roles are tenant-scoped (each point can customize).
    """
    __tablename__ = "roles"
    __table_args__ = {"schema": "public"}

    id: Optional[int] = Field(default=None, primary_key=True)
    name: str = Field(max_length=50, index=True)
    description: str = Field(default="", max_length=255)
    is_superuser: bool = Field(default=False)  # owner bypass flag

    # Relationships
    permissions: List[Permission] = Relationship(
        back_populates="roles",
        link_model=RolePermission,
    )
    users: List["User"] = Relationship(
        back_populates="roles",
        link_model=UserRole,
    )


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  USER — staff or customer account
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


class User(TimestampMixin, table=True):
    """
    Employee or customer.  Linked to one or more Roles.
    PIN is a 4-6 digit code for quick booth login (no keyboard needed).
    """
    __tablename__ = "users"
    __table_args__ = {"schema": "public"}

    id: Optional[int] = Field(default=None, primary_key=True)
    tenant_id: int = Field(foreign_key="public.tenants.id", index=True)
    username: str = Field(max_length=50, unique=True, index=True)
    full_name: str = Field(max_length=100)
    hashed_password: str = Field(max_length=255)
    pin_code: Optional[str] = Field(default=None, max_length=10)
    is_active: bool = Field(default=True)

    # Relationships
    roles: List[Role] = Relationship(
        back_populates="users",
        link_model=UserRole,
    )


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  TENANT — logical business unit
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


class Tenant(SQLModel, table=True):
    """
    Business location / point.
    tenant_id=1: Family café
    tenant_id=2: Street booth
    """
    __tablename__ = "tenants"
    __table_args__ = {"schema": "public"}

    id: Optional[int] = Field(default=None, primary_key=True)
    name: str = Field(max_length=100)
    schema_name: str = Field(max_length=50, unique=True, index=True)
    address: Optional[str] = Field(default=None, max_length=255)
    is_active: bool = Field(default=True)
    created_at: datetime = Field(
        default_factory=lambda: datetime.now(timezone.utc).replace(tzinfo=None),
    )
    
    # Feature Flags
    use_kds: bool = Field(default=True, description="Если False, заказы сразу получают статус completed минуя кухню")
    enable_inventory_deduction: bool = Field(default=True, description="Если False, списание сырья со склада отключается")


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  API SCHEMAS (Pydantic-only, not DB tables)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


class TokenResponse(SQLModel):
    """JWT response schema."""
    access_token: str
    token_type: str = "bearer"


class LoginRequest(SQLModel):
    """Username + password login."""
    username: str
    password: str


class PinLoginRequest(SQLModel):
    """Quick PIN login for booth workers."""
    pin_code: str
    tenant_id: int


class UserRead(SQLModel):
    """Public user data returned by API."""
    id: int
    tenant_id: int
    username: str
    full_name: str
    is_active: bool
    roles: List[str] = []       # role names
    permissions: List[str] = []  # permission codes


class UserCreate(SQLModel):
    """Schema for creating a new user."""
    username: str
    full_name: str
    password: str
    pin_code: Optional[str] = None
    tenant_id: int
    role_ids: List[int] = []

class UserUpdate(SQLModel):
    """Schema for updating a user."""
    username: Optional[str] = None
    full_name: Optional[str] = None
    password: Optional[str] = None
    pin_code: Optional[str] = None
    role_ids: Optional[List[int]] = None

class RoleRead(SQLModel):
    id: int
    name: str
    description: Optional[str] = None
    is_superuser: bool

class PermissionRead(SQLModel):
    id: int
    code: str
    description: Optional[str] = None
