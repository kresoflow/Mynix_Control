"""
Application configuration via environment variables.
Uses pydantic-settings for type-safe config with .env file support.
"""

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Central configuration loaded from environment variables or .env file."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
    )

    # ── Application ──────────────────────────────────────────────
    app_name: str = "Mynix Control"
    debug: bool = True

    # ── Database (PostgreSQL) ────────────────────────────────────
    database_url: str = "postgresql+asyncpg://mynix:mynix_secret@127.0.0.1:5444/mynix_control"
    database_url_sync: str = "postgresql+psycopg2://mynix:mynix_secret@127.0.0.1:5444/mynix_control"

    # ── Redis ────────────────────────────────────────────────────
    redis_url: str = "redis://127.0.0.1:6379/0"

    # ── JWT Authentication ───────────────────────────────────────
    secret_key: str = "CHANGE-ME-IN-PRODUCTION-USE-LONG-RANDOM-STRING"
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 480  # 8-hour shift

    # ── Seed defaults ────────────────────────────────────────────
    owner_default_username: str = "owner"
    owner_default_password: str = "mynix2025"
    
    # ── System Admin ─────────────────────────────────────────────
    system_admin_token: str = "super_secret_mynix_token_2026"

    # ── Monitoring & Alerting (Sentry & Telegram) ────────────────
    sentry_dsn: str = "https://ee579c86969f6643e4786fef0ebd98a6@o4511875643015168.ingest.de.sentry.io/4511875720544336"
    telegram_bot_token: str | None = None
    telegram_chat_id: str | None = None


settings = Settings()

