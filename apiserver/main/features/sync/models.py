from __future__ import annotations

from datetime import datetime
from uuid import UUID

from sqlalchemy import Index, Integer, String, func
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.schema import ForeignKey, PrimaryKeyConstraint

from main.core.models import BaseDbModel


class Entry(BaseDbModel):
    __tablename__ = "entry"
    __table_args__ = (
        PrimaryKeyConstraint("user_id", "id"),
        Index("ix_entry_user_id_server_updated_at", "user_id", "server_updated_at"),
    )

    user_id: Mapped[UUID] = mapped_column(
        ForeignKey("user.id", ondelete="CASCADE"), nullable=False
    )
    id: Mapped[str] = mapped_column(String(36))
    type: Mapped[str] = mapped_column(String(32), nullable=False)
    debit_account_id: Mapped[str] = mapped_column(String(36), nullable=False)
    credit_account_id: Mapped[str] = mapped_column(String(36), nullable=False)
    amount: Mapped[float] = mapped_column(nullable=False)
    memo: Mapped[str | None] = mapped_column(String, nullable=True)
    occurred_at: Mapped[datetime] = mapped_column(nullable=False)
    created_at: Mapped[datetime] = mapped_column(nullable=False)
    updated_at: Mapped[datetime] = mapped_column(nullable=False, index=True)
    deleted_at: Mapped[datetime | None] = mapped_column(nullable=True)
    server_updated_at: Mapped[datetime] = mapped_column(
        nullable=False, server_default=func.now()
    )


class Account(BaseDbModel):
    __tablename__ = "account"
    __table_args__ = (
        PrimaryKeyConstraint("user_id", "id"),
        Index("ix_account_user_id_server_updated_at", "user_id", "server_updated_at"),
    )

    user_id: Mapped[UUID] = mapped_column(
        ForeignKey("user.id", ondelete="CASCADE"), nullable=False
    )
    id: Mapped[str] = mapped_column(String(36))
    type: Mapped[str] = mapped_column(String(32), nullable=False)
    sub_type: Mapped[str] = mapped_column(String(64), nullable=False)
    name: Mapped[str | None] = mapped_column(String(255), nullable=True)
    icon: Mapped[str | None] = mapped_column(String(64), nullable=True)
    initial_balance: Mapped[float] = mapped_column(nullable=False, default=0)
    last_used_at: Mapped[datetime] = mapped_column(nullable=False)
    created_at: Mapped[datetime] = mapped_column(nullable=False)
    updated_at: Mapped[datetime] = mapped_column(nullable=False, index=True)
    deleted_at: Mapped[datetime | None] = mapped_column(nullable=True)
    server_updated_at: Mapped[datetime] = mapped_column(
        nullable=False, server_default=func.now()
    )


class Tag(BaseDbModel):
    __tablename__ = "tag"
    __table_args__ = (
        PrimaryKeyConstraint("user_id", "id"),
        Index("ix_tag_user_id_server_updated_at", "user_id", "server_updated_at"),
    )
    user_id: Mapped[UUID] = mapped_column(
        ForeignKey("user.id", ondelete="CASCADE"), nullable=False
    )
    id: Mapped[str] = mapped_column(String(36))
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    created_at: Mapped[datetime] = mapped_column(nullable=False)
    updated_at: Mapped[datetime] = mapped_column(nullable=False, index=True)
    deleted_at: Mapped[datetime | None] = mapped_column(nullable=True)
    server_updated_at: Mapped[datetime] = mapped_column(
        nullable=False, server_default=func.now()
    )


class EntryTag(BaseDbModel):
    __tablename__ = "entry_tag"
    __table_args__ = (
        PrimaryKeyConstraint("user_id", "entry_id", "tag_id"),
        Index("ix_entry_tag_user_id_server_updated_at", "user_id", "server_updated_at"),
    )

    user_id: Mapped[UUID] = mapped_column(
        ForeignKey("user.id", ondelete="CASCADE"), nullable=False
    )
    entry_id: Mapped[str] = mapped_column(String(36))
    tag_id: Mapped[str] = mapped_column(String(36))
    updated_at: Mapped[datetime] = mapped_column(nullable=False, index=True)
    deleted_at: Mapped[datetime | None] = mapped_column(nullable=True)
    server_updated_at: Mapped[datetime] = mapped_column(
        nullable=False, server_default=func.now()
    )


class Budget(BaseDbModel):
    __tablename__ = "budget"
    __table_args__ = (
        PrimaryKeyConstraint("user_id", "id"),
        Index("ix_budget_user_id_server_updated_at", "user_id", "server_updated_at"),
    )

    user_id: Mapped[UUID] = mapped_column(
        ForeignKey("user.id", ondelete="CASCADE"), nullable=False
    )
    id: Mapped[str] = mapped_column(String(36))
    year: Mapped[int] = mapped_column(Integer(), nullable=False)
    month: Mapped[int] = mapped_column(Integer(), nullable=False)
    total_amount: Mapped[float] = mapped_column(nullable=False)
    created_at: Mapped[datetime] = mapped_column(nullable=False)
    updated_at: Mapped[datetime] = mapped_column(nullable=False, index=True)
    deleted_at: Mapped[datetime | None] = mapped_column(nullable=True)
    server_updated_at: Mapped[datetime] = mapped_column(
        nullable=False, server_default=func.now()
    )


class CategoryBudget(BaseDbModel):
    __tablename__ = "category_budget"
    __table_args__ = (
        PrimaryKeyConstraint("user_id", "id"),
        Index(
            "ix_category_budget_user_id_server_updated_at",
            "user_id",
            "server_updated_at",
        ),
    )

    user_id: Mapped[UUID] = mapped_column(
        ForeignKey("user.id", ondelete="CASCADE"), nullable=False
    )
    id: Mapped[str] = mapped_column(String(36))
    year: Mapped[int] = mapped_column(Integer(), nullable=False)
    month: Mapped[int] = mapped_column(Integer(), nullable=False)
    account_id: Mapped[str] = mapped_column(String(36), nullable=False)
    amount: Mapped[float] = mapped_column(nullable=False)
    created_at: Mapped[datetime] = mapped_column(nullable=False)
    updated_at: Mapped[datetime] = mapped_column(nullable=False, index=True)
    deleted_at: Mapped[datetime | None] = mapped_column(nullable=True)
    server_updated_at: Mapped[datetime] = mapped_column(
        nullable=False, server_default=func.now()
    )


class Achievement(BaseDbModel):
    __tablename__ = "achievement"
    __table_args__ = (
        PrimaryKeyConstraint("user_id", "id"),
        Index(
            "ix_achievement_user_id_server_updated_at", "user_id", "server_updated_at"
        ),
    )

    user_id: Mapped[UUID] = mapped_column(
        ForeignKey("user.id", ondelete="CASCADE"), nullable=False
    )
    id: Mapped[str] = mapped_column(String(64))
    progress: Mapped[int] = mapped_column(nullable=False, default=0)
    target: Mapped[int] = mapped_column(nullable=False)
    unlocked_at: Mapped[datetime | None] = mapped_column(nullable=True)
    completed_count: Mapped[int] = mapped_column(nullable=False, default=0)
    progress_period: Mapped[str | None] = mapped_column(String(64), nullable=True)
    is_notified: Mapped[bool] = mapped_column(nullable=False, default=False)
    created_at: Mapped[datetime] = mapped_column(nullable=False)
    updated_at: Mapped[datetime] = mapped_column(nullable=False, index=True)
    server_updated_at: Mapped[datetime] = mapped_column(
        nullable=False, server_default=func.now()
    )
