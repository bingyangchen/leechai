from main.core.schema.base import BaseDataModel


class GoogleLoginRequest(BaseDataModel):
    id_token: str


class RefreshTokenRequest(BaseDataModel):
    refresh_token: str


class LogoutRequest(BaseDataModel):
    refresh_token: str
