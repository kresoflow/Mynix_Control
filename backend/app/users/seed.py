"""
Seed data — runs on first launch to populate the database with:
  - 2 tenants (Family café, Street booth)
  - All atomic permissions
  - Default roles (owner, manager, cashier)
  - Owner account with default password
  - Sample menu items with recipes (tech cards)
"""

from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select

from app.users.models import (
    Tenant, Permission, Role, RolePermission, User, UserRole,
)
from app.users.permissions import RoleName, Perm
from app.users.services import hash_password
from app.config import settings


# ── All atomic permissions in the system (Pilot MVP) ─────────────
PERMISSIONS = [
    # Orders / POS
    (Perm.ORDERS_CREATE.value, "Create new orders"),
    (Perm.ORDERS_VIEW.value, "View orders list"),
    (Perm.ORDERS_CANCEL.value, "Cancel orders"),
    (Perm.ORDERS_UPDATE_STATUS.value, "Update order status"),
    # Cash box
    (Perm.CASHBOX_OPERATE.value, "Accept payments, open cash drawer"),
    (Perm.CASHBOX_VIEW.value, "View cash transactions"),
    (Perm.CASHBOX_EXPENSE.value, "Record cash expenses"),
    (Perm.POS_CASH_OPERATIONS.value, "Deposit and withdraw cash"),
    # Shifts
    (Perm.SHIFTS_OPEN.value, "Open a cash shift"),
    (Perm.SHIFTS_CLOSE.value, "Close a cash shift"),
    (Perm.SHIFTS_VIEW.value, "View shift reports"),
    # Inventory
    (Perm.INVENTORY_MANAGE.value, "Add/edit ingredients, recipes, receive stock"),
    (Perm.INVENTORY_CREATE.value, "Create ingredients and raw materials"),
    (Perm.INVENTORY_VIEW.value, "View stock levels and menu items"),
    # Users & Roles
    (Perm.USERS_MANAGE.value, "Create/edit/deactivate staff accounts"),
    (Perm.ROLES_MANAGE.value, "Create/edit roles and assign permissions"),
    # Analytics
    (Perm.ANALYTICS_VIEW.value, "View dashboards, reports, food cost analysis"),
    # Menu
    (Perm.MENU_MANAGE.value, "Create/edit menu items and prices"),
    (Perm.MENU_CREATE.value, "Create menu items and retail products"),
    (Perm.MENU_VIEW.value, "View menu (all staff can)"),
    # Settings & System
    (Perm.SETTINGS_MANAGE.value, "Manage store and tenant settings"),
    (Perm.SYSTEM_MANAGE.value, "System admin and schema inspector"),
]

# ── Role templates with their permission sets ────────────────────
ROLE_TEMPLATES = {
    RoleName.OWNER.value: {
        "description": "Business owner — full access (superuser)",
        "is_superuser": True,
        "permissions": [],  # superuser bypasses all checks
    },
    RoleName.MANAGER.value: {
        "description": "Store manager — operations, staff, inventory",
        "is_superuser": False,
        "permissions": [
            Perm.ORDERS_CREATE.value, Perm.ORDERS_VIEW.value, Perm.ORDERS_CANCEL.value, Perm.ORDERS_UPDATE_STATUS.value,
            Perm.CASHBOX_OPERATE.value, Perm.CASHBOX_VIEW.value, Perm.CASHBOX_EXPENSE.value, Perm.POS_CASH_OPERATIONS.value,
            Perm.SHIFTS_OPEN.value, Perm.SHIFTS_CLOSE.value, Perm.SHIFTS_VIEW.value,
            Perm.INVENTORY_MANAGE.value, Perm.INVENTORY_CREATE.value, Perm.INVENTORY_VIEW.value,
            Perm.USERS_MANAGE.value,
            Perm.MENU_MANAGE.value, Perm.MENU_CREATE.value, Perm.MENU_VIEW.value,
            Perm.SETTINGS_MANAGE.value,
        ],
    },
    RoleName.CASHIER.value: {
        "description": "Cashier — POS, payments, shifts",
        "is_superuser": False,
        "permissions": [
            Perm.ORDERS_CREATE.value, Perm.ORDERS_VIEW.value, Perm.ORDERS_CANCEL.value, Perm.ORDERS_UPDATE_STATUS.value,
            Perm.CASHBOX_OPERATE.value, Perm.CASHBOX_VIEW.value, Perm.CASHBOX_EXPENSE.value, Perm.POS_CASH_OPERATIONS.value,
            Perm.SHIFTS_OPEN.value, Perm.SHIFTS_CLOSE.value, Perm.SHIFTS_VIEW.value,
            Perm.MENU_VIEW.value,
        ],
    },
}


