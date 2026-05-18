from typing import Annotated

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from src.cards import service as cards_service
from src.cards.dependencies import LibreTranslateDep
from src.cards.schemas import CardBatchIn, CardOut
from src.database import get_db
from src.sessions import service
from src.sessions.dependencies import SessionDep
from src.sessions.schemas import SessionCreate, SessionOut, SessionWithCards

router = APIRouter(prefix="/sessions", tags=["sessions"])

DbDep = Annotated[AsyncSession, Depends(get_db)]


@router.post("", response_model=SessionOut, status_code=status.HTTP_201_CREATED)
async def create_session(body: SessionCreate, db: DbDep) -> SessionOut:
    return await service.create_session(db, body)


@router.get("", response_model=list[SessionOut])
async def list_sessions(db: DbDep, source: str | None = None) -> list[SessionOut]:
    return await service.list_sessions(db, source=source)


@router.get("/{session_id}", response_model=SessionWithCards)
async def get_session(session: SessionDep) -> SessionWithCards:
    return session


@router.delete("/{session_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_session(session_id: int, db: DbDep) -> None:
    await service.delete_session(db, session_id)


@router.post(
    "/{session_id}/cards",
    response_model=list[CardOut],
    status_code=status.HTTP_201_CREATED,
    summary="Batch add cards",
    description=(
        "Translates each source_text via Redis cache (MGET) + LibreTranslate for misses, "
        "persists cards idempotently, and returns all resulting cards."
    ),
)
async def add_cards(
    session: SessionDep,
    body: CardBatchIn,
    db: DbDep,
    translator: LibreTranslateDep,
) -> list[CardOut]:
    return await cards_service.batch_add_cards(
        db,
        session.id,
        body.items,
        translator,
        body.source_lang,
        body.target_lang,
    )

