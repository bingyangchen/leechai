from main.core.schema.base import BaseDataModel


class LoginResponse(BaseDataModel):
    access_token: str
    refresh_token: str
    user_id: str
    display_name: str
    email: str
    avatar_url: str | None


class MeResponse(BaseDataModel):
    user_id: str
    display_name: str
    email: str
    avatar_url: str | None
