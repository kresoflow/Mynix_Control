from typing import Optional, List, TYPE_CHECKING
from sqlmodel import Field, Relationship, SQLModel
from app.inventory.models.enums import UnitType
from app.inventory.models.ingredient_models import Ingredient

if TYPE_CHECKING:
    from app.inventory.models.menu_models import MenuItem

class Recipe(SQLModel, table=True):
    __tablename__ = "recipes"

    id: Optional[int] = Field(default=None, primary_key=True)
    menu_item_id: int = Field(foreign_key="menu_items.id", index=True)
    ingredient_id: int = Field(foreign_key="ingredients.id", index=True)
    quantity_required: float = Field(gt=0)  # amount per 1 serving

    # Relationships
    menu_item: Optional["MenuItem"] = Relationship(back_populates="recipes")
    ingredient: Optional["Ingredient"] = Relationship(back_populates="recipes")

class RecipeRead(SQLModel):
    ingredient_id: int
    ingredient_name: str
    quantity_required: float
    unit: UnitType
    cost_per_unit: float = 0.0

class RecipeCreate(SQLModel):
    ingredient_id: int
    quantity_required: float

class RecipeCreateItem(SQLModel):
    ingredient_id: int
    quantity_required: float

class BulkRecipeCreate(SQLModel):
    recipes: List[RecipeCreateItem]
