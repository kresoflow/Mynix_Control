from enum import Enum
from typing import Optional, List
from datetime import datetime, date, timezone
from sqlmodel import SQLModel, Field, Relationship
from sqlalchemy import Column, String
from sqlalchemy import Enum as SAEnum
from app.base_model import TenantModel

class CustomerTransactionType(str, Enum):
    ORDER_DEBT = "order_debt"         # Продажа в долг по чеку
    ORDER_DEPOSIT = "order_deposit"   # Оплата чека за счет депозита
    PAYMENT = "payment"               # Погашение долга клиентом
    DEPOSIT = "deposit"               # Внесение аванса/депозита клиентом
    ADJUSTMENT = "adjustment"         # Ручная корректировка сальдо

    @classmethod
    def _missing_(cls, value):
        if isinstance(value, str):
            val_lower = value.lower()
            for member in cls:
                if member.value == val_lower or member.name.lower() == val_lower:
                    return member
        return None

class BonusTransactionType(str, Enum):
    CASHBACK = "cashback"            # Авто-начисление % от заказа
    REDEEM = "redeem"                # Списание бонусов в счет чека на кассе
    MANUAL_ACCRUAL = "manual_add"    # Ручное начисление администратором (извинение, промо)
    MANUAL_DEDUCTION = "manual_sub"  # Ручное списание
    WELCOME = "welcome"              # Приветственный бонус при регистрации
    BIRTHDAY = "birthday"            # Подарок на день рождения
    EXPIRED = "expired"              # Сгорание бонусов по сроку

    @classmethod
    def _missing_(cls, value):
        if isinstance(value, str):
            val_lower = value.lower()
            for member in cls:
                if member.value == val_lower or member.name.lower() == val_lower:
                    return member
        return None

class Customer(TenantModel, table=True):
    __tablename__ = "customers"

    id: Optional[int] = Field(default=None, primary_key=True)
    name: str = Field(max_length=150, index=True)
    phone: Optional[str] = Field(default=None, max_length=50, index=True)
    email: Optional[str] = Field(default=None, max_length=100)
    address: Optional[str] = Field(default=None, max_length=255)
    balance: float = Field(default=0.0)  # Positive = deposit/advance, negative = debt
    credit_limit: float = Field(default=0.0)  # 0.0 = no limit, otherwise max debt allowed
    discount_percent: float = Field(default=0.0)  # 0 to 100%
    notes: Optional[str] = Field(default=None, max_length=500)
    is_active: bool = Field(default=True)

    # ── Метрики LTV & Активности ─────────────────────────────────────
    total_spent: float = Field(default=0.0)      # LTV — суммарная выручка по гостю за все время
    orders_count: int = Field(default=0)         # Всего заказов/визитов
    average_check: float = Field(default=0.0)    # Средний чек (total_spent / orders_count)
    last_visit_at: Optional[datetime] = None     # Дата последнего визита

    # ── Программа Лояльности & Бонусы ───────────────────────────────
    bonus_balance: float = Field(default=0.0)    # Бонусный счет (1 бонус = 1 сом)
    tier_level: str = Field(default="standard")  # standard (3%), silver (5%), gold (10%)
    birth_date: Optional[date] = None            # Дата рождения гостя

    # Relationships
    transactions: List["CustomerTransaction"] = Relationship(
        back_populates="customer",
        sa_relationship_kwargs={"cascade": "all, delete-orphan", "lazy": "selectin"}
    )
    bonus_transactions: List["BonusTransaction"] = Relationship(
        back_populates="customer",
        sa_relationship_kwargs={"cascade": "all, delete-orphan", "lazy": "selectin"}
    )

