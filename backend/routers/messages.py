from fastapi import APIRouter, HTTPException, Depends, Query
from typing import List, Optional
import asyncpg

from ..database import get_pool
from ..models import (
    ConversationResponse, MessageResponse, SendMessageRequest,
    CreateConversationRequest, ReactionResponse, AddReactionRequest, UserResponse
)
from ..deps import get_current_user

router = APIRouter(prefix="/api/messages", tags=["messages"])


def row_to_user(row) -> UserResponse:
    if row is None:
        return None
    d = dict(row) if not isinstance(row, dict) else row
    return UserResponse(
        id=str(d["id"]), username=d["username"], display_name=d.get("display_name"),
        email=d.get("email"), academic_id=d["academic_id"], role=d["role"],
        status=d["status"], gender=d["gender"], avatar_url=d.get("avatar_url"),
        bio=d.get("bio"), is_online=d.get("is_online", False),
        last_seen=d.get("last_seen"), created_at=d["created_at"],
    )


def row_to_message(row, sender=None, reply_to=None, reactions=None) -> MessageResponse:
    d = dict(row) if not isinstance(row, dict) else row
    mention_ids = [str(uid) for uid in (d.get("mentioned_user_ids") or [])]
    return MessageResponse(
        id=str(d["id"]), conversation_id=str(d["conversation_id"]),
        sender_id=str(d["sender_id"]), sender=sender,
        content=d.get("content"), type=d["type"], status=d["status"],
        media_url=d.get("media_url"), reply_to_id=str(d["reply_to_id"]) if d.get("reply_to_id") else None,
        reply_to=reply_to, reactions=reactions or [], mentioned_user_ids=mention_ids,
        is_deleted=d.get("is_deleted", False), edited_at=d.get("edited_at"),
        created_at=d["created_at"],
    )


async def _get_full_message(conn, msg_row) -> MessageResponse:
    sender_row = await conn.fetchrow("SELECT * FROM users WHERE id=$1", msg_row["sender_id"])
    sender = row_to_user(sender_row)

    reply_to = None
    if msg_row.get("reply_to_id"):
        r = await conn.fetchrow("SELECT * FROM messages WHERE id=$1", msg_row["reply_to_id"])
        if r:
            rs = await conn.fetchrow("SELECT * FROM users WHERE id=$1", r["sender_id"])
            reply_to = row_to_message(r, sender=row_to_user(rs))

    reaction_rows = await conn.fetch(
        "SELECT * FROM message_reactions WHERE message_id=$1", msg_row["id"]
    )
    reactions = [ReactionResponse(
        id=str(r["id"]), message_id=str(r["message_id"]), user_id=str(r["user_id"]),
        emoji=r["emoji"], created_at=r["created_at"]
    ) for r in reaction_rows]

    return row_to_message(msg_row, sender=sender, reply_to=reply_to, reactions=reactions)


def _gender_filter_check(user: dict, target_gender: str) -> bool:
    role = user["role"]
    if role in ("admin", "moderator"):
        return True
    user_gender = user["gender"]
    return user_gender == target_gender


@router.get("/conversations", response_model=List[ConversationResponse])
async def get_conversations(user: dict = Depends(get_current_user)):
    pool = await get_pool()
    async with pool.acquire() as conn:
        rows = await conn.fetch(
            """SELECT c.*, cp.unread_count FROM conversations c
               JOIN conversation_participants cp ON c.id = cp.conversation_id
               WHERE cp.user_id = $1 AND c.deleted_at IS NULL AND cp.left_at IS NULL
               ORDER BY c.updated_at DESC""",
            user["id"],
        )
        result = []
        for row in rows:
            conv_id = row["id"]
            participants_rows = await conn.fetch(
                """SELECT u.* FROM users u
                   JOIN conversation_participants cp ON u.id = cp.user_id
                   WHERE cp.conversation_id = $1 AND cp.left_at IS NULL""",
                conv_id,
            )
            participants = [row_to_user(p) for p in participants_rows]

            last_msg_row = await conn.fetchrow(
                """SELECT * FROM messages WHERE conversation_id=$1 AND is_deleted=FALSE
                   ORDER BY created_at DESC LIMIT 1""",
                conv_id,
            )
            last_msg = None
            if last_msg_row:
                last_msg = await _get_full_message(conn, last_msg_row)

            result.append(ConversationResponse(
                id=str(row["id"]), type=row["type"], title=row.get("title"),
                avatar_url=row.get("avatar_url"), description=row.get("description"),
                unread_count=row.get("unread_count", 0), last_message=last_msg,
                participants=participants, created_at=row["created_at"], updated_at=row["updated_at"],
            ))
        return result


