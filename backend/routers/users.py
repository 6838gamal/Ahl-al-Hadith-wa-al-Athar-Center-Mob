from fastapi import APIRouter, HTTPException, Depends, Query
from typing import List, Optional

from ..database import get_pool
from ..models import UserResponse, UserUpdateRequest
from ..deps import get_current_user

router = APIRouter(prefix="/api/users", tags=["users"])


def row_to_user(row) -> UserResponse:
    d = dict(row) if not isinstance(row, dict) else row
    return UserResponse(
        id=str(d["id"]), username=d["username"], display_name=d.get("display_name"),
        email=d.get("email"), academic_id=d["academic_id"], role=d["role"],
        status=d["status"], gender=d["gender"], avatar_url=d.get("avatar_url"),
        bio=d.get("bio"), is_online=d.get("is_online", False),
        last_seen=d.get("last_seen"), created_at=d["created_at"],
    )


@router.get("", response_model=List[UserResponse])
async def list_users(
    q: Optional[str] = None,
    role: Optional[str] = None,
    user: dict = Depends(get_current_user),
):
    pool = await get_pool()
    async with pool.acquire() as conn:
        conditions = ["deleted_at IS NULL", "status='active'"]
        params = []

        if user["role"] not in ("admin", "moderator", "sheikh"):
            conditions.append(f"gender=${ len(params)+1 }")
            params.append(user["gender"])

        if role:
            conditions.append(f"role=${ len(params)+1 }")
            params.append(role)

        if q:
            conditions.append(f"(username ILIKE ${ len(params)+1 } OR display_name ILIKE ${ len(params)+1 })")
            params.append(f"%{q}%")

        where = " AND ".join(conditions)
        rows = await conn.fetch(f"SELECT * FROM users WHERE {where} ORDER BY display_name LIMIT 100", *params)
        return [row_to_user(r) for r in rows]


@router.get("/me", response_model=UserResponse)
async def get_me(user: dict = Depends(get_current_user)):
    return row_to_user(user)


@router.put("/me", response_model=UserResponse)
async def update_me(body: UserUpdateRequest, user: dict = Depends(get_current_user)):
    pool = await get_pool()
    async with pool.acquire() as conn:
        updates = {}
        if body.display_name is not None:
            updates["display_name"] = body.display_name
        if body.email is not None:
            updates["email"] = body.email
        if body.bio is not None:
            updates["bio"] = body.bio
        if body.avatar_url is not None:
            updates["avatar_url"] = body.avatar_url

        if not updates:
            return row_to_user(user)

        set_clause = ", ".join(f"{k}=${i+1}" for i, k in enumerate(updates.keys()))
        params = list(updates.values()) + [user["id"]]
        row = await conn.fetchrow(
            f"UPDATE users SET {set_clause} WHERE id=${len(params)} RETURNING *", *params
        )
        return row_to_user(row)


@router.get("/{user_id}", response_model=UserResponse)
async def get_user(user_id: str, current: dict = Depends(get_current_user)):
    pool = await get_pool()
    async with pool.acquire() as conn:
        row = await conn.fetchrow(
            "SELECT * FROM users WHERE id=$1 AND deleted_at IS NULL", user_id
        )
        if not row:
            raise HTTPException(404, "المستخدم غير موجود")

        if current["role"] not in ("admin", "moderator", "sheikh"):
            if row["gender"] != current["gender"]:
                raise HTTPException(403, "غير مصرح")

        return row_to_user(row)
