from fastapi import APIRouter, HTTPException, Depends, Query
from typing import List, Optional

from ..database import get_pool
from ..models import (
    TicketResponse, CreateTicketRequest, TicketReplyResponse,
    AddTicketReplyRequest, UpdateTicketRequest, UserResponse
)
from ..deps import get_current_user

router = APIRouter(prefix="/api/tickets", tags=["tickets"])


def row_to_user(row) -> Optional[UserResponse]:
    if not row:
        return None
    d = dict(row)
    return UserResponse(
        id=str(d["id"]), username=d["username"], display_name=d.get("display_name"),
        email=d.get("email"), academic_id=d["academic_id"], role=d["role"],
        status=d["status"], gender=d["gender"], avatar_url=d.get("avatar_url"),
        bio=d.get("bio"), is_online=d.get("is_online", False),
        last_seen=d.get("last_seen"), created_at=d["created_at"],
    )


async def _build_ticket(conn, row) -> TicketResponse:
    d = dict(row)
    submitter = row_to_user(await conn.fetchrow("SELECT * FROM users WHERE id=$1", d["submitter_id"]))
    assignee = None
    if d.get("assignee_id"):
        assignee = row_to_user(await conn.fetchrow("SELECT * FROM users WHERE id=$1", d["assignee_id"]))

    reply_rows = await conn.fetch(
        "SELECT * FROM ticket_replies WHERE ticket_id=$1 ORDER BY created_at ASC", d["id"]
    )
    replies = []
    for r in reply_rows:
        author = row_to_user(await conn.fetchrow("SELECT * FROM users WHERE id=$1", r["author_id"]))
        replies.append(TicketReplyResponse(
            id=str(r["id"]), ticket_id=str(r["ticket_id"]), author_id=str(r["author_id"]),
            author=author, content=r["content"], is_internal=r["is_internal"], created_at=r["created_at"],
        ))

    return TicketResponse(
        id=str(d["id"]), title=d["title"], body=d["body"],
        submitter_id=str(d["submitter_id"]), submitter=submitter,
        assignee_id=str(d["assignee_id"]) if d.get("assignee_id") else None,
        assignee=assignee, status=d["status"], priority=d["priority"],
        replies=replies, resolved_at=d.get("resolved_at"),
        created_at=d["created_at"], updated_at=d["updated_at"],
    )


@router.get("", response_model=List[TicketResponse])
async def list_tickets(
    status_filter: Optional[str] = Query(None, alias="status"),
    user: dict = Depends(get_current_user),
):
    pool = await get_pool()
    async with pool.acquire() as conn:
        conditions = ["deleted_at IS NULL"]
        params: list = []

        if user["role"] not in ("admin", "moderator", "sheikh"):
            conditions.append(f"submitter_id=${len(params)+1}")
            params.append(user["id"])

        if status_filter:
            conditions.append(f"status=${len(params)+1}::ticket_status")
            params.append(status_filter)

        where = " AND ".join(conditions)
        rows = await conn.fetch(
            f"SELECT * FROM tickets WHERE {where} ORDER BY created_at DESC LIMIT 100", *params
        )
        results = []
        for row in rows:
            results.append(await _build_ticket(conn, row))
        return results


@router.post("", response_model=TicketResponse)
async def create_ticket(body: CreateTicketRequest, user: dict = Depends(get_current_user)):
    pool = await get_pool()
    async with pool.acquire() as conn:
        row = await conn.fetchrow(
            """INSERT INTO tickets (title, body, submitter_id, priority)
               VALUES ($1,$2,$3,$4::ticket_priority) RETURNING *""",
            body.title, body.body, user["id"], body.priority,
        )
        await conn.execute(
            """INSERT INTO notifications (user_id, type, title, body)
               SELECT id, 'ticket', 'تذكرة جديدة', $1 FROM users WHERE role IN ('admin','moderator')""",
            f"تذكرة جديدة: {body.title}",
        )
        return await _build_ticket(conn, row)


