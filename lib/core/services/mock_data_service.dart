import '../../shared/models/user_model.dart';
import '../../shared/models/message_model.dart';
import '../../shared/models/conversation_model.dart';
import '../../shared/models/notification_model.dart';

class MockDataService {
  MockDataService._();
  static final instance = MockDataService._();

  // ─── Mock Users ───────────────────────────────────────────────
  final List<UserModel> _users = [
    UserModel(id: 'u1', username: 'admin', displayName: 'مدير النظام', academicId: 'ADM001', role: 'admin', status: 'active', gender: 'male', isOnline: true, createdAt: DateTime(2024, 1, 1)),
    UserModel(id: 'u2', username: 'sheikh_ibrahim', displayName: 'الشيخ إبراهيم العمري', academicId: 'SHK001', role: 'sheikh', status: 'active', gender: 'male', isOnline: true, createdAt: DateTime(2024, 1, 5)),
    UserModel(id: 'u3', username: 'mod_sara', displayName: 'سارة المشرفة', academicId: 'MOD001', role: 'moderator', status: 'active', gender: 'female', isOnline: false, createdAt: DateTime(2024, 2, 1)),
    UserModel(id: 'u4', username: 'student_ali', displayName: 'علي محمد الزهراني', academicId: 'STU001', role: 'male_student', status: 'active', gender: 'male', isOnline: true, createdAt: DateTime(2024, 3, 1)),
    UserModel(id: 'u5', username: 'student_fatima', displayName: 'فاطمة عبدالله الأنصاري', academicId: 'STU002', role: 'female_student', status: 'active', gender: 'female', isOnline: false, createdAt: DateTime(2024, 3, 5)),
    UserModel(id: 'u6', username: 'student_omar', displayName: 'عمر خالد السلمي', academicId: 'STU003', role: 'male_student', status: 'active', gender: 'male', isOnline: false, createdAt: DateTime(2024, 3, 10)),
    UserModel(id: 'u7', username: 'pending_user', displayName: 'محمد أحمد المنتظر', academicId: 'STU004', role: 'male_student', status: 'pending', gender: 'male', isOnline: false, createdAt: DateTime(2024, 4, 1)),
    UserModel(id: 'u8', username: 'sheikh_hamad', displayName: 'الشيخ حمد الدوسري', academicId: 'SHK002', role: 'sheikh', status: 'active', gender: 'male', isOnline: true, createdAt: DateTime(2024, 1, 20)),
  ];

  List<UserModel> get allUsers => List.unmodifiable(_users);
  List<UserModel> get activeUsers => _users.where((u) => u.status == 'active').toList();
  List<UserModel> get pendingUsers => _users.where((u) => u.status == 'pending').toList();

  UserModel? getUserById(String id) => _users.cast<UserModel?>().firstWhere((u) => u?.id == id, orElse: () => null);

  UserModel? authenticate(String username, String password) {
    if (password.length < 4) return null;
    return _users.cast<UserModel?>().firstWhere((u) => u?.username == username && u?.status == 'active', orElse: () => null);
  }

  // ─── Mock Conversations ───────────────────────────────────────
  List<ConversationModel> getConversations(String userId) => [
        ConversationModel(
          id: 'conv1',
          type: ConversationType.direct,
          participantIds: [userId, 'u2'],
          participants: [
            ParticipantInfo(id: userId, name: getUserById(userId)?.effectiveName ?? ''),
            ParticipantInfo(id: 'u2', name: 'الشيخ إبراهيم العمري', isOnline: true),
          ],
          lastMessageContent: 'جزاك الله خيراً شيخنا على الإجابة',
          lastMessageType: 'text',
          lastMessageAt: DateTime.now().subtract(const Duration(minutes: 5)),
          unreadCount: 2,
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
        ),
        ConversationModel(
          id: 'conv2',
          type: ConversationType.group,
          title: 'مجلس أهل الحديث العام',
          participantIds: ['u1', 'u2', 'u4', 'u6', 'u8'],
          participants: [],
          lastMessageContent: 'درس الغد سيكون بإذن الله عن صحيح البخاري',
          lastMessageType: 'text',
          lastMessageAt: DateTime.now().subtract(const Duration(hours: 2)),
          unreadCount: 15,
          isPinned: true,
          createdAt: DateTime.now().subtract(const Duration(days: 60)),
        ),
        ConversationModel(
          id: 'conv3',
          type: ConversationType.direct,
          participantIds: [userId, 'u3'],
          participants: [
            ParticipantInfo(id: userId, name: getUserById(userId)?.effectiveName ?? ''),
            ParticipantInfo(id: 'u3', name: 'سارة المشرفة', isOnline: false),
          ],
          lastMessageContent: 'تم تسجيلك في دورة مصطلح الحديث',
          lastMessageType: 'text',
          lastMessageAt: DateTime.now().subtract(const Duration(days: 1)),
          unreadCount: 0,
          createdAt: DateTime.now().subtract(const Duration(days: 20)),
        ),
        ConversationModel(
          id: 'conv4',
          type: ConversationType.group,
          title: 'حلقة دراسة الحديث النبوي',
          participantIds: ['u2', 'u4', 'u6'],
          participants: [],
          lastMessageContent: '🎙️ رسالة صوتية',
          lastMessageType: 'audio',
          lastMessageAt: DateTime.now().subtract(const Duration(hours: 5)),
          unreadCount: 3,
          createdAt: DateTime.now().subtract(const Duration(days: 15)),
        ),
      ];

