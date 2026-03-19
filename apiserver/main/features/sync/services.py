from __future__ import annotations

from datetime import UTC, datetime
from typing import Annotated
from uuid import UUID

from fastapi import Depends
from sqlalchemy import select
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.ext.asyncio import AsyncSession

from main.core.db import get_session
from main.features.sync.models import Account, Achievement, Entry, EntryTag, Tag
from main.features.sync.schema.base import (
    AccountChange,
    AchievementChange,
    Changes,
    EntryChange,
    EntryTagChange,
    TagChange,
)

MODEL_TO_CHANGE = {
    Entry: EntryChange,
    Account: AccountChange,
    Achievement: AchievementChange,
    Tag: TagChange,
    EntryTag: EntryTagChange,
}


def _utc_now() -> datetime:
    return datetime.now(tz=UTC)


class SyncService:
    def __init__(self, db_session: Annotated[AsyncSession, Depends(get_session)]):
        self._db_session = db_session

    async def pull(
        self, user_id: UUID, last_synced_at: datetime | None
    ) -> tuple[Changes, datetime]:
        changes = Changes()
        async with self._db_session.begin():
            for model in (Entry, Account, Achievement, Tag, EntryTag):
                statement = select(model).where(model.user_id == user_id)
                if last_synced_at is not None:
                    statement = statement.where(
                        model.server_updated_at > last_synced_at
                    )
                result = await self._db_session.execute(statement)
                rows = result.scalars().all()
                change_class = MODEL_TO_CHANGE[model]
                setattr(
                    changes,
                    model.__tablename__,
                    [change_class.model_validate(row) for row in rows],
                )

        return changes, _utc_now()

    async def push(self, user_id: UUID, changes: Changes) -> datetime:
        synced_at = _utc_now()
        async with self._db_session.begin():
            if entry_rows := changes.entry:
                values = [{**r.model_dump(), "user_id": user_id} for r in entry_rows]
                statement = insert(Entry).values(values)
                update_columns = {
                    "type": statement.excluded.type,
                    "debit_account_id": statement.excluded.debit_account_id,
                    "credit_account_id": statement.excluded.credit_account_id,
                    "amount": statement.excluded.amount,
                    "memo": statement.excluded.memo,
                    "occurred_at": statement.excluded.occurred_at,
                    "created_at": statement.excluded.created_at,
                    "updated_at": statement.excluded.updated_at,
                    "deleted_at": statement.excluded.deleted_at,
                    "server_updated_at": _utc_now(),
                }
                statement = statement.on_conflict_do_update(
                    index_elements=[Entry.user_id, Entry.id],
                    set_=update_columns,
                    where=statement.excluded.updated_at > Entry.updated_at,
                )
                await self._db_session.execute(statement)

            if account_rows := changes.account:
                values = [{**r.model_dump(), "user_id": user_id} for r in account_rows]
                statement = insert(Account).values(values)
                update_columns = {
                    "type": statement.excluded.type,
                    "sub_type": statement.excluded.sub_type,
                    "name": statement.excluded.name,
                    "icon": statement.excluded.icon,
                    "initial_balance": statement.excluded.initial_balance,
                    "last_used_at": statement.excluded.last_used_at,
                    "created_at": statement.excluded.created_at,
                    "updated_at": statement.excluded.updated_at,
                    "deleted_at": statement.excluded.deleted_at,
                    "server_updated_at": _utc_now(),
                }
                statement = statement.on_conflict_do_update(
                    index_elements=[Account.user_id, Account.id],
                    set_=update_columns,
                    where=statement.excluded.updated_at > Account.updated_at,
                )
                await self._db_session.execute(statement)

            if achievement_rows := changes.achievement:
                values = [
                    {**r.model_dump(), "user_id": user_id} for r in achievement_rows
                ]
                statement = insert(Achievement).values(values)
                update_columns = {
                    "progress": statement.excluded.progress,
                    "target": statement.excluded.target,
                    "unlocked_at": statement.excluded.unlocked_at,
                    "completed_count": statement.excluded.completed_count,
                    "progress_period": statement.excluded.progress_period,
                    "is_notified": statement.excluded.is_notified,
                    "created_at": statement.excluded.created_at,
                    "updated_at": statement.excluded.updated_at,
                    "server_updated_at": _utc_now(),
                }
                statement = statement.on_conflict_do_update(
                    index_elements=[Achievement.user_id, Achievement.id],
                    set_=update_columns,
                    where=statement.excluded.updated_at > Achievement.updated_at,
                )
                await self._db_session.execute(statement)

            if tag_rows := changes.tag:
                values = [{**r.model_dump(), "user_id": user_id} for r in tag_rows]
                statement = insert(Tag).values(values)
                update_columns = {
                    "title": statement.excluded.title,
                    "created_at": statement.excluded.created_at,
                    "updated_at": statement.excluded.updated_at,
                    "deleted_at": statement.excluded.deleted_at,
                    "server_updated_at": _utc_now(),
                }
                statement = statement.on_conflict_do_update(
                    index_elements=[Tag.user_id, Tag.id],
                    set_=update_columns,
                    where=statement.excluded.updated_at > Tag.updated_at,
                )
                await self._db_session.execute(statement)

            if entry_tag_rows := changes.entry_tag:
                values = [
                    {**r.model_dump(), "user_id": user_id} for r in entry_tag_rows
                ]
                statement = insert(EntryTag).values(values)
                update_columns = {
                    "updated_at": statement.excluded.updated_at,
                    "deleted_at": statement.excluded.deleted_at,
                    "server_updated_at": _utc_now(),
                }
                statement = statement.on_conflict_do_update(
                    index_elements=[
                        EntryTag.user_id,
                        EntryTag.entry_id,
                        EntryTag.tag_id,
                    ],
                    set_=update_columns,
                    where=statement.excluded.updated_at > EntryTag.updated_at,
                )
                await self._db_session.execute(statement)

        return synced_at
