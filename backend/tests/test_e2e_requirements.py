"""
Mynix Control — End-to-End Requirements Test Suite
Authoritative source: ORIGINAL_REQUEST.md & PROJECT.md

Tiers covered:
- Tier 1: Feature Coverage (>=5 tests per feature: Bulk Add dishes, retail, ingredients, categories; Goods Receipt document processing)
- Tier 2: Boundary & Corner Cases (empty batch, large batch of 50+ items, special characters, zero prices, duplicate barcodes, invalid item IDs)
- Tier 3: Combinatorial & Cross-Feature (Catalog zero-stock guarantee, Bulk add -> Goods receipt -> Stock balance, Moving average cost, Supplier debt vs stock)
- Tier 4: Real-world Workflows (restaurant opening inventory setup, new supplier delivery invoice processing)
"""

import pytest
from httpx import AsyncClient
from sqlmodel import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.users.models import Tenant, Role, User, UserRole
from app.users import services as user_svc
from app.inventory.models import (
    MenuCategory, MenuItem, RetailProduct, Ingredient,
    Supplier, InventoryDocument, InventoryDocumentItem,
    StockTransaction, DocumentType, DocumentStatus, StockTransactionType,
    UnitType
)


async def setup_auth_headers(db_session: AsyncSession) -> tuple[dict, Tenant, User]:
    """Helper to provision isolated tenant, superuser role, user and return auth bearer headers."""
    tenant = Tenant(name="E2E Test Cafe", schema_name="public", is_active=True)
    db_session.add(tenant)
    await db_session.commit()
    await db_session.refresh(tenant)

    role = Role(name="Admin", is_superuser=True, tenant_id=tenant.id)
    db_session.add(role)
    await db_session.commit()
    await db_session.refresh(role)

    user = User(
        tenant_id=tenant.id,
        username="admin_e2e",
        full_name="Admin E2E Tester",
        hashed_password="hash",
        is_active=True,
    )
    db_session.add(user)
    await db_session.commit()
    await db_session.refresh(user)

    user_role = UserRole(user_id=user.id, role_id=role.id)
    db_session.add(user_role)
    await db_session.commit()

    token = user_svc.create_access_token(
        user_id=user.id,
        tenant_id=tenant.id,
        permissions=[
            "menu:view", "menu:create", "menu:manage",
            "inventory:view", "inventory:create", "inventory:manage"
        ],
        is_superuser=True,
    )
    headers = {"Authorization": f"Bearer {token}"}
    return headers, tenant, user


# ==============================================================================
# TIER 1: FEATURE COVERAGE (>=5 tests per feature)
# ==============================================================================

