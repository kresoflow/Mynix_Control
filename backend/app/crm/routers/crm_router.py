from typing import List, Optional
from fastapi import APIRouter, Depends, status, Query
from app.dependencies import TenantSession, CurrentUser, require_permission
from app.crm.models import (
    CustomerRead, CustomerCreate, CustomerUpdate,
    CustomerTransactionRead, CustomerTransactionCreate,
    BonusTransactionRead, CreateBonusTransactionRequest
)
from app.crm.services import crm_service
from app.crm.services import crm_loyalty_service

router = APIRouter(prefix="/customers", tags=["CRM & Customers"])

@router.get("/", response_model=List[CustomerRead], dependencies=[Depends(require_permission("crm:view"))])
async def get_customers(
    session: TenantSession,
    user: CurrentUser,
    query: Optional[str] = Query(None, description="Search by name or phone"),
    filter_type: Optional[str] = Query(None, description="all, debtors, deposits, vip, churn, new"),
):
    return await crm_service.get_customers(session, query=query, filter_type=filter_type)

@router.post("/", response_model=CustomerRead, dependencies=[Depends(require_permission("crm:manage"))])
async def create_customer(
    customer_in: CustomerCreate,
    session: TenantSession,
    user: CurrentUser,
):
    return await crm_service.create_customer(session, customer_in)

@router.get("/{customer_id}", response_model=CustomerRead, dependencies=[Depends(require_permission("crm:view"))])
async def get_customer(
    customer_id: int,
    session: TenantSession,
    user: CurrentUser,
):
    customer = await crm_service.get_customer_by_id(session, customer_id)
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

@router.put("/{customer_id}", response_model=CustomerRead, dependencies=[Depends(require_permission("crm:manage"))])
async def update_customer(
    customer_id: int,
    customer_in: CustomerUpdate,
    session: TenantSession,
    user: CurrentUser,
):
    return await crm_service.update_customer(session, customer_id, customer_in)

@router.delete("/{customer_id}", status_code=status.HTTP_204_NO_CONTENT, dependencies=[Depends(require_permission("crm:manage"))])
async def delete_customer(
    customer_id: int,
    session: TenantSession,
    user: CurrentUser,
):
    await crm_service.delete_customer(session, customer_id)

# ── Ledger Transactions ──────────────────────────────────────────

@router.get("/{customer_id}/transactions", response_model=List[CustomerTransactionRead], dependencies=[Depends(require_permission("crm:view"))])
async def get_customer_transactions(
    customer_id: int,
    session: TenantSession,
    user: CurrentUser,
):
    return await crm_service.get_customer_transactions(session, customer_id)

@router.post("/{customer_id}/transactions", response_model=CustomerTransactionRead, dependencies=[Depends(require_permission("crm:manage"))])
async def create_customer_transaction(
    customer_id: int,
    txn_in: CustomerTransactionCreate,
    session: TenantSession,
    user: CurrentUser,
):
    return await crm_service.create_customer_transaction(
        session, customer_id, txn_in, user_id=user.id
    )

# ── Bonus & Loyalty Transactions ─────────────────────────────────

@router.get("/{customer_id}/bonus-transactions", response_model=List[BonusTransactionRead], dependencies=[Depends(require_permission("crm:view"))])
async def get_customer_bonus_transactions(
    customer_id: int,
    session: TenantSession,
    user: CurrentUser,
):
    return await crm_loyalty_service.get_customer_bonus_transactions(session, customer_id)

@router.post("/{customer_id}/bonus-transactions", response_model=BonusTransactionRead, dependencies=[Depends(require_permission("crm:manage"))])
async def create_bonus_transaction(
    customer_id: int,
    data: CreateBonusTransactionRequest,
    session: TenantSession,
    user: CurrentUser,
):
    return await crm_loyalty_service.create_bonus_transaction(
        session, customer_id, data, user_id=user.id
    )

# ── Customer Orders & Receipts ───────────────────────────────────

@router.get("/{customer_id}/orders", dependencies=[Depends(require_permission("crm:view"))])
async def get_customer_orders(
    customer_id: int,
    session: TenantSession,
    user: CurrentUser,
):
    return await crm_service.get_customer_orders(session, customer_id)

