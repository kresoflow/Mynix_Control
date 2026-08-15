import asyncio
import json
from app.inventory.services.document_service import create_document
from app.inventory.models.document_models import InventoryDocumentCreate, InventoryDocumentItemCreate
from app.inventory.models.enums import DocumentType
from app.database import async_session_factory
from app.users.models import User  # IMPORT USER!
from app.inventory.models.retail_models import RetailProduct
from app.inventory.models.ingredient_models import Ingredient

async def test_create_document():
    async with async_session_factory() as session:
        # We need to set the search_path to the tenant for it to work
        from sqlalchemy import text
        await session.execute(text("SET search_path TO tenant_default"))
        doc_in = InventoryDocumentCreate(
            type=DocumentType.RECEIPT,
            items=[
                InventoryDocumentItemCreate(
                    ingredient_id=1,
                    quantity=10,
                    price_per_unit=100,
                    total_price=1000
                )
            ]
        )
        try:
            doc = await create_document(session, doc_in, user_id=1)
            print(f"Success! Document ID: {doc.id}")
            # we roll back to not mess up the db
            await session.rollback()
        except Exception as e:
            import traceback
            traceback.print_exc()

asyncio.run(test_create_document())
