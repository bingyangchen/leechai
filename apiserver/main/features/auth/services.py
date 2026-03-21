import asyncio
import time
from typing import Annotated
from uuid import UUID

from fastapi import Depends
from google.auth.transport import requests as google_requests
from google.oauth2 import id_token
from jwt import encode as jwt_encode
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from main.config import Settings, get_settings
from main.core.db import get_session
from main.features.auth.models import User
from main.features.auth.schema.enums import OAuthProvider


class AuthService:
    def __init__(
        self,
        db_session: Annotated[AsyncSession, Depends(get_session)],
        settings: Annotated[Settings, Depends(get_settings)],
    ):
        self._db_session = db_session
        self._google_client_ids = [
            settings.GOOGLE_WEB_CLIENT_ID,
            settings.GOOGLE_IOS_CLIENT_ID,
            settings.GOOGLE_ANDROID_CLIENT_ID,
        ]
        self._jwt_secret = settings.JWT_SECRET
        self._jwt_algorithm = settings.JWT_ALGORITHM
        self._jwt_expire_seconds = settings.JWT_EXPIRE_SECONDS

    def _verify_google_id_token(self, token: str) -> dict[str, object]:
        id_info = id_token.verify_oauth2_token(
            token, google_requests.Request(), self._google_client_ids
        )
        return dict(id_info)

    def _create_access_token(self, user_id: UUID) -> str:
        payload = {
            "sub": str(user_id),
            "exp": int(time.time()) + self._jwt_expire_seconds,
            "iat": int(time.time()),
        }
        return jwt_encode(payload, self._jwt_secret, algorithm=self._jwt_algorithm)

    async def _get_or_create_user(self, claims: dict, provider: str) -> User:
        oauth_sub = claims["sub"]
        statement = select(User).where(
            User.oauth_provider == provider, User.oauth_sub == oauth_sub
        )
        async with self._db_session.begin():
            result = await self._db_session.execute(statement)
            user = result.scalar_one_or_none()
            if user is not None:
                return user

            email = claims.get("email") or ""
            name = claims.get("name") or email or "User"
            picture = claims.get("picture")
            user = User(
                email=email,
                oauth_provider=provider,
                oauth_sub=oauth_sub,
                name=name,
                avatar_url=picture,
            )
            self._db_session.add(user)
            await self._db_session.flush()
            await self._db_session.refresh(user)
        return user

    async def login_with_google(self, id_token: str) -> tuple[User, str]:
        claims = await asyncio.to_thread(self._verify_google_id_token, id_token)
        user = await self._get_or_create_user(claims, OAuthProvider.GOOGLE)
        token = self._create_access_token(user.id)
        return user, token
