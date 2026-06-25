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
    jwt_secret: str = Field(
        default="change-me-in-production-use-a-strong-random-secret",
        validation_alias="JWT_SECRET",
    )
    jwt_algorithm: str = "HS256"
    jwt_expiry_minutes: int = Field(default=1440, validation_alias="JWT_EXPIRY_MINUTES")

    # Outgoing email (Gmail SMTP). smtp_user/smtp_password are intentionally
    # empty by default so the app still boots without mail configured; the
    # email layer raises loudly if a send is attempted while unconfigured.
    smtp_host: str = Field(default="smtp.gmail.com", validation_alias="SMTP_HOST")
    smtp_port: int = Field(default=465, validation_alias="SMTP_PORT")
    smtp_user: str = Field(default="", validation_alias="SMTP_USER")
    smtp_password: str = Field(default="", validation_alias="SMTP_PASSWORD")
    email_from: str = Field(
        default="Srushti.jujare06@gmail.com", validation_alias="EMAIL_FROM"
    )
    email_from_name: str = Field(
        default="SiteLedger", validation_alias="EMAIL_FROM_NAME"
    )
    otp_expiry_minutes: int = Field(default=10, validation_alias="OTP_EXPIRY_MINUTES")

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )


@lru_cache
def get_settings() -> Settings:
    return Settings()
