import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_text_styles.dart';
import '../../core/networking/api_client.dart';
import '../../core/networking/api_endpoints.dart';
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
              _buildInfoCard(user.username, user.academicId, user.gender, user.email, user.bio),
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

  Widget _buildInfoCard(String username, String academicId, String gender, String? email, String? bio) {
    final isFemale = gender == 'female';
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _InfoRow(Icons.person_outline, 'اسم المستخدم', '@$username'),
            const Divider(),
            _InfoRow(Icons.numbers_rounded, 'الرقم الأكاديمي', academicId),
            const Divider(),
            _InfoRow(isFemale ? Icons.female_rounded : Icons.male_rounded, 'الجنس', isFemale ? 'أنثى' : 'ذكر'),
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
          ListTile(
            leading: const Icon(Icons.lock_outline, color: AppColors.primary),
            title: const Text('تغيير كلمة المرور'),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
            onTap: () => _showChangePasswordDialog(context),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.notifications_outlined, color: AppColors.primary),
            title: const Text('إعدادات الإشعارات'),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
          ),
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

  void _showChangePasswordDialog(BuildContext context) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool loading = false;
    String? errorMsg;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تغيير كلمة المرور'),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: currentCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'كلمة المرور الحالية', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock_outline)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'كلمة المرور الجديدة', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock_reset_rounded)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'تأكيد كلمة المرور الجديدة', border: OutlineInputBorder(), prefixIcon: Icon(Icons.check_circle_outline)),
              ),
              if (errorMsg != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Row(children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(errorMsg!, style: const TextStyle(color: AppColors.error, fontSize: 12))),
                  ]),
                ),
              ],
            ]),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: loading ? null : () async {
                  if (currentCtrl.text.isEmpty || newCtrl.text.isEmpty) {
                    setD(() => errorMsg = 'يرجى ملء جميع الحقول');
                    return;
                  }
                  if (newCtrl.text != confirmCtrl.text) {
                    setD(() => errorMsg = 'كلمتا المرور الجديدتان غير متطابقتين');
                    return;
                  }
                  if (newCtrl.text.length < 6) {
                    setD(() => errorMsg = 'كلمة المرور يجب أن تكون 6 أحرف على الأقل');
                    return;
                  }
                  setD(() { loading = true; errorMsg = null; });
                  try {
                    await ApiClient.instance.put(
                      ApiEndpoints.changePassword,
                      data: {'current_password': currentCtrl.text, 'new_password': newCtrl.text},
                    );
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم تغيير كلمة المرور بنجاح'), backgroundColor: AppColors.success),
                      );
                    }
                  } catch (e) {
                    setD(() {
                      loading = false;
                      errorMsg = 'كلمة المرور الحالية غير صحيحة';
                    });
                  }
                },
                child: loading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('حفظ', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
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
