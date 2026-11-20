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
import '../../auth/domain/app_user.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../connections/data/connections_repository.dart';
import '../../experiences/data/experiences_repository.dart';
import '../../experiences/presentation/experience_detail_sheet.dart';
import 'edit_profile_sheet.dart';

/// Screen 12: Profile Screen
///
/// Luxury Artistic UI with real authenticated profile data:
/// - Watercolor ambient mesh background
/// - Botanical leaves framing avatar
/// - Avatar with green verified badge ONLY when genuinely verified
/// - Real Display Name & Real Location
/// - Real Bio & Interests chips
/// - Real statistics: Attended/Upcoming Experiences & Mutual Connections (no fake metrics)
/// - Stadium outline [ Edit Profile ] button
/// - Community Guidelines & Safety pledge card
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);
    final userLoc = ref.watch(userLocationProvider);

    final cardBg = isDark ? const Color(0xFF1B1528) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF332A45)
        : const Color(0xFFEDE9FE);
    final primaryTextColor = isDark
        ? AppColors.darkTextPrimary
        : const Color(0xFF1E1435);
    final mutedTextColor = isDark
        ? AppColors.darkMutedText
        : const Color(0xFF7E7394);

    final displayName =
        (user?.displayName != null && user!.displayName!.trim().isNotEmpty)
        ? user.displayName!.trim()
        : 'MELSAVA Member';

    final isVerified = user?.isVerified == true;

    // Real statistics
    final connectionsCount = ref
        .watch(userConnectionsProvider)
        .maybeWhen(data: (list) => list.length, orElse: () => 0);

    final myBundle =
        ref.watch(myExperiencesProvider).valueOrNull ??
        const MyExperiencesBundle();
    final experiencesCount =
        myBundle.upcoming.length + myBundle.attended.length;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF1D142E)
          : const Color(0xFFFFFDF9),
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
              // ── Pinned Top Navigation Bar ──
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
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
                          HapticFeedback.lightImpact();
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/discover');
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
                            isDark
                                ? Icons.light_mode_rounded
                                : Icons.dark_mode_rounded,
                            color: isDark
                                ? AppColors.brightViolet
                                : AppColors.primaryPurple,
                            size: 22,
                          ),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            ref
                                .read(themeModeProvider.notifier)
                                .toggleTheme(isDark);
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
                              border: Border.all(
                                color: borderColor,
                                width: 0.9,
                              ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 12),

                      // ── Open Artistic Profile Header Canvas ──
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
                                    const Color(
                                      0xFF7DD3FC,
                                    ).withValues(alpha: isDark ? 0.18 : 0.35),
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
                                    const Color(
                                      0xFFFDE047,
                                    ).withValues(alpha: isDark ? 0.16 : 0.38),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Lush Tropical Leaves Framing Avatar
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

                          // Profile Content
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Column(
                              children: [
                                // Avatar with Verified Badge only if genuinely verified
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
                                            color: Colors.black.withValues(
                                              alpha: 0.14,
                                            ),
                                            blurRadius: 16,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: ClipOval(
                                        child: AppSmartImage(
                                          imagePath: user?.avatarUrl,
                                          isAvatar: true,
                                          nameHint: displayName,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    if (isVerified)
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
                                                color: const Color(
                                                  0xFF10B981,
                                                ).withValues(alpha: 0.4),
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

                                // User Name & Verification Icon
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
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
                                          style: AppTypography.titleLarge
                                              .copyWith(
                                                color: primaryTextColor,
                                                fontWeight: FontWeight.w800,
                                                fontSize:
                                                    displayName.length > 18
                                                    ? 17
                                                    : (displayName.length > 13
                                                          ? 19
                                                          : 21),
                                              ),
                                        ),
                                      ),
                                      if (isVerified) ...[
                                        const SizedBox(width: 6),
                                        const Icon(
                                          Icons.verified_rounded,
                                          size: 19,
                                          color: Color(0xFF10B981),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),

                                // Subtitle: "Intent • City, Region"
                                RichText(
                                  text: TextSpan(
                                    style: AppTypography.bodySmall.copyWith(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    children: [
                                      TextSpan(
                                        text:
                                            user?.primaryIntent ?? 'Friendship',
                                        style: const TextStyle(
                                          color: Color(0xFF6366F1),
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      TextSpan(
                                        text:
                                            ' • ${user?.city ?? userLoc.city}',
                                        style: TextStyle(color: mutedTextColor),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 8),

                                // Bio
                                if (user?.bio != null &&
                                    user!.bio!.trim().isNotEmpty)
                                  Text(
                                    user.bio!.trim(),
                                    textAlign: TextAlign.center,
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: primaryTextColor.withValues(
                                        alpha: 0.88,
                                      ),
                                      fontSize: 13,
                                    ),
                                  ),

                                const SizedBox(height: 18),

                                // Real Stats Organic Container (Experiences & Connections)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                    horizontal: 24,
                                  ),
                                  decoration: BoxDecoration(
                                    color: cardBg,
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(
                                      color: borderColor,
                                      width: 1.0,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isDark
                                            ? Colors.black38
                                            : Colors.black.withValues(
                                                alpha: 0.04,
                                              ),
                                        blurRadius: 14,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _buildStatCol(
                                        '$experiencesCount',
                                        'Experiences Joined',
                                        primaryTextColor,
                                        mutedTextColor,
                                      ),
                                      Container(
                                        height: 30,
                                        width: 1,
                                        color: borderColor,
                                      ),
                                      _buildStatCol(
                                        '$connectionsCount',
                                        'Mutual Connections',
                                        primaryTextColor,
                                        mutedTextColor,
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // Stadium Outline [ Edit Profile ] Button
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    EditProfileSheet.show(context);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 9,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.05)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: isDark
                                            ? AppColors.brightViolet
                                            : const Color(0xFF6366F1),
                                        width: 1.3,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              (isDark
                                                      ? AppColors.brightViolet
                                                      : const Color(0xFF6366F1))
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
                                        color: isDark
                                            ? AppColors.brightViolet
                                            : const Color(0xFF6366F1),
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

                      // ── Real Interests & Passions Card ──
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: borderColor, width: 0.9),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.favorite_rounded,
                                  size: 18,
                                  color: Color(0xFFEC4899),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'My Interests & Passions',
                                  style: TextStyle(
                                    color: primaryTextColor,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (user?.interests != null &&
                                user!.interests!.isNotEmpty)
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: user.interests!.map((interest) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.08)
                                          : const Color(0xFFF3EEFC),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: borderColor,
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Text(
                                      interest,
                                      style: TextStyle(
                                        color: primaryTextColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              )
                            else
                              Text(
                                'No interests added yet. Tap "Edit Profile" to add passions!',
                                style: TextStyle(
                                  color: mutedTextColor,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ── Community Guidelines & Safety Card ──
                      InkWell(
                        onTap: () => context.push('/community-guidelines'),
                        borderRadius: BorderRadius.circular(22),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(
                                  0xFF10B981,
                                ).withValues(alpha: isDark ? 0.15 : 0.08),
                                const Color(
                                  0xFF059669,
                                ).withValues(alpha: isDark ? 0.06 : 0.03),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: const Color(
                                0xFF10B981,
                              ).withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF10B981,
                                  ).withValues(alpha: 0.18),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.menu_book_rounded,
                                  color: Color(0xFF10B981),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'MELSAVA Community Guidelines',
                                      style: TextStyle(
                                        color: primaryTextColor,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '10 core principles for authentic, safe social meetups.',
                                      style: TextStyle(
                                        color: mutedTextColor,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: mutedTextColor,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── My Joined Experiences Section ──
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
                                color: isDark
                                    ? AppColors.brightViolet
                                    : AppColors.primaryPurple,
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

                      // ── Safety & Community Badges ──
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
                        user,
                        myBundle,
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
                            message:
                                'Are you sure you want to sign out of MELSAVA?',
                            confirmLabel: 'Sign Out',
                            isDestructive: true,
                          );
                          if (confirm == true) {
                            await ref.read(authRepositoryProvider).signOut();
                            ref.read(currentUserProvider.notifier).state = null;
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
                              Icon(
                                Icons.logout_rounded,
                                color: AppColors.error,
                                size: 18,
                              ),
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

                      // Clearance for bottom nav
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
    final myAsync = ref.watch(myExperiencesProvider);
    final myBundle = myAsync.valueOrNull ?? const MyExperiencesBundle();
    final displayExperiences = [
      ...myBundle.upcoming,
      ...myBundle.waitlisted,
      ...myBundle.attended,
    ].take(5).toList();

    if (displayExperiences.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: 0.9),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 20,
              color: isDark ? AppColors.brightViolet : AppColors.primaryPurple,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No upcoming experiences joined yet. Explore activities to find your next micro-group!',
                style: AppTypography.bodySmall.copyWith(
                  color: mutedTextColor,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        itemCount: displayExperiences.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final exp = displayExperiences[index];
          final badgeLabel = exp.isAttended
              ? 'Attended ✓'
              : (exp.isWaitlisted ? 'Waitlisted' : 'Joined • Upcoming');
          final badgeColor = exp.isWaitlisted
              ? const Color(0xFF8B5CF6)
              : const Color(0xFF10B981);

          return GestureDetector(
            onTap: () {
              ExperienceDetailSheet.show(context, experience: exp);
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badgeLabel,
                            style: TextStyle(
                              color: badgeColor,
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
                            Icon(
                              Icons.place_outlined,
                              size: 12,
                              color: mutedTextColor,
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                exp.city,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: mutedTextColor,
                                  fontSize: 10.5,
                                ),
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
    AppUser? user,
    MyExperiencesBundle myBundle,
    bool isDark,
    Color cardBg,
    Color borderColor,
    Color primaryTextColor,
    Color mutedTextColor,
  ) {
    final isVerified = user?.isVerified == true;
    final attendedCount = myBundle.attended.length;
    final interests = (user?.interests ?? [])
        .map((i) => i.toLowerCase().trim())
        .toList();

    final List<Map<String, dynamic>> badges = [];

    // 1. Verification Badge (Real ID / Selfie Check from DB)
    if (isVerified) {
      badges.add({
        'icon': '🛡️',
        'title': 'Verified Member',
        'desc': 'ID & Profile Confirmed',
        'unlocked': true,
      });
    } else {
      badges.add({
        'icon': '🔒',
        'title': 'ID Verification',
        'desc': 'Complete ID check',
        'unlocked': false,
      });
    }

    // 2. Attendance Badge (Real confirmed circle attendance)
    if (attendedCount > 0) {
      badges.add({
        'icon': '⭐',
        'title': 'Reliable RSVP',
        'desc': '$attendedCount ${attendedCount == 1 ? 'circle' : 'circles'} attended',
        'unlocked': true,
      });
    } else {
      badges.add({
        'icon': '⭐',
        'title': 'First Circle',
        'desc': 'Attend a circle to earn',
        'unlocked': false,
      });
    }

    // 3. Host / Community Badge (Real curated host role)
    final isHost = user != null &&
        (myBundle.upcoming.any((e) => e.hostId == user.id) ||
            myBundle.attended.any((e) => e.hostId == user.id) ||
            user.email.toLowerCase().contains('admin'));
    if (isHost) {
      badges.add({
        'icon': '🌿',
        'title': 'Curated Host',
        'desc': 'Verified circle guide',
        'unlocked': true,
      });
    } else if (interests.any((i) => i.contains('nature') || i.contains('hike') || i.contains('trek'))) {
      badges.add({
        'icon': '🌲',
        'title': 'Nature Lover',
        'desc': 'Outdoor explorer',
        'unlocked': true,
      });
    } else if (interests.any((i) => i.contains('coffee') || i.contains('tea'))) {
      badges.add({
        'icon': '☕',
        'title': 'Coffee Buff',
        'desc': 'Café culture lover',
        'unlocked': true,
      });
    } else {
      badges.add({
        'icon': '🌱',
        'title': 'New Explorer',
        'desc': 'Joined MELSAVA',
        'unlocked': true,
      });
    }

    // 4. Passion / Creative Badge (Derived from real user interests)
    if (interests.any((i) => i.contains('photo'))) {
      badges.add({
        'icon': '📷',
        'title': 'Visual Creator',
        'desc': 'Photography enthusiast',
        'unlocked': true,
      });
    } else if (interests.any((i) => i.contains('art') || i.contains('pottery') || i.contains('craft'))) {
      badges.add({
        'icon': '🎨',
        'title': 'Creative Spirit',
        'desc': 'Arts & culture lover',
        'unlocked': true,
      });
    } else if (interests.any((i) => i.contains('mindful') || i.contains('yoga') || i.contains('meditat'))) {
      badges.add({
        'icon': '🧘',
        'title': 'Mindful Soul',
        'desc': 'Wellness & peace',
        'unlocked': true,
      });
    } else if (interests.any((i) => i.contains('coffee') || i.contains('tea')) &&
        !badges.any((b) => b['title'] == 'Coffee Buff')) {
      badges.add({
        'icon': '☕',
        'title': 'Coffee Buff',
        'desc': 'Café culture lover',
        'unlocked': true,
      });
    } else {
      badges.add({
        'icon': '✨',
        'title': 'Authentic Self',
        'desc': 'Real community vibes',
        'unlocked': true,
      });
    }

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
        final isUnlocked = b['unlocked'] as bool? ?? true;
        return Opacity(
          opacity: isUnlocked ? 1.0 : 0.62,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isUnlocked ? borderColor : borderColor.withValues(alpha: 0.5),
                width: 0.9,
              ),
            ),
            child: Row(
              children: [
                Text(b['icon'] as String, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        b['title'] as String,
                        style: TextStyle(
                          color: isUnlocked
                              ? primaryTextColor
                              : mutedTextColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        b['desc'] as String,
                        style: TextStyle(color: mutedTextColor, fontSize: 9.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
