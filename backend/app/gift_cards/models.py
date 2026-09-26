# ==============================================================================
# МОДУЛЬ: Подарочные карты (Gift Cards)
# ДОМЕН: app.gift_cards.models
# ==============================================================================
"""
Модели данных и Pydantic-схемы модуля Подарочных карт.

[ИНВАРИАНТ]   Модели наследуются от TenantModel (изоляция через search_path).
[БЕЗОПАСНОСТЬ] Запрещено добавление колонки tenant_id.
[ФИНАНСЫ]     Все операции баланса логируются в GiftCardTransaction.
"""

from datetime import date, datetime, timezone
from enum import Enum
from typing import List, Optional
from sqlalchemy import Column, Enum as SAEnum
from sqlmodel import Field, Relationship, SQLModel

from app.base_model import TenantModel


# ─── 1. Перечисления статусов и типов транзакций ──────────────────────────────

class GiftCardStatus(str, Enum):
    """
    Статус жизненного цикла подарочной карты.
    
    [ИНВАРИАНТ] Списание разрешено только для карт со статусом ACTIVE.
    """
    ACTIVE = "active"          # Активна, готова к оплате
    EXHAUSTED = "exhausted"    # Баланс полностью исчерпан (0.00)
    EXPIRED = "expired"        # Истёк срок действия карты
    BLOCKED = "blocked"        # Заблокирована администратором

    @classmethod
    def _missing_(cls, value):
        if isinstance(value, str):
            val_lower = value.lower()
            for member in cls:
                if member.value == val_lower or member.name.lower() == val_lower:
                    return member
        return None


class GiftCardTransactionType(str, Enum):
    """
    Тип финансовой операции по подарочной карте.
    
    [ФИНАНСЫ] Обеспечивает сквозной аудит всех изменений баланса карты.
    """
    ISSUE = "issue"            # Первичный выпуск / эмиссия карты
    REDEEM = "redeem"          # Списание средств при оплате заказа
    TOPUP = "topup"            # Пополнение баланса карты
    ADJUSTMENT = "adjustment"  # Ручная корректировка баланса

    @classmethod
    def _missing_(cls, value):
        if isinstance(value, str):
            val_lower = value.lower()
            for member in cls:
                if member.value == val_lower or member.name.lower() == val_lower:
                    return member
        return None


# ─── 2. Доменные сущности БД (Tenant-Scoped) ──────────────────────────────────

class GiftCard(TenantModel, table=True):
    """
    Подарочная карта заведения с фиксированным или пополняемым номиналом.
    
    [ИНВАРИАНТ]   Код карты уникален в пределах схемы тенанта.
    [БЕЗОПАСНОСТЬ] Данные изолированы на уровне схем PostgreSQL.
    """
    __tablename__ = "gift_cards"

    id: Optional[int] = Field(default=None, primary_key=True)
    code: str = Field(max_length=64, index=True, unique=True)
    initial_balance: float = Field(default=0.0, ge=0.0)
    current_balance: float = Field(default=0.0, ge=0.0)
    status: GiftCardStatus = Field(
        sa_column=Column(
            SAEnum(
                GiftCardStatus,
                values_callable=lambda obj: [e.value for e in obj],
                native_enum=False,
            ),
            nullable=False,
            default=GiftCardStatus.ACTIVE,
        )
    )
    is_active: bool = Field(default=True, index=True)
    expiry_date: Optional[date] = Field(default=None, index=True)
    customer_id: Optional[int] = Field(
        default=None,
        foreign_key="customers.id",
        index=True,
    )
    notes: Optional[str] = Field(default=None, max_length=500)
    created_by: Optional[int] = Field(default=None, foreign_key="public.users.id")

    # Связанная история движений средств
    transactions: List["GiftCardTransaction"] = Relationship(
        back_populates="gift_card",
        sa_relationship_kwargs={"cascade": "all, delete-orphan", "lazy": "selectin"},
    )


class GiftCardTransaction(TenantModel, table=True):
    """
    Финансовая транзакция списания / пополнения подарочной карты.
    
    [ТРАНЗАКЦИЯ] Записывается атомарно при любом изменении current_balance.
    """
    __tablename__ = "gift_card_transactions"

    id: Optional[int] = Field(default=None, primary_key=True)
    gift_card_id: int = Field(foreign_key="gift_cards.id", index=True)
    order_id: Optional[int] = Field(
        default=None,
        foreign_key="orders.id",
        index=True,
    )
    type: GiftCardTransactionType = Field(
        sa_column=Column(
            SAEnum(
                GiftCardTransactionType,
                values_callable=lambda obj: [e.value for e in obj],
                native_enum=False,
            ),
            nullable=False,
        )
    )
    amount: float = Field(default=0.0)
    balance_before: float = Field(default=0.0)
    balance_after: float = Field(default=0.0)
    comment: Optional[str] = Field(default=None, max_length=255)
    created_at: datetime = Field(
        default_factory=lambda: datetime.now(timezone.utc).replace(tzinfo=None)
    )
    created_by: Optional[int] = Field(default=None, foreign_key="public.users.id")

    # Связь с родительской картой
    gift_card: Optional[GiftCard] = Relationship(back_populates="transactions")


# ─── 3. Схемы валидации и передачи данных (Pydantic DTOs) ──────────────────────

class GiftCardCreate(SQLModel):
    """Схема запроса на эмиссию новой подарочной карты."""
    code: Optional[str] = Field(default=None, max_length=64)
    initial_balance: float = Field(gt=0.0, description="Номинал карты (>0)")
    expiry_date: Optional[date] = None
    customer_id: Optional[int] = None
    notes: Optional[str] = Field(default=None, max_length=500)


class GiftCardRedeem(SQLModel):
    """Схема запроса на частичное или полное списание средств с карты."""
    amount: float = Field(gt=0.0, description="Сумма списания (>0)")
    order_id: Optional[int] = None
    notes: Optional[str] = Field(default=None, max_length=255)


class GiftCardTopUp(SQLModel):
    """Схема запроса на пополнение баланса карты."""
    amount: float = Field(gt=0.0, description="Сумма пополнения (>0)")
    notes: Optional[str] = Field(default=None, max_length=255)


class GiftCardUpdateStatus(SQLModel):
    """Схема изменения статуса активности карты."""
    is_active: Optional[bool] = None
    status: Optional[GiftCardStatus] = None
    notes: Optional[str] = None


class GiftCardTransactionRead(SQLModel):
    """Схема отображения транзакции подарочной карты."""
    id: int
    gift_card_id: int
    order_id: Optional[int] = None
    type: GiftCardTransactionType
    amount: float
    balance_before: float
    balance_after: float
    comment: Optional[str] = None
    created_at: datetime
    created_by: Optional[int] = None


class GiftCardRead(SQLModel):
    """Схема детального отображения подарочной карты."""
    id: int
    code: str
    initial_balance: float
    current_balance: float
    status: GiftCardStatus
    is_active: bool
    expiry_date: Optional[date] = None
    customer_id: Optional[int] = None
    notes: Optional[str] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    transactions: List[GiftCardTransactionRead] = []


class GiftCardListResponse(SQLModel):
    """Пагинированный ответ списка подарочных карт."""
    items: List[GiftCardRead]
    total: int
