import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../core/services/mock_data_service.dart';
import '../../shared/layout/admin_layout.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = MockDataService.instance.getAdminStats();

    return AdminLayout(
      currentPath: '/admin',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('لوحة التحكم', style: AppTextStyles.h1),
            const SizedBox(height: 8),
            Text('مرحباً، إليك ملخص النظام', style: AppTextStyles.bodySmall),
            const SizedBox(height: 24),
            _StatsGrid(stats: stats),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _RecentActivityCard()),
                const SizedBox(width: 16),
                Expanded(child: _PendingActionsCard()),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatData('إجمالي المستخدمين', '${stats['total_users']}', Icons.people_rounded, AppColors.adminAccent),
      _StatData('مستخدمون نشطون', '${stats['active_users']}', Icons.person_rounded, AppColors.success),
      _StatData('في انتظار الموافقة', '${stats['pending_users']}', Icons.hourglass_empty_rounded, AppColors.warning),
      _StatData('رسائل اليوم', '${stats['total_messages_today']}', Icons.message_rounded, AppColors.primary),
      _StatData('تذاكر مفتوحة', '${stats['open_tickets']}', Icons.confirmation_number_rounded, AppColors.error),
      _StatData('دورات نشطة', '${stats['active_courses']}', Icons.school_rounded, AppColors.secondaryLight),
      _StatData('مجموعات', '${stats['total_groups']}', Icons.group_rounded, AppColors.accent),
      _StatData('محادثات', '${stats['total_conversations']}', Icons.forum_rounded, AppColors.info),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 220, childAspectRatio: 1.6, crossAxisSpacing: 12, mainAxisSpacing: 12),
      itemCount: cards.length,
      itemBuilder: (_, i) => _StatCard(data: cards[i]),
    );
  }
}

class _StatData {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatData(this.label, this.value, this.icon, this.color);
}

class _StatCard extends StatelessWidget {
  final _StatData data;
  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: data.color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(data.icon, color: data.color, size: 20)),
              Icon(Icons.trending_up_rounded, color: AppColors.success, size: 16),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(data.value, style: AppTextStyles.h2.copyWith(color: data.color)),
              Text(data.label, style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  final _activities = const [
    ('انضم مستخدم جديد: عمر السالم', '5 دقائق'),
    ('تذكرة جديدة: مشكلة في تسجيل الدخول', '12 دقيقة'),
    ('درس جديد أُضيف: صحيح البخاري', '1 ساعة'),
    ('تم قبول طلب تسجيل', '2 ساعة'),
    ('رسالة جماعية أُرسلت: إعلان الدرس', '3 ساعات'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('النشاط الأخير', style: AppTextStyles.h3),
          const SizedBox(height: 12),
          ..._activities.map((a) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                const SizedBox(width: 10),
                Expanded(child: Text(a.$1, style: AppTextStyles.bodySmall)),
                Text(a.$2, style: AppTextStyles.caption),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _PendingActionsCard extends StatelessWidget {
  final _actions = const [
    (Icons.person_add_rounded, 'موافقة على 2 طلب تسجيل', AppColors.warning),
    (Icons.confirmation_number_rounded, '4 تذاكر لم تُعالج', AppColors.error),
    (Icons.report_rounded, '1 تقرير إشراف', AppColors.error),
    (Icons.announcement_rounded, 'لا إعلانات مجدولة', AppColors.textMuted),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('الإجراءات المطلوبة', style: AppTextStyles.h3),
          const SizedBox(height: 12),
          ..._actions.map((a) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(a.$1, color: a.$3, size: 20),
            title: Text(a.$2, style: AppTextStyles.bodySmall),
            trailing: a.$3 != AppColors.textMuted ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: a.$3.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: const Text('معالجة', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700)),
            ) : null,
          )),
        ],
      ),
    );
  }
}
