from fastapi import APIRouter, Depends
from typing import List

from ..database import get_pool
from ..models import NotificationResponse
from ..deps import get_current_user

router = APIRouter(prefix="/api/notifications", tags=["notifications"])


@router.get("", response_model=List[NotificationResponse])
async def get_notifications(user: dict = Depends(get_current_user)):
    pool = await get_pool()
    async with pool.acquire() as conn:
        rows = await conn.fetch(
            "SELECT * FROM notifications WHERE user_id=$1 ORDER BY created_at DESC LIMIT 50",
            user["id"],
        )
        return [
            NotificationResponse(
                id=str(r["id"]), user_id=str(r["user_id"]), type=r["type"],
                title=r["title"], body=r["body"], is_read=r["is_read"],
                action_url=r.get("action_url"), metadata=r.get("metadata"),
                created_at=r["created_at"],
            )
            for r in rows
        ]


@router.get("/unread-count")
async def unread_count(user: dict = Depends(get_current_user)):
    pool = await get_pool()
    async with pool.acquire() as conn:
        row = await conn.fetchrow(
            "SELECT COUNT(*) as count FROM notifications WHERE user_id=$1 AND is_read=FALSE",
            user["id"],
        )
        return {"count": row["count"]}


@router.post("/{notif_id}/read")
async def mark_read(notif_id: str, user: dict = Depends(get_current_user)):
    pool = await get_pool()
    async with pool.acquire() as conn:
        await conn.execute(
            "UPDATE notifications SET is_read=TRUE WHERE id=$1 AND user_id=$2",
            notif_id, user["id"],
        )
    return {"message": "تم التحديث"}


@router.post("/read-all")
async def mark_all_read(user: dict = Depends(get_current_user)):
    pool = await get_pool()
    async with pool.acquire() as conn:
        await conn.execute(
            "UPDATE notifications SET is_read=TRUE WHERE user_id=$1", user["id"]
        )
    return {"message": "تم تعليم جميع الإشعارات كمقروءة"}
