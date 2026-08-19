from typing import List, Optional
from fastapi import APIRouter, Depends, status
from app.dependencies import TenantSession, CurrentUser, require_permission
from app.inventory.models import (
    SupplierRead, SupplierCreate, SupplierUpdate, SupplierPaymentCreate,
    SupplierTransactionRead, SupplierTransactionCreate, SupplierTransactionUpdate
)
from app.inventory.services import supplier_service

router = APIRouter(prefix="/suppliers", tags=["Suppliers"])

@router.get("/", response_model=List[SupplierRead], dependencies=[Depends(require_permission("inventory:view"))])
async def get_suppliers(
    session: TenantSession,
    user: CurrentUser,
):
    return await supplier_service.get_suppliers(session)

@router.post("/", response_model=SupplierRead, dependencies=[Depends(require_permission("inventory:manage"))])
async def create_supplier(
    supplier_in: SupplierCreate,
    session: TenantSession,
    user: CurrentUser,
):
    return await supplier_service.create_supplier(session, supplier_in, user_id=user.id)

@router.put("/{supplier_id}", response_model=SupplierRead, dependencies=[Depends(require_permission("inventory:manage"))])
async def update_supplier(
    supplier_id: int,
    supplier_in: SupplierUpdate,
    session: TenantSession,
    user: CurrentUser,
):
    return await supplier_service.update_supplier(session, supplier_id, supplier_in)

@router.delete("/{supplier_id}", status_code=status.HTTP_204_NO_CONTENT, dependencies=[Depends(require_permission("inventory:manage"))])
async def delete_supplier(
    supplier_id: int,
    session: TenantSession,
    user: CurrentUser,
):
    await supplier_service.delete_supplier(session, supplier_id)

# --- Transactions & Ledger ---

@router.get("/{supplier_id}/transactions", response_model=List[SupplierTransactionRead], dependencies=[Depends(require_permission("inventory:view"))])
async def get_supplier_transactions(
    supplier_id: int,
    session: TenantSession,
    user: CurrentUser,
):
    return await supplier_service.get_supplier_transactions(session, supplier_id)

@router.post("/{supplier_id}/transactions", response_model=SupplierTransactionRead, dependencies=[Depends(require_permission("inventory:manage"))])
async def create_supplier_transaction(
    supplier_id: int,
    txn_in: SupplierTransactionCreate,
    session: TenantSession,
    user: CurrentUser,
):
    return await supplier_service.create_supplier_transaction(session, supplier_id, txn_in, user_id=user.id)

@router.post("/{supplier_id}/payments", response_model=SupplierTransactionRead, dependencies=[Depends(require_permission("inventory:manage"))])
async def record_supplier_payment_legacy(
    supplier_id: int,
    payment_in: SupplierPaymentCreate,
    session: TenantSession,
    user: CurrentUser,
):
    from app.inventory.models import SupplierTransactionType
    txn_in = SupplierTransactionCreate(
        type=SupplierTransactionType.PAYMENT,
        amount=payment_in.amount,
        payment_method=payment_in.payment_method,
        comment=payment_in.comment
    )
    return await supplier_service.create_supplier_transaction(session, supplier_id, txn_in, user_id=user.id)

@router.put("/{supplier_id}/transactions/{transaction_id}", response_model=SupplierTransactionRead, dependencies=[Depends(require_permission("inventory:manage"))])
async def update_supplier_transaction(
    supplier_id: int,
    transaction_id: int,
    txn_in: SupplierTransactionUpdate,
    session: TenantSession,
    user: CurrentUser,
):
    return await supplier_service.update_supplier_transaction(session, supplier_id, transaction_id, txn_in, user_id=user.id)

@router.delete("/{supplier_id}/transactions/{transaction_id}", status_code=status.HTTP_204_NO_CONTENT, dependencies=[Depends(require_permission("inventory:manage"))])
async def delete_supplier_transaction(
    supplier_id: int,
    transaction_id: int,
    session: TenantSession,
    user: CurrentUser,
):
    await supplier_service.delete_supplier_transaction(session, supplier_id, transaction_id)
