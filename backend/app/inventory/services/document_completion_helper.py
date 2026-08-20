"""
Helper functions for completing inventory documents by type.
Handles stock transaction creation, moving average recalculation, and supplier balances.
"""

from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession

from app.inventory.models import (
    InventoryDocument, DocumentType,
    Supplier, SupplierTransaction, SupplierTransactionType,
    Ingredient, RetailProduct, StockTransaction, StockTransactionType
)


async def process_receipt_completion(
    session: AsyncSession,
    doc: InventoryDocument,
    user_id: Optional[int] = None
) -> None:
    """Process receipt document items, update moving average cost, and create RECEIPT transactions."""
    for item in doc.items:
        if item.ingredient_id:
            ing = await session.get(Ingredient, item.ingredient_id)
            if not ing:
                continue

            current_value = ing.current_stock * ing.cost_per_unit
            new_value = item.quantity * item.price_per_unit
            total_qty = ing.current_stock + item.quantity

            ing.current_stock = total_qty
            if total_qty > 0:
                ing.cost_per_unit = (current_value + new_value) / total_qty

            session.add(ing)

            txn = StockTransaction(
                ingredient_id=ing.id,
                type=StockTransactionType.RECEIPT,
                quantity=item.quantity,
                reason=f"Doc #{doc.id} (Receipt)",
                created_by=user_id,
            )
            session.add(txn)

        elif item.retail_product_id:
            ret = await session.get(RetailProduct, item.retail_product_id)
            if not ret:
                continue

            current_value = ret.current_stock * ret.cost
            new_value = item.quantity * item.price_per_unit
            total_qty = ret.current_stock + item.quantity

            ret.current_stock = total_qty
            if total_qty > 0:
                ret.cost = (current_value + new_value) / total_qty

            session.add(ret)

            txn = StockTransaction(
                retail_product_id=ret.id,
                type=StockTransactionType.RECEIPT,
                quantity=item.quantity,
                reason=f"Doc #{doc.id} (Receipt)",
                created_by=user_id,
            )
            session.add(txn)


async def process_writeoff_completion(
    session: AsyncSession,
    doc: InventoryDocument,
    user_id: Optional[int] = None
) -> None:
    """Process write-off document items and decrease stock levels."""
    for item in doc.items:
        if item.ingredient_id:
            ing = await session.get(Ingredient, item.ingredient_id)
            if not ing:
                continue

            ing.current_stock -= item.quantity
            session.add(ing)

            txn = StockTransaction(
                ingredient_id=ing.id,
                type=StockTransactionType.WRITE_OFF,
                quantity=-item.quantity,
                reason=f"Doc #{doc.id} (Write-off): {doc.reason}",
                created_by=user_id,
            )
            session.add(txn)

        elif item.retail_product_id:
            ret = await session.get(RetailProduct, item.retail_product_id)
            if not ret:
                continue

            ret.current_stock -= item.quantity
            session.add(ret)

            txn = StockTransaction(
                retail_product_id=ret.id,
                type=StockTransactionType.WRITE_OFF,
                quantity=-item.quantity,
                reason=f"Doc #{doc.id} (Write-off): {doc.reason}",
                created_by=user_id,
            )
            session.add(txn)


async def process_inventory_completion(
    session: AsyncSession,
    doc: InventoryDocument,
    user_id: Optional[int] = None
) -> None:
    """Process physical inventory audit items and create surplus/shortage transactions."""
    for item in doc.items:
        actual_quantity = item.quantity

        if item.ingredient_id:
            ing = await session.get(Ingredient, item.ingredient_id)
            if not ing:
                continue

            diff = actual_quantity - ing.current_stock
            if diff != 0:
                txn_type = (
                    StockTransactionType.INVENTORY_SURPLUS if diff > 0
                    else StockTransactionType.INVENTORY_SHORTAGE
                )
                txn = StockTransaction(
                    ingredient_id=ing.id,
                    type=txn_type,
                    quantity=diff,
                    reason=f"Doc #{doc.id} (Inventory): Expected {ing.current_stock}, Got {actual_quantity}",
                    created_by=user_id,
                )
                session.add(txn)
                ing.current_stock = actual_quantity
                session.add(ing)

        elif item.retail_product_id:
            ret = await session.get(RetailProduct, item.retail_product_id)
            if not ret:
                continue

            diff = actual_quantity - ret.current_stock
            if diff != 0:
                txn_type = (
                    StockTransactionType.INVENTORY_SURPLUS if diff > 0
                    else StockTransactionType.INVENTORY_SHORTAGE
                )
                txn = StockTransaction(
                    retail_product_id=ret.id,
                    type=txn_type,
                    quantity=diff,
                    reason=f"Doc #{doc.id} (Inventory): Expected {ret.current_stock}, Got {actual_quantity}",
                    created_by=user_id,
                )
                session.add(txn)
                ret.current_stock = actual_quantity
                session.add(ret)


async def process_supplier_debt(
    session: AsyncSession,
    doc: InventoryDocument,
    user_id: Optional[int] = None
) -> None:
    """Update supplier debt balance and record invoice ledger transaction if unpaid portion exists."""
    if doc.type != DocumentType.RECEIPT or not doc.supplier_id:
        return

    supplier = await session.get(Supplier, doc.supplier_id)
    if not supplier:
        return

    unpaid_portion = doc.total_amount - (doc.paid_amount or 0.0)
    if unpaid_portion > 0:
        supplier.balance = (supplier.balance or 0.0) - unpaid_portion
        session.add(supplier)

        txn = SupplierTransaction(
            supplier_id=supplier.id,
            document_id=doc.id,
            type=SupplierTransactionType.INVOICE,
            amount=unpaid_portion,
            payment_method=doc.payment_method or "debt",
            comment=f"Приходная накладная #{doc.id}" + (f" (инвойс {doc.invoice_number})" if doc.invoice_number else ""),
            date=doc.date,
            created_by=user_id
        )
        session.add(txn)
