# مركز أهل الحديث والأثر
## Ahl al-Hadith wa al-Athar Center

منصة تعليمية إسلامية متكاملة مبنية بـ Flutter

---

## 🏗️ المعمارية

Clean Architecture + Feature-First Structure

```
lib/
├── core/
│   ├── constants/         # App-wide constants
│   ├── errors/            # Failures & exceptions
│   ├── extensions/        # Dart extensions
│   ├── networking/        # Dio client + interceptors
│   ├── services/          # Mock data service
│   ├── storage/           # Secure storage wrapper
│   └── utils/             # Result type (Either)
├── shared/
│   ├── models/            # Shared data models
│   ├── widgets/           # Reusable UI components
│   └── screens/           # Shared screens (Home, Profile)
├── features/
│   ├── auth/              # Login, Register, Session
│   ├── messaging/         # Conversations, Chat, Audio
│   ├── notifications/     # Push notifications UI
│   └── tickets/           # Support ticket system
├── admin_panel/
│   ├── dashboard/         # Stats overview
│   ├── users/             # User management
│   ├── analytics/         # Charts & reports
│   └── shared/layout/     # Admin sidebar layout
├── config/
│   ├── env/               # Environment config
│   └── theme/             # Colors, Typography, Theme
└── routes/                # GoRouter setup
```

---

## 📦 Tech Stack

| Category | Package |
|---|---|
| State Management | flutter_riverpod |
| Navigation | go_router |
| Networking | dio |
| Local Storage | hive_flutter |
| Secure Storage | flutter_secure_storage |
| Audio | just_audio + audio_waveforms |

---

## 🔌 API Layer (Mock → FastAPI Ready)

MockDataService → (swap later) → FastAPI REST API

To add FastAPI: Replace MockDataService calls in repositories with ApiClient HTTP calls. Zero UI changes needed.

---

## 👤 User Roles

| Role | Arabic | Access |
|---|---|---|
| admin | مدير النظام | Full access |
| moderator | مشرف | Moderation |
| sheikh | شيخ | Teaching |
| male_student | طالب | Student |
| female_student | طالبة | Student (gender-filtered) |

---

## 🚀 Running

```bash
flutter pub get
flutter build web --release
python3 serve.py
```

---

## 🗄️ Database

See database/README.md for full PostgreSQL schema.

Demo accounts (password: 1234):
- admin / sheikh_ibrahim / student_ali
