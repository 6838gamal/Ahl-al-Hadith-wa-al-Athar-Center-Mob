import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/networking/api_client.dart';
import '../../../../core/networking/api_endpoints.dart';
import '../../../../shared/models/notification_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/extensions/datetime_extensions.dart';

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, AsyncValue<List<NotificationModel>>>((ref) {
  ref.watch(currentUserProvider);
  return NotificationsNotifier();
});

class NotificationsNotifier extends StateNotifier<AsyncValue<List<NotificationModel>>> {
  final ApiClient _api = ApiClient.instance;
  NotificationsNotifier() : super(const AsyncValue.loading()) { load(); }

  Future<void> load() async {
    try {
      final res = await _api.get(ApiEndpoints.notifications);
      final list = (res.data as List).map((j) => NotificationModel.fromJson(j as Map<String, dynamic>)).toList();
      state = AsyncValue.data(list);
    } catch (e, st) { state = AsyncValue.error(e, st); }
  }

  Future<void> markRead(String id) async {
    try {
      await _api.post(ApiEndpoints.markRead(id));
      state.whenData((list) => state = AsyncValue.data(
        list.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList(),
      ));
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    try {
      await _api.post(ApiEndpoints.markAllRead);
      state.whenData((list) => state = AsyncValue.data(
        list.map((n) => n.copyWith(isRead: true)).toList(),
      ));
    } catch (_) {}
  }
}

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifAsync = ref.watch(notificationsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        actions: [
          TextButton(
            onPressed: () => ref.read(notificationsProvider.notifier).markAllRead(),
            child: const Text('قراءة الكل', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: notifAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text('خطأ في التحميل', style: AppTextStyles.body),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: () => ref.read(notificationsProvider.notifier).load(), child: const Text('إعادة المحاولة')),
        ])),
        data: (notifications) => notifications.isEmpty
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.notifications_none_rounded, size: 64, color: AppColors.textMuted),
                const SizedBox(height: 16),
                Text('لا توجد إشعارات', style: AppTextStyles.h3.copyWith(color: AppColors.textMuted)),
              ]))
            : RefreshIndicator(
                onRefresh: () => ref.read(notificationsProvider.notifier).load(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: notifications.length,
                  itemBuilder: (_, i) => _NotificationTile(
                    notification: notifications[i],
                    onTap: () => ref.read(notificationsProvider.notifier).markRead(notifications[i].id),
                  ),
                ),
              ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  const _NotificationTile({required this.notification, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: notification.isRead ? Colors.white : AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: notification.isRead ? AppColors.border : AppColors.primary.withOpacity(0.2)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
          child: Center(child: Text(notification.typeIcon, style: const TextStyle(fontSize: 20))),
        ),
        title: Text(notification.title, style: AppTextStyles.body.copyWith(fontWeight: notification.isRead ? FontWeight.w400 : FontWeight.w700)),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(notification.body, style: AppTextStyles.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(notification.createdAt.timeAgo, style: AppTextStyles.caption),
        ]),
        trailing: notification.isRead ? null : Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
        isThreeLine: true,
      ),
    );
  }
}
