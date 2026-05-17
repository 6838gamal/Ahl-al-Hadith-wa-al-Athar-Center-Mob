from fastapi import APIRouter, HTTPException, Depends, Query
from typing import List, Optional

from ..database import get_pool
from ..models import (
    UserResponse, AdminUserUpdateRequest, DashboardStats,
    GroupResponse, TicketResponse, CourseResponse
)
from ..deps import require_admin, require_admin_or_moderator, get_current_user

router = APIRouter(prefix="/api/admin", tags=["admin"])


def row_to_user(row) -> UserResponse:
    d = dict(row) if not isinstance(row, dict) else row
    return UserResponse(
        id=str(d["id"]), username=d["username"], display_name=d.get("display_name"),
        email=d.get("email"), academic_id=d["academic_id"], role=d["role"],
        status=d["status"], gender=d["gender"], avatar_url=d.get("avatar_url"),
        bio=d.get("bio"), is_online=d.get("is_online", False),
        last_seen=d.get("last_seen"), created_at=d["created_at"],
    )


@router.get("/dashboard", response_model=DashboardStats)
async def dashboard(_: dict = Depends(require_admin_or_moderator)):
    pool = await get_pool()
    async with pool.acquire() as conn:
        total_users = await conn.fetchval("SELECT COUNT(*) FROM users WHERE deleted_at IS NULL")
        active_users = await conn.fetchval("SELECT COUNT(*) FROM users WHERE status='active' AND deleted_at IS NULL")
        pending_users = await conn.fetchval("SELECT COUNT(*) FROM users WHERE status='pending' AND deleted_at IS NULL")
        total_messages = await conn.fetchval("SELECT COUNT(*) FROM messages WHERE is_deleted=FALSE")
        total_tickets = await conn.fetchval("SELECT COUNT(*) FROM tickets WHERE deleted_at IS NULL")
        open_tickets = await conn.fetchval("SELECT COUNT(*) FROM tickets WHERE status='open' AND deleted_at IS NULL")
        total_groups = await conn.fetchval("SELECT COUNT(*) FROM groups WHERE deleted_at IS NULL")
        total_courses = await conn.fetchval("SELECT COUNT(*) FROM courses WHERE deleted_at IS NULL")

        return DashboardStats(
            total_users=total_users, active_users=active_users, pending_users=pending_users,
            total_messages=total_messages, total_tickets=total_tickets, open_tickets=open_tickets,
            total_groups=total_groups, total_courses=total_courses,
        )


@router.get("/users", response_model=List[UserResponse])
async def list_users(
    q: Optional[str] = None,
    status_filter: Optional[str] = Query(None, alias="status"),
    role: Optional[str] = None,
    page: int = 1,
    per_page: int = 20,
    _: dict = Depends(require_admin_or_moderator),
):
    pool = await get_pool()
    async with pool.acquire() as conn:
        conditions = ["deleted_at IS NULL"]
        params: list = []

        if q:
            conditions.append(f"(username ILIKE ${len(params)+1} OR display_name ILIKE ${len(params)+1} OR academic_id ILIKE ${len(params)+1})")
            params.append(f"%{q}%")
        if status_filter:
            conditions.append(f"status=${len(params)+1}::user_status")
            params.append(status_filter)
        if role:
            conditions.append(f"role=${len(params)+1}::user_role")
            params.append(role)

        where = " AND ".join(conditions)
        offset = (page - 1) * per_page
        params.extend([per_page, offset])
        rows = await conn.fetch(
            f"SELECT * FROM users WHERE {where} ORDER BY created_at DESC LIMIT ${len(params)-1} OFFSET ${len(params)}",
            *params,
        )
        return [row_to_user(r) for r in rows]


@router.patch("/users/{user_id}", response_model=UserResponse)
async def update_user(
    user_id: str, body: AdminUserUpdateRequest, admin: dict = Depends(require_admin_or_moderator)
):
    pool = await get_pool()
    async with pool.acquire() as conn:
        updates: dict = {}
        if body.status:
            updates["status"] = body.status
        if body.role:
            if admin["role"] != "admin":
                raise HTTPException(403, "فقط المدير يمكنه تغيير الأدوار")
            updates["role"] = body.role

        if not updates:
            row = await conn.fetchrow("SELECT * FROM users WHERE id=$1", user_id)
            return row_to_user(row)

        set_parts = []
        params = []
        for k, v in updates.items():
            params.append(v)
            set_parts.append(f"{k}=${len(params)}")
        params.append(user_id)

        row = await conn.fetchrow(
            f"UPDATE users SET {', '.join(set_parts)} WHERE id=${len(params)} RETURNING *",
            *params,
        )
        if not row:
            raise HTTPException(404, "المستخدم غير موجود")

        if body.status == "active":
            await conn.execute(
                """INSERT INTO notifications (user_id, type, title, body)
                   VALUES ($1,'system','تم تفعيل حسابك','مرحباً بك في مركز أهل الحديث والأثر. تم تفعيل حسابك.')""",
                user_id,
            )

        return row_to_user(row)


@router.delete("/users/{user_id}")
async def delete_user(user_id: str, _: dict = Depends(require_admin)):
    pool = await get_pool()
    async with pool.acquire() as conn:
        await conn.execute(
            "UPDATE users SET deleted_at=NOW() WHERE id=$1", user_id
        )
    return {"message": "تم حذف المستخدم"}


@router.get("/pending-users", response_model=List[UserResponse])
async def pending_users(_: dict = Depends(require_admin_or_moderator)):
    pool = await get_pool()
    async with pool.acquire() as conn:
        rows = await conn.fetch(
            "SELECT * FROM users WHERE status='pending' AND deleted_at IS NULL ORDER BY created_at ASC"
        )
        return [row_to_user(r) for r in rows]


@router.post("/users/{user_id}/approve")
async def approve_user(user_id: str, _: dict = Depends(require_admin_or_moderator)):
    pool = await get_pool()
    async with pool.acquire() as conn:
        await conn.execute(
            "UPDATE users SET status='active' WHERE id=$1", user_id
        )
        await conn.execute(
            """INSERT INTO notifications (user_id, type, title, body)
               VALUES ($1,'system','تم تفعيل حسابك','مرحباً بك في مركز أهل الحديث والأثر. تم تفعيل حسابك.')""",
            user_id,
        )
    return {"message": "تم قبول المستخدم"}


@router.post("/users/{user_id}/reject")
async def reject_user(user_id: str, _: dict = Depends(require_admin_or_moderator)):
    pool = await get_pool()
    async with pool.acquire() as conn:
        await conn.execute(
            "UPDATE users SET status='banned' WHERE id=$1", user_id
        )
    return {"message": "تم رفض المستخدم"}


@router.get("/activity")
async def recent_activity(_: dict = Depends(require_admin_or_moderator)):
    pool = await get_pool()
    async with pool.acquire() as conn:
        recent_users = await conn.fetch(
            "SELECT username, display_name, role, status, created_at FROM users WHERE deleted_at IS NULL ORDER BY created_at DESC LIMIT 5"
        )
        recent_tickets = await conn.fetch(
            "SELECT t.title, t.status, t.priority, t.created_at, u.username FROM tickets t JOIN users u ON u.id=t.submitter_id WHERE t.deleted_at IS NULL ORDER BY t.created_at DESC LIMIT 5"
        )
        return {
            "recent_users": [dict(r) for r in recent_users],
            "recent_tickets": [dict(r) for r in recent_tickets],
        }
