import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/services/location_providers.dart';
import '../../../shared/widgets/confirmation_dialog.dart';
import '../../../shared/widgets/location_venue_picker_sheet.dart';
import '../../auth/presentation/auth_providers.dart';

/// Screen 12 & 13 (from Image 9): Profile & Settings Screen
///
/// High-fidelity Profile & Settings matching the approved prototype:
/// - Avatar with green active ring and verified checkmark
/// - Name, user title & bio ("Nature lover | Coffee enthusiast | Explorer")
/// - Stats Row: 24 Experiences, 78 Connections, 12 Followers
/// - [ Edit Profile ] pill button
/// - "Go Premium" card preview (Golden crown, key benefits, Upgrade CTA)
/// - Clean settings menu (Account & Security, Notifications, Privacy & Safety, Theme, Sign Out)
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showGoPremiumDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B142A) : AppColors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.divider,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  gradient: AppColors.goldenGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 34),
              ),
              const SizedBox(height: 16),
              Text(
                'Go Premium',
                style: AppTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.deepPlum,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Unlock more features and get the most out of MELSAVA.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: isDark ? AppColors.darkMutedText : AppColors.mutedText,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 20),
              _buildBenefitRow('See who liked you after meetups', isDark),
              _buildBenefitRow('Advanced filters by intent & vibe', isDark),
              _buildBenefitRow('Priority RSVP in micro-group caps', isDark),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('MELSAVA Premium successfully activated!')),
                  );
                },
                child: Container(
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: AppColors.goldenGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFB800).withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    'Upgrade Now',
                    style: AppTypography.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildBenefitRow(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFFFFB800), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : AppColors.deepPlum,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);
    final userLoc = ref.watch(userLocationProvider);

    final cardBg = isDark ? AppColors.darkSurface : AppColors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.divider;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.deepPlum;
    final mutedTextColor = isDark ? AppColors.darkMutedText : AppColors.mutedText;

    final displayName = user?.displayName ?? 'Sneha Roy';

    return Scaffold(
      backgroundColor: isDark ? AppColors.obsidian : AppColors.warmIvory,
      appBar: AppBar(
        title: Text(
          'Profile',
          style: AppTypography.titleLarge.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 22,
            color: primaryTextColor,
          ),
        ),
        actions: [
          // Theme Switcher Quick Toggle
          IconButton(
            tooltip: isDark ? 'Light Mode' : 'Dark Mode',
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: isDark ? AppColors.brightViolet : AppColors.primaryPurple,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              ref.read(themeModeProvider.notifier).toggleTheme(isDark);
            },
          ),
          const SizedBox(width: 8),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header Profile Card (Image 9 Screen 12) ──
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderColor, width: 0.9),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.03),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Avatar with Active Green Ring & Verified Badge
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.mintAccent,
                              width: 3,
                            ),
                          ),
                          child: ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: user?.avatarUrl ??
                                  'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=300&q=80',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.brightViolet : AppColors.primaryPurple,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? AppColors.darkSurface : Colors.white,
                                width: 2,
                              ),
                            ),
                            child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // User Name & Verification
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          displayName,
                          style: AppTypography.titleLarge.copyWith(
                            color: primaryTextColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.verified_rounded,
                          size: 18,
                          color: isDark ? AppColors.brightViolet : AppColors.primaryPurple,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Friend • ${userLoc.city}',
                      style: AppTypography.bodySmall.copyWith(
                        color: mutedTextColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nature lover | Coffee enthusiast | Explorer',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium.copyWith(
                        color: primaryTextColor,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Stats Row: 24 Experiences, 78 Connections, 12 Followers
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatCol('24', 'Experiences', primaryTextColor, mutedTextColor),
                        Container(height: 28, width: 1, color: borderColor),
                        _buildStatCol('78', 'Connections', primaryTextColor, mutedTextColor),
                        Container(height: 28, width: 1, color: borderColor),
                        _buildStatCol('12', 'Followers', primaryTextColor, mutedTextColor),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Edit Profile Button
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Edit Profile opened!')),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkElevated : AppColors.creamElevated,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: borderColor),
                        ),
                        child: Text(
                          'Edit Profile',
                          style: AppTypography.labelSmall.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: primaryTextColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Go Premium Card (Image 9 Screen 14) ──
              GestureDetector(
                onTap: () => _showGoPremiumDialog(context, isDark),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2C1E4A), Color(0xFF1A132C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFFFB800).withValues(alpha: 0.35),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFB800).withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          gradient: AppColors.goldenGradient,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.workspace_premium_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Go Premium',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Unlock who liked you & priority RSVP',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: AppColors.goldenGradient,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text(
                          'Upgrade',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── Settings List Section (Image 9 Screen 13) ──
              Text(
                'Settings',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 16.5,
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: 10),

              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor, width: 0.9),
                ),
                child: Column(
                  children: [
                    _buildSettingsTile(
                      icon: Icons.shield_outlined,
                      title: 'Account & Security',
                      onTap: () {},
                      primaryTextColor: primaryTextColor,
                      mutedTextColor: mutedTextColor,
                      isDark: isDark,
                    ),
                    _buildDivider(borderColor),
                    _buildSettingsTile(
                      icon: Icons.notifications_none_rounded,
                      title: 'Notifications',
                      onTap: () {},
                      primaryTextColor: primaryTextColor,
                      mutedTextColor: mutedTextColor,
                      isDark: isDark,
                    ),
                    _buildDivider(borderColor),
                    _buildSettingsTile(
                      icon: Icons.lock_outline_rounded,
                      title: 'Privacy & Safety',
                      onTap: () {},
                      primaryTextColor: primaryTextColor,
                      mutedTextColor: mutedTextColor,
                      isDark: isDark,
                    ),
                    _buildDivider(borderColor),
                    _buildSettingsTile(
                      icon: Icons.tune_rounded,
                      title: 'Preferences & City',
                      onTap: () => LocationVenuePickerSheet.show(context),
                      primaryTextColor: primaryTextColor,
                      mutedTextColor: mutedTextColor,
                      isDark: isDark,
                    ),
                    _buildDivider(borderColor),
                    _buildSettingsTile(
                      icon: Icons.help_outline_rounded,
                      title: 'Help & Support',
                      onTap: () {},
                      primaryTextColor: primaryTextColor,
                      mutedTextColor: mutedTextColor,
                      isDark: isDark,
                    ),
                    _buildDivider(borderColor),
                    _buildSettingsTile(
                      icon: Icons.info_outline_rounded,
                      title: 'About MELSAVA',
                      subtitle: 'v2.0.0 (Build 2026)',
                      onTap: () {},
                      primaryTextColor: primaryTextColor,
                      mutedTextColor: mutedTextColor,
                      isDark: isDark,
                    ),
                    _buildDivider(borderColor),
                    _buildSettingsTile(
                      icon: Icons.logout_rounded,
                      title: 'Sign Out',
                      isDestructive: true,
                      onTap: () async {
                        final confirm = await ConfirmationDialog.show(
                          context,
                          title: 'Sign Out',
                          message: 'Are you sure you want to sign out of MELSAVA?',
                          confirmLabel: 'Sign Out',
                          isDestructive: true,
                        );
                        if (confirm == true) {
                          await ref.read(authRepositoryProvider).signOut();
                          if (context.mounted) {
                            context.go('/welcome');
                          }
                        }
                      },
                      primaryTextColor: primaryTextColor,
                      mutedTextColor: mutedTextColor,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),

              // Guaranteed 120dp clearance so no button or setting is overlapped by bottom nav
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildStatCol(
    String value,
    String label,
    Color primaryColor,
    Color mutedColor,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.titleLarge.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            fontSize: 11,
            color: mutedColor,
          ),
        ),
      ],
    );
  }

  static Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    bool isDestructive = false,
    required VoidCallback onTap,
    required Color primaryTextColor,
    required Color mutedTextColor,
    required bool isDark,
  }) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDestructive
              ? AppColors.error.withValues(alpha: 0.12)
              : (isDark ? AppColors.darkElevated : AppColors.creamElevated),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 19,
          color: isDestructive
              ? AppColors.error
              : (isDark ? AppColors.brightViolet : AppColors.primaryPurple),
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? AppColors.error : primaryTextColor,
          fontWeight: FontWeight.w600,
          fontSize: 13.5,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(color: mutedTextColor, fontSize: 11),
            )
          : null,
      trailing: isDestructive
          ? null
          : Icon(Icons.chevron_right_rounded, size: 20, color: mutedTextColor),
      onTap: onTap,
    );
  }

  static Widget _buildDivider(Color borderColor) {
    return Divider(height: 1, thickness: 0.7, color: borderColor);
  }
}
