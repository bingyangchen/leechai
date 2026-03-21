from enum import StrEnum
from functools import cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Environment(StrEnum):
    development = "dev"
    production = "prod"


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env", env_file_encoding="utf-8", case_sensitive=True
    )

    ENVIRONMENT: Environment
    DATABASE_URL: str
    GOOGLE_WEB_CLIENT_ID: str
    GOOGLE_IOS_CLIENT_ID: str
    GOOGLE_ANDROID_CLIENT_ID: str
    JWT_SECRET: str
    JWT_ALGORITHM: str = "HS256"
    JWT_ACCESS_TOKEN_EXPIRE_SECONDS: int = 300
    JWT_REFRESH_TOKEN_EXPIRE_SECONDS: int = 365 * 24 * 3600
    LOG_LEVEL: str = "INFO"
    SQL_LOG: bool = False


@cache
def get_settings() -> Settings:
    return Settings()  # type: ignore


settings = get_settings()
