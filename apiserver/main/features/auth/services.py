import asyncio
import hashlib
import secrets
import time
from datetime import UTC, datetime, timedelta
from typing import Annotated
from uuid import UUID, uuid4

from fastapi import Depends
from google.auth.transport import requests as google_requests
from google.oauth2 import id_token
from jwt import encode as jwt_encode
from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession

from main.config import Settings, get_settings
from main.core.db import get_session
from main.features.auth.models import RefreshToken, User
from main.features.auth.schema.enums import OAuthProvider
from main.features.auth.schema.exceptions import (
    InvalidRefreshTokenError,
    RefreshTokenExpiredError,
    RefreshTokenReuseDetectedError,
    RefreshTokenUserNotFoundError,
)


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
        self._access_expire_seconds = settings.JWT_ACCESS_TOKEN_EXPIRE_SECONDS
        self._refresh_expire_seconds = settings.JWT_REFRESH_TOKEN_EXPIRE_SECONDS

    @staticmethod
    def hash_token(raw: str) -> str:
        return hashlib.sha256(raw.encode("utf-8")).hexdigest()

    @staticmethod
    def create_refresh_token() -> str:
        return secrets.token_urlsafe(48)

    def _verify_google_id_token(self, token: str) -> dict[str, object]:
        id_info = id_token.verify_oauth2_token(
            token, google_requests.Request(), self._google_client_ids
        )
        return dict(id_info)

    def _create_access_token(self, user_id: UUID) -> str:
        now = int(time.time())
        payload = {
            "sub": str(user_id),
            "exp": now + self._access_expire_seconds,
            "iat": now,
            "token_type": "access",
        }
        return jwt_encode(payload, self._jwt_secret, algorithm=self._jwt_algorithm)

    async def _delete_refresh_token_family(self, family_id: UUID) -> None:
        await self._db_session.execute(
            delete(RefreshToken).where(RefreshToken.family_id == family_id)
        )

    async def _get_or_create_user(self, claims: dict, provider: str) -> User:
        oauth_sub = claims["sub"]
        async with self._db_session.begin():
            user = (
                await self._db_session.execute(
                    select(User).where(
                        User.oauth_provider == provider, User.oauth_sub == oauth_sub
                    )
                )
            ).scalar_one_or_none()
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

    async def login_with_google(self, google_id_token: str) -> tuple[User, str, str]:
        claims = await asyncio.to_thread(self._verify_google_id_token, google_id_token)
        user = await self._get_or_create_user(claims, OAuthProvider.GOOGLE)
        access_token = self._create_access_token(user.id)
        refresh_token = self.create_refresh_token()
        async with self._db_session.begin():
            row = RefreshToken(
                user_id=user.id,
                token_hash=self.hash_token(refresh_token),
                family_id=uuid4(),
                expires_at=(
                    datetime.now(UTC) + timedelta(seconds=self._refresh_expire_seconds)
                ),
            )
            self._db_session.add(row)
        return user, access_token, refresh_token

    async def rotate_refresh_token(self, raw_token: str) -> tuple[User, str, str]:
        result: tuple[User, str, str] | None = None
        reuse_detected = False
        async with self._db_session.begin():
            current_row = (
                await self._db_session.execute(
                    select(RefreshToken)
                    .where(RefreshToken.token_hash == self.hash_token(raw_token))
                    .with_for_update()
                )
            ).scalar_one_or_none()
            if current_row is None:
                raise InvalidRefreshTokenError
            if current_row.revoked_at is not None:
                await self._delete_refresh_token_family(current_row.family_id)
                reuse_detected = True
            elif current_row.expires_at < datetime.now(UTC):
                raise RefreshTokenExpiredError
            else:
                user = (
                    await self._db_session.execute(
                        select(User).where(User.id == current_row.user_id)
                    )
                ).scalar_one_or_none()
                if user is None:
                    raise RefreshTokenUserNotFoundError

                current_row.revoked_at = datetime.now(UTC)
                new_refresh_token = self.create_refresh_token()
                new_row = RefreshToken(
                    user_id=current_row.user_id,
                    token_hash=self.hash_token(new_refresh_token),
                    family_id=current_row.family_id,
                    expires_at=(
                        datetime.now(UTC)
                        + timedelta(seconds=self._refresh_expire_seconds)
                    ),
                )
                self._db_session.add(new_row)
                access_token = self._create_access_token(user.id)
                result = (user, access_token, new_refresh_token)

        if reuse_detected:
            raise RefreshTokenReuseDetectedError
        if result is None:
            raise RuntimeError("Refresh token rotation did not produce a result")
        return result

    async def logout_with_refresh_token(self, raw_token: str) -> None:
        async with self._db_session.begin():
            row = (
                await self._db_session.execute(
                    select(RefreshToken.family_id, RefreshToken.revoked_at)
                    .where(RefreshToken.token_hash == self.hash_token(raw_token))
                    .with_for_update()
                )
            ).one_or_none()
            if row is None or row.revoked_at is not None:
                return
            await self._delete_refresh_token_family(row.family_id)