class TestTier1FeatureCoverage:
    """
    Tier 1 tests individual feature primary behaviors (happy path, metadata, attributes).
    Features:
      1. Bulk Add Dishes (POST /api/v1/menu/bulk)
      2. Bulk Add Retail Products (POST /api/v1/retail-product/bulk)
      3. Bulk Add Ingredients (POST /api/v1/ingredients/bulk)
      4. Bulk Add Categories (POST /api/v1/categories/bulk)
      5. Goods Receipt Document Processing (POST /api/v1/documents/, POST .../complete)
    """

    # --- Feature 1: Bulk Add Dishes (5 tests) ---

    @pytest.mark.asyncio
    async def test_bulk_dishes_happy_path(self, async_client: AsyncClient, db_session: AsyncSession):
        headers, _, _ = await setup_auth_headers(db_session)
        payload = [
            {"name": "Эспрессо", "price": 120.0, "type": "dish"},
            {"name": "Американо", "price": 150.0, "type": "dish"},
            {"name": "Капучино", "price": 180.0, "type": "dish"},
        ]
        resp = await async_client.post("/api/v1/menu/bulk", json=payload, headers=headers)
        assert resp.status_code in (200, 201), resp.text
        data = resp.json()
        assert len(data) == 3
        names = [item["name"] for item in data]
        assert "Эспрессо" in names and "Американо" in names and "Капучино" in names

        # Verify listing
        list_resp = await async_client.get("/api/v1/menu/", headers=headers)
        assert list_resp.status_code == 200
        menu_items = list_resp.json()
        assert any(m["name"] == "Эспрессо" for m in menu_items)

    @pytest.mark.asyncio
    async def test_bulk_dishes_with_variations(self, async_client: AsyncClient, db_session: AsyncSession):
        headers, _, _ = await setup_auth_headers(db_session)
        payload = [
            {
                "name": "Латте",
                "price": 200.0,
                "type": "dish",
                "attributes": {
                    "variations": [
                        {"name": "0.3л", "price": 200.0},
                        {"name": "0.5л", "price": 260.0},
                    ]
                },
            }
        ]
        resp = await async_client.post("/api/v1/menu/bulk", json=payload, headers=headers)
        assert resp.status_code in (200, 201), resp.text
        data = resp.json()
        assert len(data) == 1
        parent_id = data[0]["id"]

        # Variations should produce child menu items with parent_id
        stmt = select(MenuItem).where(MenuItem.parent_id == parent_id)
        res = await db_session.execute(stmt)
        children = res.scalars().all()
        assert len(children) == 2
        child_prices = {c.price for c in children}
        assert 200.0 in child_prices and 260.0 in child_prices

    @pytest.mark.asyncio
    async def test_bulk_dishes_attributes_and_tags(self, async_client: AsyncClient, db_session: AsyncSession):
        headers, _, _ = await setup_auth_headers(db_session)
        payload = [
            {
                "name": "Том Ям с морепродуктами",
                "price": 450.0,
                "type": "dish",
                "tags": ["soup", "spicy", "asian"],
                "attributes": {"spiciness_level": 3, "calories": 380},
            }
        ]
        resp = await async_client.post("/api/v1/menu/bulk", json=payload, headers=headers)
        assert resp.status_code in (200, 201), resp.text
        item = resp.json()[0]
        assert item["tags"] == ["soup", "spicy", "asian"]
        assert item["attributes"]["spiciness_level"] == 3

    @pytest.mark.asyncio
    async def test_bulk_dishes_category_association(self, async_client: AsyncClient, db_session: AsyncSession):
        headers, _, _ = await setup_auth_headers(db_session)
        # Create category
        cat_resp = await async_client.post(
            "/api/v1/categories/bulk",
            json=[{"name": "Горячие напитки", "category_type": "dish"}],
            headers=headers
        )
        assert cat_resp.status_code in (200, 201)
        cat_id = cat_resp.json()[0]["id"]

        payload = [
            {"name": "Флэт Уайт", "price": 220.0, "category_id": cat_id, "type": "dish"},
            {"name": "Раф Кофе", "price": 240.0, "category_id": cat_id, "type": "dish"},
        ]
        resp = await async_client.post("/api/v1/menu/bulk", json=payload, headers=headers)
        assert resp.status_code in (200, 201), resp.text
        items = resp.json()
        assert all(i["category_id"] == cat_id for i in items)

    @pytest.mark.asyncio
    async def test_bulk_dishes_description_and_availability(self, async_client: AsyncClient, db_session: AsyncSession):
        headers, _, _ = await setup_auth_headers(db_session)
        payload = [
            {
                "name": "Сезонный Глинтвейн",
                "price": 300.0,
                "description": "Пряный безалкогольный напиток с корицей и апельсином",
                "is_available": False,
                "type": "dish",
            }
        ]
        resp = await async_client.post("/api/v1/menu/bulk", json=payload, headers=headers)
        assert resp.status_code in (200, 201), resp.text
        item = resp.json()[0]
        assert item["description"] == "Пряный безалкогольный напиток с корицей и апельсином"
        assert item["is_available"] is False

    # --- Feature 2: Bulk Add Retail Products (5 tests) ---

    @pytest.mark.asyncio
    async def test_bulk_retail_happy_path(self, async_client: AsyncClient, db_session: AsyncSession):
        headers, _, _ = await setup_auth_headers(db_session)
        payload = [
            {"name": "Шоколадный батончик Mars", "selling_price": 60.0, "purchase_price": 40.0, "unit": "pcs"},
            {"name": "Coca-Cola 0.5л", "selling_price": 90.0, "purchase_price": 55.0, "unit": "pcs"},
        ]
        resp = await async_client.post("/api/v1/retail-product/bulk", json=payload, headers=headers)
        assert resp.status_code in (200, 201), resp.text
        data = resp.json()
        assert len(data) == 2
        assert data[0]["name"] == "Шоколадный батончик Mars"
        assert data[1]["name"] == "Coca-Cola 0.5л"

    @pytest.mark.asyncio
    async def test_bulk_retail_units(self, async_client: AsyncClient, db_session: AsyncSession):
        headers, _, _ = await setup_auth_headers(db_session)
        payload = [
            {"name": "Орехи грецкие фасованные", "selling_price": 250.0, "unit": "kg"},
            {"name": "Сок апельсиновый 1л", "selling_price": 180.0, "unit": "l"},
        ]
        resp = await async_client.post("/api/v1/retail-product/bulk", json=payload, headers=headers)
        assert resp.status_code in (200, 201), resp.text
        items = resp.json()
        assert items[0]["unit"] in ("kg", UnitType.KG.value)
        assert items[1]["unit"] in ("l", UnitType.L.value)

    @pytest.mark.asyncio
    async def test_bulk_retail_barcodes(self, async_client: AsyncClient, db_session: AsyncSession):
        headers, _, _ = await setup_auth_headers(db_session)
        payload = [
            {"name": "Вода BonAqua 0.5л", "selling_price": 50.0, "barcode": "5449000000996"},
            {"name": "Жвачка Orbit", "selling_price": 35.0, "barcode": "4009900014022"},
        ]
        resp = await async_client.post("/api/v1/retail-product/bulk", json=payload, headers=headers)
        assert resp.status_code in (200, 201), resp.text
        items = resp.json()
        barcodes = [i["barcode"] for i in items]
        assert "5449000000996" in barcodes and "4009900014022" in barcodes

    @pytest.mark.asyncio
    async def test_bulk_retail_cost_and_price(self, async_client: AsyncClient, db_session: AsyncSession):
        headers, _, _ = await setup_auth_headers(db_session)
        payload = [
            {"name": "Кружка фирменная", "selling_price": 500.0, "purchase_price": 220.0},
        ]
        resp = await async_client.post("/api/v1/retail-product/bulk", json=payload, headers=headers)
        assert resp.status_code in (200, 201), resp.text
        item = resp.json()[0]
        assert item["price"] == 500.0
        assert item["cost"] == 220.0

    @pytest.mark.asyncio
    async def test_bulk_retail_zero_initial_stock(self, async_client: AsyncClient, db_session: AsyncSession):
        """Requirement R2: Catalog creation must NOT create physical stock or virtual transactions."""
        headers, _, _ = await setup_auth_headers(db_session)
        payload = [
            {"name": "Тестовый Ритейл Товар", "selling_price": 100.0, "initial_stock": 500.0}
        ]
        resp = await async_client.post("/api/v1/retail-product/bulk", json=payload, headers=headers)
        assert resp.status_code in (200, 201), resp.text
        item = resp.json()[0]
        # current_stock MUST be strictly 0.0
        assert item["current_stock"] == 0.0

        # Verify DB directly
        db_prod = await db_session.get(RetailProduct, item["id"])
        assert db_prod.current_stock == 0.0

    # --- Feature 3: Bulk Add Ingredients (5 tests) ---

    @pytest.mark.asyncio
    async def test_bulk_ingredients_happy_path(self, async_client: AsyncClient, db_session: AsyncSession):
        headers, _, _ = await setup_auth_headers(db_session)
        payload = [
            {"name": "Зерно Арабика Колумбия", "unit": "g", "cost_per_unit": 1.2},
            {"name": "Молоко Parmalat 3.5%", "unit": "ml", "cost_per_unit": 0.09},
        ]
        resp = await async_client.post("/api/v1/ingredients/bulk", json=payload, headers=headers)
        assert resp.status_code in (200, 201), resp.text
        items = resp.json()
        assert len(items) == 2
        assert items[0]["name"] == "Зерно Арабика Колумбия"
        assert items[1]["name"] == "Молоко Parmalat 3.5%"

    @pytest.mark.asyncio
    async def test_bulk_ingredients_measurement_units(self, async_client: AsyncClient, db_session: AsyncSession):
        headers, _, _ = await setup_auth_headers(db_session)
        payload = [
            {"name": "Сахар тростниковый", "unit": "kg"},
            {"name": "Сироп Монин Ваниль", "unit": "l"},
            {"name": "Стакан бумажный 300мл", "unit": "pcs"},
        ]
        resp = await async_client.post("/api/v1/ingredients/bulk", json=payload, headers=headers)
        assert resp.status_code in (200, 201), resp.text
        items = resp.json()
        units = [i["unit"] for i in items]
        assert "kg" in units and "l" in units and "pcs" in units

    @pytest.mark.asyncio
    async def test_bulk_ingredients_min_stock_alert(self, async_client: AsyncClient, db_session: AsyncSession):
        headers, _, _ = await setup_auth_headers(db_session)
        payload = [
            {"name": "Чай Матча церемониальный", "unit": "g", "min_stock_alert": 250.0},
        ]
        resp = await async_client.post("/api/v1/ingredients/bulk", json=payload, headers=headers)
        assert resp.status_code in (200, 201), resp.text
        item = resp.json()[0]
        assert item["min_stock_alert"] == 250.0

    @pytest.mark.asyncio
    async def test_bulk_ingredients_barcodes(self, async_client: AsyncClient, db_session: AsyncSession):
        headers, _, _ = await setup_auth_headers(db_session)
        payload = [
            {"name": "Корица молотая", "unit": "g", "barcode": "7700112233445"},
        ]
        resp = await async_client.post("/api/v1/ingredients/bulk", json=payload, headers=headers)
        assert resp.status_code in (200, 201), resp.text
        item = resp.json()[0]
        assert item["barcode"] == "7700112233445"

    @pytest.mark.asyncio
    async def test_bulk_ingredients_zero_initial_stock(self, async_client: AsyncClient, db_session: AsyncSession):
        """Requirement R2: Ingredients created via Catalog must strictly have 0.0 stock."""
        headers, _, _ = await setup_auth_headers(db_session)
        payload = [
            {"name": "Какао-порошок натуральный", "unit": "g", "initial_stock": 1000.0}
        ]
        resp = await async_client.post("/api/v1/ingredients/bulk", json=payload, headers=headers)
        assert resp.status_code in (200, 201), resp.text
        item = resp.json()[0]
        assert item["current_stock"] == 0.0

        db_ing = await db_session.get(Ingredient, item["id"])
        assert db_ing.current_stock == 0.0

    # --- Feature 4: Bulk Add Menu Categories (5 tests) ---

    @pytest.mark.asyncio
    async def test_bulk_categories_happy_path(self, async_client: AsyncClient, db_session: AsyncSession):
        headers, _, _ = await setup_auth_headers(db_session)
        payload = [
            {"name": "Кофе классика", "category_type": "dish"},
            {"name": "Авторские чаи", "category_type": "dish"},
            {"name": "Выпечка", "category_type": "dish"},
        ]
        resp = await async_client.post("/api/v1/categories/bulk", json=payload, headers=headers)
        assert resp.status_code in (200, 201), resp.text
        cats = resp.json()
        assert len(cats) == 3
        cat_names = [c["name"] for c in cats]
        assert "Кофе классика" in cat_names and "Выпечка" in cat_names

    @pytest.mark.asyncio
    async def test_bulk_categories_hierarchy(self, async_client: AsyncClient, db_session: AsyncSession):
        headers, _, _ = await setup_auth_headers(db_session)
        # Create root
        root_resp = await async_client.post(
            "/api/v1/categories/bulk",
            json=[{"name": "Напитки", "category_type": "dish", "level": 1}],
            headers=headers
        )
        root_id = root_resp.json()[0]["id"]

        # Bulk create subcategories
        child_payload = [
            {"name": "Холодные напитки", "category_type": "dish", "parent_id": root_id, "level": 2},
            {"name": "Горячие напитки", "category_type": "dish", "parent_id": root_id, "level": 2},
        ]
        resp = await async_client.post("/api/v1/categories/bulk", json=child_payload, headers=headers)
        assert resp.status_code in (200, 201), resp.text
        children = resp.json()
        assert all(c["parent_id"] == root_id for c in children)

    @pytest.mark.asyncio
    async def test_bulk_categories_types(self, async_client: AsyncClient, db_session: AsyncSession):
        headers, _, _ = await setup_auth_headers(db_session)
        payload = [
            {"name": "Меню Кухни", "category_type": "dish"},
            {"name": "Витрина Ритейл", "category_type": "retail"},
            {"name": "Склад Сырья", "category_type": "ingredient"},
        ]
        resp = await async_client.post("/api/v1/categories/bulk", json=payload, headers=headers)
        assert resp.status_code in (200, 201), resp.text
        types = [c["category_type"] for c in resp.json()]
        assert "dish" in types and "retail" in types and "ingredient" in types

    @pytest.mark.asyncio
    async def test_bulk_categories_ordering_and_colors(self, async_client: AsyncClient, db_session: AsyncSession):
        headers, _, _ = await setup_auth_headers(db_session)
        payload = [
            {"name": "Топ Категория 1", "sort_order": 1, "color": "#FF0000", "icon": "coffee"},
            {"name": "Топ Категория 2", "sort_order": 2, "color": "#00FF00", "icon": "cake"},
        ]
        resp = await async_client.post("/api/v1/categories/bulk", json=payload, headers=headers)
        assert resp.status_code in (200, 201), resp.text
        cats = resp.json()
        assert cats[0]["sort_order"] == 1 and cats[0]["color"] == "#FF0000"
        assert cats[1]["sort_order"] == 2 and cats[1]["color"] == "#00FF00"

    @pytest.mark.asyncio
    async def test_bulk_categories_visibility_flags(self, async_client: AsyncClient, db_session: AsyncSession):
        headers, _, _ = await setup_auth_headers(db_session)
        payload = [
            {"name": "Скрытая категория", "is_visible": False, "is_archived": True},
        ]
        resp = await async_client.post("/api/v1/categories/bulk", json=payload, headers=headers)
        assert resp.status_code in (200, 201), resp.text
        cat = resp.json()[0]
        assert cat["is_visible"] is False
        assert cat["is_archived"] is True

    # --- Feature 5: Goods Receipt Document Processing (5 tests) ---

    @pytest.mark.asyncio
    async def test_goods_receipt_creation_multi_item(self, async_client: AsyncClient, db_session: AsyncSession):
        headers, _, _ = await setup_auth_headers(db_session)
        # Create supplier
        sup = Supplier(name="Поставщик Кофе ООО", is_active=True, balance=0.0)
        db_session.add(sup)
        # Create ingredient
        ing = Ingredient(name="Зерно Бразилия 1кг", unit=UnitType.KG, current_stock=0.0)
        db_session.add(ing)
        await db_session.commit()
        await db_session.refresh(sup)
        await db_session.refresh(ing)

        doc_payload = {
            "type": "receipt",
            "supplier_id": sup.id,
            "invoice_number": "INV-E2E-001",
            "payment_status": "unpaid",
            "paid_amount": 0.0,
            "items": [
                {"ingredient_id": ing.id, "quantity": 10.0, "price_per_unit": 800.0, "total_price": 8000.0}
            ]
        }
        resp = await async_client.post("/api/v1/documents/", json=doc_payload, headers=headers)
        assert resp.status_code in (200, 201), resp.text
        doc = resp.json()
        assert doc["total_amount"] == 8000.0
        assert doc["status"] == "draft"

    @pytest.mark.asyncio
    async def test_goods_receipt_completion_status_transition(self, async_client: AsyncClient, db_session: AsyncSession):
        headers, _, _ = await setup_auth_headers(db_session)
        sup = Supplier(name="Поставщик Молока", is_active=True, balance=0.0)
        db_session.add(sup)
        ing = Ingredient(name="Молоко 1л", unit=UnitType.L, current_stock=0.0)
        db_session.add(ing)
        await db_session.commit()
        await db_session.refresh(sup)
        await db_session.refresh(ing)

        doc_payload = {
            "type": "receipt",
            "supplier_id": sup.id,
            "invoice_number": "INV-E2E-002",
            "payment_status": "paid",
            "paid_amount": 1000.0,
            "items": [
                {"ingredient_id": ing.id, "quantity": 20.0, "price_per_unit": 50.0, "total_price": 1000.0}
            ]
        }
        create_resp = await async_client.post("/api/v1/documents/", json=doc_payload, headers=headers)
        doc_id = create_resp.json()["id"]

        comp_resp = await async_client.post(f"/api/v1/documents/{doc_id}/complete", headers=headers)
        assert comp_resp.status_code == 200, comp_resp.text
        assert comp_resp.json()["status"] == "completed"

    @pytest.mark.asyncio
    async def test_goods_receipt_unpaid_supplier_debt(self, async_client: AsyncClient, db_session: AsyncSession):
        headers, _, _ = await setup_auth_headers(db_session)
        sup = Supplier(name="ООО Снабжение", is_active=True, balance=0.0)
        db_session.add(sup)
        ing = Ingredient(name="Чай Ассам 1кг", unit=UnitType.KG, current_stock=0.0)
        db_session.add(ing)
        await db_session.commit()
        await db_session.refresh(sup)
        await db_session.refresh(ing)

        doc_payload = {
            "type": "receipt",
            "supplier_id": sup.id,
            "invoice_number": "INV-DEBT-1",
            "payment_status": "unpaid",
            "paid_amount": 0.0,
            "items": [
                {"ingredient_id": ing.id, "quantity": 5.0, "price_per_unit": 1200.0, "total_price": 6000.0}
            ]
        }
        create_resp = await async_client.post("/api/v1/documents/", json=doc_payload, headers=headers)
        doc_id = create_resp.json()["id"]
        await async_client.post(f"/api/v1/documents/{doc_id}/complete", headers=headers)

        # Supplier balance must be -6000.0 (debt)
        await db_session.refresh(sup)
        assert sup.balance == -6000.0

    @pytest.mark.asyncio
    async def test_goods_receipt_paid_supplier_neutral(self, async_client: AsyncClient, db_session: AsyncSession):
        headers, _, _ = await setup_auth_headers(db_session)
        sup = Supplier(name="ООО Оплачено", is_active=True, balance=0.0)
        db_session.add(sup)
        ing = Ingredient(name="Сироп Карамель", unit=UnitType.L, current_stock=0.0)
        db_session.add(ing)
        await db_session.commit()
        await db_session.refresh(sup)
        await db_session.refresh(ing)

        doc_payload = {
            "type": "receipt",
            "supplier_id": sup.id,
            "invoice_number": "INV-PAID-1",
            "payment_status": "paid",
            "paid_amount": 3000.0,
            "items": [
                {"ingredient_id": ing.id, "quantity": 6.0, "price_per_unit": 500.0, "total_price": 3000.0}
            ]
        }
        create_resp = await async_client.post("/api/v1/documents/", json=doc_payload, headers=headers)
        doc_id = create_resp.json()["id"]
        await async_client.post(f"/api/v1/documents/{doc_id}/complete", headers=headers)

        await db_session.refresh(sup)
        assert sup.balance == 0.0

    @pytest.mark.asyncio
    async def test_goods_receipt_stock_transaction_logged(self, async_client: AsyncClient, db_session: AsyncSession):
        headers, _, _ = await setup_auth_headers(db_session)
        sup = Supplier(name="ООО Транзакции", is_active=True, balance=0.0)
        db_session.add(sup)
        ing = Ingredient(name="Стаканы 400мл", unit=UnitType.PCS, current_stock=0.0)
        db_session.add(ing)
        await db_session.commit()
        await db_session.refresh(sup)
        await db_session.refresh(ing)

        doc_payload = {
            "type": "receipt",
            "supplier_id": sup.id,
            "invoice_number": "INV-TXN-1",
            "payment_status": "paid",
            "paid_amount": 500.0,
            "items": [
                {"ingredient_id": ing.id, "quantity": 100.0, "price_per_unit": 5.0, "total_price": 500.0}
            ]
        }
        create_resp = await async_client.post("/api/v1/documents/", json=doc_payload, headers=headers)
        doc_id = create_resp.json()["id"]
        await async_client.post(f"/api/v1/documents/{doc_id}/complete", headers=headers)

        # Check stock transaction
        stmt = select(StockTransaction).where(StockTransaction.ingredient_id == ing.id)
        res = await db_session.execute(stmt)
        txns = res.scalars().all()
        assert len(txns) >= 1
        txn = txns[0]
        assert txn.type == StockTransactionType.RECEIPT
        assert txn.quantity == 100.0


