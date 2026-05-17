import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF1B4332);
  static const Color primaryLight = Color(0xFF2D6A4F);
  static const Color primaryDark = Color(0xFF0D2B1F);

  static const Color secondary = Color(0xFFB7950B);
  static const Color secondaryLight = Color(0xFFD4AC0D);
  static const Color secondaryDark = Color(0xFF9A7D0A);

  static const Color accent = Color(0xFF40916C);
  static const Color accentLight = Color(0xFF52B788);

  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F3F4);

  static const Color error = Color(0xFFDC3545);
  static const Color success = Color(0xFF28A745);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF17A2B8);

  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6C757D);
  static const Color textMuted = Color(0xFFADB5BD);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  static const Color border = Color(0xFFDEE2E6);
  static const Color divider = Color(0xFFE9ECEF);

  static const Color unreadBadge = Color(0xFF28A745);
  static const Color onlineIndicator = Color(0xFF28A745);

  static const Color adminPrimary = Color(0xFF2C3E50);
  static const Color adminAccent = Color(0xFF3498DB);
  static const Color adminSidebar = Color(0xFF1A252F);

  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);

  static LinearGradient get primaryGradient => const LinearGradient(
        colors: [primary, primaryLight],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get goldGradient => const LinearGradient(
        colors: [secondaryDark, secondary, secondaryLight],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}
