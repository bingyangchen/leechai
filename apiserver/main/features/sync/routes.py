import logging
from datetime import datetime
from typing import Annotated

from fastapi import APIRouter, Depends, Query

from main.features.auth.dependencies import get_current_user
from main.features.auth.models import User
from main.features.sync.schema.requests import SyncPushRequest
from main.features.sync.schema.responses import SyncPullResponse, SyncPushResponse
from main.features.sync.services import SyncService

router = APIRouter()
logger = logging.getLogger(__name__)


@router.get("/pull")
async def pull(
    sync_service: Annotated[SyncService, Depends(SyncService)],
    user: Annotated[User, Depends(get_current_user)],
    last_synced_at: Annotated[datetime | None, Query(alias="lastSyncedAt")] = None,
) -> SyncPullResponse:
    changes, synced_at = await sync_service.pull(
        user_id=user.id, last_synced_at=last_synced_at
    )
    return SyncPullResponse(changes=changes, synced_at=synced_at)


@router.post("/push")
async def push(
    body: SyncPushRequest,
    sync_service: Annotated[SyncService, Depends(SyncService)],
    user: Annotated[User, Depends(get_current_user)],
) -> SyncPushResponse:
    synced_at = await sync_service.push(user_id=user.id, changes=body.root)
    return SyncPushResponse(synced_at=synced_at)
