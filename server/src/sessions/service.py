from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload
from datetime import datetime

from src.exceptions import NotFoundException
from src.sessions.models import Session as SessionRow
from src.sessions.schemas import SessionCreate


async def create_session(db: AsyncSession, body: SessionCreate) -> SessionRow:
    row = SessionRow(name=body.name, source=body.source, created_at=datetime.now())
    db.add(row)
    await db.commit()
    await db.refresh(row)
    return row


async def list_sessions(db: AsyncSession, source: str | None = None) -> list[SessionRow]:
    stmt = select(SessionRow).order_by(SessionRow.id.desc())
    if source is not None:
        stmt = stmt.where(SessionRow.source == source)
    result = await db.execute(stmt)
    return list(result.scalars().all())


async def get_session_by_id(db: AsyncSession, session_id: int) -> SessionRow:
    stmt = (
        select(SessionRow)
        .where(SessionRow.id == session_id)
        .options(selectinload(SessionRow.cards))
    )
    result = await db.execute(stmt)
    row = result.scalar_one_or_none()
    if not row:
        raise NotFoundException("Session not found")
    return row


async def delete_session(db: AsyncSession, session_id: int) -> None:
    row = await get_session_by_id(db, session_id)
    await db.delete(row)
    await db.commit()
