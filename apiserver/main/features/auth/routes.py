import logging
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Response

from main.features.auth.dependencies import get_current_user
from main.features.auth.models import User
from main.features.auth.schema.exceptions import (
    AuthTokenError,
    RefreshTokenReuseDetectedError,
)
from main.features.auth.schema.requests import (
    GoogleLoginRequest,
    LogoutRequest,
    RefreshTokenRequest,
)
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
        user, access_token, refresh_token = await auth_service.login_with_google(
            body.id_token
        )
    except ValueError as e:
        logger.error(e)
        raise HTTPException(status_code=401, detail="Invalid Google ID token") from e

    return LoginResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        user_id=str(user.id),
        display_name=user.name,
        email=user.email,
        avatar_url=user.avatar_url,
    )


@router.post("/refresh")
async def refresh_token(
    body: RefreshTokenRequest,
    auth_service: Annotated[AuthService, Depends(AuthService)],
) -> LoginResponse:
    try:
        user, access_token, refresh_token = await auth_service.rotate_refresh_token(
            body.refresh_token
        )
    except RefreshTokenReuseDetectedError as e:
        raise HTTPException(
            status_code=401, detail="Refresh token reuse detected"
        ) from e
    except AuthTokenError as e:
        raise HTTPException(status_code=401, detail="Invalid refresh token") from e

    return LoginResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        user_id=str(user.id),
        display_name=user.name,
        email=user.email,
        avatar_url=user.avatar_url,
    )


@router.post("/logout")
async def logout(
    body: LogoutRequest,
    auth_service: Annotated[AuthService, Depends(AuthService)],
) -> Response:
    await auth_service.logout_with_refresh_token(body.refresh_token)
    return Response(status_code=204)


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
