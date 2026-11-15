import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/widgets/category_chip.dart';
import '../../../shared/widgets/experience_card.dart';
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
  String _selectedCity = 'Mumbai';

  final List<Map<String, dynamic>> _categories = [
    {'name': 'All', 'icon': Icons.auto_awesome_outlined},
    {'name': 'Coffee & Conversation', 'icon': Icons.coffee_outlined},
    {'name': 'Board Games', 'icon': Icons.casino_outlined},
    {'name': 'Photography', 'icon': Icons.camera_alt_outlined},
    {'name': 'Nature Walks', 'icon': Icons.park_outlined},
    {'name': 'Sports & Fitness', 'icon': Icons.fitness_center_outlined},
    {'name': 'Reading & Books', 'icon': Icons.menu_book_outlined},
    {'name': 'Creative Workshops', 'icon': Icons.palette_outlined},
  ];

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
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

    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Top App Bar with brand logo, city picker & notifications
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
                        letterSpacing: 1.5,
                      ),
                    ),
                    const Spacer(),

                    // City selector
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(
                          AppConstants.buttonRadiusSmall,
                        ),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.place,
                            size: 14,
                            color: AppColors.mauve,
                          ),
                          const SizedBox(width: 4),
                          DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedCity,
                              isDense: true,
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.deepPlum,
                                fontWeight: FontWeight.w600,
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'Mumbai',
                                  child: Text('Mumbai'),
                                ),
                                DropdownMenuItem(
                                  value: 'Bengaluru',
                                  child: Text('Bengaluru'),
                                ),
                                DropdownMenuItem(
                                  value: 'Delhi NCR',
                                  child: Text('Delhi NCR'),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedCity = val);
                                }
                              },
                            ),
                          ),
                        ],
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
                        color: AppColors.mutedText,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingXS),
                    Text(
                      'What would you like\nto experience?',
                      style: AppTypography.displaySmall.copyWith(
                        color: AppColors.deepPlum,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingXS),
                    Text(
                      'Find something you enjoy. Meet people who enjoy it too.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
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

            const SliverToBoxAdapter(
              child: SizedBox(height: AppConstants.spacingXXL),
            ),
          ],
        ),
      ),
    );
  }
}
