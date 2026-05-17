from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
import asyncpg

from .database import get_pool
from .auth import decode_token, hash_token

security = HTTPBearer()


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
) -> dict:
    token = credentials.credentials
    payload = decode_token(token)
    if not payload:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="توكن غير صالح")

    user_id = payload.get("sub")
    if not user_id:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="توكن غير صالح")

    pool = await get_pool()
    async with pool.acquire() as conn:
        token_hash = hash_token(token)
        session = await conn.fetchrow(
            "SELECT id FROM sessions WHERE token_hash=$1 AND expires_at > NOW()",
            token_hash,
        )
        if not session:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="انتهت الجلسة")

        await conn.execute(
            "UPDATE sessions SET last_used_at=NOW() WHERE token_hash=$1", token_hash
        )

        user = await conn.fetchrow(
            "SELECT * FROM users WHERE id=$1 AND deleted_at IS NULL", user_id
        )
        if not user:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="المستخدم غير موجود")
        if user["status"] == "suspended" or user["status"] == "banned":
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="الحساب موقوف")

    return dict(user)


def require_admin(user: dict = Depends(get_current_user)) -> dict:
    if user["role"] != "admin":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="غير مصرح")
    return user


def require_admin_or_moderator(user: dict = Depends(get_current_user)) -> dict:
    if user["role"] not in ("admin", "moderator"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="غير مصرح")
    return user


def require_sheikh_or_above(user: dict = Depends(get_current_user)) -> dict:
    if user["role"] not in ("admin", "moderator", "sheikh"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="غير مصرح")
    return user
