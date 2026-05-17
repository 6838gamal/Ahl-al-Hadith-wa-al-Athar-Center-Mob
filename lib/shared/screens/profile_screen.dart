import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_text_styles.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../shared/widgets/user_avatar.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('الملف الشخصي')),
        body: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(user.effectiveName, user.roleLabel, user.isOnline),
              const SizedBox(height: 8),
              _buildInfoCard(user.username, user.academicId, user.email, user.bio),
              const SizedBox(height: 8),
              _buildSettingsCard(context, ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String name, String role, bool online) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryLight], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
      child: Column(
        children: [
          UserAvatar(name: name, size: 80, showOnline: true, isOnline: online),
          const SizedBox(height: 12),
          Text(name, style: AppTextStyles.h2.copyWith(color: Colors.white)),
          Text(role, style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String username, String academicId, String? email, String? bio) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _InfoRow(Icons.person_outline, 'اسم المستخدم', '@$username'),
            const Divider(),
            _InfoRow(Icons.badge_outlined, 'الرقم الأكاديمي', academicId),
            if (email != null) ...[const Divider(), _InfoRow(Icons.email_outlined, 'البريد الإلكتروني', email)],
            if (bio != null) ...[const Divider(), _InfoRow(Icons.info_outline, 'نبذة', bio)],
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          ListTile(leading: const Icon(Icons.lock_outline, color: AppColors.primary), title: const Text('تغيير كلمة المرور'), trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14)),
          const Divider(height: 1),
          ListTile(leading: const Icon(Icons.notifications_outlined, color: AppColors.primary), title: const Text('إعدادات الإشعارات'), trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14)),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppColors.error),
            title: const Text('تسجيل الخروج', style: TextStyle(color: AppColors.error)),
            onTap: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.caption),
            Text(value, style: AppTextStyles.body),
          ],
        ),
      ],
    );
  }
}
