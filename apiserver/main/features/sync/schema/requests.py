from pydantic import RootModel

from main.features.sync.schema.base import Changes


class SyncPushRequest(RootModel[Changes]):
    pass
