import asyncio
import httpx

async def main():
    async with httpx.AsyncClient() as client:
        res = await client.post('http://localhost:8000/api/v1/auth/token', data={'username': 'admin', 'password': 'password123'})
        # let's just create an item directly via service to bypass auth
        pass

