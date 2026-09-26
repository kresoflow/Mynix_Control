# ==============================================================================
#  Kreso Flow — POS: Cash Operations Models & Schemas
#  [ИНВАРИАНТ] Изоляция тенантов через PostgreSQL search_path (никаких tenant_id).
#  [ФИНАНСЫ] Модели служебных расходов, довнесений и инкассации кассы смены.
# ==============================================================================

from typing import Optional, List
from datetime import datetime, timezone
from enum import Enum

from sqlmodel import SQLModel, Field
from app.base_model import TenantModel


# ──────────────────────────────────────────────────────────────────────────────
#  1. Перечисления типов кассовых операций
# ──────────────────────────────────────────────────────────────────────────────

class CashOperationType(str, Enum):
    """
    Типы кассовых операций:
      - DEPOSIT: Внесение / довнесение разменной монеты
      - WITHDRAWAL: Расход / служебная выдача / инкассация выручки
    """
    DEPOSIT = "deposit"
    WITHDRAWAL = "withdrawal"

    @classmethod
    def _missing_(cls, value):
        if isinstance(value, str):
            val_lower = value.lower()
            for member in cls:
                if member.value == val_lower or member.name.lower() == val_lower:
                    return member
        return None


# ──────────────────────────────────────────────────────────────────────────────
#  2. Доменная модель БД
# ──────────────────────────────────────────────────────────────────────────────

class CashOperation(TenantModel, table=True):
    """
    [ИНВАРИАНТ] Модель кассовой операции в рамках смены.
    Наследуется от TenantModel (автоматически привязывается к схеме тенанта).
    Запрещено добавлять поле tenant_id.
    """
    __tablename__ = "cash_operations"

    id: Optional[int] = Field(default=None, primary_key=True)
    client_uuid: Optional[str] = Field(default=None, index=True)
    shift_id: int = Field(foreign_key="shifts.id", index=True)
    user_id: int = Field(foreign_key="public.users.id")

    type: CashOperationType = Field(index=True)
    amount: float = Field(gt=0)
    category: str = Field(default="Общее", max_length=100)
    comment: Optional[str] = Field(default=None, max_length=500)

    created_at: datetime = Field(
        default_factory=lambda: datetime.now(timezone.utc).replace(tzinfo=None)
    )


# ──────────────────────────────────────────────────────────────────────────────
#  3. Pydantic / SQLModel DTO схемы для API
# ──────────────────────────────────────────────────────────────────────────────

class CashOperationCreate(SQLModel):
    """Схема создания кассовой операции."""
    shift_id: Optional[int] = None
    type: CashOperationType
    amount: float = Field(gt=0, description="Сумма операции (строго > 0)")
    category: str = Field(default="Общее", min_length=1, max_length=100)
    comment: Optional[str] = Field(default=None, max_length=500)
    client_uuid: Optional[str] = None


class CashOperationRead(SQLModel):
    """Схема чтения кассовой операции."""
    id: int
    client_uuid: Optional[str] = None
    shift_id: int
    user_id: int
    user_name: Optional[str] = None
    type: CashOperationType
    amount: float
    category: str
    comment: Optional[str] = None
    created_at: datetime


class CashOperationsSummary(SQLModel):
    """Сводный отчет по кассовым операциям за смену."""
    shift_id: int
    opening_cash: float
    total_deposits: float
    total_withdrawals: float
    current_expected_cash: float
    operations_count: int
    operations: List[CashOperationRead] = []
