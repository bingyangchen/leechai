from typing import Annotated
from uuid import UUID

from fastapi import Depends, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jwt import InvalidTokenError
from jwt import decode as jwt_decode
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from main.config import Settings, get_settings
from main.core.db import get_session
from main.features.auth.models import User

bearer_scheme = HTTPBearer(auto_error=False)


async def get_current_user(
    db_session: Annotated[AsyncSession, Depends(get_session)],
    settings: Annotated[Settings, Depends(get_settings)],
    credentials: Annotated[
        HTTPAuthorizationCredentials | None,
        Depends(bearer_scheme),
    ],
) -> User:
    token = credentials.credentials.strip() if credentials else None
    if not token:
        raise HTTPException(
            status_code=401,
            detail="Missing or invalid authorization header",
            headers={"WWW-Authenticate": "Bearer"},
        )

    try:
        payload = jwt_decode(
            token, settings.JWT_SECRET, algorithms=[settings.JWT_ALGORITHM]
        )
        if payload.get("token_type") != "access":
            raise InvalidTokenError("wrong token type")
        user_id = UUID(payload.get("sub"))
    except InvalidTokenError, TypeError, ValueError:
        raise HTTPException(
            status_code=401,
            detail="Invalid token",
            headers={"WWW-Authenticate": "Bearer"},
        ) from None

    async with db_session.begin():
        statement = select(User).where(User.id == user_id)
        result = await db_session.execute(statement)
        user = result.scalar_one_or_none()

    if user is None:
        raise HTTPException(
            status_code=401,
            detail="User not found",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return user
