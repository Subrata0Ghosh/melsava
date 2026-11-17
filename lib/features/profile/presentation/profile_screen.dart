import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/services/location_providers.dart';
import '../../../shared/widgets/app_smart_image.dart';
import '../../../shared/widgets/confirmation_dialog.dart';
import '../../../shared/widgets/botanical_leaf_decoration.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../experiences/data/experiences_repository.dart';
import '../../experiences/presentation/experience_detail_sheet.dart';
import '../../experiences/presentation/join_experience_sheet.dart';
import 'edit_profile_sheet.dart';

/// Screen 12 & 13 (Image 7): Profile & Settings Screen
///
/// Luxury Artistic UI matching Image 7:
/// - Watercolor ambient mesh background (Sky blue top-left, sunny golden amber top-right)
/// - Botanical leaves framing avatar from both sides
/// - Avatar with green verified badge
/// - "Sneha" with green checkmark
/// - "Friend • Kolkata, India" with "Friend" highlighted in royal purple
/// - Bio: "Nature lover | Coffee enthusiast | Explorer"
/// - Organic rounded stats card: 24 Experiences, 78 Connections, 12 Followers
/// - Stadium outline [ Edit Profile ] button
/// - "Go Premium" golden card & modern settings list
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showGoPremiumDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 22),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? const [Color(0xFF261044), Color(0xFF130926)]
                  : const [
                      Color(0xFFFFFFFF),
                      Color(0xFFFFF9EE),
                    ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark
                  ? const Color(0xFFFFB800).withValues(alpha: 0.35)
                  : const Color(0xFFE5A93C).withValues(alpha: 0.45),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.5)
                    : const Color(0xFF261044).withValues(alpha: 0.16),
                blurRadius: 32,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Close button on top-right (Image 3 Screen 14)
              Positioned(
                top: 12,
                right: 12,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : const Color(0xFFEDE8F5),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      color: isDark ? Colors.white70 : const Color(0xFF5B4D70),
                      size: 18,
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 3D Golden Crown Emblem (Screen 14)
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFB800), Color(0xFFF59E0B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFB800).withValues(alpha: 0.45),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text('👑', style: TextStyle(fontSize: 28)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Go Premium',
                      style: AppTypography.headlineSmall.copyWith(
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF1E1435),
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Unlock more features and get the most out of MELSAVA.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.8)
                            : const Color(0xFF6B5E82),
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildBenefitRow('See who liked you', isDark),
                    _buildBenefitRow('Advanced filters', isDark),
                    _buildBenefitRow('Priority support', isDark),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('MELSAVA Premium successfully activated!')),
                        );
                      },
                      child: Container(
                        height: 50,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF9D2E), Color(0xFFFF7A00)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF7A00).withValues(alpha: 0.40),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          'Upgrade Now',
                          style: AppTypography.labelLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ],
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
      padding: const EdgeInsets.symmetric(vertical: 5.5),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFB800).withValues(alpha: 0.16),
            ),
            child: const Icon(Icons.check_circle_rounded, color: Color(0xFFF59E0B), size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF261044),
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

    final cardBg = isDark ? const Color(0xFF1B1528) : Colors.white;
    final borderColor = isDark ? const Color(0xFF332A45) : const Color(0xFFEDE9FE);
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : const Color(0xFF1E1435);
    final mutedTextColor = isDark ? AppColors.darkMutedText : const Color(0xFF7E7394);

    final displayName = user?.displayName ?? 'Sneha';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1D142E) : const Color(0xFFFFFDF9),
      body: AmbientNatureBackdrop(
        showTopLeaf: true,
        showBottomLeaf: true,
        leafStyle: BotanicalLeafStyle.monstera,
        leafColors: BotanicalLeafDecoration.goldenSunlit,
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Pinned Top Navigation Bar (Image 6 Screen 12) - Never drags down ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back Arrow Button
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: cardBg,
                        shape: BoxShape.circle,
                        border: Border.all(color: borderColor, width: 0.9),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          color: primaryTextColor,
                          size: 20,
                        ),
                        onPressed: () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                    ),

                    // Actions: Theme toggle & Settings Gear
                    Row(
                      children: [
                        IconButton(
                          tooltip: isDark ? 'Light Mode' : 'Dark Mode',
                          icon: Icon(
                            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                            color: isDark ? AppColors.brightViolet : AppColors.primaryPurple,
                            size: 22,
                          ),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            ref.read(themeModeProvider.notifier).toggleTheme(isDark);
                          },
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => context.push('/settings'),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: cardBg,
                              shape: BoxShape.circle,
                              border: Border.all(color: borderColor, width: 0.9),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.settings_outlined,
                              color: primaryTextColor,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Clamping Scrollable Profile Body ──
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [

                const SizedBox(height: 12),

                // ── Open Artistic Profile Header Canvas (Image 6 Screen 12) ──
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // Top-Left Soft Sky Blue Watercolor Aura
                    Positioned(
                      top: -10,
                      left: -20,
                      width: 180,
                      height: 180,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFF7DD3FC).withValues(alpha: isDark ? 0.18 : 0.35),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Top-Right Vibrant Sunny Golden Amber Aura
                    Positioned(
                      top: -15,
                      right: -15,
                      width: 200,
                      height: 200,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFFFDE047).withValues(alpha: isDark ? 0.16 : 0.38),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Lush Tropical Leaves Framing Avatar (Screen 12)
                    const Positioned(
                      top: 10,
                      left: 10,
                      child: BotanicalLeafDecoration(
                        style: BotanicalLeafStyle.tropicalFoliage,
                        width: 72,
                        height: 120,
                        rotation: 0.22,
                        opacity: 0.92,
                      ),
                    ),
                    const Positioned(
                      top: 5,
                      right: 12,
                      child: BotanicalLeafDecoration(
                        style: BotanicalLeafStyle.monstera,
                        width: 75,
                        height: 125,
                        rotation: -0.24,
                        opacity: 0.94,
                      ),
                    ),

                    // Profile Content flowing seamlessly
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        children: [
                          // Avatar with Green Verified Badge (Image 6 Screen 12)
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 94,
                                height: 94,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.14),
                                      blurRadius: 16,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: AppSmartImage(
                                    imagePath: user?.avatarUrl,
                                    isAvatar: true,
                                    nameHint: user?.displayName,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              // Green Verified Badge
                              Positioned(
                                bottom: 2,
                                right: 2,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF10B981).withValues(alpha: 0.4),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // User Name & Verification Icon (Adaptive for long names)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: AppTypography.titleLarge.copyWith(
                                      color: primaryTextColor,
                                      fontWeight: FontWeight.w800,
                                      fontSize: displayName.length > 18
                                          ? 17
                                          : (displayName.length > 13 ? 19 : 21),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.verified_rounded,
                                  size: 19,
                                  color: Color(0xFF10B981),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Subtitle: "Friend • Kolkata, India" (Friend in purple)
                          RichText(
                            text: TextSpan(
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                              children: [
                                TextSpan(
                                  text: user?.primaryIntent ?? 'Friend',
                                  style: const TextStyle(
                                    color: Color(0xFF6366F1),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                TextSpan(
                                  text: ' • ${user?.city ?? userLoc.city}',
                                  style: TextStyle(color: mutedTextColor),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Bio
                          Text(
                            user?.bio ?? 'Nature lover | Coffee enthusiast | Explorer',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyMedium.copyWith(
                              color: primaryTextColor.withValues(alpha: 0.88),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Stats Organic Container (Image 6 Screen 12)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: borderColor, width: 1.0),
                              boxShadow: [
                                BoxShadow(
                                  color: isDark ? Colors.black38 : Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildStatCol('24', 'Experiences', primaryTextColor, mutedTextColor),
                                Container(height: 28, width: 1, color: borderColor),
                                _buildStatCol('78', 'Connections', primaryTextColor, mutedTextColor),
                                Container(height: 28, width: 1, color: borderColor),
                                _buildStatCol('12', 'Followers', primaryTextColor, mutedTextColor),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Stadium Outline [ Edit Profile ] Button (Image 6 Screen 12)
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              EditProfileSheet.show(context);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 9),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: isDark ? AppColors.brightViolet : const Color(0xFF6366F1),
                                  width: 1.3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isDark ? AppColors.brightViolet : const Color(0xFF6366F1))
                                        .withValues(alpha: 0.12),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                'Edit Profile',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: isDark ? AppColors.brightViolet : const Color(0xFF6366F1),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 18),

              // ── Go Premium Card ──
              GestureDetector(
                onTap: () => _showGoPremiumDialog(context, isDark),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? const [Color(0xFF2C1E4A), Color(0xFF1A132C)]
                          : const [
                              Color(0xFFFFF9EE), // warm pearlescent champagne cream
                              Color(0xFFFFF1D6), // soft honey gold glow
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFFFFB800).withValues(alpha: 0.35)
                          : const Color(0xFFE5A93C).withValues(alpha: 0.50),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? const Color(0xFFFFB800).withValues(alpha: 0.15)
                            : const Color(0xFFE5A93C).withValues(alpha: 0.22),
                        blurRadius: 18,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFB800), Color(0xFFF59E0B)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
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
                            Row(
                              children: [
                                Text(
                                  'Go Premium',
                                  style: TextStyle(
                                    color: isDark ? Colors.white : const Color(0xFF1E1435),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15.5,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFFFB800), Color(0xFFF59E0B)],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'VIP',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 9.5,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Unlock who liked you & priority RSVP',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.75)
                                    : const Color(0xFF6B5E82),
                                fontSize: 11.5,
                                fontWeight: isDark ? FontWeight.normal : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF9D2E), Color(0xFFFF7A00)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF7A00).withValues(alpha: 0.38),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Text(
                          'Upgrade',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── My Joined Experiences Section (Screen 12) ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'My Joined Experiences',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 16.5,
                      color: primaryTextColor,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/experiences'),
                    child: Text(
                      'View All →',
                      style: TextStyle(
                        color: isDark ? AppColors.brightViolet : AppColors.primaryPurple,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              _buildJoinedExperiencesCarousel(
                context,
                ref,
                isDark,
                primaryTextColor,
                mutedTextColor,
                cardBg,
                borderColor,
              ),

              const SizedBox(height: 22),

              // ── Community Badges & Vibe Tags (Screen 12) ──
              Text(
                'Safety & Community Badges',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 16.5,
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: 10),

              _buildBadgesGrid(
                isDark,
                cardBg,
                borderColor,
                primaryTextColor,
                mutedTextColor,
              ),

              const SizedBox(height: 24),

              // ── Sign Out Stadium Button ──
              GestureDetector(
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
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.35),
                      width: 1.0,
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded, color: AppColors.error, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Sign Out of MELSAVA',
                        style: TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Guaranteed clearance for bottom nav
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    ],
  ),
),
      ),
    );
  }

  Widget _buildJoinedExperiencesCarousel(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    Color primaryTextColor,
    Color mutedTextColor,
    Color cardBg,
    Color borderColor,
  ) {
    final experiences = ref.watch(experiencesListProvider);
    final displayExperiences = experiences.take(3).toList();

    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        itemCount: displayExperiences.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final exp = displayExperiences[index];
          return GestureDetector(
            onTap: () {
              ExperienceDetailSheet.show(
                context,
                experience: exp,
                onToggleJoin: () {
                  JoinExperienceSheet.show(
                    context,
                    experience: exp,
                    onConfirmed: () {
                      ref.read(experiencesRepositoryProvider).toggleJoin(exp.id);
                      ref.invalidate(experiencesListProvider);
                    },
                  );
                },
              );
            },
            child: Container(
              width: 260,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderColor, width: 0.9),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 74,
                      height: 112,
                      child: AppSmartImage(
                        imagePath: exp.coverImageUrl,
                        categoryHint: exp.categoryName,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Joined • Upcoming',
                            style: TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          exp.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: primaryTextColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.place_outlined, size: 12, color: mutedTextColor),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                exp.city,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: mutedTextColor, fontSize: 10.5),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBadgesGrid(
    bool isDark,
    Color cardBg,
    Color borderColor,
    Color primaryTextColor,
    Color mutedTextColor,
  ) {
    final badges = [
      {'icon': '🌲', 'title': 'Nature Lover', 'desc': 'Joined 8 outdoor treks'},
      {'icon': '☕', 'title': 'Coffee Buff', 'desc': 'Attended 12 café meetups'},
      {'icon': '🛡️', 'title': 'Verified Host', 'desc': 'ID & Phone confirmed'},
      {'icon': '⭐', 'title': 'Reliable RSVP', 'desc': '100% attendance rate'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: badges.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.3,
      ),
      itemBuilder: (context, index) {
        final b = badges[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 0.9),
          ),
          child: Row(
            children: [
              Text(b['icon']!, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      b['title']!,
                      style: TextStyle(
                        color: primaryTextColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      b['desc']!,
                      style: TextStyle(
                        color: mutedTextColor,
                        fontSize: 9.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
