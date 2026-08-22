from typing import Optional, List
from datetime import datetime, timezone
from sqlmodel import Field, Relationship, SQLModel
from sqlalchemy import Column
from sqlalchemy import Enum as SAEnum
from app.base_model import TenantModel
from app.inventory.models.enums import DocumentType, DocumentStatus, SupplierTransactionType
from app.inventory.models.ingredient_models import Ingredient
from app.inventory.models.retail_models import RetailProduct

class Supplier(TenantModel, table=True):
    __tablename__ = "suppliers"

    id: Optional[int] = Field(default=None, primary_key=True)
    name: str = Field(max_length=150, index=True)
    contact_info: Optional[str] = Field(default=None, max_length=255)
    is_active: bool = Field(default=True)
    balance: float = Field(default=0.0)  # Negative means debt (we owe supplier), positive is advance
    
    # Relationships
    documents: List["InventoryDocument"] = Relationship(back_populates="supplier")
    transactions: List["SupplierTransaction"] = Relationship(
        back_populates="supplier",
        sa_relationship_kwargs={"cascade": "all, delete-orphan", "lazy": "selectin"}
    )

class SupplierTransaction(TenantModel, table=True):
    __tablename__ = "supplier_transactions"

    id: Optional[int] = Field(default=None, primary_key=True)
    supplier_id: int = Field(foreign_key="suppliers.id", index=True)
    document_id: Optional[int] = Field(default=None, foreign_key="inventory_documents.id", index=True)
    type: SupplierTransactionType = Field(
        sa_column=Column(
            SAEnum(SupplierTransactionType, values_callable=lambda obj: [e.value for e in obj], native_enum=False),
            nullable=False
        )
    )
    amount: float = Field(default=0.0)  # Positive value (interpretation depends on type)
    payment_method: Optional[str] = Field(default="cash", max_length=30)  # "cash", "card", "bank_transfer", "other"
    comment: Optional[str] = Field(default=None, max_length=255)
    date: datetime = Field(default_factory=lambda: datetime.now(timezone.utc).replace(tzinfo=None))
    created_by: Optional[int] = Field(default=None, foreign_key="public.users.id")

    # Relationships
    supplier: Optional[Supplier] = Relationship(back_populates="transactions")
    document: Optional["InventoryDocument"] = Relationship(sa_relationship_kwargs={"lazy": "selectin"})

class InventoryDocument(TenantModel, table=True):
    __tablename__ = "inventory_documents"

    id: Optional[int] = Field(default=None, primary_key=True)
    type: DocumentType = Field(
        sa_column=Column(
            SAEnum(DocumentType, values_callable=lambda obj: [e.value for e in obj], native_enum=False),
            nullable=False
        )
    )
    status: DocumentStatus = Field(
        default=DocumentStatus.DRAFT,
        sa_column=Column(
            SAEnum(DocumentStatus, values_callable=lambda obj: [e.value for e in obj], native_enum=False),
            nullable=False,
            server_default="draft"
        )
    )
    date: datetime = Field(default_factory=lambda: datetime.now(timezone.utc).replace(tzinfo=None))
    supplier_id: Optional[int] = Field(default=None, foreign_key="suppliers.id", index=True)
    invoice_number: Optional[str] = Field(default=None, max_length=100)
    reason: Optional[str] = Field(default=None, max_length=255)
    total_amount: float = Field(default=0.0)
    payment_status: Optional[str] = Field(default="unpaid", max_length=20)  # "unpaid", "paid", "partial"
    paid_amount: float = Field(default=0.0)
    payment_method: Optional[str] = Field(default="cash", max_length=30)  # "cash", "card", "bank_transfer", "debt"
    created_by: Optional[int] = Field(default=None, foreign_key="public.users.id")
    
    # Relationships
    supplier: Optional[Supplier] = Relationship(
        back_populates="documents",
        sa_relationship_kwargs={"lazy": "selectin"}
    )
    items: List["InventoryDocumentItem"] = Relationship(
        back_populates="document",
        sa_relationship_kwargs={"cascade": "all, delete-orphan", "lazy": "selectin"}
    )

class InventoryDocumentItem(TenantModel, table=True):
    __tablename__ = "inventory_document_items"

    id: Optional[int] = Field(default=None, primary_key=True)
    document_id: int = Field(foreign_key="inventory_documents.id", index=True)
    ingredient_id: Optional[int] = Field(default=None, foreign_key="ingredients.id", index=True)
    retail_product_id: Optional[int] = Field(default=None, foreign_key="retail_products.id", index=True)
    quantity: float
    expected_quantity: Optional[float] = Field(default=None)
    price_per_unit: float
    total_price: float
    
    # Relationships
    document: InventoryDocument = Relationship(back_populates="items")
    ingredient: Optional[Ingredient] = Relationship(sa_relationship_kwargs={"lazy": "selectin"})
    retail_product: Optional[RetailProduct] = Relationship(sa_relationship_kwargs={"lazy": "selectin"})


class SupplierRead(SQLModel):
    id: int
    name: str
    contact_info: Optional[str] = None
    is_active: bool
    balance: float = 0.0

class SupplierCreate(SQLModel):
    name: str
    contact_info: Optional[str] = None
    is_active: bool = True
    initial_balance: Optional[float] = 0.0

class SupplierUpdate(SQLModel):
    name: Optional[str] = None
    contact_info: Optional[str] = None
    is_active: Optional[bool] = None
    balance: Optional[float] = None

class SupplierTransactionRead(SQLModel):
    id: int
    supplier_id: int
    document_id: Optional[int] = None
    type: SupplierTransactionType
    amount: float
    payment_method: Optional[str] = "cash"
    comment: Optional[str] = None
    date: datetime
    created_by: Optional[int] = None
    document_invoice_number: Optional[str] = None

class SupplierTransactionCreate(SQLModel):
    type: SupplierTransactionType = SupplierTransactionType.PAYMENT
    amount: float
    payment_method: str = "cash"
    comment: Optional[str] = None
    date: Optional[datetime] = None

class SupplierTransactionUpdate(SQLModel):
    amount: Optional[float] = None
    payment_method: Optional[str] = None
    comment: Optional[str] = None
    date: Optional[datetime] = None

class SupplierPaymentCreate(SQLModel):
    amount: float
    payment_method: str = "cash"
    comment: Optional[str] = None

class InventoryDocumentItemRead(SQLModel):
    id: int
    document_id: int
    ingredient_id: Optional[int] = None
    ingredient_name: Optional[str] = None
    retail_product_id: Optional[int] = None
    retail_product_name: Optional[str] = None
    quantity: float
    expected_quantity: Optional[float] = None
    price_per_unit: float
    total_price: float

class InventoryDocumentItemCreate(SQLModel):
    ingredient_id: Optional[int] = None
    retail_product_id: Optional[int] = None
    quantity: float
    expected_quantity: Optional[float] = None
    price_per_unit: Optional[float] = 0.0
    total_price: Optional[float] = None
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
    payment_status: Optional[str] = None
    paid_amount: Optional[float] = None
    payment_method: Optional[str] = None
    created_by: Optional[int] = None

class InventoryDocumentCreate(SQLModel):
    type: DocumentType
    date: Optional[datetime] = None
    supplier_id: Optional[int] = None
    invoice_number: Optional[str] = None
    reason: Optional[str] = None
    payment_status: Optional[str] = "unpaid"
    paid_amount: Optional[float] = 0.0
    payment_method: Optional[str] = "cash"
    items: List[InventoryDocumentItemCreate] = []

class InventoryDocumentDetailRead(InventoryDocumentRead):
    items: List[InventoryDocumentItemRead] = []
