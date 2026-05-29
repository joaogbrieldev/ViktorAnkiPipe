from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field

from src.cards.schemas import CardOut


class SessionCreate(BaseModel):
    name: str = Field(min_length=1, max_length=255)
    source: str | None = Field(default=None, max_length=500)


class SessionOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    source: str | None
    created_at: datetime


class SessionWithCards(SessionOut):
    cards: list[CardOut] = []
