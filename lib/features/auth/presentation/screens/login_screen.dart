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
    if (success && mounted) context.go('/home');
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
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: const Icon(Icons.mosque_rounded, size: 52, color: Colors.white),
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
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(authState.error!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.error))),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          AppButton(
            label: 'تسجيل الدخول',
            isLoading: authState.isLoading,
            onPressed: _login,
            icon: Icons.login_rounded,
          ),
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
