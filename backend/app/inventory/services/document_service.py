from typing import List, Optional
from datetime import datetime, timezone

from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select
from fastapi import HTTPException
from sqlalchemy.orm import selectinload

from app.inventory.models import (
    InventoryDocument, InventoryDocumentItem, DocumentType, DocumentStatus,
    Supplier, SupplierTransaction, SupplierTransactionType,
    Ingredient, RetailProduct, StockTransaction, StockTransactionType,
    InventoryDocumentCreate, InventoryDocumentItemCreate,
    InventoryDocumentRead, InventoryDocumentDetailRead, InventoryDocumentItemRead
)

async def create_document(
    session: AsyncSession,
    doc_in: InventoryDocumentCreate,
    user_id: Optional[int] = None
) -> InventoryDocument:
    doc = InventoryDocument(
        type=doc_in.type,
        date=doc_in.date or datetime.now(timezone.utc).replace(tzinfo=None),
        supplier_id=doc_in.supplier_id,
        invoice_number=doc_in.invoice_number,
        reason=doc_in.reason,
        payment_status=doc_in.payment_status or "unpaid",
        paid_amount=doc_in.paid_amount or 0.0,
        payment_method=doc_in.payment_method or "cash",
        created_by=user_id,
        status=DocumentStatus.DRAFT,
        total_amount=0.0
    )
    
    session.add(doc)
    await session.flush()
    
    total = 0.0
    for item_in in doc_in.items:
        if item_in.ingredient_id is None and item_in.retail_product_id is None:
            raise HTTPException(400, "Item must have ingredient_id or retail_product_id")
            
        total_price = item_in.quantity * item_in.price_per_unit
        total += total_price
        
        item = InventoryDocumentItem(
            document_id=doc.id,
            ingredient_id=item_in.ingredient_id,
            retail_product_id=item_in.retail_product_id,
            quantity=item_in.quantity,
            price_per_unit=item_in.price_per_unit,
            total_price=total_price
        )
        session.add(item)
        
        # Update sell_price and min_stock_alert directly on the product if provided
        if item_in.ingredient_id:
            ing = await session.get(Ingredient, item_in.ingredient_id)
            if ing:
                if item_in.min_stock_alert is not None:
                    ing.min_stock_alert = item_in.min_stock_alert
                session.add(ing)
        elif item_in.retail_product_id:
            ret = await session.get(RetailProduct, item_in.retail_product_id)
            if ret:
                if item_in.sell_price is not None:
                    ret.price = item_in.sell_price
                if item_in.min_stock_alert is not None:
                    ret.min_stock_alert = item_in.min_stock_alert
                session.add(ret)
        
    doc.total_amount = total
    await session.flush()
    
    return doc

async def get_documents(
    session: AsyncSession,
    doc_type: Optional[DocumentType] = None
) -> List[InventoryDocumentRead]:
    stmt = select(InventoryDocument).options(selectinload(InventoryDocument.supplier))
    if doc_type:
        stmt = stmt.where(InventoryDocument.type == doc_type)
    stmt = stmt.order_by(InventoryDocument.date.desc())
    
    result = await session.execute(stmt)
    docs = result.scalars().all()
    return [
        InventoryDocumentRead(
            id=d.id,
            type=d.type,
            status=d.status,
            date=d.date,
            supplier_id=d.supplier_id,
            supplier_name=d.supplier.name if d.supplier else None,
            invoice_number=d.invoice_number,
            reason=d.reason,
            total_amount=d.total_amount,
            payment_status=d.payment_status,
            paid_amount=d.paid_amount,
            payment_method=d.payment_method,
            created_by=d.created_by,
        )
        for d in docs
    ]

async def get_document(
    session: AsyncSession,
    document_id: int
) -> InventoryDocumentDetailRead:
    stmt = select(InventoryDocument).where(InventoryDocument.id == document_id).options(
        selectinload(InventoryDocument.items).selectinload(InventoryDocumentItem.ingredient),
        selectinload(InventoryDocument.items).selectinload(InventoryDocumentItem.retail_product),
        selectinload(InventoryDocument.supplier),
    )
    result = await session.execute(stmt)
    doc = result.scalar_one_or_none()
    
    if not doc:
        raise HTTPException(status_code=404, detail="Document not found")
        
    return InventoryDocumentDetailRead(
        id=doc.id,
        type=doc.type,
        status=doc.status,
        date=doc.date,
        supplier_id=doc.supplier_id,
        supplier_name=doc.supplier.name if doc.supplier else None,
        invoice_number=doc.invoice_number,
        reason=doc.reason,
        total_amount=doc.total_amount,
        payment_status=doc.payment_status,
        paid_amount=doc.paid_amount,
        payment_method=doc.payment_method,
        created_by=doc.created_by,
        items=[
            InventoryDocumentItemRead(
                id=item.id,
                document_id=item.document_id,
                ingredient_id=item.ingredient_id,
                ingredient_name=item.ingredient.name if item.ingredient else None,
                retail_product_id=item.retail_product_id,
                retail_product_name=item.retail_product.name if item.retail_product else None,
                quantity=item.quantity,
                price_per_unit=item.price_per_unit,
                total_price=item.total_price,
            )
            for item in doc.items
        ]
    )


async def complete_document(
    session: AsyncSession,
    document_id: int,
    user_id: Optional[int] = None
) -> InventoryDocument:
    stmt = select(InventoryDocument).where(InventoryDocument.id == document_id).options(
        selectinload(InventoryDocument.items)
    )
    result = await session.execute(stmt)
    doc = result.scalar_one_or_none()
    
    if not doc:
        raise HTTPException(status_code=404, detail="Document not found")
        
    if doc.status == DocumentStatus.COMPLETED:
        raise HTTPException(status_code=400, detail="Document is already completed")
        
    doc.status = DocumentStatus.COMPLETED
    
    for item in doc.items:
        if doc.type == DocumentType.RECEIPT:
            if item.ingredient_id:
                ing = await session.get(Ingredient, item.ingredient_id)
                if not ing: continue
                
                # Moving Average
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
                if not ret: continue

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
                
        elif doc.type == DocumentType.WRITE_OFF:
            if item.ingredient_id:
                ing = await session.get(Ingredient, item.ingredient_id)
                if not ing: continue

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
                if not ret: continue

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
                
        elif doc.type == DocumentType.INVENTORY:
            # Here item.quantity is the ACTUAL counted quantity
            actual_quantity = item.quantity
            
            if item.ingredient_id:
                ing = await session.get(Ingredient, item.ingredient_id)
                if not ing: continue
                
                diff = actual_quantity - ing.current_stock
                if diff != 0:
                    txn_type = StockTransactionType.INVENTORY_SURPLUS if diff > 0 else StockTransactionType.INVENTORY_SHORTAGE
                    
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
                if not ret: continue
                
                diff = actual_quantity - ret.current_stock
                if diff != 0:
                    txn_type = StockTransactionType.INVENTORY_SURPLUS if diff > 0 else StockTransactionType.INVENTORY_SHORTAGE
                    
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

    # Update supplier balance & record transaction if receipt document with unpaid debt
    if doc.type == DocumentType.RECEIPT and doc.supplier_id:
        supplier = await session.get(Supplier, doc.supplier_id)
        if supplier:
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

    await session.flush()
    return doc
