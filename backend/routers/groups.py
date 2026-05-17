from fastapi import APIRouter, HTTPException, Depends, Query
from typing import List, Optional

from ..database import get_pool
from ..models import GroupResponse, CreateGroupRequest, UserResponse
from ..deps import get_current_user

router = APIRouter(prefix="/api/groups", tags=["groups"])


def row_to_group(row, member_count=0) -> GroupResponse:
    d = dict(row) if not isinstance(row, dict) else row
    return GroupResponse(
        id=str(d["id"]),
        conversation_id=str(d["conversation_id"]) if d.get("conversation_id") else None,
        name=d["name"], description=d.get("description"), avatar_url=d.get("avatar_url"),
        is_private=d.get("is_private", False), gender_filter=d.get("gender_filter"),
        max_members=d.get("max_members", 500), member_count=member_count,
        created_by=str(d["created_by"]) if d.get("created_by") else None,
        created_at=d["created_at"],
    )


@router.get("/", response_model=List[GroupResponse])
async def list_groups(
    q: Optional[str] = None,
    user: dict = Depends(get_current_user),
):
    pool = await get_pool()
    async with pool.acquire() as conn:
        conditions = ["g.deleted_at IS NULL"]
        params: list = []

        if user["role"] not in ("admin", "moderator"):
            conditions.append(f"(g.gender_filter IS NULL OR g.gender_filter=${len(params)+1})")
            params.append(user["gender"])

        if q:
            conditions.append(f"g.name ILIKE ${len(params)+1}")
            params.append(f"%{q}%")

        where = " AND ".join(conditions)
        rows = await conn.fetch(
            f"""SELECT g.*,
                (SELECT COUNT(*) FROM conversation_participants cp
                 JOIN conversations c ON c.id=cp.conversation_id
                 WHERE c.id=g.conversation_id AND cp.left_at IS NULL) as member_count
                FROM groups g WHERE {where} ORDER BY g.created_at DESC""",
            *params,
        )
        return [row_to_group(r, r.get("member_count", 0)) for r in rows]


@router.post("/", response_model=GroupResponse)
async def create_group(body: CreateGroupRequest, user: dict = Depends(get_current_user)):
    if user["role"] not in ("admin", "moderator", "sheikh"):
        raise HTTPException(403, "فقط الشيوخ والمشرفون يمكنهم إنشاء المجموعات")

    pool = await get_pool()
    async with pool.acquire() as conn:
        conv = await conn.fetchrow(
            "INSERT INTO conversations (type, title, description, created_by) VALUES ('group',$1,$2,$3) RETURNING *",
            body.name, body.description, user["id"],
        )
        group = await conn.fetchrow(
            """INSERT INTO groups (conversation_id, name, description, is_private, gender_filter, max_members, created_by)
               VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING *""",
            conv["id"], body.name, body.description, body.is_private,
            body.gender_filter, body.max_members, user["id"],
        )
        await conn.execute(
            "INSERT INTO conversation_participants (conversation_id, user_id, is_admin) VALUES ($1,$2,TRUE)",
            conv["id"], user["id"],
        )
        return row_to_group(group, 1)


@router.post("/{group_id}/join")
async def join_group(group_id: str, user: dict = Depends(get_current_user)):
    pool = await get_pool()
    async with pool.acquire() as conn:
        group = await conn.fetchrow(
            "SELECT * FROM groups WHERE id=$1 AND deleted_at IS NULL", group_id
        )
        if not group:
            raise HTTPException(404, "المجموعة غير موجودة")

        if group.get("gender_filter") and group["gender_filter"] != user["gender"]:
            raise HTTPException(403, "هذه المجموعة مخصصة لجنس آخر")

        if group.get("is_private") and user["role"] not in ("admin", "moderator", "sheikh"):
            raise HTTPException(403, "المجموعة خاصة")

        existing = await conn.fetchrow(
            "SELECT id FROM conversation_participants WHERE conversation_id=$1 AND user_id=$2",
            group["conversation_id"], user["id"],
        )
        if existing:
            await conn.execute(
                "UPDATE conversation_participants SET left_at=NULL WHERE conversation_id=$1 AND user_id=$2",
                group["conversation_id"], user["id"],
            )
        else:
            await conn.execute(
                "INSERT INTO conversation_participants (conversation_id, user_id) VALUES ($1,$2)",
                group["conversation_id"], user["id"],
            )
    return {"message": "تم الانضمام للمجموعة"}


@router.post("/{group_id}/leave")
async def leave_group(group_id: str, user: dict = Depends(get_current_user)):
    pool = await get_pool()
    async with pool.acquire() as conn:
        group = await conn.fetchrow("SELECT * FROM groups WHERE id=$1", group_id)
        if not group:
            raise HTTPException(404, "المجموعة غير موجودة")
        await conn.execute(
            "UPDATE conversation_participants SET left_at=NOW() WHERE conversation_id=$1 AND user_id=$2",
            group["conversation_id"], user["id"],
        )
    return {"message": "تم مغادرة المجموعة"}
