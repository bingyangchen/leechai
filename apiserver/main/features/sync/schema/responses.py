from datetime import datetime

from main.core.schema.base import BaseDataModel
from main.features.sync.schema.base import Changes


class SyncPullResponse(BaseDataModel):
    changes: Changes
    synced_at: datetime


class SyncPushResponse(BaseDataModel):
    synced_at: datetime
