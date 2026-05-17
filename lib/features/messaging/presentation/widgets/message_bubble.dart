import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../shared/models/message_model.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../../../core/extensions/datetime_extensions.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final bool showAvatar;
  final VoidCallback onReply;
  final void Function(String emoji) onReact;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.showAvatar,
    required this.onReply,
    required this.onReact,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2, top: showAvatar ? 8 : 2),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            showAvatar
                ? UserAvatar(name: message.senderName, size: 32)
                : const SizedBox(width: 32),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showOptions(context),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!isMe && showAvatar)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4, right: 4, left: 4),
                      child: Text(message.senderName, style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ),
                  _buildBubble(context),
                  if (message.hasReactions) _buildReactions(),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 6),
        ],
      ),
    );
  }

  Widget _buildBubble(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
      child: Container(
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.hasReply) _buildReplyPreview(),
            if (message.isDeleted)
              Text('تم حذف هذه الرسالة', style: AppTextStyles.bodySmall.copyWith(color: isMe ? Colors.white70 : AppColors.textMuted, fontStyle: FontStyle.italic))
            else if (message.isAudio)
              _buildAudioContent()
            else if (message.isImage)
              _buildImageContent()
            else
              Text(message.content ?? '', style: AppTextStyles.messageBubble.copyWith(color: isMe ? Colors.white : AppColors.textPrimary)),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(message.createdAt.timeOnly, style: AppTextStyles.timestamp.copyWith(color: isMe ? Colors.white60 : AppColors.textMuted)),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  _buildStatusIcon(),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isMe ? Colors.white.withOpacity(0.15) : AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border(right: BorderSide(color: isMe ? Colors.white : AppColors.primary, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message.replyToSenderName ?? '', style: AppTextStyles.caption.copyWith(color: isMe ? Colors.white : AppColors.primary, fontWeight: FontWeight.w700)),
          Text(message.replyToContent ?? '', style: AppTextStyles.caption.copyWith(color: isMe ? Colors.white70 : AppColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildAudioContent() {
    final duration = message.mediaDurationSeconds ?? 0;
    final mins = duration ~/ 60;
    final secs = duration % 60;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: isMe ? Colors.white.withOpacity(0.2) : AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(Icons.play_arrow_rounded, color: isMe ? Colors.white : AppColors.primary, size: 20),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 3, width: 120, decoration: BoxDecoration(color: isMe ? Colors.white.withOpacity(0.4) : AppColors.border, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 4),
            Text('$mins:${secs.toString().padLeft(2, '0')}', style: AppTextStyles.caption.copyWith(color: isMe ? Colors.white70 : AppColors.textMuted)),
          ],
        ),
        const SizedBox(width: 8),
        Icon(Icons.mic_rounded, size: 14, color: isMe ? Colors.white60 : AppColors.textMuted),
      ],
    );
  }

  Widget _buildImageContent() {
    return Container(
      width: 200, height: 160,
      decoration: BoxDecoration(
        color: isMe ? Colors.white.withOpacity(0.2) : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.image_rounded, size: 48, color: isMe ? Colors.white60 : AppColors.textMuted),
    );
  }

  Widget _buildStatusIcon() {
    switch (message.status) {
      case MessageStatus.sending: return const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white60));
      case MessageStatus.sent: return const Icon(Icons.check_rounded, size: 14, color: Colors.white60);
      case MessageStatus.delivered: return const Icon(Icons.done_all_rounded, size: 14, color: Colors.white60);
      case MessageStatus.read: return const Icon(Icons.done_all_rounded, size: 14, color: Color(0xFF64FFDA));
      case MessageStatus.failed: return const Icon(Icons.error_outline_rounded, size: 14, color: Colors.redAccent);
    }
  }

  Widget _buildReactions() {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        children: message.reactions.entries.map((entry) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2)],
          ),
          child: Text('${entry.key} ${entry.value.length}', style: const TextStyle(fontSize: 12)),
        )).toList(),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildReactionBar(context),
            const Divider(height: 1),
            _optionTile(context, Icons.reply_rounded, 'رد', onReply),
            _optionTile(context, Icons.copy_rounded, 'نسخ', () { Clipboard.setData(ClipboardData(text: message.content ?? '')); Navigator.pop(context); }),
            _optionTile(context, Icons.delete_outline_rounded, 'حذف', () => Navigator.pop(context), isDestructive: true),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildReactionBar(BuildContext context) {
    final emojis = ['❤️', '👍', '😂', '😮', '😢', '🤲'];
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: emojis.map((emoji) => GestureDetector(
          onTap: () { onReact(emoji); Navigator.pop(context); },
          child: Text(emoji, style: const TextStyle(fontSize: 28)),
        )).toList(),
      ),
    );
  }

  Widget _optionTile(BuildContext context, IconData icon, String label, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? AppColors.error : AppColors.textSecondary),
      title: Text(label, style: AppTextStyles.body.copyWith(color: isDestructive ? AppColors.error : null)),
      onTap: onTap,
    );
  }
}
