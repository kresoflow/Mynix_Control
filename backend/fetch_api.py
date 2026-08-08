import asyncio
import httpx

async def main():
    async with httpx.AsyncClient() as client:
        # First we need to find the correct tenant_id and token.
        # But wait, we can bypass auth by just importing and calling the router logic directly.
        pass

