from typing import Annotated

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from src.cards import service
from src.cards.dependencies import GeminiDep
from src.cards.schemas import CardOut, ExampleOut
from src.database import get_db

router = APIRouter(prefix="/cards", tags=["cards"])

DbDep = Annotated[AsyncSession, Depends(get_db)]


@router.post(
    "/{card_id}/example",
    response_model=ExampleOut,
    status_code=status.HTTP_200_OK,
    summary="Generate example sentence",
    description=(
        "Calls Gemini 2.5 Flash to generate a contextual English example sentence "
        "for the word stored in the card."
    ),
)
async def generate_example(card_id: int, db: DbDep, gemini: GeminiDep) -> ExampleOut:
    sentence = await service.get_example_sentence(db, card_id, gemini)
    return ExampleOut(example_sentence=sentence)

@router.get("", response_model=list[CardOut])
async def list_cards(db: DbDep, source: str | None = None) -> list[CardOut]:
    cards = await service.list_cards(db, source=source)
    return [CardOut.model_validate(c) for c in cards]
