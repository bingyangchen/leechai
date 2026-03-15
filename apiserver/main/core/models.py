from datetime import datetime
from uuid import UUID

from sqlalchemy.dialects.postgresql import UUID as PG_UUID
from sqlalchemy.orm import DeclarativeBase
from sqlalchemy.types import DateTime


class BaseDbModel(DeclarativeBase):
    type_annotation_map = {
        UUID: PG_UUID(as_uuid=True),
        datetime: DateTime(timezone=True),
    }