# ==============================================================================
# TIER 2: BOUNDARY & CORNER CASES
# ==============================================================================

class TestTier2BoundaryCornerCases:
    """
    Tier 2 tests edge cases, large payloads, special characters, and boundary constraints.
    """

    @pytest.mark.asyncio
    async def test_empty_batch_dishes(self, async_client: AsyncClient, db_session: AsyncSession):
        headers, _, _ = await setup_auth_headers(db_session)
        resp = await async_client.post("/api/v1/menu/bulk", json=[], headers=headers)
        assert resp.status_code in (200, 201)
        assert resp.json() == []

    @pytest.mark.asyncio
    async def test_empty_batch_retail(self, async_client: AsyncClient, db_session: AsyncSession):
        headers, _, _ = await setup_auth_headers(db_session)
        resp = await async_client.post("/api/v1/retail-product/bulk", json=[], headers=headers)
        assert resp.status_code in (200, 201)
        assert resp.json() == []

    @pytest.mark.asyncio
    async def test_empty_batch_ingredients(self, async_client: AsyncClient, db_session: AsyncSession):
        headers, _, _ = await setup_auth_headers(db_session)
        resp = await async_client.post("/api/v1/ingredients/bulk", json=[], headers=headers)
        assert resp.status_code in (200, 201)
        assert resp.json() == []

    @pytest.mark.asyncio
    async def test_empty_batch_categories(self, async_client: AsyncClient, db_session: AsyncSession):
        headers, _, _ = await setup_auth_headers(db_session)
        resp = await async_client.post("/api/v1/categories/bulk", json=[], headers=headers)
        assert resp.status_code in (200, 201)
        assert resp.json() == []

    @pytest.mark.asyncio
    async def test_large_batch_50_plus_items(self, async_client: AsyncClient, db_session: AsyncSession):
        """High volume batch stress: bulk create 55 items in a single atomic request."""
        headers, _, _ = await setup_auth_headers(db_session)
        payload = [
            {"name": f"Блюдо стресс-теста #{i}", "price": float(100 + i), "type": "dish"}
            for i in range(55)
        ]
        resp = await async_client.post("/api/v1/menu/bulk", json=payload, headers=headers)
        assert resp.status_code in (200, 201), resp.text
        data = resp.json()
        assert len(data) == 55

    @pytest.mark.asyncio
    async def test_special_characters_and_quotes(self, async_client: AsyncClient, db_session: AsyncSession):
        """Unicode, quotes, symbols, and emojis in nomenclature names."""
        headers, _, _ = await setup_auth_headers(db_session)
        payload = [
            {
                "name": "Кофе 'Глясе' \"Special\" & Сливки 20% <V.I.P.> №1 [HOT] ☕🔥",
                "price": 280.0,
                "type": "dish",
            },
            {
                "name": "Чай 100% натуральный: Эрл Грей (с бергамотом / мятой)",
                "price": 190.0,
                "type": "dish",
            }
        ]
        resp = await async_client.post("/api/v1/menu/bulk", json=payload, headers=headers)
        assert resp.status_code in (200, 201), resp.text
        data = resp.json()
        assert "Special" in data[0]["name"]
        assert "100%" in data[1]["name"]

    @pytest.mark.asyncio
    async def test_zero_and_fractional_pricing(self, async_client: AsyncClient, db_session: AsyncSession):
        headers, _, _ = await setup_auth_headers(db_session)
        payload = [
            {"name": "Бесплатная вода с лимоном", "price": 0.0, "type": "dish"},
            {"name": "Десерт с копейками", "price": 149.99, "type": "dish"},
        ]
        resp = await async_client.post("/api/v1/menu/bulk", json=payload, headers=headers)
        assert resp.status_code in (200, 201), resp.text
        data = resp.json()
        prices = [d["price"] for d in data]
        assert 0.0 in prices
        assert 149.99 in prices

    @pytest.mark.asyncio
    async def test_duplicate_barcodes_behavior(self, async_client: AsyncClient, db_session: AsyncSession):
        """Gracefully handle duplicate barcodes without database crash."""
        headers, _, _ = await setup_auth_headers(db_session)
        payload = [
            {"name": "Товар А", "selling_price": 50.0, "barcode": "DUPLICATE_BARCODE_123"},
            {"name": "Товар Б", "selling_price": 55.0, "barcode": "DUPLICATE_BARCODE_123"},
        ]
        resp = await async_client.post("/api/v1/retail-product/bulk", json=payload, headers=headers)
        # Should either succeed or return 400 validation error, but never 500
        assert resp.status_code in (200, 201, 400), resp.text

    @pytest.mark.asyncio
    async def test_goods_receipt_invalid_item_id_rejection(self, async_client: AsyncClient, db_session: AsyncSession):
        """Prevent phantom stock / crash when document references non-existent item ID."""
        headers, _, _ = await setup_auth_headers(db_session)
        sup = Supplier(name="ООО Тест Валидации", is_active=True, balance=0.0)
        db_session.add(sup)
        await db_session.commit()
        await db_session.refresh(sup)

        doc_payload = {
            "type": "receipt",
            "supplier_id": sup.id,
            "invoice_number": "INV-BOGUS-ID",
            "items": [
                {"ingredient_id": 9999999, "quantity": 10.0, "price_per_unit": 100.0, "total_price": 1000.0}
            ]
        }
        create_resp = await async_client.post("/api/v1/documents/", json=doc_payload, headers=headers)
        if create_resp.status_code in (200, 201):
            doc_id = create_resp.json()["id"]
            comp_resp = await async_client.post(f"/api/v1/documents/{doc_id}/complete", headers=headers)
            # Must be rejected with 400 Bad Request
            assert comp_resp.status_code in (400, 422), f"Expected 400 on bogus ID, got {comp_resp.status_code}"


