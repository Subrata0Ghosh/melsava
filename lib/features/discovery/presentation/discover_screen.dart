import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/services/location_providers.dart';
import '../../../shared/models/experience_model.dart';
import '../../../shared/widgets/activity_radar_map_card.dart';
import '../../../shared/widgets/experience_card.dart';
import '../../../shared/widgets/location_venue_picker_sheet.dart';
import '../../../shared/widgets/melsava_logo.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../experiences/data/experiences_repository.dart';
import '../../experiences/presentation/experience_detail_sheet.dart';
import '../../experiences/presentation/join_experience_sheet.dart';

/// Screen 1: Discover Screen
///
/// High-fidelity event discovery layout inspired by Dribbble Event Discovery
/// (shots/27040094), featuring:
/// - Editorial header with worldwide location picker & theme toggle
/// - Interactive search & vibe filter
/// - Featured Hero experience carousel with rich glassmorphism
/// - Segmented mode selector (Curated For You, Live Radar, All Vibes)
/// - Vetted micro-group experience listings with micro-interactions
class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  int _selectedSegment = 0; // 0: Curated, 1: Live Radar, 2: All Vibes
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> _categories = [
    {'name': 'All', 'icon': Icons.auto_awesome_rounded},
    {'name': 'Coffee & Conversation', 'icon': Icons.coffee_rounded},
    {'name': 'Board Games', 'icon': Icons.casino_rounded},
    {'name': 'Photography', 'icon': Icons.camera_alt_rounded},
    {'name': 'Nature Walks', 'icon': Icons.park_rounded},
    {'name': 'Sports & Fitness', 'icon': Icons.fitness_center_rounded},
    {'name': 'Reading & Books', 'icon': Icons.menu_book_rounded},
    {'name': 'Creative Workshops', 'icon': Icons.palette_rounded},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openJoinFlow(ExperienceModel experience) {
    JoinExperienceSheet.show(
      context,
      experience: experience,
      onConfirmed: () {
        ref.read(experiencesRepositoryProvider).toggleJoin(experience.id);
        ref.invalidate(experiencesListProvider);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);
    final userLoc = ref.watch(userLocationProvider);
    final allExperiences = ref.watch(experiencesListProvider);

    // Filter by query and category
    final filteredExperiences = allExperiences.where((e) {
      final matchesCategory = _selectedCategory == 'All' ||
          e.categoryName.toLowerCase().contains(_selectedCategory.toLowerCase());
      final matchesQuery = _searchQuery.isEmpty ||
          e.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.venueName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.categoryName.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesQuery;
    }).toList();

    final featuredExperience = allExperiences.first;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.deepPlum;
    final mutedTextColor = isDark ? AppColors.darkMutedText : AppColors.mutedText;

    return Scaffold(
      backgroundColor: isDark ? AppColors.obsidian : AppColors.warmIvory,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Top Bar: Brand, Worldwide Location Pill & Quick Theme Toggle ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                child: Row(
                  children: [
                    const MelsavaLogo(size: 34),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppConstants.appName,
                          style: AppTypography.titleLarge.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.5,
                            fontSize: 18,
                            color: primaryTextColor,
                          ),
                        ),
                        Text(
                          'MEET THROUGH MOMENTS',
                          style: AppTypography.labelSmall.copyWith(
                            letterSpacing: 1.4,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.softCoral : AppColors.mauve,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),

                    // Worldwide Location Pill
                    GestureDetector(
                      onTap: () => LocationVenuePickerSheet.show(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkElevated : AppColors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.divider,
                            width: 0.9,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? Colors.black26
                                  : AppColors.deepPlum.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 15,
                              color: isDark ? AppColors.luminousMauve : AppColors.mauve,
                            ),
                            const SizedBox(width: 4),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 96),
                              child: Text(
                                userLoc.city,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.labelSmall.copyWith(
                                  color: primaryTextColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 16,
                              color: mutedTextColor,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Theme Toggle Button
                    GestureDetector(
                      onTap: () => ref.read(themeModeProvider.notifier).toggleTheme(isDark),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkElevated : AppColors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.divider,
                            width: 0.9,
                          ),
                        ),
                        child: Icon(
                          isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                          size: 18,
                          color: isDark ? AppColors.softCoral : AppColors.mauve,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Search & Filter Input Bar ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.divider,
                      width: 0.9,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black26
                            : AppColors.deepPlum.withValues(alpha: 0.04),
                        blurRadius: 14,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 14),
                      Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: isDark ? AppColors.luminousMauve : AppColors.mauve,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(() => _searchQuery = val),
                          style: AppTypography.bodyMedium.copyWith(
                            color: primaryTextColor,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search experiences, cafes, boards...',
                            hintStyle: AppTypography.bodySmall.copyWith(
                              color: mutedTextColor,
                              fontSize: 13,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: mutedTextColor,
                            ),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Icon(
                            Icons.tune_rounded,
                            size: 18,
                            color: mutedTextColor,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Editorial Headline ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, ${user?.displayName ?? 'Explorer'} 👋',
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark ? AppColors.softCoral : AppColors.mauve,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'What would you love to\nexperience this week?',
                      style: AppTypography.displaySmall.copyWith(
                        color: primaryTextColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        height: 1.22,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Segmented Mode Selector ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: _buildSegmentControl(isDark),
              ),
            ),

            // ═════════════════════════════════════════════════════════════════
            // MODE 0: CURATED FOR YOU
            // ═════════════════════════════════════════════════════════════════
            if (_selectedSegment == 0) ...[
              // Featured Hero Card (Dribbble Event Discovery layout)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: _buildFeaturedHeroCard(
                    context,
                    featuredExperience,
                    isDark,
                    primaryTextColor,
                    mutedTextColor,
                  ),
                ),
              ),

              // Category Pills Rail
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: SizedBox(
                    height: 38,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _categories.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        final isSelected = _selectedCategory == cat['name'];
                        return _buildCategoryPill(
                          cat['name'],
                          cat['icon'],
                          isSelected,
                          isDark,
                        );
                      },
                    ),
                  ),
                ),
              ),

              // Section Header: Upcoming in [City]
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Upcoming in ${userLoc.city}',
                            style: AppTypography.titleLarge.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: primaryTextColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Vetted public spots · Small groups of 3–5',
                            style: AppTypography.bodySmall.copyWith(
                              color: mutedTextColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () => context.go('/experiences'),
                        child: Text(
                          'See All',
                          style: AppTypography.labelMedium.copyWith(
                            color: isDark ? AppColors.luminousMauve : AppColors.mauve,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Experiences List
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final exp = filteredExperiences[index];
                      return ExperienceCard(
                        experience: exp,
                        onTap: () => ExperienceDetailSheet.show(
                          context,
                          experience: exp,
                          onToggleJoin: () => _openJoinFlow(exp),
                        ),
                        onJoinTap: () => _openJoinFlow(exp),
                      );
                    },
                    childCount: filteredExperiences.length,
                  ),
                ),
              ),
            ],

            // ═════════════════════════════════════════════════════════════════
            // MODE 1: LIVE ACTIVITY RADAR
            // ═════════════════════════════════════════════════════════════════
            if (_selectedSegment == 1) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Live Area Radar in ${userLoc.city}',
                        style: AppTypography.titleLarge.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Explore verified artisan cafes, board game lounges, and park pavilions with scheduled meetups.',
                        style: AppTypography.bodySmall.copyWith(
                          color: mutedTextColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ActivityRadarMapCard(
                        location: userLoc,
                        onVenueSelected: (venue) {
                          final match = allExperiences.firstWhere(
                            (e) => e.venueName.toLowerCase().contains(venue.name.toLowerCase()),
                            orElse: () => allExperiences.first,
                          );
                          ExperienceDetailSheet.show(
                            context,
                            experience: match,
                            onToggleJoin: () => _openJoinFlow(match),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Text(
                    'Active Venues with Meetups',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      color: primaryTextColor,
                    ),
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final exp = filteredExperiences[index];
                      return ExperienceCard(
                        experience: exp,
                        onTap: () => ExperienceDetailSheet.show(
                          context,
                          experience: exp,
                          onToggleJoin: () => _openJoinFlow(exp),
                        ),
                        onJoinTap: () => _openJoinFlow(exp),
                      );
                    },
                    childCount: filteredExperiences.length,
                  ),
                ),
              ),
            ],

            // ═════════════════════════════════════════════════════════════════
            // MODE 2: ALL VIBES
            // ═════════════════════════════════════════════════════════════════
            if (_selectedSegment == 2) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: SizedBox(
                    height: 40,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _categories.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        final isSelected = _selectedCategory == cat['name'];
                        return _buildCategoryPill(
                          cat['name'],
                          cat['icon'],
                          isSelected,
                          isDark,
                        );
                      },
                    ),
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final exp = filteredExperiences[index];
                      return ExperienceCard(
                        experience: exp,
                        onTap: () => ExperienceDetailSheet.show(
                          context,
                          experience: exp,
                          onToggleJoin: () => _openJoinFlow(exp),
                        ),
                        onJoinTap: () => _openJoinFlow(exp),
                      );
                    },
                    childCount: filteredExperiences.length,
                  ),
                ),
              ),
            ],

            // Adequate bottom buffer for floating glassmorphic navbar
            const SliverToBoxAdapter(
              child: SizedBox(height: 120),
            ),
          ],
        ),
      ),
    );
  }

  // ── Featured Hero Card (Inspired by Event Discovery) ──
  Widget _buildFeaturedHeroCard(
    BuildContext context,
    ExperienceModel exp,
    bool isDark,
    Color primaryTextColor,
    Color mutedTextColor,
  ) {
    return GestureDetector(
      onTap: () => ExperienceDetailSheet.show(
        context,
        experience: exp,
        onToggleJoin: () => _openJoinFlow(exp),
      ),
      child: Container(
        height: 250,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.5)
                  : AppColors.deepPlum.withValues(alpha: 0.12),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Cover Image
              CachedNetworkImage(
                imageUrl: exp.coverImageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: isDark ? AppColors.darkElevated : AppColors.creamElevated,
                ),
              ),

              // Gradient Overlay
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.1),
                      Colors.black.withValues(alpha: 0.35),
                      Colors.black.withValues(alpha: 0.88),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),

              // Top row: Featured Tag & Spots Left
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 14,
                                color: Colors.amberAccent,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'FEATURED THIS WEEK',
                                style: AppTypography.labelSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.vividCoral,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${exp.maxParticipants - exp.currentParticipants} spots left',
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom details
              Positioned(
                left: 18,
                right: 18,
                bottom: 18,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          exp.categoryIcon,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          exp.categoryName.toUpperCase(),
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.softCoral,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      exp.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.place_rounded,
                          size: 14,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            exp.venueName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            exp.hasJoined ? 'Joined ✓' : 'Explore',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.deepPlum,
                              fontWeight: FontWeight.w800,
                              fontSize: 11.5,
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
      ),
    );
  }

  // ── Segment Control ──
  Widget _buildSegmentControl(bool isDark) {
    final activeBg = isDark ? AppColors.luminousMauve : AppColors.deepPlum;
    final inactiveText = isDark ? AppColors.darkMutedText : AppColors.mutedText;

    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.creamElevated,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.divider,
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          _buildSegmentItem(0, 'Curated', Icons.auto_awesome_rounded, activeBg, inactiveText),
          _buildSegmentItem(1, 'Live Radar', Icons.radar_rounded, activeBg, inactiveText),
          _buildSegmentItem(2, 'All Vibes', Icons.grid_view_rounded, activeBg, inactiveText),
        ],
      ),
    );
  }

  Widget _buildSegmentItem(
    int index,
    String label,
    IconData icon,
    Color activeBg,
    Color inactiveText,
  ) {
    final isSelected = _selectedSegment == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _selectedSegment = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: activeBg.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : inactiveText,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 11.5,
                  color: isSelected ? Colors.white : inactiveText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Category Pill ──
  Widget _buildCategoryPill(
    String label,
    IconData icon,
    bool isSelected,
    bool isDark,
  ) {
    final selectedBg = isDark ? AppColors.luminousMauve : AppColors.deepPlum;
    final unselectedBg = isDark ? AppColors.darkSurface : AppColors.white;
    final borderColor = isSelected
        ? selectedBg
        : (isDark ? AppColors.darkBorder : AppColors.divider);

    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : unselectedBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: 1.0),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: selectedBg.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected
                  ? Colors.white
                  : (isDark ? AppColors.luminousMauve : AppColors.mauve),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColors.darkTextPrimary : AppColors.deepPlum),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
