import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_typography.dart';

/// Standard branded text field with consistent padding, borders, and error handling
class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hintText;
  final String? errorText;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;

  const CustomTextField({
    super.key,
    this.controller,
    this.label,
    this.hintText,
    this.errorText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.onChanged,
    this.onSubmitted,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // High-contrast, theme-aware palette
    final labelColor = isDark ? const Color(0xFFF1ECF9) : AppColors.deepPlum;
    final inputTextColor = isDark
        ? const Color(0xFFFDFCFE)
        : AppColors.deepPlum;
    final hintColor = isDark
        ? const Color(0xFFA59CB6)
        : AppColors.mutedText.withValues(alpha: 0.70);
    final iconColor = isDark ? const Color(0xFFBDB2D4) : AppColors.mutedText;

    // In dark mode: sleek translucent obsidian glass surface
    // In light mode: pure crisp white card surface
    final fieldFillColor = isDark
        ? const Color(0xFF1E172E).withValues(alpha: 0.88)
        : AppColors.white;

    final defaultBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.16)
        : const Color(0xFFE2DDD7);

    final focusedBorderColor = isDark
        ? AppColors.brightViolet
        : AppColors.mauve;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTypography.labelMedium.copyWith(
              color: labelColor,
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: AppConstants.spacingSM),
        ],
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppConstants.buttonRadiusSmall),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.28)
                    : Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            maxLines: maxLines,
            readOnly: readOnly,
            onTap: onTap,
            cursorColor: isDark
                ? AppColors.brightViolet
                : AppColors.primaryPurple,
            style: AppTypography.bodyMedium.copyWith(
              color: inputTextColor,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: AppTypography.bodyMedium.copyWith(
                color: hintColor,
                fontWeight: FontWeight.w500,
              ),
              errorText: errorText,
              prefixIcon: prefixIcon != null
                  ? IconTheme(
                      data: IconThemeData(color: iconColor, size: 20),
                      child: prefixIcon!,
                    )
                  : null,
              suffixIcon: suffixIcon != null
                  ? IconTheme(
                      data: IconThemeData(color: iconColor, size: 20),
                      child: suffixIcon!,
                    )
                  : null,
              filled: true,
              fillColor: fieldFillColor,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingMD,
                vertical: AppConstants.spacingMD,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  AppConstants.buttonRadiusSmall,
                ),
                borderSide: BorderSide(color: defaultBorderColor, width: 1.0),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  AppConstants.buttonRadiusSmall,
                ),
                borderSide: BorderSide(color: defaultBorderColor, width: 1.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  AppConstants.buttonRadiusSmall,
                ),
                borderSide: BorderSide(color: focusedBorderColor, width: 1.8),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  AppConstants.buttonRadiusSmall,
                ),
                borderSide: const BorderSide(
                  color: AppColors.error,
                  width: 1.2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
