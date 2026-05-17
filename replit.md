# Ahl al-Hadith wa al-Athar Center

A Flutter web application.

## Project Overview

This is a Flutter project targeting the web platform. It currently serves as a "Hello World" boilerplate but is structured for the "Ahl al-Hadith wa al-Athar Center".

## Tech Stack

- **Framework:** Flutter 3.32.0
- **Language:** Dart
- **Target Platform:** Web (compiled to JavaScript)
- **Server:** Python `http.server` (development)

## Development

The app is compiled with:
```
flutter build web --release
```

The built output is served from `build/web/` via `serve.py` on port 5000.

To rebuild after code changes:
```
flutter build web --release
```

## Deployment

Configured as a **static** deployment:
- **Build command:** `flutter build web --release`
- **Public directory:** `build/web`

## User Preferences

- Keep Flutter web as the primary target platform.
