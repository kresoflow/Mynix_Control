from typing import Optional, List
from datetime import datetime, timezone
from sqlmodel import Field, Relationship, SQLModel
from sqlalchemy import Column
from sqlalchemy import Enum as SAEnum
from app.base_model import TenantModel
from app.inventory.models.enums import DocumentType, DocumentStatus
from app.inventory.models.ingredient_models import Ingredient
from app.inventory.models.retail_models import RetailProduct

class Supplier(TenantModel, table=True):
    __tablename__ = "suppliers"

    id: Optional[int] = Field(default=None, primary_key=True)
    name: str = Field(max_length=150, index=True)
    contact_info: Optional[str] = Field(default=None, max_length=255)
    is_active: bool = Field(default=True)
    
    # Relationships
    documents: List["InventoryDocument"] = Relationship(back_populates="supplier")

class InventoryDocument(TenantModel, table=True):
    __tablename__ = "inventory_documents"

    id: Optional[int] = Field(default=None, primary_key=True)
    type: DocumentType = Field(sa_column=Column(SAEnum(DocumentType, native_enum=False), nullable=False))
    status: DocumentStatus = Field(default=DocumentStatus.DRAFT, sa_column=Column(SAEnum(DocumentStatus, native_enum=False), nullable=False, server_default="draft"))
    date: datetime = Field(default_factory=lambda: datetime.now(timezone.utc).replace(tzinfo=None))
    supplier_id: Optional[int] = Field(default=None, foreign_key="suppliers.id", index=True)
    invoice_number: Optional[str] = Field(default=None, max_length=100)
    reason: Optional[str] = Field(default=None, max_length=255)
    total_amount: float = Field(default=0.0)
    created_by: Optional[int] = Field(default=None, foreign_key="public.users.id")
    
    # Relationships
    supplier: Optional[Supplier] = Relationship(back_populates="documents")
    items: List["InventoryDocumentItem"] = Relationship(
        back_populates="document",
        sa_relationship_kwargs={"cascade": "all, delete-orphan"}
    )

class InventoryDocumentItem(TenantModel, table=True):
    __tablename__ = "inventory_document_items"

    id: Optional[int] = Field(default=None, primary_key=True)
    document_id: int = Field(foreign_key="inventory_documents.id", index=True)
    ingredient_id: Optional[int] = Field(default=None, foreign_key="ingredients.id", index=True)
    retail_product_id: Optional[int] = Field(default=None, foreign_key="retail_products.id", index=True)
    quantity: float
    price_per_unit: float
    total_price: float
    
    # Relationships
    document: InventoryDocument = Relationship(back_populates="items")
    ingredient: Optional[Ingredient] = Relationship()
    retail_product: Optional[RetailProduct] = Relationship()


class SupplierRead(SQLModel):
    id: int
    name: str
    contact_info: Optional[str] = None
    is_active: bool

class SupplierCreate(SQLModel):
    name: str
    contact_info: Optional[str] = None
    is_active: bool = True

class SupplierUpdate(SQLModel):
    name: Optional[str] = None
    contact_info: Optional[str] = None
    is_active: Optional[bool] = None

class InventoryDocumentItemRead(SQLModel):
    id: int
    document_id: int
    ingredient_id: Optional[int] = None
    ingredient_name: Optional[str] = None
    retail_product_id: Optional[int] = None
    retail_product_name: Optional[str] = None
    quantity: float
    price_per_unit: float
    total_price: float

class InventoryDocumentItemCreate(SQLModel):
    ingredient_id: Optional[int] = None
    retail_product_id: Optional[int] = None
    quantity: float
    price_per_unit: float
    total_price: float
    sell_price: Optional[float] = None
    min_stock_alert: Optional[float] = None

class InventoryDocumentRead(SQLModel):
    id: int
    type: DocumentType
    status: DocumentStatus
    date: datetime
    supplier_id: Optional[int] = None
    supplier_name: Optional[str] = None
    invoice_number: Optional[str] = None
    reason: Optional[str] = None
    total_amount: float
    created_by: Optional[int] = None

class InventoryDocumentCreate(SQLModel):
    type: DocumentType
    date: Optional[datetime] = None
    supplier_id: Optional[int] = None
    invoice_number: Optional[str] = None
    reason: Optional[str] = None
    items: List[InventoryDocumentItemCreate] = []

class InventoryDocumentDetailRead(InventoryDocumentRead):
    items: List[InventoryDocumentItemRead] = []
