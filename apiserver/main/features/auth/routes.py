from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException

from main.features.auth.schema.requests import GoogleLoginRequest
from main.features.auth.schema.responses import LoginResponse
from main.features.auth.services import AuthService

router = APIRouter()


@router.post("/login/google")
async def google_login(
    body: GoogleLoginRequest,
    auth_service: Annotated[AuthService, Depends(AuthService)],
) -> LoginResponse:
    try:
        user, token = await auth_service.login_with_google(body.id_token)
    except ValueError as err:
        raise HTTPException(status_code=401, detail="Invalid Google ID token") from err

    return LoginResponse(
        token=token,
        user_id=str(user.id),
        display_name=user.name,
        email=user.email,
        avatar_url=user.avatar_url,
    )
