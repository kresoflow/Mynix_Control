import httpx
import asyncio

async def main():
    async with httpx.AsyncClient() as client:
        res = await client.post('http://localhost:8000/api/v1/auth/token', data={'username': 'admin', 'password': 'password123'})
        token = res.json().get('access_token')
        res = await client.get('http://localhost:8000/api/v1/menu/', headers={'Authorization': f'Bearer {token}', 'x-tenant-id': 'tenant_1'})
        items = res.json()
        print('Total items:', len(items))
        for item in items:
            if 'Q' in item.get('name', ''):
                print(item)

asyncio.run(main())
