"""
Seed data — runs on first launch to populate the database with:
  - 2 tenants (Family café, Street booth)
  - All atomic permissions
  - Default roles (owner, cashier, cook, universal_worker)
  - Owner account with default password
  - Sample menu items with recipes (tech cards)
"""

from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select

from app.users.models import (
    Tenant, Permission, Role, RolePermission, User, UserRole,
)
from app.users.services import hash_password
from app.config import settings


# ── All atomic permissions in the system ─────────────────────────
PERMISSIONS = [
    # Orders / POS
    ("orders:create", "Create new orders"),
    ("orders:view", "View orders list"),
    ("orders:cancel", "Cancel orders"),
    ("orders:update_status", "Update order status (cooking → ready)"),
    # Cash box
    ("cashbox:operate", "Accept payments, open cash drawer"),
    ("cashbox:view", "View cash transactions"),
    ("cashbox:expense", "Record cash expenses"),
    # Shifts
    ("shifts:open", "Open a cash shift"),
    ("shifts:close", "Close a cash shift"),
    ("shifts:view", "View shift reports"),
    # Kitchen
    ("kitchen:view", "View kitchen order screen"),
    # Inventory
    ("inventory:manage", "Add/edit ingredients, recipes, receive stock"),
    ("inventory:view", "View stock levels and menu items"),
    # Users & Roles
    ("users:manage", "Create/edit/deactivate staff accounts"),
    ("roles:manage", "Create/edit roles and assign permissions"),
    # Analytics
    ("analytics:view", "View dashboards, reports, food cost analysis"),
    # Menu
    ("menu:manage", "Create/edit menu items and prices"),
    ("menu:view", "View menu (all staff can)"),
    # Settings & System
    ("settings:manage", "Manage store and tenant settings"),
    ("system:manage", "System admin and schema inspector"),
    # CRM & Customers
    ("crm:manage", "Manage customers and debt ledger"),
    ("crm:view", "View customers and ledger"),
]

# ── Role templates with their permission sets ────────────────────
ROLE_TEMPLATES = {
    "owner": {
        "description": "Business owner — full access (superuser)",
        "is_superuser": True,
        "permissions": [],  # superuser bypasses all checks
    },
    "manager": {
        "description": "Store manager — operations, staff, analytics, CRM",
        "is_superuser": False,
        "permissions": [
            "orders:create", "orders:view", "orders:cancel", "orders:update_status",
            "cashbox:operate", "cashbox:view", "cashbox:expense",
            "shifts:open", "shifts:close", "shifts:view",
            "kitchen:view",
            "inventory:manage", "inventory:view",
            "users:manage", "roles:manage",
            "analytics:view",
            "menu:manage", "menu:view",
            "settings:manage",
            "crm:manage", "crm:view",
        ],
    },
    "cashier": {
        "description": "Cashier — POS, payments, shifts",
        "is_superuser": False,
        "permissions": [
            "orders:create", "orders:view", "orders:cancel",
            "cashbox:operate", "cashbox:view", "cashbox:expense",
            "shifts:open", "shifts:close", "shifts:view",
            "menu:view",
            "crm:view", "crm:manage",
        ],
    },
    "waiter": {
        "description": "Waiter — hall orders, table service, quick submit",
        "is_superuser": False,
        "permissions": [
            "orders:create", "orders:view",
            "menu:view",
            "crm:view",
        ],
    },
    "cook": {
        "description": "Cook — kitchen screen, order status updates",
        "is_superuser": False,
        "permissions": [
            "kitchen:view",
            "orders:view", "orders:update_status",
            "inventory:view",
            "menu:view",
        ],
    },
    "universal_worker": {
        "description": "Universal — cashier + cook combined (street booth)",
        "is_superuser": False,
        "permissions": [
            "orders:create", "orders:view", "orders:cancel", "orders:update_status",
            "cashbox:operate", "cashbox:view", "cashbox:expense",
            "shifts:open", "shifts:close", "shifts:view",
            "kitchen:view",
            "inventory:view",
            "menu:view",
            "crm:view", "crm:manage",
        ],
    },
    "warehouse_manager": {
        "description": "Warehouse manager — inventory, stock documents, supplies",
        "is_superuser": False,
        "permissions": [
            "inventory:manage", "inventory:view",
            "menu:view",
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
        role = Role(
            name=role_name,
            description=template["description"],
            is_superuser=template["is_superuser"],
        )
        session.add(role)
        await session.flush()

        for perm_code in template["permissions"]:
            if perm_code in perm_map:
                link = RolePermission(
                    role_id=role.id,
                    permission_id=perm_map[perm_code].id,
                )
                session.add(link)

        role_map[role_name] = role

    await session.flush()
    print(f"  - {len(ROLE_TEMPLATES)} shared roles created")

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
        role_id=role_map["owner"].id,
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
        role_id=role_map["owner"].id,
    ))

    # Sample worker for booth
    worker = User(
        tenant_id=tenant_booth.id,
        username="worker1",
        full_name="Иван Универсал",
        hashed_password=hash_password("worker123"),
        pin_code="1234",
    )
    session.add(worker)
    await session.flush()
    session.add(UserRole(
        user_id=worker.id,
        role_id=role_map["universal_worker"].id,
    ))

    await session.flush()
    print("  - 3 users created (2 owners + 1 worker)")

    await session.commit()
    print("Seed complete!")
