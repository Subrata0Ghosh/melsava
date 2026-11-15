import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_typography.dart';

/// Clean editorial section header with optional trailing action
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                title,
                style: AppTypography.titleLarge.copyWith(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.deepPlum,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (actionLabel != null && onActionTap != null)
              GestureDetector(
                onTap: onActionTap,
                child: Text(
                  actionLabel!,
                  style: AppTypography.labelMedium.copyWith(
                    color: isDark ? AppColors.luminousMauve : AppColors.mauve,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppConstants.spacingXS),
          Text(
            subtitle!,
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? AppColors.darkMutedText : AppColors.mutedText,
            ),
          ),
        ],
      ],
    );
  }
}
