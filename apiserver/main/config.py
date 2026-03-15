from functools import cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env", env_file_encoding="utf-8", case_sensitive=True
    )

    DATABASE_URL: str = "postgresql+asyncpg://postgres:password@db:5432/leechai"
    LOG_LEVEL: str = "INFO"
    SQL_LOG: bool = False


@cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
