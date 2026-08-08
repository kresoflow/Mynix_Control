from typing import Optional, List
from sqlmodel import Field, Relationship, SQLModel
from sqlalchemy import Column
from sqlalchemy.dialects.postgresql import JSONB
from app.base_model import TenantModel
from app.inventory.models.enums import UnitType
from app.inventory.models.category_models import MenuCategory

class RetailProduct(TenantModel, table=True):
    __tablename__ = "retail_products"

    id: Optional[int] = Field(default=None, primary_key=True)
    name: str = Field(max_length=100, index=True)
    category_id: int = Field(foreign_key="menu_categories.id", index=True)
    price: float = Field(ge=0)
    cost: float = Field(default=0.0)
    unit: UnitType = Field(default=UnitType.PCS)
    current_stock: float = Field(default=0.0)
    min_stock_alert: float = Field(default=0.0)
    barcode: Optional[str] = Field(default=None, max_length=50, index=True)
    is_available: bool = Field(default=True)
    sort_order: int = Field(default=0)
    attributes: Optional[dict] = Field(default_factory=dict, sa_column=Column(JSONB))

    # Relationships
    category: Optional[MenuCategory] = Relationship()
    transactions: List["StockTransaction"] = Relationship(
        back_populates="retail_product",
        sa_relationship_kwargs={"cascade": "all, delete-orphan"}
    )

class RetailProductRead(SQLModel):
    id: int
    name: str
    category_id: int
    category_name: Optional[str] = None
    price: float
    cost: float
    unit: UnitType
    current_stock: float
    min_stock_alert: float
    barcode: Optional[str] = None
    is_available: bool
    sort_order: int = 0
    attributes: Optional[dict] = None
    is_low_stock: bool = False

class RetailProductCreate(SQLModel):
    name: str
    category_id: int
    price: float
    cost: float = 0.0
    unit: UnitType = UnitType.PCS
    min_stock_alert: float = 0.0
    barcode: Optional[str] = None
    is_available: bool = True
    sort_order: int = 0
    attributes: Optional[dict] = None
    initial_stock: float = 0.0
