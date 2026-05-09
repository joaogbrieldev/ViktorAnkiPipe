# src/config.py
import json
from typing import Any

from pydantic import Field, computed_field, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

from src.constants import Environment


class Config(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    DATABASE_URL: str = "sqlite+aiosqlite:///./data/viktor.db"

    ENVIRONMENT: Environment = Environment.DEVELOPMENT

    APP_NAME: str = "viktor-anki-pipe"
    APP_VERSION: str = "0.1.0"

    LIBRETRANSLATE_URL: str = "http://localhost:5001"
    REDIS_URL: str = "redis://localhost:6379"
    REDIS_CACHE_TTL_SECONDS: int | None = None
    ANTHROPIC_API_KEY: str = ""

    # Variável de ambiente como texto simples (evita json.loads em list[str] antes dos validators).
    cors_origins_env: str = Field(default="*", alias="CORS_ORIGINS")
    CORS_ALLOW_CREDENTIALS: bool = True

    @computed_field
    @property
    def CORS_ORIGINS(self) -> list[str]:
        return self._normalize_cors_origins(self.cors_origins_env)

    @staticmethod
    def _normalize_cors_origins(value: str) -> list[str]:
        s = value.strip()
        if not s:
            return ["*"]
        if s.startswith("["):
            parsed = json.loads(s)
            if isinstance(parsed, list):
                out = [str(x).strip() for x in parsed if str(x).strip()]
                return out or ["*"]
            return ["*"]
        return [p.strip() for p in s.split(",") if p.strip()] or ["*"]

    @field_validator("DATABASE_URL", mode="before")
    @classmethod
    def strip_and_async_sqlite_url(cls, v: Any) -> Any:
        if not isinstance(v, str):
            return v
        s = v.strip()
        if not s:
            return s
        if s.startswith("sqlite+aiosqlite://"):
            return s
        if s.startswith("sqlite://"):
            return f"sqlite+aiosqlite{s[6:]}"
        return v


settings = Config()
