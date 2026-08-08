import asyncio
from datetime import datetime, timezone
from sqlalchemy import text
from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy.orm import sessionmaker
from sqlmodel.ext.asyncio.session import AsyncSession
from sqlmodel import select

# We need to import our models
from app.inventory.models import Supplier, InventoryDocument, InventoryDocumentItem, DocumentType, DocumentStatus, Ingredient
from app.users.models import Tenant

async def main():
    engine = create_async_engine("postgresql+asyncpg://mynix:mynix_secret@127.0.0.1:5444/mynix_control", connect_args={"server_settings": {"jit": "off"}, "prepared_statement_cache_size": 0})
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    async with async_session() as session:
        # Get all tenants
        result = await session.execute(select(Tenant))
        tenants = result.scalars().all()

        for tenant in tenants:
            schema = tenant.schema_name
            print(f"Seeding test data for schema: {schema}")
            
            # Switch to schema
            await session.execute(text(f"SET search_path TO {schema}"))
            
            # 1. Seed Suppliers
            suppliers_data = [
                {"name": "Metro Cash & Carry", "contact_info": "+7 (800) 700-10-77"},
                {"name": "ООО Восток-Запад", "contact_info": "vostok-zapad.ru"},
                {"name": "Фермерское хозяйство 'Ромашка'", "contact_info": "Иван: +7 999 123-45-67"},
            ]
            
            for sup_data in suppliers_data:
                # Check if exists
                stmt = select(Supplier).where(Supplier.name == sup_data["name"])
                res = await session.execute(stmt)
                existing = res.scalar_one_or_none()
                if not existing:
                    supplier = Supplier(
                        name=sup_data["name"],
                        contact_info=sup_data["contact_info"],
                        is_active=True
                    )
                    session.add(supplier)
            
            await session.commit()
            print(f"Suppliers seeded for {schema}")
            
            # 2. Seed some Documents
            doc_stmt = select(InventoryDocument)
            doc_res = await session.execute(doc_stmt)
            if not doc_res.scalars().first():
                # get a supplier
                sup_res = await session.execute(select(Supplier))
                first_sup = sup_res.scalars().first()
                
                # get an ingredient
                ing_res = await session.execute(select(Ingredient))
                first_ing = ing_res.scalars().first()
                
                if first_sup and first_ing:
                    doc = InventoryDocument(
                        type=DocumentType.RECEIPT,
                        status=DocumentStatus.COMPLETED,
                        date=datetime.now(timezone.utc).replace(tzinfo=None),
                        supplier_id=first_sup.id,
                        invoice_number="INV-001",
                        reason="Первая поставка",
                        total_amount=15000.0
                    )
                    session.add(doc)
                    await session.flush()
                    
                    item = InventoryDocumentItem(
                        document_id=doc.id,
                        ingredient_id=first_ing.id,
                        quantity=10,
                        price_per_unit=1500.0,
                        total_price=15000.0
                    )
                    session.add(item)
                    await session.commit()
                    print(f"Documents seeded for {schema}")

if __name__ == "__main__":
    asyncio.run(main())