# ==============================================================================
# TIER 3: COMBINATORIAL & CROSS-FEATURE
# ==============================================================================

class TestTier3CombinatorialCrossFeature:
    """
    Tier 3 tests interactions between Catalog and Warehouse domains.
    Guarantees:
      - Catalog creation NEVER creates physical stock or transactions.
      - Goods Receipt is the ONLY path to increment physical stock.
      - Moving average cost formula strictly preserved.
      - Supplier debt and stock balances stay synchronized.
    """

    @pytest.mark.asyncio
    async def test_catalog_creation_never_increments_stock(self, async_client: AsyncClient, db_session: AsyncSession):
        """R2 Invariant: Bulk adding catalog nomenclature leaves warehouse stock at zero."""
        headers, _, _ = await setup_auth_headers(db_session)

        # 1. Bulk add dishes
        dish_resp = await async_client.post("/api/v1/menu/bulk", json=[
            {"name": "Тестовое блюдо A", "price": 200.0, "type": "dish"},
            {"name": "Тестовое блюдо B", "price": 250.0, "type": "dish"},
        ], headers=headers)
        assert dish_resp.status_code in (200, 201)

        # 2. Bulk add retail products with initial_stock in payload
        ret_resp = await async_client.post("/api/v1/retail-product/bulk", json=[
            {"name": "Шоколад Тест", "selling_price": 100.0, "initial_stock": 50.0},
            {"name": "Чипсы Тест", "selling_price": 120.0, "initial_stock": 70.0},
        ], headers=headers)
        assert ret_resp.status_code in (200, 201)

        # 3. Bulk add ingredients with initial_stock in payload
        ing_resp = await async_client.post("/api/v1/ingredients/bulk", json=[
            {"name": "Сливки Тест 10%", "unit": "ml", "initial_stock": 5000.0},
            {"name": "Мята Тест", "unit": "g", "initial_stock": 200.0},
        ], headers=headers)
        assert ing_resp.status_code in (200, 201)

        # Verify physical stock in database: ALL MUST BE ZERO
        stmt_ret = select(RetailProduct)
        ret_items = (await db_session.execute(stmt_ret)).scalars().all()
        for r in ret_items:
            assert r.current_stock == 0.0, f"Retail product {r.name} has non-zero initial stock {r.current_stock}"

        stmt_ing = select(Ingredient)
        ing_items = (await db_session.execute(stmt_ing)).scalars().all()
        for i in ing_items:
            assert i.current_stock == 0.0, f"Ingredient {i.name} has non-zero initial stock {i.current_stock}"

        # Zero stock transactions should exist
        stmt_tx = select(StockTransaction)
        txns = (await db_session.execute(stmt_tx)).scalars().all()
        assert len(txns) == 0, f"Expected 0 StockTransactions from catalog creation, found {len(txns)}"

    @pytest.mark.asyncio
    async def test_bulk_nomenclature_to_goods_receipt_stock_sync(self, async_client: AsyncClient, db_session: AsyncSession):
        """
        End-to-End Cross Feature:
        1. Bulk add raw materials & retail products (catalog cards only).
        2. Verify stock is 0.0.
        3. Receive goods via InventoryDocument receipt.
        4. Complete document.
        5. Verify stock now reflects received quantities.
        """
        headers, _, _ = await setup_auth_headers(db_session)

        # 1. Bulk create ingredients
        ing_resp = await async_client.post("/api/v1/ingredients/bulk", json=[
            {"name": "Зерно Эфиопия Иргачеффе", "unit": "kg", "cost_per_unit": 0.0},
            {"name": "Молоко Овсяное Alpro", "unit": "l", "cost_per_unit": 0.0},
        ], headers=headers)
        assert ing_resp.status_code in (200, 201)
        ing_data = ing_resp.json()
        ing1_id = ing_data[0]["id"]
        ing2_id = ing_data[1]["id"]

        # 2. Bulk create retail product
        ret_resp = await async_client.post("/api/v1/retail-product/bulk", json=[
            {"name": "Фирменный Термостакан", "selling_price": 950.0, "unit": "pcs"},
        ], headers=headers)
        assert ret_resp.status_code in (200, 201)
        ret_id = ret_resp.json()[0]["id"]

        # Create supplier
        sup = Supplier(name="Главный Дистрибьютор HoReCa", is_active=True, balance=0.0)
        db_session.add(sup)
        await db_session.commit()
        await db_session.refresh(sup)

        # 3. Create Goods Receipt Document
        doc_payload = {
            "type": "receipt",
            "supplier_id": sup.id,
            "invoice_number": "INV-SYNC-999",
            "payment_status": "unpaid",
            "paid_amount": 0.0,
            "items": [
                {"ingredient_id": ing1_id, "quantity": 15.0, "price_per_unit": 1200.0, "total_price": 18000.0},
                {"ingredient_id": ing2_id, "quantity": 30.0, "price_per_unit": 180.0, "total_price": 5400.0},
                {"retail_product_id": ret_id, "quantity": 10.0, "price_per_unit": 500.0, "total_price": 5000.0},
            ]
        }
        doc_resp = await async_client.post("/api/v1/documents/", json=doc_payload, headers=headers)
        assert doc_resp.status_code in (200, 201), doc_resp.text
        doc_id = doc_resp.json()["id"]

        # Complete Document
        comp_resp = await async_client.post(f"/api/v1/documents/{doc_id}/complete", headers=headers)
        assert comp_resp.status_code == 200, comp_resp.text

        # 4. Verify Stock Balances Updated
        db_ing1 = await db_session.get(Ingredient, ing1_id)
        db_ing2 = await db_session.get(Ingredient, ing2_id)
        db_ret = await db_session.get(RetailProduct, ret_id)

        assert db_ing1.current_stock == 15.0
        assert db_ing1.cost_per_unit == 1200.0
        assert db_ing2.current_stock == 30.0
        assert db_ing2.cost_per_unit == 180.0
        assert db_ret.current_stock == 10.0
        assert db_ret.cost == 500.0

        # Total supplier debt = 18000 + 5400 + 5000 = 28400
        await db_session.refresh(sup)
        assert sup.balance == -28400.0

    @pytest.mark.asyncio
    async def test_moving_average_cost_recalculation(self, async_client: AsyncClient, db_session: AsyncSession):
        """
        Mathematical proof of weighted average cost invariant:
        Batch 1: 10 kg @ 100 RUB -> stock=10, cost=100.0
        Batch 2: 20 kg @ 160 RUB -> stock=30, cost = (10*100 + 20*160) / 30 = 4200/30 = 140.0
        """
        headers, _, _ = await setup_auth_headers(db_session)
        sup = Supplier(name="Поставщик Зерна", is_active=True, balance=0.0)
        db_session.add(sup)
        ing = Ingredient(name="Зерно Гондурас", unit=UnitType.KG, current_stock=0.0, cost_per_unit=0.0)
        db_session.add(ing)
        await db_session.commit()
        await db_session.refresh(sup)
        await db_session.refresh(ing)

        # Batch 1
        doc1_payload = {
            "type": "receipt",
            "supplier_id": sup.id,
            "invoice_number": "INV-BATCH-1",
            "payment_status": "paid",
            "paid_amount": 1000.0,
            "items": [{"ingredient_id": ing.id, "quantity": 10.0, "price_per_unit": 100.0, "total_price": 1000.0}]
        }
        d1 = (await async_client.post("/api/v1/documents/", json=doc1_payload, headers=headers)).json()["id"]
        await async_client.post(f"/api/v1/documents/{d1}/complete", headers=headers)

        await db_session.refresh(ing)
        assert ing.current_stock == 10.0
        assert ing.cost_per_unit == 100.0

        # Batch 2
        doc2_payload = {
            "type": "receipt",
            "supplier_id": sup.id,
            "invoice_number": "INV-BATCH-2",
            "payment_status": "paid",
            "paid_amount": 3200.0,
            "items": [{"ingredient_id": ing.id, "quantity": 20.0, "price_per_unit": 160.0, "total_price": 3200.0}]
        }
        d2 = (await async_client.post("/api/v1/documents/", json=doc2_payload, headers=headers)).json()["id"]
        await async_client.post(f"/api/v1/documents/{d2}/complete", headers=headers)

        await db_session.refresh(ing)
        assert ing.current_stock == 30.0
        assert ing.cost_per_unit == pytest.approx(140.0, 0.001)

    @pytest.mark.asyncio
    async def test_partial_payment_supplier_debt_and_stock(self, async_client: AsyncClient, db_session: AsyncSession):
        """Partial payment: 10,000 total, 3,000 paid -> debt increases by 7,000; stock increases by 100%."""
        headers, _, _ = await setup_auth_headers(db_session)
        sup = Supplier(name="Поставщик Чая", is_active=True, balance=0.0)
        db_session.add(sup)
        ing = Ingredient(name="Зеленый чай Сенча", unit=UnitType.KG, current_stock=0.0)
        db_session.add(ing)
        await db_session.commit()
        await db_session.refresh(sup)
        await db_session.refresh(ing)

        doc_payload = {
            "type": "receipt",
            "supplier_id": sup.id,
            "invoice_number": "INV-PARTIAL-1",
            "payment_status": "partial",
            "paid_amount": 3000.0,
            "payment_method": "card",
            "items": [{"ingredient_id": ing.id, "quantity": 25.0, "price_per_unit": 400.0, "total_price": 10000.0}]
        }
        doc_resp = await async_client.post("/api/v1/documents/", json=doc_payload, headers=headers)
        doc_id = doc_resp.json()["id"]
        await async_client.post(f"/api/v1/documents/{doc_id}/complete", headers=headers)

        await db_session.refresh(sup)
        await db_session.refresh(ing)
        assert sup.balance == -7000.0
        assert ing.current_stock == 25.0

    @pytest.mark.asyncio
    async def test_goods_receipt_followed_by_writeoff(self, async_client: AsyncClient, db_session: AsyncSession):
        """Lifecycle: Receipt -> Write-off -> Stock balance decrements correctly."""
        headers, _, _ = await setup_auth_headers(db_session)
        sup = Supplier(name="Поставщик Молочки", is_active=True, balance=0.0)
        db_session.add(sup)
        ing = Ingredient(name="Сливки 33%", unit=UnitType.L, current_stock=0.0)
        db_session.add(ing)
        await db_session.commit()
        await db_session.refresh(sup)
        await db_session.refresh(ing)

        # 1. Receipt 50L
        rec_payload = {
            "type": "receipt",
            "supplier_id": sup.id,
            "invoice_number": "INV-REC-50",
            "payment_status": "paid",
            "paid_amount": 10000.0,
            "items": [{"ingredient_id": ing.id, "quantity": 50.0, "price_per_unit": 200.0, "total_price": 10000.0}]
        }
        d_rec = (await async_client.post("/api/v1/documents/", json=rec_payload, headers=headers)).json()["id"]
        await async_client.post(f"/api/v1/documents/{d_rec}/complete", headers=headers)

        await db_session.refresh(ing)
        assert ing.current_stock == 50.0

        # 2. Write-off 15L (e.g. expired)
        wo_payload = {
            "type": "write_off",
            "reason": "Истек срок годности",
            "items": [{"ingredient_id": ing.id, "quantity": 15.0, "price_per_unit": 200.0, "total_price": 3000.0}]
        }
        d_wo = (await async_client.post("/api/v1/documents/", json=wo_payload, headers=headers)).json()["id"]
        await async_client.post(f"/api/v1/documents/{d_wo}/complete", headers=headers)

        await db_session.refresh(ing)
        assert ing.current_stock == 35.0


