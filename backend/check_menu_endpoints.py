import asyncio
from sqlalchemy.ext.asyncio import create_async_engine
from app.config import settings

def read_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        print(f.read())

read_file('app/inventory/routers/menu_router.py')

