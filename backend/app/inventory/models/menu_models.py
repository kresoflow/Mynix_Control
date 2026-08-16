from typing import Optional, List
from sqlmodel import Field, Relationship, SQLModel
from sqlalchemy import Column
from sqlalchemy.dialects.postgresql import JSONB
from app.base_model import TenantModel
from app.inventory.models.category_models import MenuCategory
from app.inventory.models.retail_models import RetailProduct
from app.inventory.models.recipe_models import RecipeRead

class MenuItem(TenantModel, table=True):
    __tablename__ = "menu_items"

    id: Optional[int] = Field(default=None, primary_key=True)
    name: str = Field(max_length=100, index=True)
    short_name: Optional[str] = Field(default=None, max_length=50)
    tags: Optional[list] = Field(default_factory=list, sa_column=Column(JSONB))
    category_id: Optional[int] = Field(default=None, foreign_key="menu_categories.id", index=True)
    retail_product_id: Optional[int] = Field(default=None, foreign_key="retail_products.id", index=True, nullable=True)
    price: float = Field(ge=0)         # selling price in RUB
    is_available: bool = Field(default=True)
    image_url: Optional[str] = Field(default=None, max_length=500)
    description: Optional[str] = Field(default=None, max_length=500)
    type: str = Field(default="dish")  # "dish" or "retail"
    barcode: Optional[str] = Field(default=None, max_length=50, index=True)
    sort_order: int = Field(default=0)
    attributes: Optional[dict] = Field(default_factory=dict, sa_column=Column(JSONB))
    parent_id: Optional[int] = Field(default=None, foreign_key="menu_items.id", index=True, nullable=True)

    # Relationships
    category: Optional[MenuCategory] = Relationship(back_populates="items")
    retail_product: Optional[RetailProduct] = Relationship()
    recipes: List["Recipe"] = Relationship(back_populates="menu_item")
    parent: Optional["MenuItem"] = Relationship(back_populates="children", sa_relationship_kwargs=dict(remote_side="MenuItem.id"))
    children: List["MenuItem"] = Relationship(back_populates="parent")

    @property
    def clean_name(self) -> str:
        return self.name.split("|TYPE|")[0].split("|ATTR|")[0].split("|ICON|")[0]

class MenuItemRead(SQLModel):
    id: int
    name: str
    short_name: Optional[str] = None
    tags: Optional[list] = None
    category_id: Optional[int]
    category_name: Optional[str] = None
    retail_product_id: Optional[int] = None
    price: float
    is_available: bool
    description: Optional[str] = None
    type: str = "dish"
    sort_order: int = 0
    attributes: Optional[dict] = None
    food_cost: Optional[float] = None  # calculated from recipes
    parent_id: Optional[int] = None

class MenuItemCreate(SQLModel):
    name: str
    short_name: Optional[str] = None
    tags: Optional[list] = None
    category_id: int
    retail_product_id: Optional[int] = None
    price: float
    description: Optional[str] = None
    image_url: Optional[str] = None
    sort_order: int = 0
    barcode: Optional[str] = None
    attributes: Optional[dict] = None
    is_available: bool = True
    parent_id: Optional[int] = None
    type: str = "dish"

class MenuItemDetailRead(MenuItemRead):
    recipes: List[RecipeRead] = []
