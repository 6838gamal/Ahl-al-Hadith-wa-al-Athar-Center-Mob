# مركز أهل الحديث والأثر

A full-featured Flutter web application — Islamic educational center platform.

## Project Overview

A production-ready MVP for "مركز أهل الحديث والأثر" (Ahl al-Hadith wa al-Athar Center). Built with Clean Architecture, Feature-First structure, and a Mock Backend layer designed to be swapped with a real FastAPI backend with zero UI changes.

## Tech Stack

- **Framework:** Flutter 3.32.0 (Web)
- **State Management:** Riverpod
- **Navigation:** GoRouter
- **Networking:** Dio + Interceptors (Auth, Error, Logging)
- **Local Storage:** Hive + Flutter Secure Storage
- **Audio:** just_audio + audio_waveforms
- **Architecture:** Clean Architecture + Feature-First
- **Database Schema:** PostgreSQL (full schema in `database/`)

## Project Structure

```
lib/
├── core/           # Networking, storage, errors, extensions
├── shared/         # Models, widgets, shared screens
├── features/       # auth, messaging, notifications, tickets
├── admin_panel/    # dashboard, users, analytics
├── config/         # Theme, colors, environment config
├── routes/         # GoRouter + shell scaffold
└── main.dart

database/
├── schema/         # Full PostgreSQL schema + triggers
└── seeds/          # Development seed data
```

## Demo Accounts (Password: 1234)

| Username | Role |
|---|---|
| admin | مدير النظام (Admin) |
| sheikh_ibrahim | شيخ (Sheikh) |
| student_ali | طالب (Male Student) |

## Running Locally

```bash
flutter pub get
flutter build web --release
python3 serve.py
```

## Deployment

Static deployment:
- **Build command:** `flutter build web --release`
- **Public directory:** `build/web`

## Architecture: Mock → FastAPI Ready

The API layer is fully decoupled. To add FastAPI later:
1. Replace `MockDataService` calls in repositories with `ApiClient` HTTP calls
2. Zero Flutter UI changes needed

## User Preferences

- Keep Flutter web as the primary target platform
- Clean Architecture + Feature-First folder structure
- RTL Arabic UI with Islamic green color scheme
- Mock backend layer ready for FastAPI replacement
