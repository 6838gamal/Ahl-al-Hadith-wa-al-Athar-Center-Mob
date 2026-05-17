import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _academicIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _selectedGender = 'male';
  bool _isLoading = false;
  bool _submitted = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _academicIdController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) setState(() { _isLoading = false; _submitted = true; });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('إنشاء حساب جديد'),
          leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded), onPressed: () => context.pop()),
        ),
        body: _submitted ? _buildSuccessView() : _buildForm(),
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
            Text('سيتم مراجعة طلبك من قِبل الإدارة والرد عليك في أقرب وقت ممكن.', style: AppTextStyles.body, textAlign: TextAlign.center),
            const SizedBox(height: 32),
            AppButton(label: 'العودة لتسجيل الدخول', onPressed: () => context.go('/login'), icon: Icons.login_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(controller: _usernameController, label: 'اسم المستخدم', hint: 'مثال: ahmad_ali', prefixIcon: Icons.person_outline, validator: (v) => v == null || v.length < 3 ? 'اسم المستخدم 3 أحرف على الأقل' : null),
            const SizedBox(height: 16),
            AppTextField(controller: _academicIdController, label: 'الرقم الأكاديمي', hint: 'رقمك الأكاديمي', prefixIcon: Icons.badge_outlined, validator: (v) => v == null || v.isEmpty ? 'الرقم الأكاديمي مطلوب' : null),
            const SizedBox(height: 16),
            AppTextField(controller: _passwordController, label: 'كلمة المرور', prefixIcon: Icons.lock_outline, obscureText: true, validator: (v) => v == null || v.length < 6 ? 'كلمة المرور 6 أحرف على الأقل' : null),
            const SizedBox(height: 16),
            AppTextField(controller: _confirmPasswordController, label: 'تأكيد كلمة المرور', prefixIcon: Icons.lock_outline, obscureText: true, validator: (v) => v != _passwordController.text ? 'كلمتا المرور غير متطابقتين' : null),
            const SizedBox(height: 16),
            _buildGenderSelector(),
            const SizedBox(height: 24),
            AppButton(label: 'إرسال طلب التسجيل', isLoading: _isLoading, onPressed: _register, icon: Icons.send_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('الجنس', style: AppTextStyles.label),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _genderOption('male', 'طالب (ذكر)', Icons.male_rounded)),
            const SizedBox(width: 12),
            Expanded(child: _genderOption('female', 'طالبة (أنثى)', Icons.female_rounded)),
          ],
        ),
      ],
    );
  }

  Widget _genderOption(String value, String label, IconData icon) {
    final selected = _selectedGender == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedGender = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.1) : Colors.white,
          border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 2 : 1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(label, style: AppTextStyles.body.copyWith(color: selected ? AppColors.primary : AppColors.textSecondary, fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
          ],
        ),
      ),
    );
  }
}
