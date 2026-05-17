import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_text_styles.dart';

class UserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String name;
  final double size;
  final bool showOnline;
  final bool isOnline;
  final Color? backgroundColor;

  const UserAvatar({
    super.key,
    this.avatarUrl,
    required this.name,
    this.size = 40,
    this.showOnline = false,
    this.isOnline = false,
    this.backgroundColor,
  });

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}';
    return name.isNotEmpty ? name[0] : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: backgroundColor ?? AppColors.primary.withOpacity(0.15),
          ),
          child: avatarUrl != null
              ? ClipOval(child: Image.network(avatarUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildInitials()))
              : _buildInitials(),
        ),
        if (showOnline)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: size * 0.28,
              height: size * 0.28,
              decoration: BoxDecoration(
                color: isOnline ? AppColors.onlineIndicator : AppColors.textMuted,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInitials() {
    return Center(
      child: Text(
        _initials,
        style: AppTextStyles.label.copyWith(
          color: AppColors.primary,
          fontSize: size * 0.35,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