@router.get("/{ticket_id}", response_model=TicketResponse)
async def get_ticket(ticket_id: str, user: dict = Depends(get_current_user)):
    pool = await get_pool()
    async with pool.acquire() as conn:
        row = await conn.fetchrow(
            "SELECT * FROM tickets WHERE id=$1 AND deleted_at IS NULL", ticket_id
        )
        if not row:
            raise HTTPException(404, "التذكرة غير موجودة")

        if user["role"] not in ("admin", "moderator", "sheikh"):
            if str(row["submitter_id"]) != str(user["id"]):
                raise HTTPException(403, "غير مصرح")

        return await _build_ticket(conn, row)


@router.patch("/{ticket_id}", response_model=TicketResponse)
async def update_ticket(
    ticket_id: str, body: UpdateTicketRequest, user: dict = Depends(get_current_user)
):
    if user["role"] not in ("admin", "moderator", "sheikh"):
        raise HTTPException(403, "غير مصرح")

    pool = await get_pool()
    async with pool.acquire() as conn:
        updates: dict = {}
        if body.status:
            updates["status"] = body.status
            if body.status == "resolved":
                updates["resolved_at"] = "NOW()"
        if body.priority:
            updates["priority"] = body.priority
        if body.assignee_id is not None:
            updates["assignee_id"] = body.assignee_id

        if updates:
            set_parts = []
            params = []
            for k, v in updates.items():
                if v == "NOW()":
                    set_parts.append(f"{k}=NOW()")
                else:
                    params.append(v)
                    set_parts.append(f"{k}=${len(params)}")
            params.append(ticket_id)
            await conn.execute(
                f"UPDATE tickets SET {', '.join(set_parts)} WHERE id=${len(params)}",
                *params,
            )

        row = await conn.fetchrow("SELECT * FROM tickets WHERE id=$1", ticket_id)
        return await _build_ticket(conn, row)


@router.post("/{ticket_id}/replies", response_model=TicketReplyResponse)
async def add_reply(
    ticket_id: str, body: AddTicketReplyRequest, user: dict = Depends(get_current_user)
):
    pool = await get_pool()
    async with pool.acquire() as conn:
        ticket = await conn.fetchrow("SELECT * FROM tickets WHERE id=$1", ticket_id)
        if not ticket:
            raise HTTPException(404, "التذكرة غير موجودة")

        if user["role"] not in ("admin", "moderator", "sheikh"):
            if str(ticket["submitter_id"]) != str(user["id"]):
                raise HTTPException(403, "غير مصرح")
            if body.is_internal:
                raise HTTPException(403, "غير مصرح")

        reply = await conn.fetchrow(
            """INSERT INTO ticket_replies (ticket_id, author_id, content, is_internal)
               VALUES ($1,$2,$3,$4) RETURNING *""",
            ticket_id, user["id"], body.content, body.is_internal,
        )
        await conn.execute(
            "UPDATE tickets SET status='in_progress', updated_at=NOW() WHERE id=$1 AND status='open'",
            ticket_id,
        )

        submitter_id = ticket["submitter_id"]
        if str(submitter_id) != str(user["id"]):
            await conn.execute(
                """INSERT INTO notifications (user_id, type, title, body, action_url)
                   VALUES ($1,'ticket','رد جديد على تذكرتك',$2,$3)""",
                submitter_id, f"تم الرد على: {ticket['title']}", f"/tickets/{ticket_id}",
            )

        author = await conn.fetchrow("SELECT * FROM users WHERE id=$1", user["id"])
        from ..models import UserResponse
        author_resp = UserResponse(
            id=str(author["id"]), username=author["username"],
            display_name=author.get("display_name"), email=author.get("email"),
            academic_id=author["academic_id"], role=author["role"], status=author["status"],
            gender=author["gender"], avatar_url=author.get("avatar_url"), bio=author.get("bio"),
            is_online=author.get("is_online", False), last_seen=author.get("last_seen"),
            created_at=author["created_at"],
        )
        return TicketReplyResponse(
            id=str(reply["id"]), ticket_id=str(reply["ticket_id"]),
            author_id=str(reply["author_id"]), author=author_resp,
            content=reply["content"], is_internal=reply["is_internal"],
            created_at=reply["created_at"],
        )