class CustomerTransaction(TenantModel, table=True):
    __tablename__ = "customer_transactions"

    id: Optional[int] = Field(default=None, primary_key=True)
    customer_id: int = Field(foreign_key="customers.id", index=True)
    order_id: Optional[int] = Field(default=None, foreign_key="orders.id", index=True)
    type: CustomerTransactionType = Field(
        sa_column=Column(
            SAEnum(CustomerTransactionType, values_callable=lambda obj: [e.value for e in obj], native_enum=False),
            nullable=False
        )
    )
    amount: float = Field(default=0.0)  # Positive value
    payment_method: Optional[str] = Field(default="cash", max_length=30)  # "cash", "transfer", "card"
    comment: Optional[str] = Field(default=None, max_length=255)
    date: datetime = Field(default_factory=lambda: datetime.now(timezone.utc).replace(tzinfo=None))
    created_by: Optional[int] = Field(default=None, foreign_key="public.users.id")

    # Relationships
    customer: Optional[Customer] = Relationship(back_populates="transactions")

class BonusTransaction(TenantModel, table=True):
    __tablename__ = "bonus_transactions"

    id: Optional[int] = Field(default=None, primary_key=True)
    customer_id: int = Field(foreign_key="customers.id", index=True)
    order_id: Optional[int] = Field(default=None, foreign_key="orders.id", index=True)
    type: BonusTransactionType = Field(
        sa_column=Column(
            SAEnum(BonusTransactionType, values_callable=lambda obj: [e.value for e in obj], native_enum=False),
            nullable=False
        )
    )
    amount: float = Field(default=0.0)  # Positive value
    comment: Optional[str] = Field(default=None, max_length=255)
    date: datetime = Field(default_factory=lambda: datetime.now(timezone.utc).replace(tzinfo=None))
    created_by: Optional[int] = Field(default=None, foreign_key="public.users.id")

    # Relationships
    customer: Optional[Customer] = Relationship(back_populates="bonus_transactions")


# ── Pydantic DTOs ────────────────────────────────────────────────

class CustomerRead(SQLModel):
    id: int
    name: str
    phone: Optional[str] = None
    email: Optional[str] = None
    address: Optional[str] = None
    balance: float = 0.0
    credit_limit: float = 0.0
    discount_percent: float = 0.0
    notes: Optional[str] = None
    is_active: bool = True
    total_spent: float = 0.0
    orders_count: int = 0
    average_check: float = 0.0
    last_visit_at: Optional[datetime] = None
    bonus_balance: float = 0.0
    tier_level: str = "standard"
    birth_date: Optional[date] = None
    created_at: Optional[datetime] = None

class CustomerCreate(SQLModel):
    name: str
    phone: Optional[str] = None
    email: Optional[str] = None
    address: Optional[str] = None
    credit_limit: float = 0.0
    discount_percent: float = 0.0
    notes: Optional[str] = None
    birth_date: Optional[date] = None

class CustomerUpdate(SQLModel):
    name: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[str] = None
    address: Optional[str] = None
    credit_limit: Optional[float] = None
    discount_percent: Optional[float] = None
    notes: Optional[str] = None
    is_active: Optional[bool] = None
    birth_date: Optional[date] = None

class CustomerTransactionCreate(SQLModel):
    type: CustomerTransactionType = CustomerTransactionType.PAYMENT
    amount: float
    payment_method: str = "cash"  # "cash", "transfer"
    comment: Optional[str] = None
    date: Optional[datetime] = None

class CustomerTransactionRead(SQLModel):
    id: int
    customer_id: int
    order_id: Optional[int] = None
    order_number: Optional[int] = None
    type: CustomerTransactionType
    amount: float
    payment_method: Optional[str] = "cash"
    comment: Optional[str] = None
    date: datetime
    created_by: Optional[int] = None

class CreateBonusTransactionRequest(SQLModel):
    type: BonusTransactionType = BonusTransactionType.MANUAL_ACCRUAL
    amount: float
    comment: Optional[str] = None

class BonusTransactionRead(SQLModel):
    id: int
    customer_id: int
    order_id: Optional[int] = None
    type: BonusTransactionType
    amount: float
    comment: Optional[str] = None
    date: datetime
    created_by: Optional[int] = None
