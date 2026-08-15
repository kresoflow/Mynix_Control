import requests
import json

url = "http://127.0.0.1:8000/retail-product/"
headers = {
    "Content-Type": "application/json",
    "Authorization": "Bearer TEST_TOKEN" # I don't have a token, but I can check if it returns 422 before 401? Actually no, 401 is returned first.
}

payload = {
    "name": "Test Retail",
    "category_id": 1,
    "unit": "pcs",
    "purchase_price": 10.0,
    "selling_price": 20.0,
    "initial_stock": 0.0,
    "min_stock_alert": 0.0,
    "barcode": "123456789",
    "parent_id": None
}

# Instead of hitting the server, I'll just validate using Pydantic directly to see if barcode is accepted
import sys
import os
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', '..')))

from backend.app.inventory.routers.menu_router import RetailProductCreate

try:
    obj = RetailProductCreate(**payload)
    print("SUCCESS: ", obj.model_dump())
except Exception as e:
    print("ERROR: ", e)
