import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  int _logoPressCount = 0;
  DateTime? _lastLogoPress;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref.read(authProvider.notifier).login(
      _usernameController.text.trim(),
      _passwordController.text.trim(),
    );
    if (!mounted) return;
    if (success) {
      final user = ref.read(authProvider).user;
      if (user != null && (user.isAdmin || user.isModerator)) {
        context.go('/admin');
      } else {
        context.go('/home');
      }
    }
  }

  void _handleLogoTap() {
    final now = DateTime.now();
    if (_lastLogoPress != null && now.difference(_lastLogoPress!).inMilliseconds < 500) {
      _logoPressCount++;
    } else {
      _logoPressCount = 1;
    }
    _lastLogoPress = now;

    if (_logoPressCount >= 2) {
      _logoPressCount = 0;
      _showAdminLoginDialog();
    }
  }

  void _showAdminLoginDialog() {
    final usernameCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    bool obscure = true;
    bool loading = false;
    String? error;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              const Text('دخول الإدارة'),
            ]),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: usernameCtrl,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(
                    labelText: 'اسم المستخدم',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                StatefulBuilder(
                  builder: (_, setSt) => TextField(
                    controller: passwordCtrl,
                    obscureText: obscure,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        onPressed: () { setSt(() => obscure = !obscure); setDialogState(() {}); },
                      ),
                    ),
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Row(children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(error!, style: const TextStyle(color: AppColors.error, fontSize: 12))),
                    ]),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: loading ? null : () async {
                  setDialogState(() { loading = true; error = null; });
                  final success = await ref.read(authProvider.notifier).adminLogin(
                    usernameCtrl.text.trim(),
                    passwordCtrl.text.trim(),
                  );
                  if (!mounted) return;
                  if (success) {
                    Navigator.pop(ctx);
                    context.go('/admin');
                  } else {
                    setDialogState(() {
                      loading = false;
                      error = ref.read(authProvider).error ?? 'بيانات الدخول غير صحيحة';
                    });
                  }
                },
                child: loading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('دخول', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 48),
                  _buildHeader(),
                  const SizedBox(height: 48),
                  _buildLoginCard(authState),
                  const SizedBox(height: 24),
                  _buildRegisterLink(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        GestureDetector(
          onTap: _handleLogoTap,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: const Icon(Icons.mosque_rounded, size: 52, color: Colors.white),
          ),
        ),
        const SizedBox(height: 20),
        Text('مركز أهل الحديث والأثر', style: AppTextStyles.h2, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text('تسجيل الدخول إلى المنصة التعليمية', style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildLoginCard(AuthState authState) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('تسجيل الدخول', style: AppTextStyles.h3),
          const SizedBox(height: 24),
          AppTextField(
            controller: _usernameController,
            label: 'اسم المستخدم',
            hint: 'أدخل اسم المستخدم',
            prefixIcon: Icons.person_outline,
            validator: (v) => v == null || v.isEmpty ? 'اسم المستخدم مطلوب' : null,
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _passwordController,
            label: 'كلمة المرور',
            hint: 'أدخل كلمة المرور',
            prefixIcon: Icons.lock_outline,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (v) => v == null || v.length < 4 ? 'كلمة المرور يجب أن تكون 4 أحرف على الأقل' : null,
          ),
          if (authState.error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(authState.error!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.error))),
              ]),
            ),
          ],
          const SizedBox(height: 24),
          AppButton(label: 'تسجيل الدخول', isLoading: authState.isLoading, onPressed: _login, icon: Icons.login_rounded),
          const SizedBox(height: 12),
          _buildDemoAccounts(),
        ],
      ),
    );
  }

  Widget _buildDemoAccounts() {
    final demos = [
      ('admin', 'مدير النظام'),
      ('sheikh_ibrahim', 'شيخ'),
      ('student_ali', 'طالب'),
      ('student_sara', 'طالبة'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('حسابات تجريبية (كلمة المرور: 1234):', style: AppTextStyles.caption),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: demos.map((demo) => GestureDetector(
            onTap: () {
              _usernameController.text = demo.$1;
              _passwordController.text = '1234';
            },
            child: Chip(
              label: Text('${demo.$2} (${demo.$1})', style: AppTextStyles.caption),
              backgroundColor: AppColors.primary.withOpacity(0.08),
              side: BorderSide.none,
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('ليس لديك حساب؟ ', style: AppTextStyles.bodySmall),
        GestureDetector(
          onTap: () => context.push('/register'),
          child: Text('سجّل الآن', style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}
