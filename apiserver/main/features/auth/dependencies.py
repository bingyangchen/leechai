from typing import Annotated
from uuid import UUID

from fastapi import Depends, Header, HTTPException
from jwt import InvalidTokenError
from jwt import decode as jwt_decode
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from main.config import Settings, get_settings
from main.core.db import get_session
from main.features.auth.models import User


def _extract_bearer_token(authorization: str | None) -> str | None:
    if not authorization or not authorization.strip():
        return None
    if not authorization.strip().lower().startswith("bearer "):
        return None
    return authorization.strip()[7:].strip() or None


async def get_current_user(
    db_session: Annotated[AsyncSession, Depends(get_session)],
    settings: Annotated[Settings, Depends(get_settings)],
    authorization: Annotated[str | None, Header(alias="Authorization")] = None,
) -> User:
    token = _extract_bearer_token(authorization)
    if not token:
        raise HTTPException(
            status_code=401,
            detail="Missing or invalid authorization header",
            headers={"WWW-Authenticate": "Bearer"},
        )

    try:
        payload = jwt_decode(
            token,
            settings.JWT_SECRET,
            algorithms=[settings.JWT_ALGORITHM],
        )
    except InvalidTokenError:
        raise HTTPException(
            status_code=401,
            detail="Invalid or expired token",
            headers={"WWW-Authenticate": "Bearer"},
        ) from None

    user_id_str = payload.get("sub")
    try:
        user_id = UUID(user_id_str)
    except TypeError, ValueError:
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
