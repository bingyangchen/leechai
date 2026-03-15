from main.core.schema.base import BaseDataModel


class GoogleLoginRequest(BaseDataModel):
    id_token: str
