import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_typography.dart';

/// Reusable adaptive category chip for activity discovery
class CategoryChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.label,
    this.icon,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final selectedBg = isDark ? AppColors.luminousMauve : AppColors.deepPlum;
    final unselectedBg = isDark ? AppColors.darkElevated : AppColors.white;
    final borderColor = isSelected
        ? selectedBg
        : (isDark ? AppColors.darkBorder : AppColors.divider);

    final textColor = isSelected
        ? AppColors.white
        : (isDark ? AppColors.darkTextPrimary : AppColors.deepPlum);

    final iconColor = isSelected
        ? AppColors.white
        : (isDark ? AppColors.luminousMauve : AppColors.mauve);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppConstants.animFast,
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingMD,
          vertical: AppConstants.spacingSM + 2,
        ),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : unselectedBg,
          borderRadius: BorderRadius.circular(AppConstants.buttonRadiusSmall),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: selectedBg.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: iconColor,
              ),
              const SizedBox(width: AppConstants.spacingSM),
            ],
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: textColor,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
