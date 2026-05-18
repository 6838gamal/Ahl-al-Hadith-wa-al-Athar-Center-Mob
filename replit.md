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

## Deployment on Render (RECOMMENDED)

> **Important:** `build/web` is committed to the repo intentionally.
> Render uses Python runtime which has no Flutter — so we pre-build locally and push.

### Steps

1. Push repo to GitHub (including `build/web` folder)
2. Connect repo to [Render](https://render.com) → New Web Service
3. Render reads `render.yaml` automatically, which sets:
   - **Build command:** `pip install -r requirements.txt`
   - **Start command:** `python3 serve.py`
   - **Port:** `10000`
4. In Render dashboard → Environment → add:
   - `RENDER_DATABASE_URL` → your PostgreSQL connection string
   - `SECRET_KEY` → any long random string
5. Deploy → works immediately at `https://xxx.onrender.com`

### Updating the frontend after changes

Whenever you change Flutter code, rebuild locally then push:

```bash
flutter pub get && flutter build web --release
git add build/web
git commit -m "rebuild web"
git push
```

Render will auto-deploy on push.

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
