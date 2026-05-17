-- =============================================================
-- Seed Data - مركز أهل الحديث والأثر
-- Password hash for '1234' (bcrypt)
-- =============================================================

-- ─── Users ────────────────────────────────────────────────────
INSERT INTO users (id, username, display_name, academic_id, role, status, gender, password_hash, is_online) VALUES
    ('11111111-1111-1111-1111-111111111111', 'admin', 'مدير النظام', 'ADM001', 'admin', 'active', 'male', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQyCgC7MVQvhLT0hOGLcD4Qwq', true),
    ('22222222-2222-2222-2222-222222222222', 'sheikh_ibrahim', 'الشيخ إبراهيم العمري', 'SHK001', 'sheikh', 'active', 'male', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQyCgC7MVQvhLT0hOGLcD4Qwq', true),
    ('33333333-3333-3333-3333-333333333333', 'mod_sara', 'سارة المشرفة', 'MOD001', 'moderator', 'active', 'female', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQyCgC7MVQvhLT0hOGLcD4Qwq', false),
    ('44444444-4444-4444-4444-444444444444', 'student_ali', 'علي محمد الزهراني', 'STU001', 'male_student', 'active', 'male', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQyCgC7MVQvhLT0hOGLcD4Qwq', true),
    ('55555555-5555-5555-5555-555555555555', 'student_fatima', 'فاطمة عبدالله الأنصاري', 'STU002', 'female_student', 'active', 'female', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQyCgC7MVQvhLT0hOGLcD4Qwq', false),
    ('66666666-6666-6666-6666-666666666666', 'student_omar', 'عمر خالد السلمي', 'STU003', 'male_student', 'active', 'male', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQyCgC7MVQvhLT0hOGLcD4Qwq', false),
    ('77777777-7777-7777-7777-777777777777', 'pending_user', 'محمد أحمد المنتظر', 'STU004', 'male_student', 'pending', 'male', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQyCgC7MVQvhLT0hOGLcD4Qwq', false);

-- ─── Conversations ────────────────────────────────────────────
INSERT INTO conversations (id, type, title) VALUES
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'group', 'مجلس أهل الحديث العام'),
    ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'group', 'حلقة دراسة الحديث النبوي'),
    ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'direct', NULL);

-- ─── Participants ─────────────────────────────────────────────
INSERT INTO conversation_participants (conversation_id, user_id) VALUES
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111'),
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '22222222-2222-2222-2222-222222222222'),
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '44444444-4444-4444-4444-444444444444'),
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '66666666-6666-6666-6666-666666666666'),
    ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '22222222-2222-2222-2222-222222222222'),
    ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '44444444-4444-4444-4444-444444444444'),
    ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '66666666-6666-6666-6666-666666666666'),
    ('cccccccc-cccc-cccc-cccc-cccccccccccc', '44444444-4444-4444-4444-444444444444'),
    ('cccccccc-cccc-cccc-cccc-cccccccccccc', '22222222-2222-2222-2222-222222222222');

-- ─── Messages ─────────────────────────────────────────────────
INSERT INTO messages (conversation_id, sender_id, content, type, status) VALUES
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '22222222-2222-2222-2222-222222222222', 'السلام عليكم ورحمة الله وبركاته', 'text', 'read'),
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '44444444-4444-4444-4444-444444444444', 'وعليكم السلام ورحمة الله وبركاته شيخنا', 'text', 'read'),
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '22222222-2222-2222-2222-222222222222', 'درس الغد سيكون بإذن الله عن صحيح البخاري', 'text', 'read');

-- ─── Courses ──────────────────────────────────────────────────
INSERT INTO courses (title, description, instructor_id, status) VALUES
    ('مقدمة في علم الحديث', 'شرح مفصل لمصطلح الحديث النبوي', '22222222-2222-2222-2222-222222222222', 'published'),
    ('دراسة صحيح البخاري', 'شرح الأحاديث المختارة من صحيح الإمام البخاري', '22222222-2222-2222-2222-222222222222', 'published'),
    ('علوم القرآن الكريم', 'مقدمة في التفسير وعلوم القرآن', '22222222-2222-2222-2222-222222222222', 'draft');

-- ─── Tickets ──────────────────────────────────────────────────
INSERT INTO tickets (title, body, submitter_id, status, priority) VALUES
    ('استفسار عن موعد الدرس', 'هل سيُقام الدرس الأسبوعي يوم الجمعة؟', '44444444-4444-4444-4444-444444444444', 'open', 'medium'),
    ('مشكلة في تسجيل الدخول', 'لا أستطيع الدخول منذ يومين', '55555555-5555-5555-5555-555555555555', 'in_progress', 'high'),
    ('طلب شهادة إتمام دورة', 'أطلب شهادة لدورة مصطلح الحديث', '66666666-6666-6666-6666-666666666666', 'resolved', 'low');
