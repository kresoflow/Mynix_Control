import asyncio
import httpx

async def main():
    # we need to login to get a token
    async with httpx.AsyncClient() as client:
        # Instead of full login, I will just call the service method directly!
        pass

