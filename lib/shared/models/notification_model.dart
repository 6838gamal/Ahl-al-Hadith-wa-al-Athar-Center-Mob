enum NotificationType { message, group, course, ticket, system, announcement }

class NotificationModel {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final bool isRead;
  final String? actionUrl;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.isRead = false,
    this.actionUrl,
    this.metadata,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) => NotificationModel(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        type: NotificationType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => NotificationType.system,
        ),
        title: json['title'] as String,
        body: json['body'] as String,
        isRead: json['is_read'] as bool? ?? false,
        actionUrl: json['action_url'] as String?,
        metadata: json['metadata'] as Map<String, dynamic>?,
        createdAt: DateTime.parse(json['created_at']),
      );

  NotificationModel copyWith({bool? isRead}) => NotificationModel(
        id: id,
        userId: userId,
        type: type,
        title: title,
        body: body,
        isRead: isRead ?? this.isRead,
        actionUrl: actionUrl,
        metadata: metadata,
        createdAt: createdAt,
      );

  String get typeIcon {
    switch (type) {
      case NotificationType.message: return '💬';
      case NotificationType.group: return '👥';
      case NotificationType.course: return '📚';
      case NotificationType.ticket: return '🎫';
      case NotificationType.announcement: return '📢';
      case NotificationType.system: return '⚙️';
    }
  }
}
