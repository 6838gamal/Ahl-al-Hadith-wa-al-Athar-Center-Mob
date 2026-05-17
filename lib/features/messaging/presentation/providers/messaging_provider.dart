import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/networking/api_client.dart';
import '../../../../core/networking/api_endpoints.dart';
import '../../../../shared/models/conversation_model.dart';
import '../../../../shared/models/message_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// ─── Conversations ────────────────────────────────────────────
final conversationsProvider =
    StateNotifierProvider<ConversationsNotifier, AsyncValue<List<ConversationModel>>>((ref) {
  ref.watch(currentUserProvider);
  return ConversationsNotifier();
});

class ConversationsNotifier extends StateNotifier<AsyncValue<List<ConversationModel>>> {
  final ApiClient _api = ApiClient.instance;

  ConversationsNotifier() : super(const AsyncValue.loading()) { load(); }

  Future<void> load() async {
    try {
      final res = await _api.get(ApiEndpoints.conversations);
      final list = (res.data as List)
          .map((json) => _parseConversation(json as Map<String, dynamic>))
          .toList();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void markRead(String conversationId) {
    state.whenData((convs) {
      state = AsyncValue.data(
          convs.map((c) => c.id == conversationId ? _clearUnread(c) : c).toList());
    });
  }

  ConversationModel _clearUnread(ConversationModel c) => ConversationModel(
        id: c.id, type: c.type, title: c.title, avatarUrl: c.avatarUrl,
        participantIds: c.participantIds, participants: c.participants,
        lastMessageContent: c.lastMessageContent, lastMessageSenderId: c.lastMessageSenderId,
        lastMessageType: c.lastMessageType, lastMessageAt: c.lastMessageAt,
        unreadCount: 0, isMuted: c.isMuted, isPinned: c.isPinned, createdAt: c.createdAt,
      );
}

ConversationModel _parseConversation(Map<String, dynamic> json) {
  final rawType = json['type'] as String? ?? 'direct';
  final convType = rawType == 'group' ? ConversationType.group : ConversationType.direct;

  final participants = (json['participants'] as List? ?? [])
      .map((p) => _parseParticipant(p as Map<String, dynamic>))
      .toList();

  final participantIds = participants.map((p) => p.id).toList();

  final last = json['last_message'] as Map<String, dynamic>?;

  return ConversationModel(
    id: json['id'] as String,
    type: convType,
    title: json['title'] as String?,
    avatarUrl: json['avatar_url'] as String?,
    participantIds: participantIds,
    participants: participants,
    lastMessageContent: last?['content'] as String?,
    lastMessageSenderId: last?['sender_id'] as String?,
    lastMessageType: last?['type'] as String?,
    lastMessageAt: last != null
        ? DateTime.tryParse(last['created_at'] as String? ?? '')
        : null,
    unreadCount: json['unread_count'] as int? ?? 0,
    isMuted: json['is_muted'] as bool? ?? false,
    isPinned: false,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}

ParticipantInfo _parseParticipant(Map<String, dynamic> json) {
  return ParticipantInfo(
    id: json['id'] as String,
    name: json['display_name'] as String? ?? json['username'] as String? ?? '',
    avatarUrl: json['avatar_url'] as String?,
    isOnline: json['is_online'] as bool? ?? false,
  );
}

// ─── Messages ─────────────────────────────────────────────────
final messagesProvider = StateNotifierProvider.family<MessagesNotifier,
    AsyncValue<List<MessageModel>>, String>(
  (ref, conversationId) => MessagesNotifier(conversationId),
);

class MessagesNotifier extends StateNotifier<AsyncValue<List<MessageModel>>> {
  final String _conversationId;
  final ApiClient _api = ApiClient.instance;

  MessagesNotifier(this._conversationId) : super(const AsyncValue.loading()) { load(); }

  Future<void> load() async {
    try {
      final res = await _api.get(ApiEndpoints.conversationMessages(_conversationId));
      final list = (res.data as List)
          .map((json) => _parseMessage(json as Map<String, dynamic>))
          .toList();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> sendMessage({
    required String senderId,
    required String senderName,
    required String content,
    MessageModel? replyTo,
  }) async {
    try {
      final res = await _api.post(
        ApiEndpoints.sendMessage(_conversationId),
        data: {
          'content': content,
          'type': 'text',
          if (replyTo != null) 'reply_to_id': replyTo.id,
        },
      );
      final msg = _parseMessage(res.data as Map<String, dynamic>);
      state.whenData((msgs) => state = AsyncValue.data([...msgs, msg]));
    } catch (e) {
      final tmp = MessageModel(
        id: 'tmp_${DateTime.now().millisecondsSinceEpoch}',
        conversationId: _conversationId,
        senderId: senderId,
        senderName: senderName,
        content: content,
        type: MessageType.text,
        status: MessageStatus.failed,
        createdAt: DateTime.now(),
      );
      state.whenData((msgs) => state = AsyncValue.data([...msgs, tmp]));
    }
  }

  Future<void> toggleReaction(String messageId, String emoji, String userId) async {
    try {
      await _api.post(ApiEndpoints.messageReaction(messageId), data: {'emoji': emoji});
      state.whenData((msgs) {
        state = AsyncValue.data(msgs.map((m) {
          if (m.id != messageId) return m;
          final reactions = Map<String, List<String>>.from(
              m.reactions.map((k, v) => MapEntry(k, List<String>.from(v))));
          final users = List<String>.from(reactions[emoji] ?? []);
          if (users.contains(userId)) {
            users.remove(userId);
            if (users.isEmpty) reactions.remove(emoji);
            else reactions[emoji] = users;
          } else {
            reactions[emoji] = [...users, userId];
          }
          return m.copyWith(reactions: reactions);
        }).toList());
      });
    } catch (_) {}
  }
}

MessageModel _parseMessage(Map<String, dynamic> json) {
  final sender = json['sender'] as Map<String, dynamic>?;
  final replyTo = json['reply_to'] as Map<String, dynamic>?;

  final reactions = <String, List<String>>{};
  for (final r in (json['reactions'] as List? ?? [])) {
    final emoji = r['emoji'] as String;
    final userId = r['user_id'] as String;
    reactions[emoji] = [...(reactions[emoji] ?? []), userId];
  }

  return MessageModel(
    id: json['id'] as String,
    conversationId: json['conversation_id'] as String,
    senderId: json['sender_id'] as String,
    senderName: sender?['display_name'] as String? ??
        sender?['username'] as String? ?? '',
    senderAvatarUrl: sender?['avatar_url'] as String?,
    content: json['content'] as String?,
    type: MessageType.values.firstWhere(
      (t) => t.name == (json['type'] as String? ?? 'text'),
      orElse: () => MessageType.text,
    ),
    status: MessageStatus.values.firstWhere(
      (s) => s.name == (json['status'] as String? ?? 'sent'),
      orElse: () => MessageStatus.sent,
    ),
    replyToId: json['reply_to_id'] as String?,
    replyToContent: replyTo?['content'] as String?,
    replyToSenderName: replyTo?['sender'] != null
        ? (replyTo!['sender'] as Map<String, dynamic>)['display_name'] as String? ??
            (replyTo['sender'] as Map<String, dynamic>)['username'] as String?
        : null,
    reactions: reactions,
    mentionedUserIds: List<String>.from(json['mentioned_user_ids'] as List? ?? []),
    isDeleted: json['is_deleted'] as bool? ?? false,
    editedAt: json['edited_at'] != null
        ? DateTime.tryParse(json['edited_at'] as String)
        : null,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}

// ─── Active Conversation ──────────────────────────────────────
final activeConversationProvider = StateProvider<ConversationModel?>((ref) => null);
final replyToMessageProvider = StateProvider<MessageModel?>((ref) => null);
