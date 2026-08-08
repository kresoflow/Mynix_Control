from typing import Optional, List
from sqlmodel import Field, Relationship, SQLModel
from sqlalchemy import Column
from sqlalchemy.dialects.postgresql import JSONB
from app.base_model import TenantModel
from app.inventory.models.enums import UnitType
from app.inventory.models.category_models import MenuCategory

class Ingredient(TenantModel, table=True):
    __tablename__ = "ingredients"

    id: Optional[int] = Field(default=None, primary_key=True)
    name: str = Field(max_length=100, index=True)
    unit: UnitType = Field(default=UnitType.G)
    current_stock: float = Field(default=0.0)
    min_stock_alert: float = Field(default=0.0)
    cost_per_unit: float = Field(default=0.0)
    category_id: Optional[int] = Field(default=None, foreign_key="menu_categories.id", index=True)
    sort_order: int = Field(default=0)
    attributes: Optional[dict] = Field(default_factory=dict, sa_column=Column(JSONB))
    barcode: Optional[str] = Field(default=None, max_length=50, index=True)

    # Relationships
    category: Optional[MenuCategory] = Relationship()
    recipes: List["Recipe"] = Relationship(
        back_populates="ingredient",
        sa_relationship_kwargs={"cascade": "all, delete-orphan"}
    )
    transactions: List["StockTransaction"] = Relationship(
        back_populates="ingredient",
        sa_relationship_kwargs={"cascade": "all, delete-orphan"}
    )

class IngredientRead(SQLModel):
    id: int
    name: str
    unit: UnitType
    current_stock: float
    min_stock_alert: float
    cost_per_unit: float
    category_id: Optional[int] = None
    category_name: Optional[str] = None
    sort_order: int = 0
    attributes: Optional[dict] = None
    is_low_stock: bool = False
    barcode: Optional[str] = None

class IngredientCreate(SQLModel):
    name: str
    unit: UnitType = UnitType.G
    category_id: Optional[int] = None
    min_stock_alert: float = 0.0
    cost_per_unit: float = 0.0
    sort_order: int = 0
    attributes: Optional[dict] = None
    initial_stock: float = 0.0
    barcode: Optional[str] = None
