# ==============================================================================
#  Kreso Flow — System Module: Pydantic DTO Schemas
# ==============================================================================
#  [КОНТРАКТЫ] Схемы валидации и сериализации для супер-админской панели.
# ==============================================================================

import re
from typing import Optional
from pydantic import BaseModel, Field, field_validator

SCHEMA_NAME_REGEX = re.compile(r"^[a-z0-9_]{3,30}$")
RESERVED_SCHEMAS = {"public", "information_schema", "pg_catalog", "pg_toast", "system"}


# ─── 1. Создание заведения ───────────────────────────────────────────────────

class TenantCreateRequest(BaseModel):
    """Запрос на создание нового тенанта и первого владельца точки."""
    name: str
    schema_name: str = Field(..., description="PostgreSQL schema name (lowercase letters, digits, underscore, 3-30 chars)")
    address: str = ""
    currency: str = "сом"
    owner_username: str
    owner_password: str
    owner_full_name: str
    owner_pin_code: str = "1234"
    owner_phone: Optional[str] = None
    owner_email: Optional[str] = None
    use_kds: bool = False
    use_orders: bool = True
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


# ─── 2. Чтение и метаданные заведения ────────────────────────────────────────

class TenantRead(BaseModel):
    """Полные метаданные тенанта для списка и инспектора заведений."""
    id: int
    name: str
    schema_name: str
    address: str
    currency: str
    is_active: bool
    use_kds: bool
    use_orders: bool
    enable_inventory_deduction: bool
    created_at: str
    owner_id: Optional[int] = None
    owner_username: Optional[str] = None
    owner_full_name: Optional[str] = None
    owner_phone: Optional[str] = None
    owner_email: Optional[str] = None
    owner_pin_code: Optional[str] = None


# ─── 3. Обновление статуса и параметров ──────────────────────────────────────

class TenantStatusUpdate(BaseModel):
    """Схема переключения активности тенанта (заморозка / разморозка)."""
    is_active: bool


class TenantUpdateRequest(BaseModel):
    """Схема частичного обновления конфигурации, модулей и аккаунта владельца."""
    name: Optional[str] = None
    address: Optional[str] = None
    currency: Optional[str] = None
    is_active: Optional[bool] = None
    use_kds: Optional[bool] = None
    use_orders: Optional[bool] = None
    enable_inventory_deduction: Optional[bool] = None
    # Данные учетной записи владельца
    owner_full_name: Optional[str] = None
    owner_phone: Optional[str] = None
    owner_email: Optional[str] = None
    owner_password: Optional[str] = None
    owner_pin_code: Optional[str] = None
