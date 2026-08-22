"""
POS module — database models.

Entities:
  - Shift:           Cash register shift (open/close, cash balances)
  - Order:           Customer order with items and payment
  - OrderItem:       Single line in an order (menu item × quantity)
  - CashTransaction: Cash movement log (income, expense, withdrawal)
"""

from typing import Optional, List
from datetime import datetime, timezone
from enum import Enum

from sqlmodel import SQLModel, Field, Relationship
from sqlalchemy import Column
from sqlalchemy.dialects.postgresql import JSONB

from app.base_model import TenantModel


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  ENUMS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


class OrderStatus(str, Enum):
    NEW = "new"               # Just created
    COOKING = "cooking"       # Sent to kitchen
    READY = "ready"           # Ready for pickup
    COMPLETED = "completed"   # Handed to customer
    CANCELLED = "cancelled"   # Cancelled

    @classmethod
    def _missing_(cls, value):
        if isinstance(value, str):
            val_lower = value.lower()
            for member in cls:
                if member.value == val_lower or member.name.lower() == val_lower:
                    return member
        return None


class PaymentMethod(str, Enum):
    CASH = "cash"
    CARD = "card"
    TRANSFER = "transfer"
    MIXED = "mixed"
    DEBT = "debt"
    DEPOSIT = "deposit"

    @classmethod
    def _missing_(cls, value):
        if isinstance(value, str):
            val_lower = value.lower()
            for member in cls:
                if member.value == val_lower or member.name.lower() == val_lower:
                    return member
        return None


class CashTransactionType(str, Enum):
    INCOME = "income"         # Payment received
    EXPENSE = "expense"       # Cash expense (e.g. napkins purchase)
    WITHDRAWAL = "withdrawal" # Owner cash withdrawal

    @classmethod
    def _missing_(cls, value):
        if isinstance(value, str):
            val_lower = value.lower()
            for member in cls:
                if member.value == val_lower or member.name.lower() == val_lower:
                    return member
        return None


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  SHIFT — cash register session
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


class Shift(TenantModel, table=True):
    """
    Represents a cash register shift.
    Opening: worker counts cash, enters opening_cash.
    Closing: system calculates expected cash, worker enters actual.
    Discrepancy = actual - expected (negative = shortage).
    """
    __tablename__ = "shifts"

    id: Optional[int] = Field(default=None, primary_key=True)
    opened_by: int = Field(foreign_key="public.users.id")
    closed_by: Optional[int] = Field(default=None, foreign_key="public.users.id")

    opened_at: datetime = Field(
        default_factory=lambda: datetime.now(timezone.utc).replace(tzinfo=None),
    )
    closed_at: Optional[datetime] = Field(default=None)

    opening_cash: float = Field(default=0.0)
    closing_cash_expected: Optional[float] = Field(default=None)
    closing_cash_actual: Optional[float] = Field(default=None)
    discrepancy: Optional[float] = Field(default=None)

    is_open: bool = Field(default=True)

    # Relationships
    orders: List["Order"] = Relationship(back_populates="shift")
    cash_transactions: List["CashTransaction"] = Relationship(back_populates="shift")


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  ORDER — customer order
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


from sqlalchemy.types import TypeDecorator, String

class OrderStatusType(TypeDecorator):
    impl = String(30)
    cache_ok = True

    def process_bind_param(self, value, dialect):
        if value is None:
            return None
        if isinstance(value, OrderStatus):
            return value.value
        return str(value).lower()

    def process_result_value(self, value, dialect):
        if value is None:
            return None
        val_lower = str(value).lower()
        for member in OrderStatus:
            if member.value == val_lower or member.name.lower() == val_lower:
                return member
        return OrderStatus.NEW

class PaymentMethodType(TypeDecorator):
    impl = String(30)
    cache_ok = True

    def process_bind_param(self, value, dialect):
        if value is None:
            return None
        if isinstance(value, PaymentMethod):
            return value.value
        return str(value).lower()

    def process_result_value(self, value, dialect):
        if value is None:
            return None
        val_lower = str(value).lower()
        for member in PaymentMethod:
            if member.value == val_lower or member.name.lower() == val_lower:
                return member
        return PaymentMethod.CASH


