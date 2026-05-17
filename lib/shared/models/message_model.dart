enum MessageType { text, audio, image, file, system }
enum MessageStatus { sending, sent, delivered, read, failed }

class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String? senderAvatarUrl;
  final String? content;
  final MessageType type;
  final MessageStatus status;
  final String? mediaUrl;
  final int? mediaDurationSeconds;
  final int? mediaFileSizeBytes;
  final String? replyToId;
  final String? replyToContent;
  final String? replyToSenderName;
  final List<String> mentionedUserIds;
  final Map<String, List<String>> reactions;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime? editedAt;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    this.senderAvatarUrl,
    this.content,
    required this.type,
    required this.status,
    this.mediaUrl,
    this.mediaDurationSeconds,
    this.mediaFileSizeBytes,
    this.replyToId,
    this.replyToContent,
    this.replyToSenderName,
    this.mentionedUserIds = const [],
    this.reactions = const {},
    this.isDeleted = false,
    required this.createdAt,
    this.editedAt,
  });

  bool get hasMedia => mediaUrl != null;
  bool get isAudio => type == MessageType.audio;
  bool get isImage => type == MessageType.image;
  bool get isText => type == MessageType.text;
  bool get hasReply => replyToId != null;
  bool get hasReactions => reactions.isNotEmpty;
  int get totalReactions => reactions.values.fold(0, (sum, list) => sum + list.length);

  factory MessageModel.fromJson(Map<String, dynamic> json) => MessageModel(
        id: json['id'] as String,
        conversationId: json['conversation_id'] as String,
        senderId: json['sender_id'] as String,
        senderName: json['sender_name'] as String,
        senderAvatarUrl: json['sender_avatar_url'] as String?,
        content: json['content'] as String?,
        type: MessageType.values.firstWhere((e) => e.name == json['type'], orElse: () => MessageType.text),
        status: MessageStatus.values.firstWhere((e) => e.name == json['status'], orElse: () => MessageStatus.sent),
        mediaUrl: json['media_url'] as String?,
        mediaDurationSeconds: json['media_duration_seconds'] as int?,
        mediaFileSizeBytes: json['media_file_size_bytes'] as int?,
        replyToId: json['reply_to_id'] as String?,
        replyToContent: json['reply_to_content'] as String?,
        replyToSenderName: json['reply_to_sender_name'] as String?,
        mentionedUserIds: List<String>.from(json['mentioned_user_ids'] ?? []),
        reactions: (json['reactions'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, List<String>.from(v))) ??
            {},
        isDeleted: json['is_deleted'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at']),
        editedAt: json['edited_at'] != null ? DateTime.parse(json['edited_at']) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversation_id': conversationId,
        'sender_id': senderId,
        'sender_name': senderName,
        'sender_avatar_url': senderAvatarUrl,
        'content': content,
        'type': type.name,
        'status': status.name,
        'media_url': mediaUrl,
        'media_duration_seconds': mediaDurationSeconds,
        'media_file_size_bytes': mediaFileSizeBytes,
        'reply_to_id': replyToId,
        'reply_to_content': replyToContent,
        'reply_to_sender_name': replyToSenderName,
        'mentioned_user_ids': mentionedUserIds,
        'reactions': reactions,
        'is_deleted': isDeleted,
        'created_at': createdAt.toIso8601String(),
        'edited_at': editedAt?.toIso8601String(),
      };

  MessageModel copyWith({
    MessageStatus? status,
    bool? isDeleted,
    Map<String, List<String>>? reactions,
  }) =>
      MessageModel(
        id: id,
        conversationId: conversationId,
        senderId: senderId,
        senderName: senderName,
        senderAvatarUrl: senderAvatarUrl,
        content: content,
        type: type,
        status: status ?? this.status,
        mediaUrl: mediaUrl,
        mediaDurationSeconds: mediaDurationSeconds,
        mediaFileSizeBytes: mediaFileSizeBytes,
        replyToId: replyToId,
        replyToContent: replyToContent,
        replyToSenderName: replyToSenderName,
        mentionedUserIds: mentionedUserIds,
        reactions: reactions ?? this.reactions,
        isDeleted: isDeleted ?? this.isDeleted,
        createdAt: createdAt,
        editedAt: editedAt,
      );
}
