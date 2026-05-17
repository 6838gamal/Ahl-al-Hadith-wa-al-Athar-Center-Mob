import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _displayNameCtrl = TextEditingController();
  final _academicIdCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  String _selectedRole = 'male_student';
  bool _submitted = false;
  String? _successMessage;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _displayNameCtrl.dispose();
    _academicIdCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final msg = await ref.read(authProvider.notifier).register(
      username: _usernameCtrl.text.trim(),
      displayName: _displayNameCtrl.text.trim(),
      password: _passwordCtrl.text.trim(),
      academicId: _academicIdCtrl.text.trim(),
      role: _selectedRole,
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
    );
    if (mounted && msg != null) {
      setState(() { _submitted = true; _successMessage = msg; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('إنشاء حساب جديد'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        body: _submitted ? _buildSuccessView() : _buildForm(authState),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100, height: 100,
              decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 52),
            ),
            const SizedBox(height: 24),
            Text('تم إرسال طلبك بنجاح!', style: AppTextStyles.h2, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(
              _successMessage ?? 'سيتم مراجعة طلبك من قِبل الإدارة والرد عليك في أقرب وقت ممكن.',
              style: AppTextStyles.body, textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            AppButton(
              label: 'العودة لتسجيل الدخول',
              onPressed: () => context.go('/login'),
              icon: Icons.login_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(AuthState authState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildRoleSelector(),
            const SizedBox(height: 20),
            AppTextField(
              controller: _displayNameCtrl,
              label: 'الاسم الكامل',
              hint: 'مثال: أحمد محمد الخالدي',
              prefixIcon: Icons.badge_outlined,
              validator: (v) => v == null || v.length < 3 ? 'الاسم يجب أن يكون 3 أحرف على الأقل' : null,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _usernameCtrl,
              label: 'اسم المستخدم',
              hint: 'مثال: ahmad_ali',
              prefixIcon: Icons.person_outline,
              validator: (v) => v == null || v.length < 3 ? 'اسم المستخدم 3 أحرف على الأقل' : null,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _academicIdCtrl,
              label: 'الرقم الأكاديمي',
              hint: 'رقمك الأكاديمي (4 أرقام على الأقل)',
              prefixIcon: Icons.numbers_rounded,
              validator: (v) => v == null || v.length < 4 ? 'الرقم الأكاديمي 4 أرقام على الأقل' : null,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _emailCtrl,
              label: 'البريد الإلكتروني (اختياري)',
              hint: 'example@email.com',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _passwordCtrl,
              label: 'كلمة المرور',
              hint: '6 أحرف على الأقل',
              prefixIcon: Icons.lock_outline,
              obscureText: true,
              validator: (v) => v == null || v.length < 6 ? 'كلمة المرور 6 أحرف على الأقل' : null,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _confirmPasswordCtrl,
              label: 'تأكيد كلمة المرور',
              prefixIcon: Icons.lock_outline,
              obscureText: true,
              validator: (v) => v != _passwordCtrl.text ? 'كلمتا المرور غير متطابقتين' : null,
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
            AppButton(
              label: 'إرسال طلب التسجيل',
              isLoading: authState.isLoading,
              onPressed: _register,
              icon: Icons.send_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('نوع الحساب', style: AppTextStyles.label),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _roleOption('male_student', 'طالب', Icons.school_rounded, 'ذكر')),
              const SizedBox(width: 10),
              Expanded(child: _roleOption('female_student', 'طالبة', Icons.school_rounded, 'أنثى')),
              const SizedBox(width: 10),
              Expanded(child: _roleOption('sheikh', 'شيخ / معلم', Icons.menu_book_rounded, 'معلم')),
            ],
          ),
          const SizedBox(height: 10),
          _buildRoleDescription(),
        ],
      ),
    );
  }

  Widget _roleOption(String value, String label, IconData icon, String sub) {
    final selected = _selectedRole == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.1) : AppColors.surface,
          border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 2 : 1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? AppColors.primary : AppColors.textSecondary, size: 22),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: selected ? FontWeight.w700 : FontWeight.w400, color: selected ? AppColors.primary : AppColors.textSecondary), textAlign: TextAlign.center),
            Text(sub, style: TextStyle(fontSize: 10, color: selected ? AppColors.primary.withOpacity(0.7) : AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleDescription() {
    final descriptions = {
      'male_student': 'سيتم مراجعة طلبك من قِبل الإدارة قبل التفعيل. ستتمكن من الوصول إلى المجموعات والدورات المخصصة للطلاب.',
      'female_student': 'سيتم مراجعة طلبك من قِبل الإدارة. ستتمكن من الوصول إلى المجموعات والدورات المخصصة للطالبات.',
      'sheikh': 'سيتم التحقق من هويتك قبل التفعيل. ستتمكن من إنشاء الدورات والمجموعات التعليمية.',
    };
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.primary, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(descriptions[_selectedRole] ?? '', style: AppTextStyles.caption)),
        ],
      ),
    );
  }
}
