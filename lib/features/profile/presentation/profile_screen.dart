import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/services/location_providers.dart';
import '../../../shared/widgets/confirmation_dialog.dart';
import '../../../shared/widgets/location_venue_picker_sheet.dart';
import '../../auth/presentation/auth_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);
    final userLoc = ref.watch(userLocationProvider);

    final cardBg = isDark ? AppColors.darkSurface : AppColors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.divider;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.deepPlum;
    final mutedTextColor = isDark ? AppColors.darkMutedText : AppColors.mutedText;

    return Scaffold(
      backgroundColor: isDark ? AppColors.obsidian : AppColors.warmIvory,
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: AppTypography.titleLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: primaryTextColor,
          ),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.spacingLG),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // User Card
              Container(
                padding: const EdgeInsets.all(AppConstants.spacingLG),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(
                    AppConstants.cardRadiusLarge,
                  ),
                  border: Border.all(color: borderColor, width: 0.8),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black26
                          : AppColors.deepPlum.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: isDark
                          ? AppColors.darkElevated
                          : AppColors.sage,
                      child: Icon(
                        Icons.person_rounded,
                        size: 48,
                        color: isDark ? AppColors.luminousMauve : AppColors.mauve,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingMD),
                    Text(
                      user?.displayName ?? 'Explorer',
                      style: AppTypography.headlineSmall.copyWith(
                        color: primaryTextColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${userLoc.shortLabel} • Verified (18+)',
                      style: AppTypography.bodySmall.copyWith(
                        color: mutedTextColor,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingMD),
                    Text(
                      'Enjoys discovering specialty coffee roasters, weekend nature walks, and tabletop board games.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium.copyWith(
                        color: primaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.spacingLG),

              // Intentions Section
              Text(
                'My Intentions',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: AppConstants.spacingSM),
              Wrap(
                spacing: AppConstants.spacingSM,
                runSpacing: AppConstants.spacingSM,
                children: [
                  _buildTag('Genuine friendship', isPrimary: true, isDark: isDark),
                  _buildTag('Activity partner', isPrimary: true, isDark: isDark),
                  _buildTag('Meaningful dating', isPrimary: false, isDark: isDark),
                ],
              ),
              const SizedBox(height: AppConstants.spacingLG),

              // Interests Section
              Text(
                'My Interests',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: AppConstants.spacingSM),
              Wrap(
                spacing: AppConstants.spacingSM,
                runSpacing: AppConstants.spacingSM,
                children: [
                  _buildTag('Specialty Coffee', isPrimary: false, isDark: isDark),
                  _buildTag('Nature Photography', isPrimary: false, isDark: isDark),
                  _buildTag('Badminton', isPrimary: false, isDark: isDark),
                  _buildTag('Historical Fiction', isPrimary: false, isDark: isDark),
                  _buildTag('Board Games', isPrimary: false, isDark: isDark),
                ],
              ),
              const SizedBox(height: AppConstants.spacingXL),

              // Settings & Controls List
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(
                    AppConstants.cardRadiusSmall,
                  ),
                  border: Border.all(color: borderColor, width: 0.8),
                ),
                child: Column(
                  children: [
                    // Theme Switcher Tile
                    ListTile(
                      leading: Icon(
                        isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        color: isDark ? AppColors.luminousMauve : AppColors.mauve,
                      ),
                      title: Text(
                        'Appearance (Theme)',
                        style: AppTypography.bodyMedium.copyWith(
                          color: primaryTextColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        isDark ? 'Dark Obsidian Mode' : 'Warm Ivory Light Mode',
                        style: AppTypography.bodySmall.copyWith(
                          color: mutedTextColor,
                        ),
                      ),
                      trailing: Switch.adaptive(
                        value: isDark,
                        activeColor: AppColors.luminousMauve,
                        onChanged: (val) {
                          ref
                              .read(themeModeProvider.notifier)
                              .setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
                        },
                      ),
                    ),
                    Divider(height: 1, color: borderColor),

                    // Worldwide Location Tile
                    ListTile(
                      leading: Icon(
                        Icons.public_rounded,
                        color: isDark ? AppColors.luminousMauve : AppColors.mauve,
                      ),
                      title: Text(
                        'Worldwide Location',
                        style: AppTypography.bodyMedium.copyWith(
                          color: primaryTextColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        userLoc.shortLabel,
                        style: AppTypography.bodySmall.copyWith(
                          color: mutedTextColor,
                        ),
                      ),
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: mutedTextColor,
                      ),
                      onTap: () => LocationVenuePickerSheet.show(context),
                    ),
                    Divider(height: 1, color: borderColor),

                    // Community Standards
                    ListTile(
                      leading: Icon(
                        Icons.shield_outlined,
                        color: isDark ? AppColors.luminousMauve : AppColors.mauve,
                      ),
                      title: Text(
                        'Community Guidelines & Safety',
                        style: AppTypography.bodyMedium.copyWith(
                          color: primaryTextColor,
                        ),
                      ),
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: mutedTextColor,
                      ),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: cardBg,
                            title: Text(
                              'MELSAVA Community Standards',
                              style: TextStyle(color: primaryTextColor),
                            ),
                            content: Text(
                              '1. Respect & Consent: All connections are strictly mutual.\n2. Public Venues Only: All offline activities take place in public, vetted locations.\n3. Zero Harassment: Harassment results in immediate account suspension.\n4. Adult Community: Exclusively for respectful adults 18+.',
                              style: TextStyle(color: primaryTextColor),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Understood'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    Divider(height: 1, color: borderColor),

                    // Sign Out
                    ListTile(
                      leading: const Icon(Icons.logout_rounded, color: AppColors.error),
                      title: Text(
                        'Sign Out',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onTap: () async {
                        final confirmed = await ConfirmationDialog.show(
                          context,
                          title: 'Sign Out',
                          message:
                              'Are you sure you want to sign out from MELSAVA?',
                          confirmLabel: 'Sign Out',
                          isDestructive: true,
                        );
                        if (confirmed == true && context.mounted) {
                          await ref.read(authRepositoryProvider).signOut();
                          ref.read(currentUserProvider.notifier).state = null;
                          if (context.mounted) {
                            context.go('/welcome');
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),

              // Bottom padding buffer for floating glassmorphic navbar
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text, {required bool isPrimary, required bool isDark}) {
    final bg = isPrimary
        ? (isDark
            ? AppColors.luminousMauve.withValues(alpha: 0.18)
            : AppColors.sage)
        : (isDark ? AppColors.darkElevated : AppColors.white);

    final border = isPrimary
        ? (isDark ? AppColors.luminousMauve : AppColors.mauve)
        : (isDark ? AppColors.darkBorder : AppColors.divider);

    final textColor = isPrimary
        ? (isDark ? AppColors.luminousMauve : AppColors.deepPlum)
        : (isDark ? AppColors.darkTextPrimary : AppColors.deepPlum);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppConstants.buttonRadiusSmall),
        border: Border.all(color: border, width: isPrimary ? 1.2 : 0.8),
      ),
      child: Text(
        text,
        style: AppTypography.labelSmall.copyWith(
          color: textColor,
          fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}
