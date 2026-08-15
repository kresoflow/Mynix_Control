import asyncio
from sqlalchemy import text
from app.database import async_session_factory
from datetime import datetime

async def main():
    async with async_session_factory() as session:
        await session.execute(text('SET search_path TO "tenant_1"'))
        
        today = datetime.now().strftime('%Y-%m-%d')
        
        result = await session.execute(text(f"""
            SELECT oi.menu_item_name, SUM(oi.quantity), SUM(oi.quantity * oi.unit_price), SUM(oi.quantity * oi.unit_cost) 
            FROM order_items oi
            JOIN orders o ON oi.order_id = o.id
            WHERE o.created_at >= '{today} 00:00:00'
            GROUP BY oi.menu_item_name
        """))
        print(f"{'Item':<20} | {'Qty':<5} | {'Revenue':<10} | {'COGS':<10} | {'Profit':<10}")
        print("-" * 65)
        for row in result.fetchall():
            name = row[0]
            qty = row[1]
            rev = row[2]
            cogs = row[3]
            profit = rev - cogs
            # Need to print ASCII compatible if cp1252 is an issue, but let's just print numbers
            print(f"Item_{hash(name) % 1000:<15} | {qty:<5} | {rev:<10} | {cogs:<10} | {profit:<10}")

if __name__ == "__main__":
    asyncio.run(main())
