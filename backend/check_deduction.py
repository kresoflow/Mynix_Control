import asyncio
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from sqlmodel import select, text
from app.pos.models import Order, OrderItem
import sys

# Ensure utf-8 output
sys.stdout.reconfigure(encoding='utf-8')

async def main():
    engine = create_async_engine("postgresql+asyncpg://mynix:mynix_secret@127.0.0.1:5444/mynix_control")
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    async with async_session() as session:
        await session.execute(text("SET search_path TO tenant_1"))
        
        # Get the latest order
        orders = (await session.execute(select(Order).order_by(Order.id.desc()).limit(1))).scalars().all()
        if not orders:
            print("No orders found!")
            return
            
        latest_order = orders[0]
        print(f"Latest Order ID: {latest_order.id}, Created At: {latest_order.created_at}")
        
        # Get its items
        items = (await session.execute(select(OrderItem).where(OrderItem.order_id == latest_order.id))).scalars().all()
        for item in items:
            print(f"  Item ID: {item.menu_item_id}, Qty: {item.quantity}")
            
            # Check recipes for this item
            recipes = (await session.execute(text(f"SELECT * FROM tenant_1.recipes WHERE menu_item_id = {item.menu_item_id}"))).fetchall()
            print(f"    Found {len(recipes)} recipes for this menu_item_id.")
            
        # Check stock transactions
        txns = (await session.execute(text("SELECT id, type, quantity FROM tenant_1.stock_transactions ORDER BY id DESC LIMIT 5"))).fetchall()
        print("Recent Stock Transactions:")
        for t in txns:
            print(f"  Txn ID: {t.id}, Type: {t.type}, Qty: {t.quantity}")

if __name__ == "__main__":
    asyncio.run(main())
