import asyncio
import asyncpg
import sys
import os
sys.path.append('D:\\Mynix_Control\\SCafe')
from app.config import settings

async def main():
    db_url = str(settings.database_url).replace("+asyncpg", "")
    conn = await asyncpg.connect(db_url)
    try:
        print("Adding attributes to menu_items...")
        await conn.execute("ALTER TABLE menu_items ADD COLUMN IF NOT EXISTS attributes JSONB DEFAULT '{}'::jsonb;")
        
        print("Adding attributes to ingredients...")
        await conn.execute("ALTER TABLE ingredients ADD COLUMN IF NOT EXISTS attributes JSONB DEFAULT '{}'::jsonb;")
        
        print("Done!")
    except Exception as e:
        print(f"Error: {e}")
    finally:
        await conn.close()

if __name__ == "__main__":
    asyncio.run(main())