class Order(TenantModel, table=True):
    __tablename__ = "orders"

    id: Optional[int] = Field(default=None, primary_key=True)
    client_uuid: Optional[str] = Field(default=None, index=True, unique=True)
    shift_id: int = Field(foreign_key="shifts.id", index=True)
    created_by: int = Field(foreign_key="public.users.id")
    customer_id: Optional[int] = Field(default=None, foreign_key="customers.id", index=True)
    order_number: int = Field(default=0)  # daily sequential number
    status: OrderStatus = Field(
        default=OrderStatus.NEW,
        sa_column=Column(OrderStatusType(), nullable=False, default=OrderStatus.NEW)
    )
    payment_method: PaymentMethod = Field(
        default=PaymentMethod.CASH,
        sa_column=Column(PaymentMethodType(), nullable=False, default=PaymentMethod.CASH)
    )
    bonus_spent: float = Field(default=0.0)
    total: float = Field(default=0.0)
    note: Optional[str] = Field(default=None, max_length=500)

    # Relationships
    shift: Optional[Shift] = Relationship(back_populates="orders")
    items: List["OrderItem"] = Relationship(back_populates="order")


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  ORDER ITEM — single line in an order
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


class OrderItem(SQLModel, table=True):
    __tablename__ = "order_items"

    id: Optional[int] = Field(default=None, primary_key=True)
    order_id: int = Field(foreign_key="orders.id", index=True)
    menu_item_id: int = Field(foreign_key="menu_items.id")
    menu_item_name: str = Field(max_length=100)  # snapshot at order time
    quantity: int = Field(ge=1)
    unit_price: float = Field(ge=0)
    unit_cost: float = Field(default=0.0, ge=0)
    subtotal: float = Field(ge=0)
    item_type: str = Field(default="dish")
    selected_options: Optional[dict] = Field(default_factory=dict, sa_column=Column(JSONB))

    # Relationships
    order: Optional[Order] = Relationship(back_populates="items")


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  CASH TRANSACTION — cash movement log
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


class CashTransaction(TenantModel, table=True):
    __tablename__ = "cash_transactions"

    id: Optional[int] = Field(default=None, primary_key=True)
    shift_id: int = Field(foreign_key="shifts.id", index=True)
    user_id: int = Field(foreign_key="public.users.id")
    type: CashTransactionType
    amount: float
    description: str = Field(default="", max_length=255)

    # Relationships
    shift: Optional[Shift] = Relationship(back_populates="cash_transactions")


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  API SCHEMAS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


class OpenShiftRequest(SQLModel):
    opening_cash: float


class CloseShiftRequest(SQLModel):
    closing_cash_actual: float


class OrderItemCreate(SQLModel):
    menu_item_id: int
    quantity: int = Field(default=1, ge=1)
    unit_price_override: Optional[float] = Field(default=None, ge=0.0)
    options_json: Optional[str] = None
    selected_options: Optional[dict] = None


class CreateOrderRequest(SQLModel):
    items: list[OrderItemCreate]
    payment_method: PaymentMethod = PaymentMethod.CASH
    customer_id: Optional[int] = None
    bonus_spent: float = 0.0
    note: Optional[str] = None
    client_uuid: Optional[str] = None


class RecordExpenseRequest(SQLModel):
    amount: float = Field(gt=0)
    description: str


class OrderRead(SQLModel):
    id: int
    client_uuid: Optional[str] = None
    order_number: int
    status: OrderStatus
    payment_method: PaymentMethod
    customer_id: Optional[int] = None
    customer_name: Optional[str] = None
    bonus_spent: float = 0.0
    total: float
    note: Optional[str] = None
    created_by: int
    items: list[dict] = []
    created_at: datetime


class ShiftRead(SQLModel):
    id: int
    opened_by: int
    opened_at: datetime
    is_open: bool
    opening_cash: float
    closing_cash_expected: Optional[float] = None
    closing_cash_actual: Optional[float] = None
    discrepancy: Optional[float] = None
    total_orders: int = 0
    total_revenue: float = 0.0
