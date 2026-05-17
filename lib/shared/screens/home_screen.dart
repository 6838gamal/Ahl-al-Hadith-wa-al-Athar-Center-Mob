import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_text_styles.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/messaging/presentation/providers/messaging_provider.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../shared/widgets/user_avatar.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final convAsync = ref.watch(conversationsProvider);
    final notifAsync = ref.watch(notificationsProvider);

    final unreadNotifs = notifAsync.whenData((list) => list.where((n) => !n.isRead).length).value ?? 0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          title: Text('مركز أهل الحديث والأثر', style: AppTextStyles.appBarTitle.copyWith(fontSize: 15)),
          actions: [
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                  onPressed: () => context.push('/home/notifications'),
                ),
                if (unreadNotifs > 0)
                  Positioned(
                    top: 8, left: 8,
                    child: Container(
                      width: 16, height: 16,
                      decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                      child: Center(child: Text('$unreadNotifs', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700))),
                    ),
                  ),
              ],
            ),
            IconButton(
              icon: UserAvatar(name: user?.effectiveName ?? '', size: 32, backgroundColor: Colors.white.withOpacity(0.2)),
              onPressed: () => context.push('/home/profile'),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            ref.refresh(conversationsProvider);
            ref.refresh(notificationsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGreeting(user?.effectiveName ?? 'طالب', user?.roleLabel ?? ''),
                const SizedBox(height: 20),
                _buildQuickActions(context, user?.isAdmin ?? false, user?.isModerator ?? false),
                const SizedBox(height: 20),
                _buildRecentConversations(context, ref, convAsync),
                const SizedBox(height: 20),
                _buildAnnouncementBanner(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGreeting(String name, String role) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'صباح الخير' : hour < 17 ? 'مساء الخير' : 'مساء النور';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$greeting، $name!', style: AppTextStyles.h3.copyWith(color: Colors.white)),
        if (role.isNotEmpty) Text(role, style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
          child: Text('﴿ وَمَن يَتَّقِ اللَّهَ يَجْعَل لَّهُ مَخْرَجاً ﴾',
              style: AppTextStyles.body.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center),
        ),
      ]),
    );
  }

  Widget _buildQuickActions(BuildContext context, bool isAdmin, bool isModerator) {
    final actions = [
      _QuickAction('المحادثات', Icons.message_rounded, '/home/messages', AppColors.primary),
      _QuickAction('الإشعارات', Icons.notifications_rounded, '/home/notifications', AppColors.secondary),
      _QuickAction('التذاكر', Icons.confirmation_number_rounded, '/home/tickets', AppColors.accent),
      if (isAdmin || isModerator)
        _QuickAction('لوحة التحكم', Icons.dashboard_rounded, '/admin', AppColors.adminAccent),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('الوصول السريع', style: AppTextStyles.h3),
      const SizedBox(height: 12),
      GridView.count(
        crossAxisCount: 4, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.9,
        children: actions.map((a) => GestureDetector(
          onTap: () => context.go(a.path),
          child: Column(children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(color: a.color.withOpacity(0.12), borderRadius: BorderRadius.circular(14), border: Border.all(color: a.color.withOpacity(0.3))),
              child: Icon(a.icon, color: a.color, size: 26),
            ),
            const SizedBox(height: 8),
            Text(a.label, style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          ]),
        )).toList(),
      ),
    ]);
  }

  Widget _buildRecentConversations(BuildContext context, WidgetRef ref, AsyncValue convAsync) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text('المحادثات الأخيرة', style: AppTextStyles.h3)),
        TextButton(onPressed: () => context.go('/home/messages'), child: const Text('عرض الكل', style: TextStyle(color: AppColors.primary))),
      ]),
      const SizedBox(height: 8),
      convAsync.when(
        loading: () => const Card(child: Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))),
        error: (e, _) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Text('تعذّر تحميل المحادثات', style: AppTextStyles.bodySmall))),
        data: (convs) {
          if (convs.isEmpty) return Card(child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              const Icon(Icons.chat_bubble_outline_rounded, size: 40, color: AppColors.textMuted),
              const SizedBox(height: 8),
              Text('لا توجد محادثات بعد', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => context.go('/home/messages'),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('ابدأ محادثة'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              ),
            ]),
          ));
          final recent = convs.take(3).toList();
          return Card(child: Column(children: recent.asMap().entries.map((entry) {
            final conv = entry.value;
            final isLast = entry.key == recent.length - 1;
            return Column(children: [
              ListTile(
                leading: UserAvatar(name: conv.title ?? 'م', size: 44, showOnline: conv.isDirect, isOnline: true),
                title: Text(conv.title ?? 'محادثة', style: AppTextStyles.body.copyWith(fontWeight: conv.hasUnread ? FontWeight.w700 : FontWeight.w500)),
                subtitle: Text(conv.lastMessageContent ?? '', style: AppTextStyles.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: conv.unreadCount > 0 ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: const BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.all(Radius.circular(10))),
                  child: Text('${conv.unreadCount}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                ) : null,
                onTap: () => context.push('/home/chat/${conv.id}'),
              ),
              if (!isLast) const Divider(height: 1, indent: 16),
            ]);
          }).toList()));
        },
      ),
    ]);
  }

  Widget _buildAnnouncementBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(gradient: AppColors.goldGradient, borderRadius: BorderRadius.circular(12)),
      child: const Row(children: [
        Icon(Icons.campaign_rounded, color: Colors.white, size: 28),
        SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('درس الجمعة القادمة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
          Text('سيُعقد درس التفسير بعد صلاة العصر', style: TextStyle(color: Colors.white70, fontSize: 12)),
        ])),
      ]),
    );
  }
}

class _QuickAction {
  final String label, path; final IconData icon; final Color color;
  const _QuickAction(this.label, this.icon, this.path, this.color);
}