# ==============================================================================
# TIER 4: REAL-WORLD WORKFLOWS
# ==============================================================================

class TestTier4RealWorldWorkflows:
    """
    Tier 4 tests complete real-world scenarios from opening to weekly replenishment.
    """

    @pytest.mark.asyncio
    async def test_workflow_restaurant_opening_inventory_setup(self, async_client: AsyncClient, db_session: AsyncSession):
        """
        Workflow 1: Restaurant Opening Inventory Setup
        1. Bulk create categories (Кофе, Чай, Десерты, Сырье, Ритейл).
        2. Bulk create dishes with variations.
        3. Bulk create retail merchandise (кружки, термосы).
        4. Bulk create raw ingredients.
        5. Verify all catalog cards exist and physical inventory is 0 everywhere.
        6. Onboard opening supplier and process primary delivery invoice.
        7. Complete delivery document and verify inventory is ready for opening day.
        """
        headers, _, _ = await setup_auth_headers(db_session)

        # 1. Bulk create categories
        cats_payload = [
            {"name": "Кофейная карта", "category_type": "dish", "sort_order": 1},
            {"name": "Чайная коллекция", "category_type": "dish", "sort_order": 2},
            {"name": "Десерты и выпечка", "category_type": "dish", "sort_order": 3},
            {"name": "Мерч и ритейл", "category_type": "retail", "sort_order": 4},
            {"name": "Складские запасы", "category_type": "ingredient", "sort_order": 5},
        ]
        cat_resp = await async_client.post("/api/v1/categories/bulk", json=cats_payload, headers=headers)
        assert cat_resp.status_code in (200, 201)
        cats = {c["name"]: c["id"] for c in cat_resp.json()}

        # 2. Bulk create dishes
        dishes_payload = [
            {"name": "Эспрессо Доппио", "price": 160.0, "category_id": cats["Кофейная карта"], "type": "dish"},
            {"name": "Капучино Гранд", "price": 240.0, "category_id": cats["Кофейная карта"], "type": "dish"},
            {"name": "Чай Зеленый Жасмин", "price": 180.0, "category_id": cats["Чайная коллекция"], "type": "dish"},
            {"name": "Круассан с миндалем", "price": 220.0, "category_id": cats["Десерты и выпечка"], "type": "dish"},
        ]
        dish_resp = await async_client.post("/api/v1/menu/bulk", json=dishes_payload, headers=headers)
        assert dish_resp.status_code in (200, 201)

        # 3. Bulk create retail items
        retail_payload = [
            {"name": "Термокружка Mynix Black", "selling_price": 1200.0, "purchase_price": 600.0, "unit": "pcs"},
            {"name": "Зерновой кофе в пачке 250г", "selling_price": 650.0, "purchase_price": 350.0, "unit": "pcs"},
        ]
        retail_resp = await async_client.post("/api/v1/retail-product/bulk", json=retail_payload, headers=headers)
        assert retail_resp.status_code in (200, 201)
        retail_items = retail_resp.json()

        # 4. Bulk create raw ingredients
        ing_payload = [
            {"name": "Зерно Эспрессо Бленд", "unit": "kg"},
            {"name": "Молоко цельное 3.2%", "unit": "l"},
            {"name": "Сироп Соленая Карамель", "unit": "l"},
        ]
        ing_resp = await async_client.post("/api/v1/ingredients/bulk", json=ing_payload, headers=headers)
        assert ing_resp.status_code in (200, 201)
        ingredients = ing_resp.json()

        # 5. Check catalog is ready, stock is 0
        list_ing = await async_client.get("/api/v1/ingredients/", headers=headers)
        for ing in list_ing.json():
            assert ing["current_stock"] == 0.0

        # 6. Onboard opening supplier & invoice
        sup = Supplier(name="Единый Поставщик Открытия", is_active=True, balance=0.0)
        db_session.add(sup)
        await db_session.commit()
        await db_session.refresh(sup)

        opening_invoice = {
            "type": "receipt",
            "supplier_id": sup.id,
            "invoice_number": "OPENING-INV-001",
            "payment_status": "unpaid",
            "paid_amount": 0.0,
            "items": [
                {"ingredient_id": ingredients[0]["id"], "quantity": 50.0, "price_per_unit": 900.0, "total_price": 45000.0},
                {"ingredient_id": ingredients[1]["id"], "quantity": 100.0, "price_per_unit": 65.0, "total_price": 6500.0},
                {"ingredient_id": ingredients[2]["id"], "quantity": 10.0, "price_per_unit": 450.0, "total_price": 4500.0},
                {"retail_product_id": retail_items[0]["id"], "quantity": 20.0, "price_per_unit": 600.0, "total_price": 12000.0},
                {"retail_product_id": retail_items[1]["id"], "quantity": 30.0, "price_per_unit": 350.0, "total_price": 10500.0},
            ]
        }
        inv_resp = await async_client.post("/api/v1/documents/", json=opening_invoice, headers=headers)
        assert inv_resp.status_code in (200, 201)
        inv_id = inv_resp.json()["id"]

        # 7. Complete delivery document
        comp_resp = await async_client.post(f"/api/v1/documents/{inv_id}/complete", headers=headers)
        assert comp_resp.status_code == 200

        # Verify warehouse is primed
        updated_beans = await db_session.get(Ingredient, ingredients[0]["id"])
        assert updated_beans.current_stock == 50.0
        assert updated_beans.cost_per_unit == 900.0

        updated_mugs = await db_session.get(RetailProduct, retail_items[0]["id"])
        assert updated_mugs.current_stock == 20.0
        assert updated_mugs.cost == 600.0

        # Total debt: 45000 + 6500 + 4500 + 12000 + 10500 = 78,500 RUB
        await db_session.refresh(sup)
        assert sup.balance == -78500.0

    @pytest.mark.asyncio
    async def test_workflow_supplier_delivery_invoice_processing(self, async_client: AsyncClient, db_session: AsyncSession):
        """
        Workflow 2: Recurring Supplier Delivery Invoice Processing
        1. Supplier exists with prior running balance (-5,000 RUB debt).
        2. New weekly delivery arrives: invoice INV-WK37 with milk, syrup, and cups.
        3. Document is recorded with partial payment (10,000 cash).
        4. Complete document: moving average recalculated, stock updated, supplier debt updated.
        5. Register supplier debt settlement payment via /suppliers/{id}/payments.
        6. Verify supplier balance is settled.
        """
        headers, _, _ = await setup_auth_headers(db_session)

        # 1. Existing supplier with initial debt
        sup = Supplier(name="ООО Базис Трейд", is_active=True, balance=-5000.0)
        db_session.add(sup)
        # Existing ingredient with existing stock
        ing = Ingredient(name="Молоко Базовое", unit=UnitType.L, current_stock=20.0, cost_per_unit=60.0)
        db_session.add(ing)
        await db_session.commit()
        await db_session.refresh(sup)
        await db_session.refresh(ing)

        # 2. Weekly delivery arrives: 80L @ 70 RUB = 5,600 RUB
        # Paid: 2,000 RUB, remaining debt addition: 3,600 RUB
        inv_payload = {
            "type": "receipt",
            "supplier_id": sup.id,
            "invoice_number": "INV-WK37",
            "payment_status": "partial",
            "paid_amount": 2000.0,
            "payment_method": "cash",
            "items": [
                {"ingredient_id": ing.id, "quantity": 80.0, "price_per_unit": 70.0, "total_price": 5600.0}
            ]
        }
        create_resp = await async_client.post("/api/v1/documents/", json=inv_payload, headers=headers)
        assert create_resp.status_code in (200, 201)
        doc_id = create_resp.json()["id"]

        # 4. Complete document
        comp_resp = await async_client.post(f"/api/v1/documents/{doc_id}/complete", headers=headers)
        assert comp_resp.status_code == 200

        # Check stock: 20 + 80 = 100L
        # Moving average: (20*60 + 80*70) / 100 = (1200 + 5600) / 100 = 68.0 RUB
        await db_session.refresh(ing)
        assert ing.current_stock == 100.0
        assert ing.cost_per_unit == pytest.approx(68.0, 0.001)

        # Supplier balance: was -5,000, unpaid portion was 3,600 -> now -8,600
        await db_session.refresh(sup)
        assert sup.balance == -8600.0

        # 5. Settle supplier balance
        pay_resp = await async_client.post(
            f"/api/v1/suppliers/{sup.id}/payments",
            json={"amount": 8600.0, "payment_method": "bank_transfer", "comment": "Полное погашение долга по INV-WK37"},
            headers=headers
        )
        assert pay_resp.status_code == 200

        # 6. Balance is fully settled to 0.0
        await db_session.refresh(sup)
        assert sup.balance == 0.0
