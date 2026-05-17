# قاعدة البيانات - مركز أهل الحديث والأثر

## نظرة عامة

PostgreSQL database schema for the Ahl al-Hadith wa al-Athar Center platform.

## Structure

```
database/
├── schema/
│   ├── 001_initial_schema.sql    # Tables, indexes, enums
│   └── 002_functions_triggers.sql # Functions & triggers
├── seeds/
│   └── 001_seed_data.sql         # Development seed data
├── migrations/                    # Version-controlled migrations
├── functions/                     # Stored procedures
├── triggers/                      # Database triggers
└── views/                         # Database views
```

## Key Design Decisions

- **UUID Primary Keys** — all tables use `uuid_generate_v4()`
- **Soft Deletes** — `deleted_at` column on all major tables
- **Audit Columns** — `created_at`, `updated_at`, `created_by`
- **Full Text Search** — Arabic FTS on messages, users, courses
- **ENUM Types** — for roles, statuses, message types, etc.
- **Foreign Keys** — enforced at DB level
- **Indexes** — on all frequently queried columns

## Tables

| Table | Purpose |
|---|---|
| `users` | User accounts & profiles |
| `sessions` | Auth tokens & sessions |
| `conversations` | Direct & group conversations |
| `conversation_participants` | Membership + unread counts |
| `messages` | Chat messages (text/audio/image/file) |
| `message_reactions` | Emoji reactions on messages |
| `groups` | Study groups |
| `courses` | Educational courses |
| `course_enrollments` | Student enrollments |
| `tickets` | Support ticket system |
| `ticket_replies` | Ticket conversation thread |
| `notifications` | Push notifications |
| `audit_logs` | System audit trail |

## Setup

```bash
# Create database
createdb ahl_al_hadith

# Run schema
psql ahl_al_hadith < database/schema/001_initial_schema.sql
psql ahl_al_hadith < database/schema/002_functions_triggers.sql

# Seed development data
psql ahl_al_hadith < database/seeds/001_seed_data.sql
```

## Future: FastAPI Integration

When adding FastAPI backend:
1. Use `DATABASE_URL` env variable
2. Use SQLAlchemy or asyncpg
3. Replace Mock Services with real HTTP calls in Flutter
4. No Flutter architecture changes needed
