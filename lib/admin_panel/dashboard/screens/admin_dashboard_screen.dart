import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../core/networking/api_client.dart';
import '../../../core/networking/api_endpoints.dart';
import '../../shared/layout/admin_layout.dart';

// ─── Provider ─────────────────────────────────────────────────
class DashboardStats {
  final int totalUsers, activeUsers, pendingUsers, totalMessages, totalTickets, openTickets, totalGroups, totalCourses;
  const DashboardStats({required this.totalUsers, required this.activeUsers, required this.pendingUsers, required this.totalMessages, required this.totalTickets, required this.openTickets, required this.totalGroups, required this.totalCourses});
  factory DashboardStats.fromJson(Map<String, dynamic> j) => DashboardStats(
    totalUsers: j['total_users'] as int? ?? 0, activeUsers: j['active_users'] as int? ?? 0, pendingUsers: j['pending_users'] as int? ?? 0,
    totalMessages: j['total_messages'] as int? ?? 0, totalTickets: j['total_tickets'] as int? ?? 0, openTickets: j['open_tickets'] as int? ?? 0,
    totalGroups: j['total_groups'] as int? ?? 0, totalCourses: j['total_courses'] as int? ?? 0,
  );
}

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final res = await ApiClient.instance.get(ApiEndpoints.adminDashboard);
  return DashboardStats.fromJson(res.data as Map<String, dynamic>);
});

final recentActivityProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final res = await ApiClient.instance.get(ApiEndpoints.adminActivity);
  return res.data as Map<String, dynamic>;
});

final pendingUsersCountProvider = FutureProvider<int>((ref) async {
  final res = await ApiClient.instance.get(ApiEndpoints.adminPendingUsers);
  return (res.data as List).length;
});

// ─── Screen ───────────────────────────────────────────────────
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final activityAsync = ref.watch(recentActivityProvider);
    return AdminLayout(
      currentPath: '/admin',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('لوحة التحكم', style: AppTextStyles.h1),
          const SizedBox(height: 4),
          Text('مرحباً، إليك ملخص النظام اللحظي', style: AppTextStyles.bodySmall),
          const SizedBox(height: 24),
          statsAsync.when(
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())),
            error: (e, _) => _ErrorCard(message: 'خطأ في تحميل الإحصائيات', onRetry: () => ref.refresh(dashboardStatsProvider)),
            data: (stats) => _StatsGrid(stats: stats),
          ),
          const SizedBox(height: 24),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: activityAsync.when(
              loading: () => _LoadingCard(title: 'النشاط الأخير'),
              error: (_, __) => _LoadingCard(title: 'النشاط الأخير'),
              data: (data) => _RecentActivityCard(data: data),
            )),
            const SizedBox(width: 16),
            Expanded(child: statsAsync.when(
              loading: () => _LoadingCard(title: 'الإجراءات المطلوبة'),
              error: (_, __) => _LoadingCard(title: 'الإجراءات المطلوبة'),
              data: (stats) => _PendingActionsCard(stats: stats),
            )),
          ]),
        ]),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final DashboardStats stats;
  const _StatsGrid({required this.stats});
  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatData('إجمالي المستخدمين', '${stats.totalUsers}', Icons.people_rounded, AppColors.adminAccent),
      _StatData('مستخدمون نشطون', '${stats.activeUsers}', Icons.person_rounded, AppColors.success),
      _StatData('في انتظار الموافقة', '${stats.pendingUsers}', Icons.hourglass_empty_rounded, AppColors.warning),
      _StatData('إجمالي الرسائل', '${stats.totalMessages}', Icons.message_rounded, AppColors.primary),
      _StatData('تذاكر مفتوحة', '${stats.openTickets}', Icons.confirmation_number_rounded, AppColors.error),
      _StatData('إجمالي التذاكر', '${stats.totalTickets}', Icons.inbox_rounded, AppColors.secondaryLight),
      _StatData('المجموعات', '${stats.totalGroups}', Icons.group_rounded, AppColors.accent),
      _StatData('الدورات', '${stats.totalCourses}', Icons.school_rounded, AppColors.info),
    ];
    return GridView.builder(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 220, childAspectRatio: 1.6, crossAxisSpacing: 12, mainAxisSpacing: 12),
      itemCount: cards.length,
      itemBuilder: (_, i) => _StatCard(data: cards[i]),
    );
  }
}

