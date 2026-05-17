import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_text_styles.dart';
import '../../core/services/mock_data_service.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../shared/widgets/user_avatar.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final stats = MockDataService.instance.getAdminStats();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          title: Text('مركز أهل الحديث والأثر', style: AppTextStyles.appBarTitle.copyWith(fontSize: 15)),
          actions: [
            IconButton(icon: const Icon(Icons.notifications_outlined, color: Colors.white), onPressed: () => context.push('/home/notifications')),
            IconButton(icon: UserAvatar(name: user?.effectiveName ?? '', size: 32, backgroundColor: Colors.white.withOpacity(0.2)), onPressed: () => context.push('/home/profile')),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGreeting(user?.effectiveName ?? 'طالب'),
              const SizedBox(height: 20),
              _buildQuickActions(context, user?.isAdmin ?? false),
              const SizedBox(height: 20),
              _buildRecentConversations(context),
              const SizedBox(height: 20),
              _buildAnnouncementBanner(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreeting(String name) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'صباح الخير' : hour < 17 ? 'مساء الخير' : 'مساء النور';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$greeting، $name! 👋', style: AppTextStyles.h3.copyWith(color: Colors.white)),
          const SizedBox(height: 6),
          Text('بسم الله الرحمن الرحيم', style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: Text(
              '﴿ وَمَن يَتَّقِ اللَّهَ يَجْعَل لَّهُ مَخْرَجاً ﴾',
              style: AppTextStyles.body.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, bool isAdmin) {
    final actions = [
      _QuickAction('المحادثات', Icons.message_rounded, '/home/messages', AppColors.primary),
      _QuickAction('الإشعارات', Icons.notifications_rounded, '/home/notifications', AppColors.secondary),
      _QuickAction('التذاكر', Icons.confirmation_number_rounded, '/home/tickets', AppColors.accent),
      if (isAdmin) _QuickAction('لوحة التحكم', Icons.dashboard_rounded, '/admin', AppColors.adminAccent),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('الوصول السريع', style: AppTextStyles.h3),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.9,
          children: actions.map((a) => GestureDetector(
            onTap: () => context.go(a.path),
            child: Column(
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(color: a.color.withOpacity(0.12), borderRadius: BorderRadius.circular(14), border: Border.all(color: a.color.withOpacity(0.3))),
                  child: Icon(a.icon, color: a.color, size: 26),
                ),
                const SizedBox(height: 8),
                Text(a.label, style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
              ],
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildRecentConversations(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(child: Text('المحادثات الأخيرة', style: AppTextStyles.h3)),
          TextButton(onPressed: () => context.go('/home/messages'), child: const Text('عرض الكل', style: TextStyle(color: AppColors.primary))),
        ]),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              _ConvPreview('الشيخ إبراهيم العمري', 'جزاك الله خيراً على سؤالك...', '5 دق', 2, true),
              const Divider(height: 1, indent: 16),
              _ConvPreview('مجلس أهل الحديث العام', 'درس الغد سيكون...', '2 س', 15, false),
              const Divider(height: 1, indent: 16),
              _ConvPreview('سارة المشرفة', 'تم تسجيلك في الدورة', 'أمس', 0, false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnnouncementBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.campaign_rounded, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('درس الجمعة القادمة', style: AppTextStyles.body.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                Text('سيُعقد درس التفسير بعد صلاة العصر', style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction {
  final String label, path;
  final IconData icon;
  final Color color;
  const _QuickAction(this.label, this.icon, this.path, this.color);
}

class _ConvPreview extends StatelessWidget {
  final String name, lastMsg, time;
  final int unread;
  final bool isOnline;
  const _ConvPreview(this.name, this.lastMsg, this.time, this.unread, this.isOnline);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: UserAvatar(name: name, size: 44, showOnline: true, isOnline: isOnline),
      title: Text(name, style: AppTextStyles.body.copyWith(fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w500)),
      subtitle: Text(lastMsg, style: AppTextStyles.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(time, style: AppTextStyles.caption),
          if (unread > 0) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: const BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.all(Radius.circular(10))),
              child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
            ),
          ],
        ],
      ),
      onTap: () => context.go('/home/messages'),
    );
  }
}
