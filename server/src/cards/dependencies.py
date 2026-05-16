from functools import lru_cache
from typing import Annotated

from fastapi import Depends

from src.cards.ai_service import GeminiService
from src.cards.translator import LibreTranslateClient
from src.config import settings


@lru_cache
def get_gemini_service() -> GeminiService:
    return GeminiService(api_key=settings.GEMINI_API_KEY)


@lru_cache
def get_libretranslate_client() -> LibreTranslateClient:
    return LibreTranslateClient(base_url=settings.LIBRETRANSLATE_URL)


GeminiDep = Annotated[GeminiService, Depends(get_gemini_service)]
LibreTranslateDep = Annotated[LibreTranslateClient, Depends(get_libretranslate_client)]
