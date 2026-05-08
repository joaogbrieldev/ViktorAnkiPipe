import hashlib

import redis.asyncio as aioredis

from src.config import settings

_redis: aioredis.Redis | None = None


def get_redis() -> aioredis.Redis:
    global _redis
    if _redis is None:
        _redis = aioredis.from_url(settings.REDIS_URL, decode_responses=True)
    return _redis


def translation_key(source_lang: str, target_lang: str, text: str) -> str:
    h = hashlib.sha256(text.encode()).hexdigest()
    return f"translate:{source_lang}:{target_lang}:{h}"


async def mget_translations(keys: list[str]) -> list[str | None]:
    if not keys:
        return []
    r = get_redis()
    return await r.mget(*keys)  # type: ignore[return-value]


async def set_translation(key: str, value: str, ttl: int | None = None) -> None:
    r = get_redis()
    if ttl:
        await r.set(key, value, ex=ttl)
    else:
        await r.set(key, value)
