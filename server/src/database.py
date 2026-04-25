from __future__ import annotations

from collections.abc import AsyncIterator
from pathlib import Path

from sqlalchemy import event
from sqlalchemy.engine import make_url
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.orm import DeclarativeBase

from src.config import settings
from src.constants import Environment


def _ensure_data_dir(url: str) -> None:
    parsed = make_url(url)
    if "sqlite" not in parsed.drivername or not parsed.database:
        return
    path = Path(parsed.database)
    if not path.is_absolute():
        path = (Path.cwd() / path).resolve()
    path.parent.mkdir(parents=True, exist_ok=True)


_ensure_data_dir(str(settings.DATABASE_URL))


class Base(DeclarativeBase):
    """Classe base para os modelos ORM. Os modelos herdam: `class Deck(Base): ...`"""


def _on_sqlite_connect(dbapi_connection, _connection_record):
    if "sqlite" not in str(type(dbapi_connection)).lower():
        return
    cursor = dbapi_connection.cursor()
    cursor.execute("PRAGMA foreign_keys=ON")
    cursor.close()


engine = create_async_engine(
    str(settings.DATABASE_URL),
    echo=settings.ENVIRONMENT == Environment.DEVELOPMENT,
    pool_pre_ping=True,
)

event.listen(engine.sync_engine, "connect", _on_sqlite_connect)

async_session_factory = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autoflush=False,
    autocommit=False,
)


async def get_db() -> AsyncIterator[AsyncSession]:
    async with async_session_factory() as session:
        yield session