async def seed_database(session: AsyncSession) -> None:
    """
    Populate the DB with initial data if it's empty.
    Idempotent — skips if tenants already exist.
    """
    # Check if already seeded
    existing = await session.execute(select(Tenant).limit(1))
    if existing.scalar() is not None:
        print(">> Database already seeded, skipping.")
        return

    print("Seeding database...")

    # 1. Create tenants
    tenant_cafe = Tenant(name="Family cafe", schema_name="tenant_1", address="Main St. 123")
    tenant_booth = Tenant(name="Street booth", schema_name="tenant_2", address="Park Ave. 1")
    session.add_all([tenant_cafe, tenant_booth])
    await session.flush()
    print("  - 2 tenants created")

    # 2.5 Init schemas for tenants!
    from app.database import init_tenant_schema
    await init_tenant_schema(tenant_cafe.schema_name)
    await init_tenant_schema(tenant_booth.schema_name)
    print("  - Tenant schemas initialized")

    # ── 2. Create permissions ────────────────────────────────────
    perm_map: dict[str, Permission] = {}
    for code, description in PERMISSIONS:
        perm = Permission(code=code, description=description)
        session.add(perm)
        perm_map[code] = perm
    await session.flush()
    print(f"  - {len(PERMISSIONS)} permissions created")

    # 3. Create global roles
    role_map = {}
    for role_name, template in ROLE_TEMPLATES.items():
        existing_role_res = await session.execute(select(Role).where(Role.name == role_name))
        existing_role = existing_role_res.scalars().first()
        if existing_role:
            role = existing_role
        else:
            role = Role(
                name=role_name,
                description=template["description"],
                is_superuser=template["is_superuser"],
            )
            session.add(role)
            await session.flush()

        for perm_code in template["permissions"]:
            if perm_code in perm_map:
                existing_link = await session.execute(
                    select(RolePermission).where(
                        RolePermission.role_id == role.id,
                        RolePermission.permission_id == perm_map[perm_code].id,
                    )
                )
                if not existing_link.scalars().first():
                    link = RolePermission(
                        role_id=role.id,
                        permission_id=perm_map[perm_code].id,
                    )
                    session.add(link)

        role_map[role_name] = role

    await session.flush()
    print(f"  - {len(ROLE_TEMPLATES)} shared roles created or verified")

    # ── 4. Create owner accounts ─────────────────────────────────
    hashed = hash_password(settings.owner_default_password)

    owner_cafe = User(
        tenant_id=tenant_cafe.id,
        username=settings.owner_default_username,
        full_name="Владелец (кафе)",
        hashed_password=hashed,
        pin_code="0000",
    )
    session.add(owner_cafe)
    await session.flush()
    session.add(UserRole(
        user_id=owner_cafe.id,
        role_id=role_map[RoleName.OWNER.value].id,
    ))

    owner_booth = User(
        tenant_id=tenant_booth.id,
        username="owner_booth",
        full_name="Владелец (будка)",
        hashed_password=hashed,
        pin_code="0001",
    )
    session.add(owner_booth)
    await session.flush()
    session.add(UserRole(
        user_id=owner_booth.id,
        role_id=role_map[RoleName.OWNER.value].id,
    ))

    # Sample worker for booth
    worker = User(
        tenant_id=tenant_booth.id,
        username="worker1",
        full_name="Иван Кассир",
        hashed_password=hash_password("worker123"),
        pin_code="1234",
    )
    session.add(worker)
    await session.flush()
    session.add(UserRole(
        user_id=worker.id,
        role_id=role_map[RoleName.CASHIER.value].id,
    ))

    await session.flush()
    print("  - 3 users created (2 owners + 1 worker)")

    await session.commit()
    print("Seed complete!")