class _StatData { final String label, value; final IconData icon; final Color color; const _StatData(this.label, this.value, this.icon, this.color); }

class _StatCard extends StatelessWidget {
  final _StatData data;
  const _StatCard({required this.data});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: data.color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(data.icon, color: data.color, size: 20)),
        const Icon(Icons.bar_chart_rounded, color: AppColors.textMuted, size: 16),
      ]),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(data.value, style: AppTextStyles.h2.copyWith(color: data.color)),
        Text(data.label, style: AppTextStyles.caption),
      ]),
    ]),
  );
}

class _RecentActivityCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _RecentActivityCard({required this.data});
  @override
  Widget build(BuildContext context) {
    final users = (data['recent_users'] as List? ?? []);
    final tickets = (data['recent_tickets'] as List? ?? []);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('النشاط الأخير', style: AppTextStyles.h3),
        const SizedBox(height: 12),
        ...users.take(3).map((u) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(children: [
            Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
            const SizedBox(width: 10),
            Expanded(child: Text('انضم: ${u['display_name'] ?? u['username']}', style: AppTextStyles.bodySmall)),
            Text(u['role'] as String? ?? '', style: AppTextStyles.caption),
          ]),
        )),
        ...tickets.take(3).map((t) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(children: [
            Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.warning, shape: BoxShape.circle)),
            const SizedBox(width: 10),
            Expanded(child: Text('تذكرة: ${t['title']}', style: AppTextStyles.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis)),
          ]),
        )),
        if (users.isEmpty && tickets.isEmpty)
          Text('لا يوجد نشاط حديث', style: AppTextStyles.caption),
      ]),
    );
  }
}

class _PendingActionsCard extends StatelessWidget {
  final DashboardStats stats;
  const _PendingActionsCard({required this.stats});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('الإجراءات المطلوبة', style: AppTextStyles.h3),
      const SizedBox(height: 12),
      _ActionItem(icon: Icons.person_add_rounded, label: 'طلبات تسجيل معلقة: ${stats.pendingUsers}', color: stats.pendingUsers > 0 ? AppColors.warning : AppColors.textMuted),
      _ActionItem(icon: Icons.confirmation_number_rounded, label: 'تذاكر مفتوحة: ${stats.openTickets}', color: stats.openTickets > 0 ? AppColors.error : AppColors.textMuted),
      _ActionItem(icon: Icons.people_rounded, label: 'مستخدمون نشطون: ${stats.activeUsers}', color: AppColors.success),
      _ActionItem(icon: Icons.school_rounded, label: 'دورات مُسجَّلة: ${stats.totalCourses}', color: AppColors.info),
    ]),
  );
}

class _ActionItem extends StatelessWidget {
  final IconData icon; final String label; final Color color;
  const _ActionItem({required this.icon, required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      Icon(icon, color: color, size: 18), const SizedBox(width: 10),
      Expanded(child: Text(label, style: AppTextStyles.bodySmall)),
    ]),
  );
}

class _LoadingCard extends StatelessWidget {
  final String title;
  const _LoadingCard({required this.title});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
    child: Column(children: [Text(title, style: AppTextStyles.h3), const SizedBox(height: 20), const CircularProgressIndicator()]),
  );
}

class _ErrorCard extends StatelessWidget {
  final String message; final VoidCallback onRetry;
  const _ErrorCard({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
    child: Column(children: [Text(message, style: AppTextStyles.body), const SizedBox(height: 8), ElevatedButton(onPressed: onRetry, child: const Text('إعادة المحاولة'))]),
  );
}
