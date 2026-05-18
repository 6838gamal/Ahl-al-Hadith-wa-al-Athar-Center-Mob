# مركز أهل الحديث والأثر

A full-stack Islamic educational center platform — Flutter Web frontend + FastAPI backend + PostgreSQL (Render).

## Project Overview

Production-ready app for "مركز أهل الحديث والأثر". Built with Clean Architecture, Feature-First structure, and a FastAPI backend connected to Render PostgreSQL.

## Tech Stack

- **Frontend:** Flutter 3.32.0 (Web)
- **Backend:** FastAPI + asyncpg (Python)
- **Database:** PostgreSQL on Render
- **State Management:** Riverpod
- **Navigation:** GoRouter
- **Networking:** Dio + Interceptors (Auth, Error, Logging)
- **Local Storage:** Flutter Secure Storage
- **Architecture:** Clean Architecture + Feature-First

## Admin Account

| Username | Password | Role |
|---|---|---|
| admin | admin | مدير النظام |

To access the admin panel: double-tap the logo on the login screen → admin login dialog.

## Running Locally (Replit)

```bash
flutter pub get
flutter build web --release
python3 serve.py
```

## Deployment Options

### Option A — Full Stack on Render (RECOMMENDED)
Deploy frontend + backend together as one service.

1. Connect your GitHub repo to [Render](https://render.com)
2. Create a **Web Service** with:
   - **Runtime:** Python
   - **Build command:** `pip install -r requirements.txt && flutter pub get && flutter build web --release`
   - **Start command:** `python3 serve.py`
3. Set environment variables in Render dashboard:
   - `RENDER_DATABASE_URL` → your Render PostgreSQL connection string
   - `SECRET_KEY` → any random long string (e.g. generate with `openssl rand -hex 32`)
4. Deploy — get a `xxx.onrender.com` URL that works immediately

### Option B — Flutter on Netlify + Backend on Render
Deploy them separately (requires configuring the backend URL).

**Step 1** — Deploy the backend on Render (Web Service):
- Build: `pip install -r requirements.txt`
- Start: `python3 serve.py`
- Set: `RENDER_DATABASE_URL`, `SECRET_KEY`, `PORT=10000`
- Note your backend URL (e.g. `https://my-backend.onrender.com`)

**Step 2** — Deploy Flutter on Netlify:
- Edit `netlify.toml`: replace `REPLACE_WITH_YOUR_BACKEND_URL` with your Render backend URL
- Build command becomes: `flutter pub get && flutter build web --release --dart-define=API_BASE_URL=https://my-backend.onrender.com/api`
- Publish directory: `build/web`

## Architecture

```
serve.py              ← Entry point (reads PORT from env)
backend/
├── main.py           ← FastAPI app + CORS + static file serving
├── database.py       ← asyncpg pool (uses RENDER_DATABASE_URL)
├── auth.py           ← JWT token logic
├── deps.py           ← Auth dependencies
├── models.py         ← Pydantic request/response models
└── routers/          ← auth, users, messages, tickets, etc.

lib/
├── core/             ← Networking (Dio), storage, errors
├── features/         ← auth, messaging, notifications, tickets
├── admin_panel/      ← dashboard, users, analytics
├── config/           ← Theme, colors, AppEnv (API_BASE_URL)
└── routes/           ← GoRouter + shell scaffold

requirements.txt      ← Python dependencies for Render
render.yaml           ← Render one-click deployment config
netlify.toml          ← Netlify build config (Option B)
```

## User Preferences

- Keep Flutter web as the primary target platform
- Clean Architecture + Feature-First folder structure
- RTL Arabic UI with Islamic green color scheme
- FastAPI backend connected to Render PostgreSQL
