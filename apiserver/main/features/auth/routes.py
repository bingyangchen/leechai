import logging
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException

from main.features.auth.dependencies import get_current_user
from main.features.auth.models import User
from main.features.auth.schema.requests import GoogleLoginRequest
from main.features.auth.schema.responses import LoginResponse, MeResponse
from main.features.auth.services import AuthService

router = APIRouter()
logger = logging.getLogger(__name__)


@router.post("/login/google")
async def google_login(
    body: GoogleLoginRequest,
    auth_service: Annotated[AuthService, Depends(AuthService)],
) -> LoginResponse:
    try:
        user, token = await auth_service.login_with_google(body.id_token)
    except ValueError as e:
        logger.error(e)
        raise HTTPException(status_code=401, detail="Invalid Google ID token") from e

    return LoginResponse(
        token=token,
        user_id=str(user.id),
        display_name=user.name,
        email=user.email,
        avatar_url=user.avatar_url,
    )


@router.get("/me", response_model=MeResponse)
async def get_me(
    current_user: Annotated[User, Depends(get_current_user)],
) -> MeResponse:
    return MeResponse(
        user_id=str(current_user.id),
        display_name=current_user.name,
        email=current_user.email,
        avatar_url=current_user.avatar_url,
    )
