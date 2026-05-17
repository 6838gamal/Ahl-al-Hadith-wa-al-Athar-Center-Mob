import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../shared/models/message_model.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/messaging_provider.dart';
import '../../../../core/extensions/datetime_extensions.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input.dart';

class ChatScreen extends ConsumerWidget {
  final String conversationId;
  const ChatScreen({super.key, required this.conversationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversation = ref.watch(activeConversationProvider);
    final messagesAsync = ref.watch(messagesProvider(conversationId));
    final currentUser = ref.watch(currentUserProvider);
    final replyTo = ref.watch(replyToMessageProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F4F8),
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white), onPressed: () => context.pop()),
          title: conversation != null
              ? Row(
                  children: [
                    UserAvatar(name: conversation.getDisplayName(currentUser?.id ?? ''), size: 36, showOnline: conversation.isDirect, isOnline: true),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(conversation.getDisplayName(currentUser?.id ?? ''), style: AppTextStyles.appBarTitle.copyWith(fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(conversation.isGroup ? '${conversation.participantIds.length} عضو' : 'متصل الآن', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                )
              : const Text('المحادثة'),
          actions: [
            IconButton(icon: const Icon(Icons.call_outlined, color: Colors.white), onPressed: () {}),
            IconButton(icon: const Icon(Icons.more_vert_rounded, color: Colors.white), onPressed: () {}),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: messagesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('خطأ: $e')),
                data: (messages) => _MessagesList(messages: messages, currentUserId: currentUser?.id ?? '', onReply: (msg) => ref.read(replyToMessageProvider.notifier).state = msg, onReact: (msgId, emoji) => ref.read(messagesProvider(conversationId).notifier).toggleReaction(msgId, emoji, currentUser?.id ?? '')),
              ),
            ),
            MessageInput(
              replyTo: replyTo,
              onClearReply: () => ref.read(replyToMessageProvider.notifier).state = null,
              onSend: (text) {
                if (currentUser == null) return;
                ref.read(messagesProvider(conversationId).notifier).sendMessage(senderId: currentUser.id, senderName: currentUser.effectiveName, content: text, replyTo: replyTo);
                ref.read(replyToMessageProvider.notifier).state = null;
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MessagesList extends StatefulWidget {
  final List<MessageModel> messages;
  final String currentUserId;
  final void Function(MessageModel) onReply;
  final void Function(String, String) onReact;

  const _MessagesList({required this.messages, required this.currentUserId, required this.onReply, required this.onReact});

  @override
  State<_MessagesList> createState() => _MessagesListState();
}

class _MessagesListState extends State<_MessagesList> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void didUpdateWidget(_MessagesList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.messages.length != oldWidget.messages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      itemCount: widget.messages.length,
      itemBuilder: (context, index) {
        final msg = widget.messages[index];
        final prev = index > 0 ? widget.messages[index - 1] : null;
        final showDate = prev == null || !_sameDay(msg.createdAt, prev.createdAt);
        final showAvatar = msg.senderId != (index + 1 < widget.messages.length ? widget.messages[index + 1].senderId : null);

        return Column(
          children: [
            if (showDate) _DateDivider(date: msg.createdAt),
            MessageBubble(
              message: msg,
              isMe: msg.senderId == widget.currentUserId,
              showAvatar: showAvatar,
              onReply: () => widget.onReply(msg),
              onReact: (emoji) => widget.onReact(msg.id, emoji),
            ),
          ],
        );
      },
    );
  }

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DateDivider extends StatelessWidget {
  final DateTime date;
  const _DateDivider({required this.date});

  @override
  Widget build(BuildContext context) {
    String label;
    if (date.isToday) label = 'اليوم';
    else if (date.isYesterday) label = 'أمس';
    else label = date.dateOnly;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider(color: AppColors.border)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]),
              child: Text(label, style: AppTextStyles.caption),
            ),
          ),
          const Expanded(child: Divider(color: AppColors.border)),
        ],
      ),
    );
  }
}
