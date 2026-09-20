import pytest
from httpx import AsyncClient
from sqlmodel import select
from app.inventory.models import MenuItem, RetailProduct, MenuCategory
from app.inventory.services.retail_service import bulk_create_retail_products
from app.pos.models import Shift
from datetime import datetime, timezone

@pytest.mark.asyncio
async def test_retail_multi_variations_creation_and_stock(async_client: AsyncClient, db_session):
    # 1. Create a category
    cat = MenuCategory(name="Шоколад", category_type="retail", is_visible=True)
    db_session.add(cat)
    await db_session.commit()
    await db_session.refresh(cat)

    # 2. Bulk create a retail item with 3 variations (Snickers: 50g, 200g, 300g)
    items_payload = [{
        "name": "Сникерс",
        "category_id": cat.id,
        "selling_price": 10.0,
        "purchase_price": 6.0,
        "unit": "pcs",
        "attributes": {
            "flavor": "Классик",
            "variations": [
                {
                    "name": "Сникерс Классик 50 г",
                    "price": 10.0,
                    "purchase_price": 6.0,
                    "unit": "pcs",
                    "barcode": "SNK50",
                    "initial_stock": 20.0,
                },
                {
                    "name": "Сникерс Классик 200 г",
                    "price": 20.0,
                    "purchase_price": 12.0,
                    "unit": "pcs",
                    "barcode": "SNK200",
                    "initial_stock": 10.0,
                },
                {
                    "name": "Сникерс Классик 300 г",
                    "price": 40.0,
                    "purchase_price": 24.0,
                    "unit": "pcs",
                    "barcode": "SNK300",
                    "initial_stock": 5.0,
                },
            ]
        }
    }]

    created_retails = await bulk_create_retail_products(db_session, items_payload, user_id=1)
    await db_session.commit()

    # 3. Verify created parent and child items
    parent_menu_res = await db_session.execute(select(MenuItem).where(MenuItem.name == "Сникерс", MenuItem.parent_id == None))
    parent_menu = parent_menu_res.scalars().first()
    assert parent_menu is not None
    assert parent_menu.type == "retail"

    # Child MenuItems
    children_res = await db_session.execute(select(MenuItem).where(MenuItem.parent_id == parent_menu.id))
    children = children_res.scalars().all()
    assert len(children) == 3

    for child in children:
        assert child.type == "retail"
        assert child.retail_product_id is not None
        child_ret = await db_session.get(RetailProduct, child.retail_product_id)
        assert child_ret is not None
        assert child_ret.unit == "pcs"
        if "50 г" in child.name:
            assert child.price == 10.0
            assert child.barcode == "SNK50"
            assert child_ret.current_stock == 20.0
        elif "200 г" in child.name:
            assert child.price == 20.0
            assert child.barcode == "SNK200"
            assert child_ret.current_stock == 10.0
        elif "300 г" in child.name:
            assert child.price == 40.0
            assert child.barcode == "SNK300"
            assert child_ret.current_stock == 5.0

    print("Retail variations test passed successfully!")
