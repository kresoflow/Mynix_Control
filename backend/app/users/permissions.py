"""
Kreso Flow - Centralized Role and Permission Registry (PBAC).
Defines all system roles and atomic permissions as strongly-typed Enums.
[БЕЗОПАСНОСТЬ] [PBAC] Единая точка правды для ролей и прав.
"""
from enum import Enum


class RoleName(str, Enum):
    """
    Канонические системные роли заведения (Единая точка правды).
    """
    OWNER = "owner"
    MANAGER = "manager"
    CASHIER = "cashier"


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
    POS_CASH_OPERATIONS = "pos:cash_operations"

    # Shifts
    SHIFTS_OPEN = "shifts:open"
    SHIFTS_CLOSE = "shifts:close"
    SHIFTS_VIEW = "shifts:view"

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

    # Settings & System
    SETTINGS_MANAGE = "settings:manage"
    SYSTEM_MANAGE = "system:manage"

