import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_text_styles.dart';

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final bool isOutlined;
  final double? width;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.isOutlined = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.primary;
    final tc = textColor ?? Colors.white;

    if (isOutlined) {
      return SizedBox(
        width: width,
        child: OutlinedButton.icon(
          onPressed: isLoading ? null : onPressed,
          icon: isLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : (icon != null ? Icon(icon, size: 18) : const SizedBox.shrink()),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: bg),
            foregroundColor: bg,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      );
    }

    return SizedBox(
      width: width,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(backgroundColor: bg, foregroundColor: tc, padding: const EdgeInsets.symmetric(vertical: 14)),
        child: isLoading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
                  Text(label, style: AppTextStyles.button.copyWith(color: tc)),
                ],
              ),
      ),
    );
  }
}
