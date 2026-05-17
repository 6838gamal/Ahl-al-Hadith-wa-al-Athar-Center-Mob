import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../shared/layout/admin_layout.dart';

class AdminAnalyticsScreen extends StatelessWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      currentPath: '/admin/analytics',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الإحصائيات والتقارير', style: AppTextStyles.h1),
            const SizedBox(height: 24),
            _DateRangeSelector(),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: _BarChartCard(title: 'رسائل يومية', data: [40, 65, 55, 80, 90, 75, 147])),
              const SizedBox(width: 16),
              Expanded(child: _BarChartCard(title: 'مستخدمون جدد (أسبوعي)', data: [2, 5, 1, 3, 4, 2, 3])),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _RoleDistributionCard()),
              const SizedBox(width: 16),
              Expanded(child: _TopUsersCard()),
            ]),
          ],
        ),
      ),
    );
  }
}

class _DateRangeSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final options = ['اليوم', 'الأسبوع', 'الشهر', '3 أشهر'];
    return Row(
      children: options.map((o) => Padding(
        padding: const EdgeInsets.only(left: 8),
        child: ChoiceChip(
          label: Text(o),
          selected: o == 'الأسبوع',
          onSelected: (_) {},
          selectedColor: AppColors.primary.withOpacity(0.15),
          labelStyle: AppTextStyles.label.copyWith(color: AppColors.primary),
        ),
      )).toList(),
    );
  }
}

class _BarChartCard extends StatelessWidget {
  final String title;
  final List<int> data;
  const _BarChartCard({required this.title, required this.data});

  @override
  Widget build(BuildContext context) {
    final max = data.reduce((a, b) => a > b ? a : b).toDouble();
    const days = ['ن', 'ث', 'ث', 'خ', 'ج', 'س', 'أ'];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.h3),
          const SizedBox(height: 24),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(data.length, (i) => Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('${data[i]}', style: AppTextStyles.caption),
                  const SizedBox(height: 4),
                  Container(
                    width: 28,
                    height: (data[i] / max) * 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.7 + (i == data.length - 1 ? 0.3 : 0)),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(days[i], style: AppTextStyles.caption),
                ],
              )),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleDistributionCard extends StatelessWidget {
  final _roles = const [
    ('طلاب ذكور', 45, AppColors.primary),
    ('طالبات', 30, AppColors.accentLight),
    ('مشايخ', 10, AppColors.secondary),
    ('مشرفون', 10, AppColors.info),
    ('مدراء', 5, AppColors.adminAccent),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('توزيع الأدوار', style: AppTextStyles.h3),
          const SizedBox(height: 16),
          ..._roles.map((r) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: r.$3, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(child: Text(r.$1, style: AppTextStyles.bodySmall)),
              Expanded(flex: 2, child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: r.$2 / 100, backgroundColor: AppColors.border, valueColor: AlwaysStoppedAnimation(r.$3), minHeight: 8),
              )),
              const SizedBox(width: 8),
              Text('${r.$2}%', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700)),
            ]),
          )),
        ],
      ),
    );
  }
}

class _TopUsersCard extends StatelessWidget {
  final _users = const [
    ('الشيخ إبراهيم العمري', '247 رسالة', AppColors.secondary),
    ('علي محمد الزهراني', '143 رسالة', AppColors.primary),
    ('عمر خالد السلمي', '98 رسالة', AppColors.accentLight),
    ('فاطمة الأنصاري', '76 رسالة', AppColors.info),
    ('سارة المشرفة', '65 رسالة', AppColors.adminAccent),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('الأكثر نشاطاً', style: AppTextStyles.h3),
          const SizedBox(height: 12),
          ..._users.asMap().entries.map((e) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(backgroundColor: e.value.$3.withOpacity(0.15), child: Text('${e.key + 1}', style: TextStyle(color: e.value.$3, fontWeight: FontWeight.w700))),
            title: Text(e.value.$1, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary)),
            trailing: Text(e.value.$2, style: AppTextStyles.caption.copyWith(color: e.value.$3, fontWeight: FontWeight.w700)),
          )),
        ],
      ),
    );
  }
}
