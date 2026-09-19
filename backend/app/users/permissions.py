"""
Mynix Control - Centralized Permission Registry (PBAC).
Defines all atomic permissions as a strongly-typed StrEnum to eliminate string hardcode.
"""
from enum import Enum


class Perm(str, Enum):
    # Orders / POS
    ORDERS_CREATE = "orders:create"
    ORDERS_VIEW = "orders:view"
    ORDERS_CANCEL = "orders:cancel"
    ORDERS_UPDATE_STATUS = "orders:update_status"

    # Cashbox
    CASHBOX_OPERATE = "cashbox:operate"
    CASHBOX_VIEW = "cashbox:view"
    CASHBOX_EXPENSE = "cashbox:expense"

    # Shifts
    SHIFTS_OPEN = "shifts:open"
    SHIFTS_CLOSE = "shifts:close"
    SHIFTS_VIEW = "shifts:view"

    # Kitchen
    KITCHEN_VIEW = "kitchen:view"

    # Inventory
    INVENTORY_MANAGE = "inventory:manage"
    INVENTORY_CREATE = "inventory:create"
    INVENTORY_VIEW = "inventory:view"

    # Menu
    MENU_MANAGE = "menu:manage"
    MENU_CREATE = "menu:create"
    MENU_VIEW = "menu:view"

    # Users & Roles
    USERS_MANAGE = "users:manage"
    ROLES_MANAGE = "roles:manage"

    # Analytics
    ANALYTICS_VIEW = "analytics:view"

    # CRM
    CRM_MANAGE = "crm:manage"
    CRM_VIEW = "crm:view"

    # Settings & System
    SETTINGS_MANAGE = "settings:manage"
    SYSTEM_MANAGE = "system:manage"
