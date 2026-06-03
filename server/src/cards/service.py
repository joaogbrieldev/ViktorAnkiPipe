from sqlalchemy import select
from sqlalchemy.dialects.sqlite import insert as sqlite_insert
from sqlalchemy.ext.asyncio import AsyncSession

from src.cache.models import mget_translations, set_translation, translation_key
from src.cards.ai_service import GeminiService
from src.cards.exceptions import CardNotFoundException
from src.cards.models import Card
from src.cards.schemas import CardCreate
from src.cards.translator import LibreTranslateClient
from src.config import settings


async def get_example_sentence(
    db: AsyncSession,
    card_id: int,
    gemini: GeminiService,
) -> str:
    result = await db.execute(select(Card).where(Card.id == card_id))
    card = result.scalar_one_or_none()
    if card is None:
        raise CardNotFoundException()
    return await gemini.generate_example(
        card.source_text, card.translated_text, card.context
    )


async def batch_add_cards(
    db: AsyncSession,
    session_id: int,
    items: list[CardCreate],
    translator: LibreTranslateClient,
    source_lang: str = "en",
    target_lang: str = "pt",
) -> list[Card]:
    # Deduplicate by source_text, preserving first occurrence
    seen: set[str] = set()
    deduped: list[CardCreate] = []
    for item in items:
        if item.source_text not in seen:
            seen.add(item.source_text)
            deduped.append(item)

    # Single MGET for all cache keys
    keys = [translation_key(source_lang, target_lang, item.source_text) for item in deduped]
    cached_values = await mget_translations(keys)

    # Split into hits and misses
    translation_map: dict[str, str] = {}
    miss_texts: list[str] = []
    for item, cached in zip(deduped, cached_values):
        if cached is not None:
            translation_map[item.source_text] = cached
        else:
            miss_texts.append(item.source_text)

    # One batch call to LibreTranslate for misses only
    if miss_texts:
        translations = await translator.translate_batch(miss_texts, source_lang, target_lang)
        ttl = settings.REDIS_CACHE_TTL_SECONDS
        for text, translated in zip(miss_texts, translations):
            translation_map[text] = translated
            await set_translation(
                translation_key(source_lang, target_lang, text), translated, ttl
            )

    # Upsert — existing cards are kept as-is (idempotent)
    rows = [
        {
            "session_id": session_id,
            "source_text": item.source_text,
            "translated_text": translation_map[item.source_text],
            "context": item.context,
        }
        for item in deduped
    ]
    await db.execute(sqlite_insert(Card).values(rows).on_conflict_do_nothing())
    await db.commit()

    source_texts = [item.source_text for item in deduped]
    result = await db.execute(
        select(Card)
        .where(Card.session_id == session_id, Card.source_text.in_(source_texts))
        .order_by(Card.id)
    )
    return list(result.scalars().all())


async def list_cards(db: AsyncSession, source: str | None = None) -> list[Card]:
    stmt = select(Card).order_by(Card.id.desc())
    result = await db.execute(stmt)
    return list(result.scalars().all())


async def delete_card(db: AsyncSession, session_id: int, card_id: int) -> None:
    result = await db.execute(
        select(Card).where(Card.id == card_id, Card.session_id == session_id)
    )
    card = result.scalar_one_or_none()
    if card is None:
        raise CardNotFoundException()
    await db.delete(card)
    await db.commit()