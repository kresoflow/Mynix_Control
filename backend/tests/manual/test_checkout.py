import asyncio
import httpx

async def main():
    async with httpx.AsyncClient() as client:
        # Get token
        res = await client.post('http://localhost:8000/api/v1/auth/login', data={'username': 'admin', 'password': 'password123'})
        token = res.json().get('access_token')
        if not token:
            print('No token', res.text)
            return

        headers = {
            'Authorization': f'Bearer {token}',
            'x-tenant-id': 'tenant_1'
        }

        # Try to checkout a fake item
        # First get menu to find an ID
        menu_res = await client.get('http://localhost:8000/api/v1/menu/', headers=headers)
        if menu_res.status_code != 200:
            print('Menu error:', menu_res.text)
            return
        
        items = menu_res.json()
        if not items:
            print('No items')
            return
            
        first_item = items[0]
        item_id = first_item['id']
        
        # Now checkout
        order_data = {
            'items': [
                {
                    'menu_item_id': item_id,
                    'quantity': 2,
                    'unit_price_override': 123.45,
                    'options_json': '"{\"some\": \"options\"}"'
                }
            ],
            'payment_method': 'cash'
        }
        order_res = await client.post('http://localhost:8000/api/v1/orders/', json=order_data, headers=headers)
        print('Order created:', order_res.status_code, order_res.text)

asyncio.run(main())
