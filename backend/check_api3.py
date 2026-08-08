import asyncio
import httpx

async def main():
    async with httpx.AsyncClient() as client:
        res = await client.post('http://localhost:8000/api/v1/auth/token', data={'username': 'admin', 'password': 'password123'})
        token = res.json().get('access_token')
        res = await client.get('http://localhost:8000/api/v1/menu/', headers={'Authorization': f'Bearer {token}', 'x-tenant-id': 'tenant_1'})
        items = res.json()
        if isinstance(items, dict):
            print(items)
        else:
            for item in items:
                if 'Q' in item.get('name', ''):
                    print(item.get('name'))

asyncio.run(main())
