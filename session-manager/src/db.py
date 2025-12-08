import asyncpg
import asyncio
import dotenv
import os

dotenv.load_dotenv()

db_url = os.getenv("DATABASE_URL")

pool : asyncpg.Pool | None = None

async def get_pool() -> asyncpg.Pool:
    global pool
    if pool is None:
        pool = await asyncpg.create_pool(
            db_url,
            min_size=1,
            max_size=10
        )
    return pool

async def fetch_all(query: str, *args):
    pool = await get_pool()
    async with pool.acquire() as conn:
        return await conn.fetch(query, *args)

async def execute(query: str, *args):
    pool = await get_pool()
    async with pool.acquire() as conn:
        return await conn.execute(query, *args)
    
async def main():
    con = await fetch_all('SELECT * FROM "Campaign";')
    con = [dict(row) for row in con]
    print(con)

if __name__ == "__main__":
    asyncio.run(main())