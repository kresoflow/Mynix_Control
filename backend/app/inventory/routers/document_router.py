from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.dependencies import TenantSession, CurrentUser, require_permission
from app.inventory.models import (
    InventoryDocumentRead, InventoryDocumentDetailRead, InventoryDocumentCreate,
    SupplierRead, SupplierCreate, SupplierUpdate, Supplier, DocumentType
)
from app.inventory.services import document_service
from sqlmodel import select

router = APIRouter(prefix="/documents", tags=["Inventory Documents"])
supplier_router = APIRouter(prefix="/suppliers", tags=["Suppliers"])

# --- Suppliers ---

@supplier_router.get("/", response_model=List[SupplierRead], dependencies=[Depends(require_permission("inventory:view"))])
async def get_suppliers(
    session: TenantSession,
    user: CurrentUser,
):
    return await document_service.get_suppliers(session)

@supplier_router.post("/", response_model=SupplierRead, dependencies=[Depends(require_permission("inventory:manage"))])
async def create_supplier(
    supplier_in: SupplierCreate,
    session: TenantSession,
    user: CurrentUser,
):
    supplier = Supplier(**supplier_in.model_dump())
    session.add(supplier)
    await session.flush()
    return supplier

@supplier_router.put("/{supplier_id}", response_model=SupplierRead, dependencies=[Depends(require_permission("inventory:manage"))])
async def update_supplier(
    supplier_id: int,
    supplier_in: SupplierUpdate,
    session: TenantSession,
    user: CurrentUser,
):
    supplier = await session.get(Supplier, supplier_id)
    if not supplier:
        raise HTTPException(status_code=404, detail="Supplier not found")
    
    update_data = supplier_in.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(supplier, key, value)
    
    session.add(supplier)
    await session.flush()
    return supplier

@supplier_router.delete("/{supplier_id}", status_code=status.HTTP_204_NO_CONTENT, dependencies=[Depends(require_permission("inventory:manage"))])
async def delete_supplier(
    supplier_id: int,
    session: TenantSession,
    user: CurrentUser,
):
    supplier = await session.get(Supplier, supplier_id)
    if not supplier:
        raise HTTPException(status_code=404, detail="Supplier not found")
    
    # Let SQLAlchemy throw an IntegrityError if it's referenced by documents,
    # or handle it nicely:
    from sqlalchemy.exc import IntegrityError
    try:
        await session.delete(supplier)
        await session.flush()
    except IntegrityError:
        await session.rollback()
        raise HTTPException(status_code=400, detail="Cannot delete supplier because there are documents attached to it. You can deactivate it instead.")

# --- Documents ---

@router.get("/", response_model=List[InventoryDocumentRead], dependencies=[Depends(require_permission("inventory:view"))])
async def get_documents(
    session: TenantSession,
    user: CurrentUser,
    type: Optional[DocumentType] = None,
):
    return await document_service.get_documents(session, doc_type=type)

@router.post("/", response_model=InventoryDocumentRead, dependencies=[Depends(require_permission("inventory:manage"))])
async def create_document(
    doc_in: InventoryDocumentCreate,
    session: TenantSession,
    user: CurrentUser,
):
    return await document_service.create_document(session, doc_in, user_id=user.id)

@router.get("/{document_id}", response_model=InventoryDocumentDetailRead, dependencies=[Depends(require_permission("inventory:view"))])
async def get_document(
    document_id: int,
    session: TenantSession,
    user: CurrentUser,
):
    return await document_service.get_document(session, document_id)

@router.post("/{document_id}/complete", response_model=InventoryDocumentRead, dependencies=[Depends(require_permission("inventory:manage"))])
async def complete_document(
    document_id: int,
    session: TenantSession,
    user: CurrentUser,
):
    return await document_service.complete_document(session, document_id, user_id=user.id)
