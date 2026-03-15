from datetime import datetime
from uuid import UUID, uuid4

from sqlalchemy import Enum, String, UniqueConstraint, func
from sqlalchemy.orm import Mapped, mapped_column

from main.core.models import BaseDbModel
from main.features.auth.schema.enums import OAuthProvider


class User(BaseDbModel):
    __tablename__ = "user"
    __table_args__ = (UniqueConstraint("oauth_provider", "oauth_sub"),)

    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    email: Mapped[str] = mapped_column(
        String(255), unique=True, nullable=False, index=True
    )
    oauth_provider: Mapped[OAuthProvider] = mapped_column(
        Enum(OAuthProvider, native_enum=False),
        nullable=False,
        index=True,
    )
    oauth_sub: Mapped[str] = mapped_column(String(255), nullable=False, index=True)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    avatar_url: Mapped[str | None] = mapped_column(String(2048), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        nullable=False, server_default=func.now()
    )
