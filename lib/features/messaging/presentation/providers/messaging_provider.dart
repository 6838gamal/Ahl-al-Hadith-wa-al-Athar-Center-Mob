import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/mock_data_service.dart';
import '../../../../shared/models/conversation_model.dart';
import '../../../../shared/models/message_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'package:uuid/uuid.dart';

// ─── Conversations ────────────────────────────────────────────
final conversationsProvider = StateNotifierProvider<ConversationsNotifier, AsyncValue<List<ConversationModel>>>((ref) {
  final user = ref.watch(currentUserProvider);
  return ConversationsNotifier(MockDataService.instance, user?.id ?? '');
});

class ConversationsNotifier extends StateNotifier<AsyncValue<List<ConversationModel>>> {
  final MockDataService _mock;
  final String _userId;

  ConversationsNotifier(this._mock, this._userId) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    await Future.delayed(const Duration(milliseconds: 400));
    final conversations = _mock.getConversations(_userId);
    conversations.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      final aTime = a.lastMessageAt ?? a.createdAt;
      final bTime = b.lastMessageAt ?? b.createdAt;
      return bTime.compareTo(aTime);
    });
    state = AsyncValue.data(conversations);
  }

  void markRead(String conversationId) {
    state.whenData((convs) {
      state = AsyncValue.data(convs.map((c) => c.id == conversationId ? _clearUnread(c) : c).toList());
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

// ─── Messages ─────────────────────────────────────────────────
final messagesProvider = StateNotifierProvider.family<MessagesNotifier, AsyncValue<List<MessageModel>>, String>((ref, conversationId) {
  return MessagesNotifier(MockDataService.instance, conversationId);
});

class MessagesNotifier extends StateNotifier<AsyncValue<List<MessageModel>>> {
  final MockDataService _mock;
  final String _conversationId;
  final _uuid = const Uuid();

  MessagesNotifier(this._mock, this._conversationId) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    await Future.delayed(const Duration(milliseconds: 300));
    state = AsyncValue.data(_mock.getMessages(_conversationId));
  }

  Future<void> sendMessage({required String senderId, required String senderName, required String content, MessageModel? replyTo}) async {
    final msg = MessageModel(
      id: _uuid.v4(),
      conversationId: _conversationId,
      senderId: senderId,
      senderName: senderName,
      content: content,
      type: MessageType.text,
      status: MessageStatus.sending,
      replyToId: replyTo?.id,
      replyToContent: replyTo?.content,
      replyToSenderName: replyTo?.senderName,
      createdAt: DateTime.now(),
    );
    state.whenData((messages) => state = AsyncValue.data([...messages, msg]));
    await Future.delayed(const Duration(milliseconds: 600));
    state.whenData((messages) => state = AsyncValue.data(
      messages.map((m) => m.id == msg.id ? m.copyWith(status: MessageStatus.sent) : m).toList(),
    ));
  }

  void toggleReaction(String messageId, String emoji, String userId) {
    state.whenData((messages) {
      state = AsyncValue.data(messages.map((m) {
        if (m.id != messageId) return m;
        final reactions = Map<String, List<String>>.from(m.reactions.map((k, v) => MapEntry(k, List<String>.from(v))));
        final users = reactions[emoji] ?? [];
        if (users.contains(userId)) {
          users.remove(userId);
          if (users.isEmpty) reactions.remove(emoji);
        } else {
          users.add(userId);
          reactions[emoji] = users;
        }
        return m.copyWith(reactions: reactions);
      }).toList());
    });
  }
}

// ─── Active Conversation ──────────────────────────────────────
final activeConversationProvider = StateProvider<ConversationModel?>((ref) => null);
final replyToMessageProvider = StateProvider<MessageModel?>((ref) => null);
