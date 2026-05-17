import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../shared/models/conversation_model.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/messaging_provider.dart';
import '../../../../core/extensions/datetime_extensions.dart';

class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationsProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('المحادثات'),
        actions: [
          IconButton(icon: const Icon(Icons.search_rounded), onPressed: () {}),
          IconButton(icon: const Icon(Icons.edit_rounded), onPressed: () {}),
        ],
      ),
      body: conversationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('حدث خطأ: $e')),
        data: (conversations) => ListView.builder(
          itemCount: conversations.length,
          itemBuilder: (context, index) => _ConversationTile(
            conversation: conversations[index],
            currentUserId: currentUser?.id ?? '',
            onTap: () {
              ref.read(activeConversationProvider.notifier).state = conversations[index];
              ref.read(conversationsProvider.notifier).markRead(conversations[index].id);
              context.push('/home/chat/${conversations[index].id}');
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.message_rounded, color: Colors.white),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ConversationModel conversation;
  final String currentUserId;
  final VoidCallback onTap;

  const _ConversationTile({required this.conversation, required this.currentUserId, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = conversation.getDisplayName(currentUserId);
    final avatar = conversation.getDisplayAvatar(currentUserId);
    final time = conversation.lastMessageAt?.chatTime ?? '';
    final lastMsg = _formatLastMessage();

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: conversation.unreadCount > 0 ? AppColors.primary.withOpacity(0.03) : Colors.white,
          border: const Border(bottom: BorderSide(color: AppColors.divider, width: 0.5)),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                UserAvatar(name: name, avatarUrl: avatar, size: 52, showOnline: conversation.isDirect, isOnline: true),
                if (conversation.isGroup)
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                      child: const Icon(Icons.group_rounded, size: 12, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (conversation.isPinned) ...[
                        const Icon(Icons.push_pin_rounded, size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(name, style: AppTextStyles.body.copyWith(fontWeight: conversation.hasUnread ? FontWeight.w700 : FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      Text(time, style: AppTextStyles.timestamp.copyWith(color: conversation.hasUnread ? AppColors.primary : null)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(child: Text(lastMsg, style: AppTextStyles.bodySmall.copyWith(fontWeight: conversation.hasUnread ? FontWeight.w600 : FontWeight.w400), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      if (conversation.hasUnread)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: const BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.all(Radius.circular(10))),
                          child: Text('${conversation.unreadCount}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                      if (conversation.isMuted)
                        const Icon(Icons.volume_off_rounded, size: 14, color: AppColors.textMuted),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatLastMessage() {
    final type = conversation.lastMessageType;
    final content = conversation.lastMessageContent;
    if (type == 'audio') return '🎙️ رسالة صوتية';
    if (type == 'image') return '📷 صورة';
    if (type == 'file') return '📄 ملف';
    return content ?? '';
  }
}
