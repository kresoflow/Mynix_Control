from typing import Optional, List
from sqlmodel import Field, Relationship, SQLModel
from app.base_model import TenantModel

class MenuCategory(TenantModel, table=True):
    __tablename__ = "menu_categories"

    id: Optional[int] = Field(default=None, primary_key=True)
    name: str = Field(max_length=100, index=True)
    category_type: str = Field(default="dish", max_length=20)
    sort_order: int = Field(default=0)
    color: Optional[str] = Field(default=None, max_length=50)
    icon: Optional[str] = Field(default=None)
    level: int = Field(default=1)
    path: Optional[str] = Field(default=None, max_length=255)
    is_visible: bool = Field(default=True)
    parent_id: Optional[int] = Field(default=None, foreign_key="menu_categories.id")

    # Relationships
    items: List["MenuItem"] = Relationship(back_populates="category")
    
    # Self-referential relationship for hierarchical categories
    parent: Optional["MenuCategory"] = Relationship(
        back_populates="children",
        sa_relationship_kwargs={"remote_side": "MenuCategory.id"}
    )
    children: List["MenuCategory"] = Relationship(back_populates="parent")

class MenuCategoryRead(SQLModel):
    id: int
    name: str
    category_type: str
    sort_order: int
    color: Optional[str]
    icon: Optional[str]
    level: int = 1
    path: Optional[str] = None
    is_visible: bool = True
    parent_id: Optional[int] = None

class MenuCategoryCreate(SQLModel):
    name: str
    category_type: str = "dish"
    sort_order: int = 0
    color: Optional[str] = None
    icon: Optional[str] = None
    level: int = 1
    path: Optional[str] = None
    is_visible: bool = True
    parent_id: Optional[int] = None
