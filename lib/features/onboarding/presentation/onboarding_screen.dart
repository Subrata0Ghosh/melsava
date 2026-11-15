import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/services/location_providers.dart';
import '../../../shared/widgets/location_venue_picker_sheet.dart';
import '../../../shared/widgets/melsava_logo.dart';
import '../../../shared/widgets/primary_button.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final int _totalPages = 4;

  void _onNext() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } else {
      context.go('/welcome');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.obsidian : AppColors.warmIvory,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Brand Wordmark + Theme Toggle + Skip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  const MelsavaLogo(size: 26),
                  const SizedBox(width: 8),
                  Text(
                    AppConstants.appName,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.0,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.deepPlum,
                    ),
                  ),
                  const Spacer(),

                  // Quick Dark / Light Theme Toggle Pill
                  GestureDetector(
                    onTap: () => ref.read(themeModeProvider.notifier).toggleTheme(isDark),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkElevated : AppColors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.divider,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                            size: 15,
                            color: isDark ? AppColors.luminousMauve : AppColors.mauve,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isDark ? 'Dark' : 'Light',
                            style: AppTypography.labelSmall.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.deepPlum,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Skip button
                  TextButton(
                    onPressed: () => context.go('/welcome'),
                    child: Text(
                      'Skip',
                      style: AppTypography.labelMedium.copyWith(
                        color: isDark ? AppColors.darkMutedText : AppColors.mutedText,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Page View
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                children: [
                  _buildStepOne(isDark),
                  _buildStepTwo(isDark),
                  _buildStepThree(isDark),
                  _buildStepFour(isDark),
                ],
              ),
            ),

            // Bottom Navigation & Indicators
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  // Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_totalPages, (i) {
                      final isActive = i == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 6,
                        width: isActive ? 24 : 6,
                        decoration: BoxDecoration(
                          color: isActive
                              ? (isDark ? AppColors.luminousMauve : AppColors.mauve)
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.15)
                                  : AppColors.divider),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),

                  // Primary Action Button
                  PrimaryButton(
                    label: _currentPage == _totalPages - 1
                        ? 'Explore MELSAVA'
                        : 'Continue',
                    onPressed: _onNext,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Step 1: Beyond Swipes
  Widget _buildStepOne(bool isDark) {
    return _buildSlideLayout(
      isDark: isDark,
      badge: 'ACTIVITY-FIRST CONNECTION',
      title: 'Meet people through experiences, not endless swiping.',
      description:
          'Dating apps designed around static photo cards lead to superficial judgments and fatigue. MELSAVA unites compatible people around shared real-world moments.',
      visualWidget: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.divider,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black38 : AppColors.deepPlum.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildAvatarBubble('☕', 'Coffee', isDark),
                const SizedBox(width: 12),
                _buildAvatarBubble('🎲', 'Board Games', isDark),
                const SizedBox(width: 12),
                _buildAvatarBubble('🌿', 'Nature', isDark),
                const SizedBox(width: 12),
                _buildAvatarBubble('🎨', 'Art', isDark),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkElevated : AppColors.warmIvory,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_rounded,
                      size: 16, color: AppColors.mintAccent),
                  const SizedBox(width: 6),
                  Text(
                    'No swiping fatigue • Real human chemistry',
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.deepPlum,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Step 2: Small Safe Groups (3–5 participants)
  Widget _buildStepTwo(bool isDark) {
    return _buildSlideLayout(
      isDark: isDark,
      badge: 'SAFE & INTIMATE',
      title: 'Curated small groups of 3 to 5 participants.',
      description:
          'No awkward 1-on-1 blind dates. Gather in relaxed, small circles at vetted public venues where conversations flow naturally and pressure is removed.',
      visualWidget: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.divider,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.mauve.withValues(alpha: 0.8),
                        AppColors.softCoral,
                      ],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      ['Alex', 'Priya', 'Leo', 'Maya'][index][0],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 14),
            Text(
              'Public Vetted Venues • Verified 18+ Profiles',
              style: AppTypography.labelMedium.copyWith(
                color: isDark ? AppColors.luminousMauve : AppColors.mauve,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Step 3: Private Mutual Chemistry
  Widget _buildStepThree(bool isDark) {
    return _buildSlideLayout(
      isDark: isDark,
      badge: 'DIGNITY BY DESIGN',
      title: 'Private mutual intentions. Zero rejection alerts.',
      description:
          'After the meetup, privately select how you\'d like to stay in touch: Friendship, Activity Partner, Explore Dating, or No Connection. No one ever gets notified of a pass.',
      visualWidget: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.divider,
          ),
        ),
        child: Column(
          children: [
            _buildIntentionPreview('🤝 Friendship', isDark),
            const SizedBox(height: 8),
            _buildIntentionPreview('🏸 Activity Partner', isDark),
            const SizedBox(height: 8),
            _buildIntentionPreview('💫 Explore Dating', isDark),
            const SizedBox(height: 8),
            _buildIntentionPreview('🕊️ No Connection', isDark, isGhost: true),
          ],
        ),
      ),
    );
  }

  // Step 4: Worldwide Anywhere
  Widget _buildStepFour(bool isDark) {
    final userLoc = ref.watch(userLocationProvider);

    return _buildSlideLayout(
      isDark: isDark,
      badge: 'GLOBAL PERSPECTIVE',
      title: 'Connect anywhere in the world.',
      description:
          'Whether you are in Tokyo, London, New York, Mumbai, or exploring abroad, discover experiences or host your own at top cafes, restaurants, and lounges.',
      visualWidget: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.divider,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.public_rounded, size: 28, color: AppColors.mauve),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Current Base',
                        style: AppTypography.labelSmall.copyWith(
                          color: isDark
                              ? AppColors.darkMutedText
                              : AppColors.mutedText,
                        ),
                      ),
                      Text(
                        userLoc.shortLabel,
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.deepPlum,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () => LocationVenuePickerSheet.show(context),
              icon: const Icon(Icons.place_rounded, size: 16),
              label: const Text('Change City or Choose Meetup Venue'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlideLayout({
    required bool isDark,
    required String badge,
    required String title,
    required String description,
    required Widget visualWidget,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkElevated : AppColors.sage,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              badge,
              style: AppTypography.labelSmall.copyWith(
                color: isDark ? AppColors.luminousMauve : AppColors.deepPlum,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.headlineSmall.copyWith(
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkTextPrimary : AppColors.deepPlum,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? AppColors.darkMutedText : AppColors.mutedText,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),
          visualWidget,
        ],
      ),
    );
  }

  Widget _buildAvatarBubble(String emoji, String label, bool isDark) {
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkElevated : AppColors.warmIvory,
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.divider,
            ),
          ),
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 22)),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            fontSize: 10,
            color: isDark ? AppColors.darkTextPrimary : AppColors.deepPlum,
          ),
        ),
      ],
    );
  }

  Widget _buildIntentionPreview(String label, bool isDark, {bool isGhost = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isGhost
            ? Colors.transparent
            : (isDark ? AppColors.darkElevated : AppColors.warmIvory),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isGhost
              ? (isDark ? Colors.white12 : AppColors.divider)
              : (isDark ? AppColors.luminousMauve : AppColors.mauve),
          width: isGhost ? 0.8 : 1.2,
        ),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.deepPlum,
            ),
          ),
          const Spacer(),
          Icon(
            isGhost ? Icons.visibility_off_rounded : Icons.lock_outline_rounded,
            size: 16,
            color: isDark ? AppColors.darkMutedText : AppColors.mutedText,
          ),
        ],
      ),
    );
  }
}
