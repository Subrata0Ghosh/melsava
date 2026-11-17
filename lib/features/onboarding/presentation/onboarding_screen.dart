import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/services/location_providers.dart';
import '../../../shared/widgets/botanical_leaf_decoration.dart';
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
      context.go('/adults-only');
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
      backgroundColor: isDark ? AppColors.obsidian : const Color(0xFFFFFDF9),
      body: AmbientNatureBackdrop(
        showTopLeaf: true,
        showBottomLeaf: true,
        leafStyle: BotanicalLeafStyle.tropicalFoliage,
        leafColors: BotanicalLeafDecoration.goldenSunlit,
        child: SafeArea(
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
                      onPressed: () => context.go('/adults-only'),
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                            gradient: isActive ? AppColors.sunsetCtaGradient : null,
                            color: isActive
                                ? null
                                : (isDark
                                    ? Colors.white.withValues(alpha: 0.15)
                                    : AppColors.divider),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),

                    // Primary Action Button (Gradient)
                    PrimaryButton(
                      label: _currentPage == 0
                          ? 'Get Started →'
                          : (_currentPage == _totalPages - 1
                              ? 'Explore MELSAVA'
                              : 'Continue'),
                      gradient: AppColors.sunsetCtaGradient,
                      onPressed: _onNext,
                    ),

                    const SizedBox(height: 10),

                    // "Sign In" text button (as shown in Image 3 Screen 2)
                    GestureDetector(
                      onTap: () => context.go('/sign-in'),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          'Sign In',
                          style: AppTypography.labelLarge.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: isDark ? AppColors.brightViolet : AppColors.primaryPurple,
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

  // Step 1: Discover Experiences, Meet Amazing People (Image 3 Screen 2)
  Widget _buildStepOne(bool isDark) {
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.deepPlum;
    final mutedTextColor = isDark ? AppColors.darkMutedText : AppColors.mutedText;

    return Stack(
      children: [
        // Botanical leaves decoration in the top corner (Screen 2)
        const Positioned(
          top: -15,
          left: -10,
          child: BotanicalLeafDecoration(
            style: BotanicalLeafStyle.tropicalFoliage,
            width: 75,
            height: 130,
            rotation: -0.25,
            opacity: 0.90,
          ),
        ),
        const Positioned(
          top: 10,
          right: -15,
          child: BotanicalLeafDecoration(
            style: BotanicalLeafStyle.monstera,
            width: 70,
            height: 120,
            rotation: 0.35,
            opacity: 0.90,
          ),
        ),

        // Main Slide Body
        SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 8),

              // Title: Discover Experiences, Meet Amazing People
              Text(
                'Discover\nExperiences,\nMeet Amazing People',
                textAlign: TextAlign.center,
                style: AppTypography.displaySmall.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 27,
                  height: 1.25,
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: 10),

              // Subtitle
              Text(
                'Join activities, make friends and find your people.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: mutedTextColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 28),

              // ── Collage of 3 Tilted Experience Cards (Screen 2) ──
              SizedBox(
                height: 250,
                width: 320,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Card 1 (Left): Coffee & Conversation
                    Positioned(
                      left: 10,
                      top: 15,
                      child: Transform.rotate(
                        angle: -0.10,
                        child: _buildCollagePhotoCard(
                          assetPath: 'assets/images/coffee_latte_art.png',
                          width: 140,
                          height: 110,
                          isDark: isDark,
                        ),
                      ),
                    ),

                    // Card 2 (Right): Hiking & Trekking
                    Positioned(
                      right: 12,
                      top: 10,
                      child: Transform.rotate(
                        angle: 0.08,
                        child: _buildCollagePhotoCard(
                          assetPath: 'assets/images/hikers_mountain_trek.png',
                          width: 150,
                          height: 115,
                          isDark: isDark,
                        ),
                      ),
                    ),

                    // Card 3 (Bottom Center): Live Concert / Festival
                    Positioned(
                      left: 35,
                      bottom: 10,
                      child: Transform.rotate(
                        angle: -0.04,
                        child: _buildCollagePhotoCard(
                          assetPath: 'assets/images/concert_party_crowd.png',
                          width: 210,
                          height: 125,
                          isDark: isDark,
                        ),
                      ),
                    ),

                    // Floating 3D Heart Jewel
                    Positioned(
                      right: 40,
                      bottom: 45,
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF5E7E), Color(0xFFFF9E7D)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF5E7E).withValues(alpha: 0.5),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // ── Micro-Experience Pillars / Perks ──
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildPerkPill('🛡️ Vetted Public Venues', isDark),
                  _buildPerkPill('☕ 3–5 Micro-Groups', isDark),
                  _buildPerkPill('✨ Mutual Match Only', isDark),
                ],
              ),

              const SizedBox(height: 14),

              // ── Social Proof Community Badge ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkElevated : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : const Color(0xFFEDE9FE),
                    width: 0.9,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 58,
                      height: 24,
                      child: Stack(
                        children: [
                          Positioned(
                            left: 0,
                            child: _buildMiniAvatar('assets/images/sneha_avatar.png'),
                          ),
                          Positioned(
                            left: 16,
                            child: _buildMiniAvatar('assets/images/aditi_avatar.png'),
                          ),
                          Positioned(
                            left: 32,
                            child: _buildMiniAvatar('assets/images/rohan_avatar.png'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '2,400+ people joined this week',
                      style: TextStyle(
                        color: primaryTextColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCollagePhotoCard({
    required String assetPath,
    required double width,
    required double height,
    required bool isDark,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white,
          width: 3.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Image.asset(
          assetPath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: AppColors.mauve,
            child: const Icon(Icons.photo_rounded, color: Colors.white),
          ),
        ),
      ),
    );
  }

  // Step 2: Small Safe Groups (3–5 participants)
  Widget _buildStepTwo(bool isDark) {
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.deepPlum;
    final mutedTextColor = isDark ? AppColors.darkMutedText : AppColors.mutedText;

    final attendees = [
      {'name': 'Sneha', 'role': 'Designer', 'avatar': 'assets/images/sneha_avatar.png'},
      {'name': 'Rohan', 'role': 'Architect', 'avatar': 'assets/images/rohan_avatar.png'},
      {'name': 'Aditi', 'role': 'Writer', 'avatar': 'assets/images/aditi_avatar.png'},
      {'name': 'Vikram', 'role': 'Foodie', 'avatar': 'assets/images/vikram_avatar.png'},
    ];

    return Stack(
      children: [
        // Botanical Leaves Accent
        const Positioned(
          top: -12,
          left: -12,
          child: BotanicalLeafDecoration(
            style: BotanicalLeafStyle.tropicalFoliage,
            width: 75,
            height: 125,
            rotation: -0.22,
            opacity: 0.85,
          ),
        ),
        const Positioned(
          top: 8,
          right: -15,
          child: BotanicalLeafDecoration(
            style: BotanicalLeafStyle.eucalyptus,
            width: 70,
            height: 115,
            rotation: 0.28,
            opacity: 0.85,
          ),
        ),

        SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 8),

              // Safe & Intimate Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: (isDark ? const Color(0xFF10B981) : const Color(0xFF059669)).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: (isDark ? const Color(0xFF10B981) : const Color(0xFF059669)).withValues(alpha: 0.3),
                    width: 0.9,
                  ),
                ),
                child: Text(
                  'SAFE & INTIMATE CIRCLES',
                  style: AppTypography.labelSmall.copyWith(
                    color: isDark ? const Color(0xFF34D399) : const Color(0xFF047857),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'Curated small groups of\n3 to 5 participants.',
                textAlign: TextAlign.center,
                style: AppTypography.displaySmall.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 25,
                  height: 1.25,
                  color: primaryTextColor,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'No awkward 1-on-1 blind dates. Gather in relaxed, small circles at vetted public venues where conversations flow naturally.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: mutedTextColor,
                  fontSize: 13.5,
                  height: 1.45,
                ),
              ),

              const SizedBox(height: 20),

              // ── Hero Interactive Gathering Showcase Card ──
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : const Color(0xFFEDE9FE),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Top Venue Photo Header with Ambient Glow & Badges
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(23)),
                      child: Stack(
                        children: [
                          Image.asset(
                            'assets/images/live_meetup_cafe_bg.png',
                            height: 115,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 115,
                              color: AppColors.brightViolet.withValues(alpha: 0.2),
                              child: const Icon(Icons.coffee_rounded, color: AppColors.brightViolet, size: 36),
                            ),
                          ),
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.25),
                                    Colors.black.withValues(alpha: 0.65),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 10,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.white24, width: 0.8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.place_rounded, size: 12, color: Color(0xFFFBBF24)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Subko Specialty Coffee • Bandra',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 10,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.bolt_rounded, size: 13, color: Colors.white),
                                  SizedBox(width: 3),
                                  Text(
                                    '1 Spot Left!',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                      child: Column(
                        children: [
                          // 5 Circle Attendees (4 real + 1 'You' spot)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ...attendees.map((a) {
                                return Column(
                                  children: [
                                    Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Container(
                                          width: 46,
                                          height: 46,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isDark ? AppColors.brightViolet : AppColors.primaryPurple,
                                              width: 1.8,
                                            ),
                                          ),
                                          child: ClipOval(
                                            child: Image.asset(
                                              a['avatar']!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) =>
                                                  const ColoredBox(color: AppColors.brightViolet),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          right: -1,
                                          bottom: -1,
                                          child: Container(
                                            width: 13,
                                            height: 13,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF10B981),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: isDark ? AppColors.darkSurface : Colors.white,
                                                width: 1.8,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      a['name']!,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1E1435),
                                      ),
                                    ),
                                    Text(
                                      a['role']!,
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        color: isDark ? AppColors.darkMutedText : const Color(0xFF7E7394),
                                      ),
                                    ),
                                  ],
                                );
                              }),

                              // 5th Spot: You!
                              Column(
                                children: [
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFFFF5E7E),
                                        width: 1.8,
                                      ),
                                      color: const Color(0xFFFF5E7E).withValues(alpha: 0.1),
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.add_rounded, color: Color(0xFFFF5E7E), size: 24),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'You',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFFF5E7E),
                                    ),
                                  ),
                                  Text(
                                    'Your Seat',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppColors.darkMutedText : const Color(0xFF7E7394),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),
                          Divider(height: 1, color: isDark ? AppColors.darkBorder : const Color(0xFFEDE9FE)),
                          const SizedBox(height: 10),

                          // Icebreaker Prompt Bubble
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: (isDark ? AppColors.brightViolet : AppColors.primaryPurple).withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.forum_outlined, size: 17, color: AppColors.brightViolet),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Icebreaker: "What\'s your go-to weekend passion project?"',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      fontStyle: FontStyle.italic,
                                      color: isDark ? Colors.white : const Color(0xFF1E1435),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Safety & Quality Pillars ──
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildPerkPill('🛡️ Public Vetted Cafes', isDark),
                  _buildPerkPill('✨ Verified 18+ Profiles', isDark),
                  _buildPerkPill('☕ Balanced Circles', isDark),
                ],
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  // Step 3: Private Mutual Chemistry
  Widget _buildStepThree(bool isDark) {
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.deepPlum;
    final mutedTextColor = isDark ? AppColors.darkMutedText : AppColors.mutedText;

    return Stack(
      children: [
        // Botanical Leaves Accent
        const Positioned(
          top: -10,
          left: -15,
          child: BotanicalLeafDecoration(
            style: BotanicalLeafStyle.monstera,
            width: 75,
            height: 120,
            rotation: -0.25,
            opacity: 0.85,
          ),
        ),
        const Positioned(
          top: 10,
          right: -12,
          child: BotanicalLeafDecoration(
            style: BotanicalLeafStyle.wildGrass,
            width: 65,
            height: 110,
            rotation: 0.24,
            opacity: 0.85,
          ),
        ),

        SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 8),

              // Dignity Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.brightViolet : AppColors.primaryPurple).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: (isDark ? AppColors.brightViolet : AppColors.primaryPurple).withValues(alpha: 0.3),
                    width: 0.9,
                  ),
                ),
                child: Text(
                  'DIGNITY BY DESIGN',
                  style: AppTypography.labelSmall.copyWith(
                    color: isDark ? AppColors.luminousMauve : AppColors.deepPlum,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'Private mutual intentions.\nZero rejection alerts.',
                textAlign: TextAlign.center,
                style: AppTypography.displaySmall.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 25,
                  height: 1.25,
                  color: primaryTextColor,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'After the meetup, privately select who you\'d like to stay in touch with. We only reveal connections when the interest is mutual.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: mutedTextColor,
                  fontSize: 13.5,
                  height: 1.45,
                ),
              ),

              const SizedBox(height: 20),

              // ── Interactive Mutual Chemistry Match Showcase ──
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : const Color(0xFFEDE9FE),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Dual Profiles & Mutual Connection Spark
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // Left: You
                        Column(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFFF5E7E), width: 2),
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/images/rohan_avatar.png',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const ColoredBox(color: AppColors.brightViolet),
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              'You',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                            ),
                            Container(
                              margin: const EdgeInsets.only(top: 3),
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF5E7E).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Voted 💫 + 🤝',
                                style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFFFF5E7E)),
                              ),
                            ),
                          ],
                        ),

                        // Center: Sparkle & Lock
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFF5E7E), Color(0xFF8B5CF6)],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF5E7E).withValues(alpha: 0.4),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.auto_awesome_rounded, size: 14, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text(
                                    'Mutual Spark!',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.lock_rounded, size: 11, color: Color(0xFF10B981)),
                                SizedBox(width: 3),
                                Text(
                                  'Encrypted & Private',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF10B981)),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Right: Sneha
                        Column(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF8B5CF6), width: 2),
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/images/sneha_avatar.png',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const ColoredBox(color: AppColors.brightViolet),
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              'Sneha',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                            ),
                            Container(
                              margin: const EdgeInsets.only(top: 3),
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Voted 💫 + 🤝',
                                style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF8B5CF6)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),
                    Divider(height: 1, color: isDark ? AppColors.darkBorder : const Color(0xFFEDE9FE)),
                    const SizedBox(height: 12),

                    // Zero Rejection Reassurance
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: (isDark ? const Color(0xFF10B981) : const Color(0xFF059669)).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.shield_outlined, size: 16, color: Color(0xFF10B981)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'If either person passes: Pure silence. No one ever gets notified.',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ── 4 Intentions in 2x2 Grid ──
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.3,
                children: [
                  _buildIntentionTile('🤝 Friendship', 'Coffee & casual chats', const Color(0xFFF59E0B), isDark),
                  _buildIntentionTile('🏸 Activity Partner', 'Sports & hobbies', const Color(0xFF10B981), isDark),
                  _buildIntentionTile('💫 Explore Dating', 'Spark chemistry', const Color(0xFFFF5E7E), isDark),
                  _buildIntentionTile('🕊️ Polite Pass', 'Zero awkwardness', const Color(0xFF8B5CF6), isDark, isPass: true),
                ],
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  // Step 4: Worldwide Anywhere
  Widget _buildStepFour(bool isDark) {
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.deepPlum;
    final mutedTextColor = isDark ? AppColors.darkMutedText : AppColors.mutedText;
    final userLoc = ref.watch(userLocationProvider);

    final globalCities = [
      {
        'city': 'Tokyo, Japan',
        'venue': 'Shibuya Roastery Social',
        'circles': '42 Live Circles',
        'image': 'assets/images/coffee_latte_art.png',
      },
      {
        'city': 'New York, USA',
        'venue': 'SoHo Art & Sunset Social',
        'circles': '68 Live Circles',
        'image': 'assets/images/concert_party_crowd.png',
      },
      {
        'city': 'London, UK',
        'venue': 'Mayfair Weekend Gathering',
        'circles': '35 Live Circles',
        'image': 'assets/images/morning_yoga_zen.png',
      },
      {
        'city': 'Mumbai, India',
        'venue': 'Bandra Heritage Brunch',
        'circles': '50 Live Circles',
        'image': 'assets/images/live_meetup_cafe_bg.png',
      },
    ];

    return Stack(
      children: [
        // Botanical Leaves Accent
        const Positioned(
          top: -12,
          right: -15,
          child: BotanicalLeafDecoration(
            style: BotanicalLeafStyle.tropicalFoliage,
            width: 75,
            height: 125,
            rotation: 0.28,
            opacity: 0.85,
          ),
        ),
        const Positioned(
          top: 10,
          left: -12,
          child: BotanicalLeafDecoration(
            style: BotanicalLeafStyle.eucalyptus,
            width: 65,
            height: 110,
            rotation: -0.22,
            opacity: 0.85,
          ),
        ),

        SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 8),

              // Global Perspective Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7)).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7)).withValues(alpha: 0.3),
                    width: 0.9,
                  ),
                ),
                child: Text(
                  'GLOBAL PERSPECTIVE',
                  style: AppTypography.labelSmall.copyWith(
                    color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0369A1),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'Connect anywhere\nin the world.',
                textAlign: TextAlign.center,
                style: AppTypography.displaySmall.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 25,
                  height: 1.25,
                  color: primaryTextColor,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Whether you\'re at home in Mumbai or traveling to Tokyo, London, or New York—discover small group experiences wherever you go.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: mutedTextColor,
                  fontSize: 13.5,
                  height: 1.45,
                ),
              ),

              const SizedBox(height: 18),

              // ── Horizontal Postcards of Global Cities ──
              SizedBox(
                height: 148,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  itemCount: globalCities.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 12),
                  itemBuilder: (context, i) {
                    final c = globalCities[i];
                    return Container(
                      width: 160,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(
                              c['image']!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: AppColors.brightViolet.withValues(alpha: 0.3),
                                child: const Icon(Icons.location_city_rounded, color: Colors.white),
                              ),
                            ),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.80),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  c['circles']!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 10,
                              left: 10,
                              right: 10,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    c['city']!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    c['venue']!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10,
                                    ),
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
              ),

              const SizedBox(height: 16),

              // ── Interactive Current Base Card ──
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : const Color(0xFFEDE9FE),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.04),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: (isDark ? AppColors.brightViolet : AppColors.primaryPurple).withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.location_on_rounded, color: AppColors.brightViolet, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'YOUR CURRENT BASE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.1,
                                  color: isDark ? AppColors.darkMutedText : const Color(0xFF7E7394),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                userLoc.shortLabel,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: primaryTextColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    '18 circles active this week',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          side: BorderSide(
                            color: isDark ? AppColors.brightViolet : AppColors.primaryPurple,
                            width: 1.2,
                          ),
                        ),
                        onPressed: () => LocationVenuePickerSheet.show(context),
                        icon: const Icon(Icons.public_rounded, size: 16),
                        label: const Text(
                          'Change City or Choose Meetup Venue',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ── Global Trust Metrics Pill ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkElevated : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : const Color(0xFFEDE9FE),
                    width: 0.9,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildMetricCol('45+', 'Global Cities', isDark),
                    Container(height: 20, width: 1, color: isDark ? Colors.white12 : const Color(0xFFEDE9FE)),
                    _buildMetricCol('12k+', 'Vetted Venues', isDark),
                    Container(height: 20, width: 1, color: isDark ? Colors.white12 : const Color(0xFFEDE9FE)),
                    _buildMetricCol('99%', 'Felt Safe', isDark),
                  ],
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIntentionTile(String title, String subtitle, Color color, bool isDark, {bool isPass = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkElevated : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.35 : 0.25),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isDark ? 0.15 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1E1435),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9.5,
              color: isDark ? AppColors.darkMutedText : const Color(0xFF7E7394),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCol(String value, String label, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF1E1435),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 9.5,
            color: isDark ? AppColors.darkMutedText : const Color(0xFF7E7394),
          ),
        ),
      ],
    );
  }

  static Widget _buildMiniAvatar(String assetPath) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: ClipOval(
        child: Image.asset(
          assetPath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const ColoredBox(color: AppColors.brightViolet),
        ),
      ),
    );
  }

  static Widget _buildPerkPill(String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkElevated : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFEDE9FE),
          width: 0.9,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1E1435),
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}
