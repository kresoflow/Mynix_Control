import asyncio
from sqlalchemy import text
from app.database import async_session_factory

async def main():
    async with async_session_factory() as session:
        try:
            # Let's try adding the enum value in both public and tenant_1 just in case
            schemas = ["public", "tenant_1"]
            for schema in schemas:
                try:
                    await session.execute(text(f"ALTER TYPE {schema}.paymentmethod ADD VALUE 'TRANSFER'"))
                    await session.commit()
                    print(f"Successfully added 'TRANSFER' to {schema}.paymentmethod")
                except Exception as e:
                    await session.rollback()
                    print(f"Could not add to {schema}.paymentmethod: {e}")
                    
        except Exception as e:
            import traceback
            traceback.print_exc()

if __name__ == "__main__":
    asyncio.run(main())
