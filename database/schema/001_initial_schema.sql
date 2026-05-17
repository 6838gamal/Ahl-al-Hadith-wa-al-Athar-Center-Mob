-- =============================================================
-- مركز أهل الحديث والأثر - PostgreSQL Schema
-- Version: 1.0.0
-- =============================================================

-- ─── Extensions ───────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
CREATE EXTENSION IF NOT EXISTS "unaccent";

-- ─── ENUMs ────────────────────────────────────────────────────
CREATE TYPE user_role AS ENUM (
    'admin', 'moderator', 'sheikh', 'male_student', 'female_student'
);

CREATE TYPE user_status AS ENUM (
    'pending', 'active', 'suspended', 'banned'
);

CREATE TYPE user_gender AS ENUM ('male', 'female');

CREATE TYPE message_type AS ENUM (
    'text', 'audio', 'image', 'file', 'system'
);

CREATE TYPE message_status AS ENUM (
    'sending', 'sent', 'delivered', 'read', 'failed'
);

CREATE TYPE conversation_type AS ENUM ('direct', 'group');

CREATE TYPE ticket_status AS ENUM (
    'open', 'in_progress', 'resolved', 'closed'
);

CREATE TYPE ticket_priority AS ENUM (
    'low', 'medium', 'high', 'urgent'
);

CREATE TYPE notification_type AS ENUM (
    'message', 'group', 'course', 'ticket', 'system', 'announcement'
);

CREATE TYPE course_status AS ENUM (
    'draft', 'published', 'archived'
);

-- ─── Users ────────────────────────────────────────────────────
CREATE TABLE users (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username        VARCHAR(50) UNIQUE NOT NULL,
    display_name    VARCHAR(100),
    email           VARCHAR(255) UNIQUE,
    password_hash   VARCHAR(255) NOT NULL,
    academic_id     VARCHAR(50) UNIQUE NOT NULL,
    role            user_role NOT NULL DEFAULT 'male_student',
    status          user_status NOT NULL DEFAULT 'pending',
    gender          user_gender NOT NULL,
    avatar_url      TEXT,
    bio             TEXT,
    is_online       BOOLEAN NOT NULL DEFAULT FALSE,
    last_seen       TIMESTAMPTZ,
    -- Audit
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at      TIMESTAMPTZ,
    created_by      UUID REFERENCES users(id),
    CONSTRAINT username_length CHECK (char_length(username) >= 3),
    CONSTRAINT academic_id_length CHECK (char_length(academic_id) >= 4)
);

CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_academic_id ON users(academic_id);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_status ON users(status);
CREATE INDEX idx_users_deleted_at ON users(deleted_at) WHERE deleted_at IS NULL;
CREATE INDEX idx_users_search ON users USING gin(to_tsvector('arabic', coalesce(display_name,'') || ' ' || username));

