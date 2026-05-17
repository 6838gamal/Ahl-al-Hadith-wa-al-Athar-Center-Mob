from fastapi import APIRouter, HTTPException, Depends
from typing import List, Optional

from ..database import get_pool
from ..models import CourseResponse, CreateCourseRequest, UserResponse
from ..deps import get_current_user

router = APIRouter(prefix="/api/courses", tags=["courses"])


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


async def _build_course(conn, row, user_id) -> CourseResponse:
    d = dict(row)
    instructor = row_to_user(await conn.fetchrow("SELECT * FROM users WHERE id=$1", d["instructor_id"]))
    enrollment = await conn.fetchrow(
        "SELECT * FROM course_enrollments WHERE course_id=$1 AND user_id=$2", d["id"], user_id
    )
    return CourseResponse(
        id=str(d["id"]), title=d["title"], description=d.get("description"),
        thumbnail_url=d.get("thumbnail_url"), instructor_id=str(d["instructor_id"]),
        instructor=instructor, status=d["status"], gender_filter=d.get("gender_filter"),
        start_date=str(d["start_date"]) if d.get("start_date") else None,
        end_date=str(d["end_date"]) if d.get("end_date") else None,
        enrolled=bool(enrollment), progress=enrollment["progress"] if enrollment else 0,
        created_at=d["created_at"],
    )


@router.get("/", response_model=List[CourseResponse])
async def list_courses(user: dict = Depends(get_current_user)):
    pool = await get_pool()
    async with pool.acquire() as conn:
        conditions = ["deleted_at IS NULL", "status='published'"]
        params: list = []

        if user["role"] not in ("admin", "moderator"):
            conditions.append(f"(gender_filter IS NULL OR gender_filter=${len(params)+1}::user_gender)")
            params.append(user["gender"])

        where = " AND ".join(conditions)
        rows = await conn.fetch(f"SELECT * FROM courses WHERE {where} ORDER BY created_at DESC", *params)
        results = []
        for row in rows:
            results.append(await _build_course(conn, row, user["id"]))
        return results


@router.post("/", response_model=CourseResponse)
async def create_course(body: CreateCourseRequest, user: dict = Depends(get_current_user)):
    if user["role"] not in ("admin", "moderator", "sheikh"):
        raise HTTPException(403, "فقط الشيوخ يمكنهم إنشاء الدورات")

    pool = await get_pool()
    async with pool.acquire() as conn:
        row = await conn.fetchrow(
            """INSERT INTO courses (title, description, thumbnail_url, instructor_id, status, gender_filter, start_date, end_date)
               VALUES ($1,$2,$3,$4,$5::course_status,$6::user_gender,$7::date,$8::date) RETURNING *""",
            body.title, body.description, body.thumbnail_url, user["id"],
            body.status, body.gender_filter, body.start_date, body.end_date,
        )
        return await _build_course(conn, row, user["id"])


@router.post("/{course_id}/enroll")
async def enroll(course_id: str, user: dict = Depends(get_current_user)):
    pool = await get_pool()
    async with pool.acquire() as conn:
        course = await conn.fetchrow("SELECT * FROM courses WHERE id=$1 AND deleted_at IS NULL", course_id)
        if not course:
            raise HTTPException(404, "الدورة غير موجودة")
        if course.get("gender_filter") and course["gender_filter"] != user["gender"]:
            raise HTTPException(403, "هذه الدورة مخصصة لجنس آخر")

        existing = await conn.fetchrow(
            "SELECT id FROM course_enrollments WHERE course_id=$1 AND user_id=$2", course_id, user["id"]
        )
        if not existing:
            await conn.execute(
                "INSERT INTO course_enrollments (course_id, user_id) VALUES ($1,$2)", course_id, user["id"]
            )
    return {"message": "تم التسجيل في الدورة"}
