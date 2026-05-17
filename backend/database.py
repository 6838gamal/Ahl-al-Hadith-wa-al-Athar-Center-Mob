import os
import asyncpg
from typing import Optional

_pool: Optional[asyncpg.Pool] = None


def _get_dsn() -> str:
    return os.environ.get("RENDER_DATABASE_URL") or os.environ["DATABASE_URL"]


async def get_pool() -> asyncpg.Pool:
    global _pool
    if _pool is None:
        _pool = await asyncpg.create_pool(
            dsn=_get_dsn(),
            min_size=2,
            max_size=10,
            statement_cache_size=0,
        )
    return _pool


async def close_pool():
    global _pool
    if _pool:
        await _pool.close()
        _pool = None


async def get_conn():
    pool = await get_pool()
    async with pool.acquire() as conn:
        yield conn
