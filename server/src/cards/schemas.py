from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class CardCreate(BaseModel):
    source_text: str = Field(min_length=1)
    context: str | None = None


class CardBatchIn(BaseModel):
    items: list[CardCreate] = Field(min_length=1)
    source_lang: str = "en"
    target_lang: str = "pt"


class CardOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    session_id: int
    source_text: str
    translated_text: str
    context: str | None
    created_at: datetime


class ExampleOut(BaseModel):
    example_sentence: str
