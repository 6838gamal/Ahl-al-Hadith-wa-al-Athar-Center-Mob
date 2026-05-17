enum ConversationType { direct, group }

class ConversationModel {
  final String id;
  final ConversationType type;
  final String? title;
  final String? avatarUrl;
  final List<String> participantIds;
  final List<ParticipantInfo> participants;
  final String? lastMessageContent;
  final String? lastMessageSenderId;
  final String? lastMessageType;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final bool isMuted;
  final bool isPinned;
  final DateTime createdAt;

  const ConversationModel({
    required this.id,
    required this.type,
    this.title,
    this.avatarUrl,
    required this.participantIds,
    this.participants = const [],
    this.lastMessageContent,
    this.lastMessageSenderId,
    this.lastMessageType,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.isMuted = false,
    this.isPinned = false,
    required this.createdAt,
  });

  bool get isDirect => type == ConversationType.direct;
  bool get isGroup => type == ConversationType.group;
  bool get hasUnread => unreadCount > 0;

  String getDisplayName(String currentUserId) {
    if (isGroup) return title ?? 'مجموعة';
    final other = participants.firstWhere(
      (p) => p.id != currentUserId,
      orElse: () => participants.isNotEmpty ? participants.first : ParticipantInfo(id: '', name: 'مجهول'),
    );
    return other.name;
  }

  String? getDisplayAvatar(String currentUserId) {
    if (isGroup) return avatarUrl;
    final other = participants.firstWhere(
      (p) => p.id != currentUserId,
      orElse: () => ParticipantInfo(id: '', name: ''),
    );
    return other.avatarUrl;
  }

  factory ConversationModel.fromJson(Map<String, dynamic> json) => ConversationModel(
        id: json['id'] as String,
        type: json['type'] == 'group' ? ConversationType.group : ConversationType.direct,
        title: json['title'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        participantIds: List<String>.from(json['participant_ids'] ?? []),
        participants: (json['participants'] as List<dynamic>?)
                ?.map((p) => ParticipantInfo.fromJson(p))
                .toList() ??
            [],
        lastMessageContent: json['last_message_content'] as String?,
        lastMessageSenderId: json['last_message_sender_id'] as String?,
        lastMessageType: json['last_message_type'] as String?,
        lastMessageAt: json['last_message_at'] != null ? DateTime.parse(json['last_message_at']) : null,
        unreadCount: json['unread_count'] as int? ?? 0,
        isMuted: json['is_muted'] as bool? ?? false,
        isPinned: json['is_pinned'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'avatar_url': avatarUrl,
        'participant_ids': participantIds,
        'participants': participants.map((p) => p.toJson()).toList(),
        'last_message_content': lastMessageContent,
        'last_message_sender_id': lastMessageSenderId,
        'last_message_type': lastMessageType,
        'last_message_at': lastMessageAt?.toIso8601String(),
        'unread_count': unreadCount,
        'is_muted': isMuted,
        'is_pinned': isPinned,
        'created_at': createdAt.toIso8601String(),
      };
}

class ParticipantInfo {
  final String id;
  final String name;
  final String? avatarUrl;
  final bool isOnline;

  ParticipantInfo({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.isOnline = false,
  });

  factory ParticipantInfo.fromJson(Map<String, dynamic> json) => ParticipantInfo(
        id: json['id'] as String,
        name: json['name'] as String,
        avatarUrl: json['avatar_url'] as String?,
        isOnline: json['is_online'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'avatar_url': avatarUrl,
        'is_online': isOnline,
      };
}
