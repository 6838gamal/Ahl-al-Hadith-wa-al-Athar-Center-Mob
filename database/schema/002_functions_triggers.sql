-- =============================================================
-- Functions & Triggers
-- =============================================================

-- ─── Auto update updated_at ───────────────────────────────────
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_conversations_updated_at BEFORE UPDATE ON conversations FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_messages_updated_at BEFORE UPDATE ON messages FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_tickets_updated_at BEFORE UPDATE ON tickets FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_courses_updated_at BEFORE UPDATE ON courses FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_groups_updated_at BEFORE UPDATE ON groups FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ─── Update unread count on new message ───────────────────────
CREATE OR REPLACE FUNCTION increment_unread_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE conversation_participants
    SET unread_count = unread_count + 1
    WHERE conversation_id = NEW.conversation_id
      AND user_id != NEW.sender_id
      AND left_at IS NULL;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_message_unread AFTER INSERT ON messages
    FOR EACH ROW EXECUTE FUNCTION increment_unread_count();

-- ─── Soft delete helper ───────────────────────────────────────
CREATE OR REPLACE FUNCTION soft_delete()
RETURNS TRIGGER AS $$
BEGIN
    NEW.deleted_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ─── Full text search function ────────────────────────────────
CREATE OR REPLACE FUNCTION search_messages(
    p_conversation_id UUID,
    p_query TEXT,
    p_limit INT DEFAULT 20,
    p_offset INT DEFAULT 0
)
RETURNS TABLE(id UUID, content TEXT, sender_id UUID, created_at TIMESTAMPTZ, rank REAL) AS $$
BEGIN
    RETURN QUERY
    SELECT m.id, m.content, m.sender_id, m.created_at,
           ts_rank(to_tsvector('arabic', coalesce(m.content,'')), plainto_tsquery('arabic', p_query)) AS rank
    FROM messages m
    WHERE m.conversation_id = p_conversation_id
      AND m.is_deleted = FALSE
      AND to_tsvector('arabic', coalesce(m.content,'')) @@ plainto_tsquery('arabic', p_query)
    ORDER BY rank DESC, m.created_at DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql;

-- ─── Get conversation summary ─────────────────────────────────
CREATE OR REPLACE FUNCTION get_conversations_for_user(p_user_id UUID)
RETURNS TABLE (
    conversation_id UUID,
    type conversation_type,
    title TEXT,
    last_message_content TEXT,
    last_message_at TIMESTAMPTZ,
    unread_count INT,
    is_pinned BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.id,
        c.type,
        COALESCE(c.title, (
            SELECT u.display_name FROM users u
            JOIN conversation_participants cp2 ON cp2.user_id = u.id
            WHERE cp2.conversation_id = c.id AND u.id != p_user_id
            LIMIT 1
        ))::TEXT,
        (SELECT m.content FROM messages m WHERE m.conversation_id = c.id ORDER BY m.created_at DESC LIMIT 1),
        (SELECT m.created_at FROM messages m WHERE m.conversation_id = c.id ORDER BY m.created_at DESC LIMIT 1),
        cp.unread_count,
        FALSE
    FROM conversations c
    JOIN conversation_participants cp ON cp.conversation_id = c.id
    WHERE cp.user_id = p_user_id AND cp.left_at IS NULL AND c.deleted_at IS NULL
    ORDER BY (SELECT m.created_at FROM messages m WHERE m.conversation_id = c.id ORDER BY created_at DESC LIMIT 1) DESC NULLS LAST;
END;
$$ LANGUAGE plpgsql;
