import mimetypes
from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, JSONResponse

from .database import get_pool, close_pool
from .routers import auth, users, messages, groups, tickets, notifications, courses, admin

WEB_DIR = Path(__file__).parent.parent / "build" / "web"


@asynccontextmanager
async def lifespan(app: FastAPI):
    await get_pool()
    yield
    await close_pool()


app = FastAPI(title="مركز أهل الحديث والأثر API", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(users.router)
app.include_router(messages.router)
app.include_router(groups.router)
app.include_router(tickets.router)
app.include_router(notifications.router)
app.include_router(courses.router)
app.include_router(admin.router)


@app.get("/api/health")
async def health():
    return {"status": "ok"}


def _serve_file(path: Path) -> FileResponse:
    mime, _ = mimetypes.guess_type(str(path))
    return FileResponse(str(path), media_type=mime or "application/octet-stream")


@app.get("/{full_path:path}")
async def serve_flutter(request: Request, full_path: str):
    if full_path.startswith("api/"):
        return JSONResponse({"error": "not found"}, status_code=404)
    if WEB_DIR.exists():
        candidate = WEB_DIR / full_path
        if candidate.exists() and candidate.is_file():
            return _serve_file(candidate)
        index = WEB_DIR / "index.html"
        if index.exists():
            return FileResponse(str(index), media_type="text/html")
    return JSONResponse({"error": "not found"}, status_code=404)


@app.get("/")
async def serve_root():
    index = WEB_DIR / "index.html"
    if index.exists():
        return FileResponse(str(index), media_type="text/html")
    return JSONResponse({"error": "Flutter build not found"}, status_code=404)
