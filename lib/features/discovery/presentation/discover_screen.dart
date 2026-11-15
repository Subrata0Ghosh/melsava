import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/services/location_providers.dart';
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

            // Curated Meetup Venue Banner (Cafes, Restaurants, Board Games)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingLG,
                  vertical: AppConstants.spacingSM,
                ),
                child: GestureDetector(
                  onTap: () => LocationVenuePickerSheet.show(
                    context,
                    selectVenueMode: true,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: isDark
                          ? const LinearGradient(
                              colors: [Color(0xFF261D3B), Color(0xFF1B1528)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : const LinearGradient(
                              colors: [Color(0xFFEFE8DE), Color(0xFFF7F3EE)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? AppColors.luminousMauve.withValues(alpha: 0.3)
                            : AppColors.mauve.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.luminousMauve.withValues(alpha: 0.2)
                                : AppColors.mauve.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.storefront_rounded,
                            color: isDark ? AppColors.luminousMauve : AppColors.mauve,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Explore Meetup Cafes & Venues',
                                style: AppTypography.titleSmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: primaryTextColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Vetted coffee spots, board game lounges & restaurants in ${userLoc.city}',
                                style: AppTypography.bodySmall.copyWith(
                                  fontSize: 11,
                                  color: mutedTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: isDark ? AppColors.luminousMauve : AppColors.mauve,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Category Horizontal Scroll
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppConstants.spacingMD,
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

            // Featured Experience Hero Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingLG,
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

            // Experiences List
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
                  final exp = filteredExperiences[index];
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
                }, childCount: filteredExperiences.length),
              ),
            ),

            // Adequate bottom buffer for floating glassmorphic navbar
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }
}
