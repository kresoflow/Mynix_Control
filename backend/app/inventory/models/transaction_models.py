from typing import Optional
from sqlmodel import Field, Relationship, SQLModel
from app.base_model import TenantModel
from app.inventory.models.enums import StockTransactionType
from app.inventory.models.ingredient_models import Ingredient
from app.inventory.models.retail_models import RetailProduct

class StockTransaction(TenantModel, table=True):
    __tablename__ = "stock_transactions"

    id: Optional[int] = Field(default=None, primary_key=True)
    ingredient_id: Optional[int] = Field(default=None, foreign_key="ingredients.id", index=True, nullable=True)
    retail_product_id: Optional[int] = Field(default=None, foreign_key="retail_products.id", index=True, nullable=True)
    type: StockTransactionType
    quantity: float  # positive for receipt, negative for deduction/write-off
    reason: str = Field(default="", max_length=255)
    created_by: Optional[int] = Field(default=None, foreign_key="public.users.id")

    # Relationships
    ingredient: Optional[Ingredient] = Relationship(back_populates="transactions")
    retail_product: Optional[RetailProduct] = Relationship(back_populates="transactions")

class ReceiveStockRequest(SQLModel):
    ingredient_id: int
    quantity: float
    reason: str = "Приёмка товара"

class RetailReceiveStockRequest(SQLModel):
    retail_product_id: int
    quantity: float
    reason: str = "Приёмка товара"
