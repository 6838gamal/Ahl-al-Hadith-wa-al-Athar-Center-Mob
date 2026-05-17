import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../shared/models/message_model.dart';

class MessageInput extends StatefulWidget {
  final MessageModel? replyTo;
  final VoidCallback onClearReply;
  final void Function(String text) onSend;

  const MessageInput({super.key, this.replyTo, required this.onClearReply, required this.onSend});

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final _controller = TextEditingController();
  bool _hasText = false;
  bool _isRecording = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _controller.clear();
    setState(() => _hasText = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.replyTo != null) _buildReplyPreview(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(icon: const Icon(Icons.attach_file_rounded, color: AppColors.textSecondary), onPressed: () {}),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(24)),
                      child: TextField(
                        controller: _controller,
                        maxLines: 4,
                        minLines: 1,
                        style: AppTextStyles.body,
                        textDirection: TextDirection.rtl,
                        decoration: const InputDecoration(
                          hintText: 'اكتب رسالة...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        onChanged: (v) => setState(() => _hasText = v.trim().isNotEmpty),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: _hasText ? _send : () => setState(() => _isRecording = !_isRecording),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: _isRecording ? AppColors.error : AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _hasText ? Icons.send_rounded : (_isRecording ? Icons.stop_rounded : Icons.mic_rounded),
                        color: Colors.white, size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.surfaceVariant,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          const Icon(Icons.reply_rounded, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.replyTo?.senderName ?? '', style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                Text(widget.replyTo?.content ?? '', style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary), onPressed: widget.onClearReply),
        ],
      ),
    );
  }
}
