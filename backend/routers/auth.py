from datetime import timedelta, datetime, timezone
from fastapi import APIRouter, HTTPException, status, Depends, Request
import asyncpg

from ..database import get_pool
from ..auth import verify_password, hash_password, create_access_token, hash_token, ACCESS_TOKEN_EXPIRE_MINUTES
from ..models import LoginRequest, RegisterRequest, TokenResponse, AdminLoginRequest, UserResponse
from ..deps import get_current_user

router = APIRouter(prefix="/api/auth", tags=["auth"])

GENDER_MAP = {
    "male_student": "male",
    "female_student": "female",
    "sheikh": "male",
    "moderator": "male",
    "admin": "male",
}

ALLOWED_ROLES = {"male_student", "female_student", "sheikh"}
ADMIN_ROLES = {"admin", "moderator"}


def row_to_user(row: dict) -> UserResponse:
    return UserResponse(
        id=str(row["id"]),
        username=row["username"],
        display_name=row.get("display_name"),
        email=row.get("email"),
        academic_id=row["academic_id"],
        role=row["role"],
        status=row["status"],
        gender=row["gender"],
        avatar_url=row.get("avatar_url"),
        bio=row.get("bio"),
        is_online=row.get("is_online", False),
        last_seen=row.get("last_seen"),
        created_at=row["created_at"],
    )


async def _do_login(conn, username: str, password: str, require_role=None):
    user = await conn.fetchrow(
        "SELECT * FROM users WHERE username=$1 AND deleted_at IS NULL", username
    )
    if not user or not verify_password(password, user["password_hash"]):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="اسم المستخدم أو كلمة المرور غير صحيحة")

    if require_role and user["role"] not in require_role:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="غير مصرح بهذا الدور")

    if user["status"] == "pending":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="الحساب في انتظار الموافقة")
    if user["status"] in ("suspended", "banned"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="الحساب موقوف")

    token = create_access_token({"sub": str(user["id"]), "role": user["role"]})
    token_hash = hash_token(token)
    expires_at = datetime.now(timezone.utc) + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)

    await conn.execute(
        """INSERT INTO sessions (user_id, token_hash, expires_at) VALUES ($1, $2, $3)""",
        user["id"], token_hash, expires_at,
    )
    await conn.execute("UPDATE users SET is_online=TRUE, last_seen=NOW() WHERE id=$1", user["id"])

    return TokenResponse(access_token=token, user=row_to_user(dict(user)))


@router.post("/login", response_model=TokenResponse)
async def login(body: LoginRequest, request: Request):
    pool = await get_pool()
    async with pool.acquire() as conn:
        return await _do_login(conn, body.username, body.password)


@router.post("/admin-login", response_model=TokenResponse)
async def admin_login(body: AdminLoginRequest, request: Request):
    pool = await get_pool()
    async with pool.acquire() as conn:
        return await _do_login(conn, body.username, body.password, require_role=ADMIN_ROLES)


@router.post("/register", response_model=TokenResponse)
async def register(body: RegisterRequest):
    if body.role not in ALLOWED_ROLES:
        raise HTTPException(status_code=400, detail="دور غير مسموح به")

    gender = GENDER_MAP.get(body.role, "male")
    pw_hash = hash_password(body.password)

    pool = await get_pool()
    async with pool.acquire() as conn:
        existing = await conn.fetchrow(
            "SELECT id FROM users WHERE username=$1 OR academic_id=$2",
            body.username, body.academic_id,
        )
        if existing:
            raise HTTPException(status_code=400, detail="اسم المستخدم أو الرقم الأكاديمي مستخدم مسبقاً")

        status_val = "active" if body.role == "sheikh" else "pending"

        user = await conn.fetchrow(
            """INSERT INTO users (username, display_name, email, password_hash, academic_id, role, status, gender)
               VALUES ($1,$2,$3,$4,$5,$6,$7,$8) RETURNING *""",
            body.username, body.display_name, body.email, pw_hash,
            body.academic_id, body.role, status_val, gender,
        )

        if status_val == "pending":
            raise HTTPException(
                status_code=202,
                detail="تم تسجيل طلبك بنجاح. سيتم مراجعة حسابك من قِبَل الإدارة وإشعارك عند التفعيل.",
            )

        token = create_access_token({"sub": str(user["id"]), "role": user["role"]})
        token_hash = hash_token(token)
        expires_at = datetime.now(timezone.utc) + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)

        await conn.execute(
            "INSERT INTO sessions (user_id, token_hash, expires_at) VALUES ($1,$2,$3)",
            user["id"], token_hash, expires_at,
        )

        return TokenResponse(access_token=token, user=row_to_user(dict(user)))


@router.post("/logout")
async def logout(user: dict = Depends(get_current_user)):
    pool = await get_pool()
    async with pool.acquire() as conn:
        await conn.execute(
            "DELETE FROM sessions WHERE user_id=$1", user["id"]
        )
        await conn.execute(
            "UPDATE users SET is_online=FALSE, last_seen=NOW() WHERE id=$1", user["id"]
        )
    return {"message": "تم تسجيل الخروج بنجاح"}


@router.get("/me", response_model=UserResponse)
async def me(user: dict = Depends(get_current_user)):
    return UserResponse(
        id=str(user["id"]),
        username=user["username"],
        display_name=user.get("display_name"),
        email=user.get("email"),
        academic_id=user["academic_id"],
        role=user["role"],
        status=user["status"],
        gender=user["gender"],
        avatar_url=user.get("avatar_url"),
        bio=user.get("bio"),
        is_online=user.get("is_online", False),
        last_seen=user.get("last_seen"),
        created_at=user["created_at"],
    )
