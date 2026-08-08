import asyncio
import httpx

async def main():
    async with httpx.AsyncClient() as client:
        # Get token
        res = await client.post('http://localhost:8000/api/v1/auth/token', data={'username': 'admin', 'password': 'password'})
        token = res.json().get('access_token')
        if not token:
            print('Failed to get token:', res.json())
            return
        
        res = await client.get('http://localhost:8000/api/v1/menu/', headers={'Authorization': f'Bearer {token}', 'x-tenant-id': 'tenant_1'})
        items = res.json()
        print('Total items via API:', len(items))
        q_items = [i for i in items if 'TOP' in i.get('name', '') or 'MEGA' in i.get('name', '')]
        for i in q_items:
            print(i.get('id'), i.get('name'))

asyncio.run(main())
