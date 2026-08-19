from typing import List, Optional
from datetime import datetime, timezone
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select
from fastapi import HTTPException
from sqlalchemy.orm import selectinload

from app.inventory.models import (
    Supplier, SupplierCreate, SupplierUpdate,
    SupplierTransaction, SupplierTransactionType,
    SupplierTransactionCreate, SupplierTransactionUpdate, SupplierTransactionRead
)

async def get_suppliers(session: AsyncSession) -> List[Supplier]:
    result = await session.execute(select(Supplier).order_by(Supplier.name))
    return result.scalars().all()

async def get_supplier_by_id(session: AsyncSession, supplier_id: int) -> Supplier:
    supplier = await session.get(Supplier, supplier_id)
    if not supplier:
        raise HTTPException(status_code=404, detail="Supplier not found")
    return supplier

async def create_supplier(session: AsyncSession, supplier_in: SupplierCreate, user_id: Optional[int] = None) -> Supplier:
    supplier = Supplier(
        name=supplier_in.name,
        contact_info=supplier_in.contact_info,
        is_active=supplier_in.is_active,
        balance=0.0
    )
    session.add(supplier)
    await session.flush()

    if supplier_in.initial_balance and supplier_in.initial_balance != 0:
        supplier.balance = supplier_in.initial_balance
        txn_type = SupplierTransactionType.MANUAL_DEBT if supplier_in.initial_balance < 0 else SupplierTransactionType.ADJUSTMENT
        txn = SupplierTransaction(
            supplier_id=supplier.id,
            type=txn_type,
            amount=abs(supplier_in.initial_balance),
            payment_method="cash",
            comment="Начальный баланс при создании",
            created_by=user_id
        )
        session.add(txn)
        await session.flush()

    return supplier

async def update_supplier(session: AsyncSession, supplier_id: int, supplier_in: SupplierUpdate) -> Supplier:
    supplier = await get_supplier_by_id(session, supplier_id)
    update_data = supplier_in.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(supplier, key, value)
    session.add(supplier)
    await session.flush()
    return supplier

async def delete_supplier(session: AsyncSession, supplier_id: int):
    supplier = await get_supplier_by_id(session, supplier_id)
    from sqlalchemy.exc import IntegrityError
    try:
        await session.delete(supplier)
        await session.flush()
    except IntegrityError:
        await session.rollback()
        raise HTTPException(
            status_code=400,
            detail="Невозможно удалить поставщика, так как к нему привязаны накладные или взаиморасчеты. Деактивируйте его."
        )

# --- Transactions & Ledger ---

async def get_supplier_transactions(session: AsyncSession, supplier_id: int) -> List[SupplierTransactionRead]:
    await get_supplier_by_id(session, supplier_id)
    stmt = (
        select(SupplierTransaction)
        .options(selectinload(SupplierTransaction.document))
        .where(SupplierTransaction.supplier_id == supplier_id)
        .order_by(SupplierTransaction.date.desc(), SupplierTransaction.id.desc())
    )
    result = await session.execute(stmt)
    txns = result.scalars().all()
    
    return [
        SupplierTransactionRead(
            id=t.id,
            supplier_id=t.supplier_id,
            document_id=t.document_id,
            type=t.type,
            amount=t.amount,
            payment_method=t.payment_method,
            comment=t.comment,
            date=t.date,
            created_by=t.created_by,
            document_invoice_number=t.document.invoice_number if t.document else None
        )
        for t in txns
    ]

async def create_supplier_transaction(
    session: AsyncSession,
    supplier_id: int,
    txn_in: SupplierTransactionCreate,
    user_id: Optional[int] = None
) -> SupplierTransaction:
    supplier = await get_supplier_by_id(session, supplier_id)

    txn = SupplierTransaction(
        supplier_id=supplier.id,
        type=txn_in.type,
        amount=txn_in.amount,
        payment_method=txn_in.payment_method,
        comment=txn_in.comment,
        date=txn_in.date or datetime.now(timezone.utc).replace(tzinfo=None),
        created_by=user_id
    )
    session.add(txn)

    # Balance impact:
    # PAYMENT increases balance (reduces debt)
    # INVOICE / MANUAL_DEBT decreases balance (increases debt)
    # ADJUSTMENT: positive amount increases balance, negative decreases
    if txn_in.type == SupplierTransactionType.PAYMENT:
        supplier.balance = (supplier.balance or 0.0) + txn_in.amount
    elif txn_in.type in [SupplierTransactionType.INVOICE, SupplierTransactionType.MANUAL_DEBT]:
        supplier.balance = (supplier.balance or 0.0) - txn_in.amount
    elif txn_in.type == SupplierTransactionType.ADJUSTMENT:
        supplier.balance = (supplier.balance or 0.0) + txn_in.amount

    session.add(supplier)
    await session.flush()
    return txn

async def update_supplier_transaction(
    session: AsyncSession,
    supplier_id: int,
    transaction_id: int,
    txn_in: SupplierTransactionUpdate,
    user_id: Optional[int] = None
) -> SupplierTransaction:
    supplier = await get_supplier_by_id(session, supplier_id)
    txn = await session.get(SupplierTransaction, transaction_id)
    if not txn or txn.supplier_id != supplier_id:
        raise HTTPException(status_code=404, detail="Transaction not found")

    old_amount = txn.amount
    old_type = txn.type

    # Revert old balance impact
    if old_type == SupplierTransactionType.PAYMENT:
        supplier.balance = (supplier.balance or 0.0) - old_amount
    elif old_type in [SupplierTransactionType.INVOICE, SupplierTransactionType.MANUAL_DEBT]:
        supplier.balance = (supplier.balance or 0.0) + old_amount
    elif old_type == SupplierTransactionType.ADJUSTMENT:
        supplier.balance = (supplier.balance or 0.0) - old_amount

    # Apply updates
    if txn_in.amount is not None:
        txn.amount = txn_in.amount
    if txn_in.payment_method is not None:
        txn.payment_method = txn_in.payment_method
    if txn_in.comment is not None:
        txn.comment = txn_in.comment
    if txn_in.date is not None:
        txn.date = txn_in.date

    # Apply new balance impact
    if txn.type == SupplierTransactionType.PAYMENT:
        supplier.balance = (supplier.balance or 0.0) + txn.amount
    elif txn.type in [SupplierTransactionType.INVOICE, SupplierTransactionType.MANUAL_DEBT]:
        supplier.balance = (supplier.balance or 0.0) - txn.amount
    elif txn.type == SupplierTransactionType.ADJUSTMENT:
        supplier.balance = (supplier.balance or 0.0) + txn.amount

    session.add(txn)
    session.add(supplier)
    await session.flush()
    return txn

async def delete_supplier_transaction(
    session: AsyncSession,
    supplier_id: int,
    transaction_id: int
):
    supplier = await get_supplier_by_id(session, supplier_id)
    txn = await session.get(SupplierTransaction, transaction_id)
    if not txn or txn.supplier_id != supplier_id:
        raise HTTPException(status_code=404, detail="Transaction not found")

    # Revert balance impact
    if txn.type == SupplierTransactionType.PAYMENT:
        supplier.balance = (supplier.balance or 0.0) - txn.amount
    elif txn.type in [SupplierTransactionType.INVOICE, SupplierTransactionType.MANUAL_DEBT]:
        supplier.balance = (supplier.balance or 0.0) + txn.amount
    elif txn.type == SupplierTransactionType.ADJUSTMENT:
        supplier.balance = (supplier.balance or 0.0) - txn.amount

    session.add(supplier)
    await session.delete(txn)
    await session.flush()
