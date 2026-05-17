import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/services/mock_data_service.dart';
import '../../../../shared/models/notification_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/extensions/datetime_extensions.dart';

final notificationsProvider = FutureProvider<List<NotificationModel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  await Future.delayed(const Duration(milliseconds: 300));
  return MockDataService.instance.getNotifications(user?.id ?? '');
});

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        actions: [TextButton(onPressed: () {}, child: const Text('قراءة الكل', style: TextStyle(color: Colors.white)))],
      ),
      body: notifAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: $e')),
        data: (notifications) => notifications.isEmpty
            ? _buildEmpty()
            : ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (_, i) => _NotificationTile(notification: notifications[i]),
              ),
      ),
    );
  }

  Widget _buildEmpty() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none_rounded, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text('لا توجد إشعارات', style: AppTextStyles.h3.copyWith(color: AppColors.textMuted)),
          ],
        ),
      );
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: notification.isRead ? Colors.white : AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: notification.isRead ? AppColors.border : AppColors.primary.withOpacity(0.2)),
      ),
      child: ListTile(
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
          child: Center(child: Text(notification.typeIcon, style: const TextStyle(fontSize: 20))),
        ),
        title: Text(notification.title, style: AppTextStyles.body.copyWith(fontWeight: notification.isRead ? FontWeight.w400 : FontWeight.w700)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.body, style: AppTextStyles.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(notification.createdAt.timeAgo, style: AppTextStyles.caption),
          ],
        ),
        trailing: notification.isRead ? null : Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
        isThreeLine: true,
        onTap: () {},
      ),
    );
  }
}