-- ─── Sessions ─────────────────────────────────────────────────
CREATE TABLE sessions (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash      VARCHAR(255) NOT NULL,
    refresh_token   VARCHAR(255),
    ip_address      INET,
    user_agent      TEXT,
    expires_at      TIMESTAMPTZ NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_used_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_sessions_user_id ON sessions(user_id);
CREATE INDEX idx_sessions_token ON sessions(token_hash);

-- ─── Conversations ────────────────────────────────────────────
CREATE TABLE conversations (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    type            conversation_type NOT NULL,
    title           VARCHAR(255),
    avatar_url      TEXT,
    description     TEXT,
    is_muted        BOOLEAN NOT NULL DEFAULT FALSE,
    is_archived     BOOLEAN NOT NULL DEFAULT FALSE,
    created_by      UUID REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at      TIMESTAMPTZ
);

CREATE INDEX idx_conversations_type ON conversations(type);
CREATE INDEX idx_conversations_created_by ON conversations(created_by);

-- ─── Conversation Participants ─────────────────────────────────
CREATE TABLE conversation_participants (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id     UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    user_id             UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    is_admin            BOOLEAN NOT NULL DEFAULT FALSE,
    is_muted            BOOLEAN NOT NULL DEFAULT FALSE,
    unread_count        INT NOT NULL DEFAULT 0,
    last_read_at        TIMESTAMPTZ,
    joined_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    left_at             TIMESTAMPTZ,
    UNIQUE(conversation_id, user_id)
);

CREATE INDEX idx_conv_participants_conv ON conversation_participants(conversation_id);
CREATE INDEX idx_conv_participants_user ON conversation_participants(user_id);

-- ─── Messages ─────────────────────────────────────────────────
CREATE TABLE messages (
    id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id         UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    sender_id               UUID NOT NULL REFERENCES users(id),
    content                 TEXT,
    type                    message_type NOT NULL DEFAULT 'text',
    status                  message_status NOT NULL DEFAULT 'sent',
    media_url               TEXT,
    media_mime_type         VARCHAR(100),
    media_duration_seconds  INT,
    media_file_size_bytes   BIGINT,
    media_thumbnail_url     TEXT,
    reply_to_id             UUID REFERENCES messages(id),
    mentioned_user_ids      UUID[] DEFAULT '{}',
    is_deleted              BOOLEAN NOT NULL DEFAULT FALSE,
    deleted_at              TIMESTAMPTZ,
    edited_at               TIMESTAMPTZ,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT content_or_media CHECK (content IS NOT NULL OR media_url IS NOT NULL)
);

CREATE INDEX idx_messages_conversation ON messages(conversation_id, created_at DESC);
CREATE INDEX idx_messages_sender ON messages(sender_id);
CREATE INDEX idx_messages_reply ON messages(reply_to_id) WHERE reply_to_id IS NOT NULL;
CREATE INDEX idx_messages_fts ON messages USING gin(to_tsvector('arabic', coalesce(content,'')));

-- ─── Message Reactions ────────────────────────────────────────
CREATE TABLE message_reactions (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    message_id  UUID NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    emoji       VARCHAR(10) NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(message_id, user_id, emoji)
);

CREATE INDEX idx_reactions_message ON message_reactions(message_id);

-- ─── Groups ───────────────────────────────────────────────────
CREATE TABLE groups (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID REFERENCES conversations(id),
    name            VARCHAR(255) NOT NULL,
    description     TEXT,
    avatar_url      TEXT,
    is_private      BOOLEAN NOT NULL DEFAULT FALSE,
    gender_filter   user_gender,
    max_members     INT DEFAULT 500,
    created_by      UUID REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at      TIMESTAMPTZ
);

CREATE INDEX idx_groups_created_by ON groups(created_by);
CREATE INDEX idx_groups_gender ON groups(gender_filter);

-- ─── Courses ──────────────────────────────────────────────────
CREATE TABLE courses (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title           VARCHAR(255) NOT NULL,
    description     TEXT,
    thumbnail_url   TEXT,
    instructor_id   UUID NOT NULL REFERENCES users(id),
    status          course_status NOT NULL DEFAULT 'draft',
    gender_filter   user_gender,
    start_date      DATE,
    end_date        DATE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at      TIMESTAMPTZ
);

CREATE INDEX idx_courses_instructor ON courses(instructor_id);
CREATE INDEX idx_courses_status ON courses(status);
CREATE INDEX idx_courses_search ON courses USING gin(to_tsvector('arabic', title || ' ' || coalesce(description,'')));

-- ─── Course Enrollments ───────────────────────────────────────
CREATE TABLE course_enrollments (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    course_id       UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    enrolled_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at    TIMESTAMPTZ,
    progress        SMALLINT NOT NULL DEFAULT 0 CHECK (progress BETWEEN 0 AND 100),
    UNIQUE(course_id, user_id)
);

-- ─── Tickets ──────────────────────────────────────────────────
CREATE TABLE tickets (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title           VARCHAR(255) NOT NULL,
    body            TEXT NOT NULL,
    submitter_id    UUID NOT NULL REFERENCES users(id),
    assignee_id     UUID REFERENCES users(id),
    status          ticket_status NOT NULL DEFAULT 'open',
    priority        ticket_priority NOT NULL DEFAULT 'medium',
    resolved_at     TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at      TIMESTAMPTZ
);

CREATE INDEX idx_tickets_submitter ON tickets(submitter_id);
CREATE INDEX idx_tickets_assignee ON tickets(assignee_id);
CREATE INDEX idx_tickets_status ON tickets(status);

-- ─── Ticket Replies ───────────────────────────────────────────
CREATE TABLE ticket_replies (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ticket_id   UUID NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,
    author_id   UUID NOT NULL REFERENCES users(id),
    content     TEXT NOT NULL,
    is_internal BOOLEAN NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── Notifications ────────────────────────────────────────────
CREATE TABLE notifications (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type        notification_type NOT NULL,
    title       VARCHAR(255) NOT NULL,
    body        TEXT NOT NULL,
    is_read     BOOLEAN NOT NULL DEFAULT FALSE,
    action_url  TEXT,
    metadata    JSONB,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notifications_user ON notifications(user_id, is_read, created_at DESC);

-- ─── Audit Log ────────────────────────────────────────────────
CREATE TABLE audit_logs (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    actor_id    UUID REFERENCES users(id),
    action      VARCHAR(100) NOT NULL,
    entity_type VARCHAR(100) NOT NULL,
    entity_id   UUID,
    old_data    JSONB,
    new_data    JSONB,
    ip_address  INET,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_audit_actor ON audit_logs(actor_id, created_at DESC);
CREATE INDEX idx_audit_entity ON audit_logs(entity_type, entity_id);
