import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/services/location_providers.dart';
import '../../../shared/widgets/activity_radar_map_card.dart';
import '../../../shared/widgets/category_chip.dart';
import '../../../shared/widgets/experience_card.dart';
import '../../../shared/widgets/location_venue_picker_sheet.dart';
import '../../../shared/widgets/melsava_logo.dart';
import '../../../shared/widgets/section_header.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../experiences/data/experiences_repository.dart';
import '../../experiences/presentation/experience_detail_sheet.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  int _selectedSegment = 0; // 0: Curated, 1: Activity Radar, 2: All Vibes
  String _selectedCategory = 'All';

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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);
    final userLoc = ref.watch(userLocationProvider);
    final allExperiences = ref.watch(experiencesListProvider);

    final filteredExperiences = _selectedCategory == 'All'
        ? allExperiences
        : allExperiences
            .where(
              (e) => e.categoryName.toLowerCase().contains(
                    _selectedCategory.toLowerCase(),
                  ),
            )
            .toList();

    final featured = allExperiences.first;

    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.deepPlum;
    final mutedTextColor = isDark ? AppColors.darkMutedText : AppColors.mutedText;

    return Scaffold(
      backgroundColor: isDark ? AppColors.obsidian : AppColors.warmIvory,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            // Top App Bar with brand logo, worldwide location picker & theme toggle
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingLG,
                  vertical: AppConstants.spacingMD,
                ),
                child: Row(
                  children: [
                    const MelsavaLogo(size: 32),
                    const SizedBox(width: AppConstants.spacingSM),
                    Text(
                      AppConstants.appName,
                      style: AppTypography.titleLarge.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.0,
                        color: primaryTextColor,
                      ),
                    ),
                    const Spacer(),

                    // Worldwide Location Selector Pill
                    GestureDetector(
                      onTap: () => LocationVenuePickerSheet.show(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkElevated : AppColors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.divider,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? Colors.black26
                                  : AppColors.deepPlum.withValues(alpha: 0.04),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.place_rounded,
                              size: 14,
                              color: isDark ? AppColors.luminousMauve : AppColors.mauve,
                            ),
                            const SizedBox(width: 4),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 88),
                              child: Text(
                                userLoc.city,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.labelSmall.copyWith(
                                  color: primaryTextColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 14,
                              color: mutedTextColor,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Quick Dark / Light Theme Toggle Button
                    GestureDetector(
                      onTap: () => ref.read(themeModeProvider.notifier).toggleTheme(isDark),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkElevated : AppColors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.divider,
                          ),
                        ),
                        child: Icon(
                          isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                          size: 17,
                          color: isDark ? AppColors.softCoral : AppColors.mauve,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Editorial Greeting & Heading
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingLG,
                  vertical: AppConstants.spacingSM,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, ${user?.displayName ?? 'Explorer'}',
                      style: AppTypography.bodyMedium.copyWith(
                        color: mutedTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingXS),
                    Text(
                      'What would you like\nto experience?',
                      style: AppTypography.displaySmall.copyWith(
                        color: primaryTextColor,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingXS),
                    Text(
                      'Find activities you love in ${userLoc.city}. Meet people who love them too.',
                      style: AppTypography.bodySmall.copyWith(
                        color: mutedTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Segmented Pill Control (Proxima / Dribbble inspired)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingLG,
                  vertical: AppConstants.spacingMD,
                ),
                child: _buildSegmentControl(isDark),
              ),
            ),

            // ── TAB 0: CURATED FOR YOU ────────────────────────────────────
            if (_selectedSegment == 0) ...[
              // Curated Activity Radar Preview
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingLG,
                    vertical: AppConstants.spacingSM,
                  ),
                  child: ActivityRadarMapCard(
                    location: userLoc,
                    onVenueSelected: (venue) {
                      // Find experience matching venue or open detail
                      final match = allExperiences.firstWhere(
                        (e) => e.venueName.toLowerCase().contains(venue.name.toLowerCase()),
                        orElse: () => allExperiences.first,
                      );
                      ExperienceDetailSheet.show(
                        context,
                        experience: match,
                        onToggleJoin: () {
                          ref.read(experiencesRepositoryProvider).toggleJoin(match.id);
                          ref.invalidate(experiencesListProvider);
                        },
                      );
                    },
                  ),
                ),
              ),

              // Featured Experience Hero Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: AppConstants.spacingLG,
                    right: AppConstants.spacingLG,
                    top: AppConstants.spacingLG,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(
                        title: 'Featured Experience',
                        subtitle: 'Specially curated for your area this week',
                      ),
                      const SizedBox(height: AppConstants.spacingMD),
                      ExperienceCard(
                        experience: featured,
                        onTap: () => ExperienceDetailSheet.show(
                          context,
                          experience: featured,
                          onToggleJoin: () {
                            ref
                                .read(experiencesRepositoryProvider)
                                .toggleJoin(featured.id);
                            ref.invalidate(experiencesListProvider);
                          },
                        ),
                        onJoinTap: () {
                          ref
                              .read(experiencesRepositoryProvider)
                              .toggleJoin(featured.id);
                          ref.invalidate(experiencesListProvider);
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Upcoming Near You Section
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingLG,
                ),
                sliver: SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'Upcoming Near You',
                    subtitle: 'Small groups of 3–5 participants',
                    actionLabel: 'See All',
                    onActionTap: () => context.go('/experiences'),
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingLG,
                  vertical: AppConstants.spacingMD,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final exp = allExperiences[index];
                    return ExperienceCard(
                      experience: exp,
                      onTap: () => ExperienceDetailSheet.show(
                        context,
                        experience: exp,
                        onToggleJoin: () {
                          ref
                              .read(experiencesRepositoryProvider)
                              .toggleJoin(exp.id);
                          ref.invalidate(experiencesListProvider);
                        },
                      ),
                      onJoinTap: () {
                        ref
                            .read(experiencesRepositoryProvider)
                            .toggleJoin(exp.id);
                        ref.invalidate(experiencesListProvider);
                      },
                    );
                  }, childCount: allExperiences.length),
                ),
              ),
            ],

            // ── TAB 1: LIVE ACTIVITY RADAR ─────────────────────────────────
            if (_selectedSegment == 1) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingLG,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Live Area Radar',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          color: primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Verified cafes, gaming hubs & meetup spaces in ${userLoc.city}.',
                        style: AppTypography.bodySmall.copyWith(
                          color: mutedTextColor,
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingMD),
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
                            onToggleJoin: () {
                              ref.read(experiencesRepositoryProvider).toggleJoin(match.id);
                              ref.invalidate(experiencesListProvider);
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.only(
                  left: AppConstants.spacingLG,
                  right: AppConstants.spacingLG,
                  top: AppConstants.spacingLG,
                ),
                sliver: SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'Active Meetups in ${userLoc.city}',
                    subtitle: 'Hosted exclusively in vetted public venues',
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingLG,
                  vertical: AppConstants.spacingMD,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final exp = allExperiences[index];
                    return ExperienceCard(
                      experience: exp,
                      onTap: () => ExperienceDetailSheet.show(
                        context,
                        experience: exp,
                        onToggleJoin: () {
                          ref.read(experiencesRepositoryProvider).toggleJoin(exp.id);
                          ref.invalidate(experiencesListProvider);
                        },
                      ),
                      onJoinTap: () {
                        ref.read(experiencesRepositoryProvider).toggleJoin(exp.id);
                        ref.invalidate(experiencesListProvider);
                      },
                    );
                  }, childCount: allExperiences.length),
                ),
              ),
            ],

            // ── TAB 2: ALL VIBES & CATEGORIES ─────────────────────────────
            if (_selectedSegment == 2) ...[
              // Category Horizontal Scroll
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppConstants.spacingSM,
                  ),
                  child: SizedBox(
                    height: 40,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.spacingLG,
                      ),
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: AppConstants.spacingSM),
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        final isSelected = _selectedCategory == cat['name'];
                        return CategoryChip(
                          label: cat['name'],
                          icon: cat['icon'],
                          isSelected: isSelected,
                          onTap: () =>
                              setState(() => _selectedCategory = cat['name']),
                        );
                      },
                    ),
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingLG,
                  vertical: AppConstants.spacingMD,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final exp = filteredExperiences[index];
                    return ExperienceCard(
                      experience: exp,
                      onTap: () => ExperienceDetailSheet.show(
                        context,
                        experience: exp,
                        onToggleJoin: () {
                          ref.read(experiencesRepositoryProvider).toggleJoin(exp.id);
                          ref.invalidate(experiencesListProvider);
                        },
                      ),
                      onJoinTap: () {
                        ref.read(experiencesRepositoryProvider).toggleJoin(exp.id);
                        ref.invalidate(experiencesListProvider);
                      },
                    );
                  }, childCount: filteredExperiences.length),
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

  Widget _buildSegmentControl(bool isDark) {
    final activeBg = isDark ? AppColors.luminousMauve : AppColors.deepPlum;
    final inactiveText = isDark ? AppColors.darkMutedText : AppColors.mutedText;

    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkElevated : AppColors.creamElevated,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.divider,
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          _buildSegmentItem(0, 'Curated', Icons.auto_awesome_rounded, isDark, activeBg, inactiveText),
          _buildSegmentItem(1, 'Activity Radar', Icons.radar_rounded, isDark, activeBg, inactiveText),
          _buildSegmentItem(2, 'All Vibes', Icons.category_rounded, isDark, activeBg, inactiveText),
        ],
      ),
    );
  }

  Widget _buildSegmentItem(
    int index,
    String label,
    IconData icon,
    bool isDark,
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
                      color: activeBg.withValues(alpha: 0.3),
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
}
