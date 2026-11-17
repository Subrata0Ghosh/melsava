import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_typography.dart';

/// Primary action button for MELSAVA
///
/// Features rich multi-stop gradient (or solid color), pill corner radius (28dp),
/// tactile press state, glowing drop shadow, and smooth inline progress indicator.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double height;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Gradient? gradient;
  final double borderRadius;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 54.0,
    this.backgroundColor,
    this.foregroundColor,
    this.gradient,
    this.borderRadius = 28.0,
  });

  @override
  Widget build(BuildContext context) {
    final fg = foregroundColor ?? Colors.white;
    final effectiveGradient = backgroundColor != null
        ? null
        : (gradient ?? AppColors.purpleGradient);

    final isEnabled = !isLoading && onPressed != null;

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: effectiveGradient == null
              ? (backgroundColor ?? AppColors.primaryPurple)
              : null,
          gradient: effectiveGradient,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.22),
            width: 1.0,
          ),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: (effectiveGradient != null
                            ? AppColors.primaryPurple
                            : (backgroundColor ?? AppColors.primaryPurple))
                        .withValues(alpha: 0.38),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(borderRadius),
            onTap: isEnabled ? onPressed : null,
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(fg),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, size: 20, color: fg),
                          const SizedBox(width: AppConstants.spacingSM),
                        ],
                        Text(
                          label,
                          style: AppTypography.labelLarge.copyWith(
                            color: fg,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
