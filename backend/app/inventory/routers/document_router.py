from typing import List, Optional
from fastapi import APIRouter, Depends
from app.dependencies import TenantSession, CurrentUser, require_permission
from app.inventory.models import (
    InventoryDocumentRead, InventoryDocumentDetailRead, InventoryDocumentCreate, DocumentType
)
from app.inventory.services import document_service

router = APIRouter(prefix="/documents", tags=["Inventory Documents"])

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
