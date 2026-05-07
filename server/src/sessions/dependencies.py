from typing import Annotated

from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

from src.database import get_db
from src.sessions.models import Session as SessionRow
from src.sessions.service import get_session_by_id

DbDep = Annotated[AsyncSession, Depends(get_db)]


async def valid_session_id(session_id: int, db: DbDep) -> SessionRow:
    return await get_session_by_id(db, session_id)


SessionDep = Annotated[SessionRow, Depends(valid_session_id)]