@router.post("/conversations", response_model=ConversationResponse)
async def create_direct_conversation(
    body: CreateConversationRequest, user: dict = Depends(get_current_user)
):
    pool = await get_pool()
    async with pool.acquire() as conn:
        other = await conn.fetchrow(
            "SELECT * FROM users WHERE id=$1 AND deleted_at IS NULL", body.participant_id
        )
        if not other:
            raise HTTPException(404, "المستخدم غير موجود")

        if user["role"] not in ("admin", "moderator", "sheikh"):
            if other["gender"] != user["gender"]:
                raise HTTPException(403, "لا يمكن إنشاء محادثة مع مستخدم من الجنس الآخر")

        existing = await conn.fetchrow(
            """SELECT c.id FROM conversations c
               JOIN conversation_participants cp1 ON c.id=cp1.conversation_id AND cp1.user_id=$1
               JOIN conversation_participants cp2 ON c.id=cp2.conversation_id AND cp2.user_id=$2
               WHERE c.type='direct' AND c.deleted_at IS NULL LIMIT 1""",
            user["id"], other["id"],
        )
        if existing:
            conv = await conn.fetchrow("SELECT * FROM conversations WHERE id=$1", existing["id"])
        else:
            conv = await conn.fetchrow(
                "INSERT INTO conversations (type, created_by) VALUES ('direct',$1) RETURNING *",
                user["id"],
            )
            await conn.execute(
                "INSERT INTO conversation_participants (conversation_id, user_id) VALUES ($1,$2),($1,$3)",
                conv["id"], user["id"], other["id"],
            )

        participants = [row_to_user(user), row_to_user(other)]
        return ConversationResponse(
            id=str(conv["id"]), type=conv["type"], title=conv.get("title"),
            avatar_url=conv.get("avatar_url"), description=conv.get("description"),
            unread_count=0, last_message=None, participants=participants,
            created_at=conv["created_at"], updated_at=conv["updated_at"],
        )


@router.get("/conversations/{conv_id}/messages", response_model=List[MessageResponse])
async def get_messages(
    conv_id: str,
    before: Optional[str] = None,
    limit: int = Query(default=50, le=100),
    user: dict = Depends(get_current_user),
):
    pool = await get_pool()
    async with pool.acquire() as conn:
        participant = await conn.fetchrow(
            "SELECT id FROM conversation_participants WHERE conversation_id=$1 AND user_id=$2 AND left_at IS NULL",
            conv_id, user["id"],
        )
        if not participant:
            raise HTTPException(403, "غير مصرح")

        if before:
            rows = await conn.fetch(
                """SELECT * FROM messages WHERE conversation_id=$1 AND is_deleted=FALSE AND created_at < (
                       SELECT created_at FROM messages WHERE id=$2
                   ) ORDER BY created_at DESC LIMIT $3""",
                conv_id, before, limit,
            )
        else:
            rows = await conn.fetch(
                """SELECT * FROM messages WHERE conversation_id=$1 AND is_deleted=FALSE
                   ORDER BY created_at DESC LIMIT $2""",
                conv_id, limit,
            )

        await conn.execute(
            """UPDATE conversation_participants SET unread_count=0, last_read_at=NOW()
               WHERE conversation_id=$1 AND user_id=$2""",
            conv_id, user["id"],
        )

        messages = []
        for row in reversed(rows):
            messages.append(await _get_full_message(conn, row))
        return messages


@router.post("/conversations/{conv_id}/messages", response_model=MessageResponse)
async def send_message(
    conv_id: str, body: SendMessageRequest, user: dict = Depends(get_current_user)
):
    if not body.content and body.type == "text":
        raise HTTPException(400, "محتوى الرسالة مطلوب")

    pool = await get_pool()
    async with pool.acquire() as conn:
        participant = await conn.fetchrow(
            "SELECT id FROM conversation_participants WHERE conversation_id=$1 AND user_id=$2 AND left_at IS NULL",
            conv_id, user["id"],
        )
        if not participant:
            raise HTTPException(403, "غير مصرح")

        mention_ids = [uid for uid in body.mentioned_user_ids]

        msg_row = await conn.fetchrow(
            """INSERT INTO messages (conversation_id, sender_id, content, type, reply_to_id, mentioned_user_ids)
               VALUES ($1,$2,$3,$4,$5,$6::uuid[]) RETURNING *""",
            conv_id, user["id"], body.content, body.type,
            body.reply_to_id, mention_ids,
        )

        await conn.execute(
            """UPDATE conversations SET updated_at=NOW() WHERE id=$1""", conv_id
        )
        await conn.execute(
            """UPDATE conversation_participants SET unread_count=unread_count+1
               WHERE conversation_id=$1 AND user_id!=$2""",
            conv_id, user["id"],
        )

        return await _get_full_message(conn, msg_row)


@router.post("/messages/{msg_id}/reactions")
async def add_reaction(
    msg_id: str, body: AddReactionRequest, user: dict = Depends(get_current_user)
):
    pool = await get_pool()
    async with pool.acquire() as conn:
        msg = await conn.fetchrow("SELECT * FROM messages WHERE id=$1", msg_id)
        if not msg:
            raise HTTPException(404, "الرسالة غير موجودة")

        existing = await conn.fetchrow(
            "SELECT id FROM message_reactions WHERE message_id=$1 AND user_id=$2 AND emoji=$3",
            msg_id, user["id"], body.emoji,
        )
        if existing:
            await conn.execute(
                "DELETE FROM message_reactions WHERE message_id=$1 AND user_id=$2 AND emoji=$3",
                msg_id, user["id"], body.emoji,
            )
            return {"action": "removed"}
        else:
            await conn.execute(
                "INSERT INTO message_reactions (message_id, user_id, emoji) VALUES ($1,$2,$3)",
                msg_id, user["id"], body.emoji,
            )
            return {"action": "added"}


@router.delete("/messages/{msg_id}")
async def delete_message(msg_id: str, user: dict = Depends(get_current_user)):
    pool = await get_pool()
    async with pool.acquire() as conn:
        msg = await conn.fetchrow("SELECT * FROM messages WHERE id=$1", msg_id)
        if not msg:
            raise HTTPException(404, "الرسالة غير موجودة")
        if str(msg["sender_id"]) != str(user["id"]) and user["role"] not in ("admin", "moderator"):
            raise HTTPException(403, "غير مصرح")
        await conn.execute(
            "UPDATE messages SET is_deleted=TRUE, deleted_at=NOW() WHERE id=$1", msg_id
        )
    return {"message": "تم حذف الرسالة"}
