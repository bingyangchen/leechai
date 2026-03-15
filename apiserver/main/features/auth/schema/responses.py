from main.core.schema.base import BaseDataModel


class LoginResponse(BaseDataModel):
    token: str
    user_id: str
    display_name: str
    email: str
    avatar_url: str | None
