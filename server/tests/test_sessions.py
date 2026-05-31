import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from src.cards.models import Card
from src.sessions.models import Session


@pytest.mark.asyncio
async def test_create_session(client: AsyncClient):
    resp = await client.post("/sessions", json={"name": "My Reading"})
    assert resp.status_code == 201
    data = resp.json()
    assert data["name"] == "My Reading"
    assert data["source"] is None
    assert "id" in data


@pytest.mark.asyncio
async def test_create_session_with_source(client: AsyncClient):
    resp = await client.post(
        "/sessions",
        json={"name": "HP Session", "source": "Harry Potter ch.1"},
    )
    assert resp.status_code == 201
    assert resp.json()["source"] == "Harry Potter ch.1"


@pytest.mark.asyncio
async def test_list_sessions_empty(client: AsyncClient):
    resp = await client.get("/sessions")
    assert resp.status_code == 200
    assert resp.json() == []


@pytest.mark.asyncio
async def test_list_sessions(client: AsyncClient):
    await client.post("/sessions", json={"name": "Session A"})
    await client.post("/sessions", json={"name": "Session B"})
    resp = await client.get("/sessions")
    assert resp.status_code == 200
    data = resp.json()
    assert len(data) == 2
    assert all(item["card_count"] == 0 for item in data)


@pytest.mark.asyncio
async def test_list_sessions_includes_card_count(
    client: AsyncClient, db_session: AsyncSession
):
    session = Session(name="With Cards")
    db_session.add(session)
    await db_session.flush()
    db_session.add_all(
        [
            Card(session_id=session.id, source_text="hello", translated_text="olá"),
            Card(session_id=session.id, source_text="world", translated_text="mundo"),
        ]
    )
    await db_session.commit()

    resp = await client.get("/sessions")
    assert resp.status_code == 200
    match = next(item for item in resp.json() if item["id"] == session.id)
    assert match["card_count"] == 2


@pytest.mark.asyncio
async def test_list_sessions_filter_by_source(client: AsyncClient):
    await client.post("/sessions", json={"name": "HP", "source": "Harry Potter ch.1"})
    await client.post("/sessions", json={"name": "LotR", "source": "LotR ch.1"})
    resp = await client.get("/sessions?source=Harry Potter ch.1")
    assert resp.status_code == 200
    results = resp.json()
    assert len(results) == 1
    assert results[0]["name"] == "HP"


@pytest.mark.asyncio
async def test_get_session(client: AsyncClient):
    created = (await client.post("/sessions", json={"name": "Test"})).json()
    resp = await client.get(f"/sessions/{created['id']}")
    assert resp.status_code == 200
    data = resp.json()
    assert data["id"] == created["id"]
    assert data["cards"] == []


@pytest.mark.asyncio
async def test_get_session_not_found(client: AsyncClient):
    resp = await client.get("/sessions/999")
    assert resp.status_code == 404
    assert resp.json()["error"] == "not_found"


@pytest.mark.asyncio
async def test_delete_session(client: AsyncClient):
    created = (await client.post("/sessions", json={"name": "ToDelete"})).json()
    resp = await client.delete(f"/sessions/{created['id']}")
    assert resp.status_code == 204
    resp = await client.get(f"/sessions/{created['id']}")
    assert resp.status_code == 404


@pytest.mark.asyncio
async def test_delete_session_not_found(client: AsyncClient):
    resp = await client.delete("/sessions/999")
    assert resp.status_code == 404


@pytest.mark.asyncio
async def test_create_session_name_too_short(client: AsyncClient):
    resp = await client.post("/sessions", json={"name": ""})
    assert resp.status_code == 422
