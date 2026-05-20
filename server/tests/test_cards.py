import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

import src.cards.service as cards_service
from src.cards.ai_service import GeminiService
from src.cards.dependencies import get_gemini_service, get_libretranslate_client
from src.cards.models import Card
from src.cards.translator import LibreTranslateClient
from src.main import app
from src.sessions.models import Session


class _FakeGemini(GeminiService):
    def __init__(self) -> None:
        pass  # skip real client init

    async def generate_example(
        self, source_text: str, translated_text: str, context: str | None
    ) -> str:
        return f"She felt {source_text} about the outcome."


@pytest.fixture(autouse=True)
def _override_gemini():
    app.dependency_overrides[get_gemini_service] = lambda: _FakeGemini()
    yield
    app.dependency_overrides.pop(get_gemini_service, None)


async def _seed_card(db: AsyncSession) -> Card:
    session = Session(name="Test Session", source="book-ch1")
    db.add(session)
    await db.flush()
    card = Card(
        session_id=session.id,
        source_text="ephemeral",
        translated_text="efémero",
        context="It was an ephemeral moment of joy.",
    )
    db.add(card)
    await db.commit()
    await db.refresh(card)
    return card


@pytest.mark.asyncio
async def test_generate_example_returns_sentence(
    client: AsyncClient, db_session: AsyncSession
):
    card = await _seed_card(db_session)
    resp = await client.post(f"/cards/{card.id}/example")
    assert resp.status_code == 200
    body = resp.json()
    assert "example_sentence" in body
    assert isinstance(body["example_sentence"], str)
    assert len(body["example_sentence"]) > 0


@pytest.mark.asyncio
async def test_generate_example_not_found(client: AsyncClient):
    resp = await client.post("/cards/99999/example")
    assert resp.status_code == 404
    assert resp.json()["error"] == "not_found"


# ---------------------------------------------------------------------------
# POST /sessions/{id}/cards — batch add
# ---------------------------------------------------------------------------


class _FakeTranslator(LibreTranslateClient):
    def __init__(self) -> None:
        self.call_count = 0

    async def translate_batch(
        self, texts: list[str], source_lang: str, target_lang: str
    ) -> list[str]:
        self.call_count += 1
        return [f"[pt] {t}" for t in texts]


_fake_translator = _FakeTranslator()


@pytest.fixture(autouse=True)
def _override_translator():
    _fake_translator.call_count = 0
    app.dependency_overrides[get_libretranslate_client] = lambda: _fake_translator
    yield
    app.dependency_overrides.pop(get_libretranslate_client, None)


@pytest.fixture
def _mock_redis_all_miss(monkeypatch):
    async def fake_mget(keys: list[str]) -> list[str | None]:
        return [None] * len(keys)

    async def fake_set(key: str, value: str, ttl: int | None = None) -> None:
        pass

    monkeypatch.setattr(cards_service, "mget_translations", fake_mget)
    monkeypatch.setattr(cards_service, "set_translation", fake_set)


@pytest.fixture
def _mock_redis_all_hit(monkeypatch):
    async def fake_mget(keys: list[str]) -> list[str | None]:
        return ["[redis] hit" for _ in keys]

    async def fake_set(key: str, value: str, ttl: int | None = None) -> None:
        pass

    monkeypatch.setattr(cards_service, "mget_translations", fake_mget)
    monkeypatch.setattr(cards_service, "set_translation", fake_set)


async def _create_session(client: AsyncClient, name: str = "Batch Session") -> int:
    resp = await client.post("/sessions", json={"name": name})
    assert resp.status_code == 201
    return resp.json()["id"]


@pytest.mark.asyncio
async def test_batch_add_all_misses(client: AsyncClient, _mock_redis_all_miss):
    sid = await _create_session(client)
    resp = await client.post(
        f"/sessions/{sid}/cards",
        json={
            "items": [
                {"source_text": "ephemeral", "context": "an ephemeral moment"},
                {"source_text": "serendipity"},
            ]
        },
    )
    assert resp.status_code == 201
    cards = resp.json()
    assert len(cards) == 2
    texts = {c["source_text"] for c in cards}
    assert texts == {"ephemeral", "serendipity"}
    assert all(c["translated_text"].startswith("[pt]") for c in cards)
    assert _fake_translator.call_count == 1


@pytest.mark.asyncio
async def test_batch_add_all_cache_hits(client: AsyncClient, _mock_redis_all_hit):
    sid = await _create_session(client)
    resp = await client.post(
        f"/sessions/{sid}/cards",
        json={"items": [{"source_text": "melange"}, {"source_text": "spice"}]},
    )
    assert resp.status_code == 201
    cards = resp.json()
    assert len(cards) == 2
    assert all(c["translated_text"] == "[redis] hit" for c in cards)
    assert _fake_translator.call_count == 0


@pytest.mark.asyncio
async def test_batch_add_mixed_hits_and_misses(client: AsyncClient, monkeypatch):
    import hashlib

    melange_hash = hashlib.sha256("melange".encode()).hexdigest()

    async def fake_mget(keys: list[str]) -> list[str | None]:
        return ["[redis] hit" if melange_hash in key else None for key in keys]

    async def fake_set(key: str, value: str, ttl: int | None = None) -> None:
        pass

    monkeypatch.setattr(cards_service, "mget_translations", fake_mget)
    monkeypatch.setattr(cards_service, "set_translation", fake_set)

    sid = await _create_session(client)
    resp = await client.post(
        f"/sessions/{sid}/cards",
        json={"items": [{"source_text": "melange"}, {"source_text": "arrakis"}]},
    )
    assert resp.status_code == 201
    cards = resp.json()
    assert len(cards) == 2
    by_text = {c["source_text"]: c["translated_text"] for c in cards}
    assert by_text["melange"] == "[redis] hit"
    assert by_text["arrakis"] == "[pt] arrakis"
    assert _fake_translator.call_count == 1


@pytest.mark.asyncio
async def test_batch_add_deduplicates_source_text(client: AsyncClient, _mock_redis_all_miss):
    sid = await _create_session(client)
    resp = await client.post(
        f"/sessions/{sid}/cards",
        json={"items": [{"source_text": "ephemeral"}, {"source_text": "ephemeral"}]},
    )
    assert resp.status_code == 201
    assert len(resp.json()) == 1


@pytest.mark.asyncio
async def test_batch_add_idempotent(client: AsyncClient, _mock_redis_all_miss):
    sid = await _create_session(client)
    payload = {"items": [{"source_text": "ephemeral"}]}
    r1 = await client.post(f"/sessions/{sid}/cards", json=payload)
    r2 = await client.post(f"/sessions/{sid}/cards", json=payload)
    assert r1.status_code == 201
    assert r2.status_code == 201
    assert r1.json()[0]["id"] == r2.json()[0]["id"]


@pytest.mark.asyncio
async def test_batch_add_session_not_found(client: AsyncClient, _mock_redis_all_miss):
    resp = await client.post(
        "/sessions/99999/cards",
        json={"items": [{"source_text": "ghost"}]},
    )
    assert resp.status_code == 404
    assert resp.json()["error"] == "not_found"


@pytest.mark.asyncio
async def test_batch_add_empty_items_rejected(client: AsyncClient):
    sid = await _create_session(client)
    resp = await client.post(f"/sessions/{sid}/cards", json={"items": []})
    assert resp.status_code == 422
