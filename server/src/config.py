# src/config.py
from typing import Any

from pydantic import field_validator
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

    CORS_ORIGINS: list[str] = ["*"]
    CORS_ALLOW_CREDENTIALS: bool = True

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
        return s

    @field_validator("CORS_ORIGINS", mode="before")
    @classmethod
    def split_cors_origins(cls, v: Any) -> Any:
        if isinstance(v, str):
            s = v.strip()
            if not s:
                return ["*"]
            if s.startswith("["):
                return s
            return [p.strip() for p in s.split(",") if p.strip()] or ["*"]
        return v


settings = Config()