  // ─── Mock Messages ────────────────────────────────────────────
  List<MessageModel> getMessages(String conversationId) {
    final now = DateTime.now();
    return [
      MessageModel(id: 'm1', conversationId: conversationId, senderId: 'u2', senderName: 'الشيخ إبراهيم العمري', content: 'السلام عليكم ورحمة الله وبركاته', type: MessageType.text, status: MessageStatus.read, createdAt: now.subtract(const Duration(hours: 2, minutes: 30))),
      MessageModel(id: 'm2', conversationId: conversationId, senderId: 'u4', senderName: 'علي محمد', content: 'وعليكم السلام ورحمة الله وبركاته شيخنا الفاضل', type: MessageType.text, status: MessageStatus.read, createdAt: now.subtract(const Duration(hours: 2, minutes: 25))),
      MessageModel(id: 'm3', conversationId: conversationId, senderId: 'u2', senderName: 'الشيخ إبراهيم العمري', content: 'اليوم سنشرح حديث إنما الأعمال بالنيات من صحيح البخاري رقم ١', type: MessageType.text, status: MessageStatus.read, createdAt: now.subtract(const Duration(hours: 2, minutes: 20))),
      MessageModel(id: 'm4', conversationId: conversationId, senderId: 'u2', senderName: 'الشيخ إبراهيم العمري', type: MessageType.audio, status: MessageStatus.read, mediaUrl: 'mock://audio/lesson1.mp3', mediaDurationSeconds: 187, createdAt: now.subtract(const Duration(hours: 2))),
      MessageModel(id: 'm5', conversationId: conversationId, senderId: 'u4', senderName: 'علي محمد', content: 'جزاك الله خيراً شيخنا، سؤال: ما هو شرط النية في العبادة؟', type: MessageType.text, status: MessageStatus.read, createdAt: now.subtract(const Duration(hours: 1, minutes: 45)), replyToId: 'm4', replyToContent: '🎙️ رسالة صوتية', replyToSenderName: 'الشيخ إبراهيم'),
      MessageModel(id: 'm6', conversationId: conversationId, senderId: 'u6', senderName: 'عمر خالد', content: 'سؤال مهم بارك الله فيك أخي', type: MessageType.text, status: MessageStatus.read, reactions: {'👍': ['u2', 'u4'], '❤️': ['u8']}, createdAt: now.subtract(const Duration(hours: 1, minutes: 40))),
      MessageModel(id: 'm7', conversationId: conversationId, senderId: 'u2', senderName: 'الشيخ إبراهيم العمري', content: 'النية شرط في كل العبادات، وهي محلها القلب، ولا تصح العبادة بدونها. وقد ذهب الجمهور إلى أنها ركن من أركان العبادة.', type: MessageType.text, status: MessageStatus.read, mentionedUserIds: ['u4'], createdAt: now.subtract(const Duration(hours: 1, minutes: 30))),
      MessageModel(id: 'm8', conversationId: conversationId, senderId: 'u4', senderName: 'علي محمد', content: 'جزاك الله خيراً شيخنا على الإجابة', type: MessageType.text, status: MessageStatus.sent, createdAt: now.subtract(const Duration(minutes: 5))),
    ];
  }

  // ─── Mock Notifications ───────────────────────────────────────
  List<NotificationModel> getNotifications(String userId) => [
        NotificationModel(id: 'n1', userId: userId, type: NotificationType.message, title: 'رسالة جديدة', body: 'أرسل لك الشيخ إبراهيم رسالة جديدة', isRead: false, createdAt: DateTime.now().subtract(const Duration(minutes: 10))),
        NotificationModel(id: 'n2', userId: userId, type: NotificationType.announcement, title: 'إعلان مهم', body: 'سيبدأ درس مصطلح الحديث غداً بإذن الله', isRead: false, createdAt: DateTime.now().subtract(const Duration(hours: 3))),
        NotificationModel(id: 'n3', userId: userId, type: NotificationType.course, title: 'دورة جديدة', body: 'تم إضافة دورة: أصول الحديث النبوي', isRead: true, createdAt: DateTime.now().subtract(const Duration(days: 1))),
        NotificationModel(id: 'n4', userId: userId, type: NotificationType.ticket, title: 'تم الرد على تذكرتك', body: 'تم الرد على استفساركم بشأن التسجيل', isRead: true, createdAt: DateTime.now().subtract(const Duration(days: 2))),
      ];

  // ─── Admin Stats ──────────────────────────────────────────────
  Map<String, dynamic> getAdminStats() => {
        'total_users': _users.length,
        'active_users': activeUsers.length,
        'pending_users': pendingUsers.length,
        'total_conversations': 24,
        'total_messages_today': 147,
        'open_tickets': 8,
        'active_courses': 5,
        'total_groups': 12,
      };
}
