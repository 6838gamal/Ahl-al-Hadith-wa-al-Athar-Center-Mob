import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static const TextStyle h1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.4,
    
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.4,
    
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
    
  );

  static const TextStyle body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.6,
    
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
    
  );

  static const TextStyle button = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
    
  );

  static const TextStyle label = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    
  );

  static const TextStyle appBarTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    
  );

  static const TextStyle messageBubble = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    
  );

  static const TextStyle timestamp = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
    
  );
}
