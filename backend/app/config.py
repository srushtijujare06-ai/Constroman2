from functools import lru_cache

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "Constroman API"
    environment: str = "development"
    debug: bool = True
    database_url: str = Field(
        default="postgresql+psycopg://postgres:1134@localhost:5432/constroman",
        validation_alias="DATABASE_URL",
    )
    cors_origins: list[str] = [
        "http://localhost:3000",
        "http://127.0.0.1:3000",
    ]
    api_prefix: str = "/api/v1"
    default_page_size: int = 50
    max_page_size: int = 200

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )


@lru_cache
def get_settings() -> Settings:
    return Settings()
