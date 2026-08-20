from typing import List, Optional
from datetime import datetime, timezone, timedelta
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select, func, or_
from fastapi import HTTPException, status

from app.crm.models import (
    Customer, CustomerTransaction, CustomerTransactionType,
    CustomerCreate, CustomerUpdate, CustomerTransactionCreate,
    CustomerRead, CustomerTransactionRead, BonusTransaction, BonusTransactionType
)
from app.pos.models import Shift, CashTransaction, CashTransactionType

async def get_customers(
    session: AsyncSession,
    query: Optional[str] = None,
    filter_type: Optional[str] = None,  # "all", "debtors", "deposits", "vip", "churn", "new"
) -> List[CustomerRead]:
    stmt = select(Customer).where(Customer.is_active == True)

    if query:
        search = f"%{query.strip()}%"
        stmt = stmt.where(or_(Customer.name.ilike(search), Customer.phone.ilike(search)))

    now = datetime.now(timezone.utc).replace(tzinfo=None)

    if filter_type == "debtors":
        stmt = stmt.where(Customer.balance < 0)
    elif filter_type == "deposits":
        stmt = stmt.where(Customer.balance > 0)
    elif filter_type == "vip":
        stmt = stmt.where(Customer.total_spent >= 10000.0)
    elif filter_type == "churn":
        thirty_days_ago = now - timedelta(days=30)
        stmt = stmt.where(Customer.last_visit_at != None, Customer.last_visit_at < thirty_days_ago)
    elif filter_type == "new":
        stmt = stmt.where(Customer.orders_count <= 1)

    stmt = stmt.order_by(Customer.name.asc())
    result = await session.execute(stmt)
    customers = result.scalars().all()

    return [
        CustomerRead(
            id=c.id,
            name=c.name,
            phone=c.phone,
            email=c.email,
            address=c.address,
            balance=c.balance,
            credit_limit=c.credit_limit,
            discount_percent=c.discount_percent,
            notes=c.notes,
            is_active=c.is_active,
            total_spent=c.total_spent or 0.0,
            orders_count=c.orders_count or 0,
            average_check=c.average_check or 0.0,
            last_visit_at=c.last_visit_at,
            bonus_balance=c.bonus_balance or 0.0,
            tier_level=c.tier_level or "standard",
            birth_date=c.birth_date,
            created_at=c.created_at,
        )
        for c in customers
    ]

async def get_customer_by_id(session: AsyncSession, customer_id: int) -> Customer:
    customer = await session.get(Customer, customer_id)
    if not customer or not customer.is_active:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Клиент не найден")
    return customer

async def create_customer(
    session: AsyncSession,
    customer_in: CustomerCreate,
    welcome_bonus: float = 50.0,
) -> CustomerRead:
    customer = Customer(
        name=customer_in.name,
        phone=customer_in.phone,
        email=customer_in.email,
        address=customer_in.address,
        credit_limit=customer_in.credit_limit,
        discount_percent=customer_in.discount_percent,
        notes=customer_in.notes,
        balance=0.0,
        bonus_balance=welcome_bonus,
        total_spent=0.0,
        orders_count=0,
        average_check=0.0,
        tier_level="standard",
        birth_date=customer_in.birth_date,
        is_active=True,
    )
    session.add(customer)
    await session.flush()

    if welcome_bonus > 0:
        welcome_txn = BonusTransaction(
            customer_id=customer.id,
            type=BonusTransactionType.WELCOME,
            amount=welcome_bonus,
            comment="Приветственный бонус при регистрации",
            date=datetime.now(timezone.utc).replace(tzinfo=None),
        )
        session.add(welcome_txn)
        await session.flush()

    return CustomerRead(
        id=customer.id,
        name=customer.name,
        phone=customer.phone,
        email=customer.email,
        address=customer.address,
        balance=customer.balance,
        credit_limit=customer.credit_limit,
        discount_percent=customer.discount_percent,
        notes=customer.notes,
        is_active=customer.is_active,
        total_spent=customer.total_spent,
        orders_count=customer.orders_count,
        average_check=customer.average_check,
        last_visit_at=customer.last_visit_at,
        bonus_balance=customer.bonus_balance,
        tier_level=customer.tier_level,
        birth_date=customer.birth_date,
        created_at=customer.created_at,
    )

async def update_customer(
    session: AsyncSession,
    customer_id: int,
    customer_in: CustomerUpdate,
) -> CustomerRead:
    customer = await get_customer_by_id(session, customer_id)
    
    update_data = customer_in.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(customer, key, value)

    session.add(customer)
    await session.flush()
    return CustomerRead(
        id=customer.id,
        name=customer.name,
        phone=customer.phone,
        email=customer.email,
        address=customer.address,
        balance=customer.balance,
        credit_limit=customer.credit_limit,
        discount_percent=customer.discount_percent,
        notes=customer.notes,
        is_active=customer.is_active,
        total_spent=customer.total_spent or 0.0,
        orders_count=customer.orders_count or 0,
        average_check=customer.average_check or 0.0,
        last_visit_at=customer.last_visit_at,
        bonus_balance=customer.bonus_balance or 0.0,
        tier_level=customer.tier_level or "standard",
        birth_date=customer.birth_date,
        created_at=customer.created_at,
    )

async def delete_customer(session: AsyncSession, customer_id: int) -> None:
    customer = await get_customer_by_id(session, customer_id)
    if customer.balance < 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Невозможно удалить клиента с непогашенным долгом. Погасите долг перед удалением."
        )
    customer.is_active = False
    session.add(customer)
    await session.flush()

# ── Ledger Transactions & Orders (Delegated to crm_ledger_service) ──
from app.crm.services.crm_ledger_service import (
    get_customer_transactions,
    create_customer_transaction,
    get_customer_orders,
)

__all__ = [
    "get_customers",
    "get_customer_by_id",
    "create_customer",
    "update_customer",
    "delete_customer",
    "get_customer_transactions",
    "create_customer_transaction",
    "get_customer_orders",
]

