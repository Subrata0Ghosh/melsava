import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/services/location_providers.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/experience_card.dart';
import '../../../shared/widgets/location_venue_picker_sheet.dart';
import '../../../shared/widgets/primary_button.dart';
import '../data/experiences_repository.dart';
import 'experience_detail_sheet.dart';
import 'post_experience_choice_screen.dart';

class ExperiencesScreen extends ConsumerStatefulWidget {
  const ExperiencesScreen({super.key});

  @override
  ConsumerState<ExperiencesScreen> createState() => _ExperiencesScreenState();
}

class _ExperiencesScreenState extends ConsumerState<ExperiencesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userLoc = ref.watch(userLocationProvider);
    final allExperiences = ref.watch(experiencesListProvider);
    final myExperiences = allExperiences
        .where((e) => e.hasJoined || e.isCompleted)
        .toList();

    final filteredAll = _searchQuery.isEmpty
        ? allExperiences
        : allExperiences
            .where(
              (e) =>
                  e.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  e.categoryName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  e.venueName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  e.city.toLowerCase().contains(_searchQuery.toLowerCase()),
            )
            .toList();

    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.deepPlum;
    final mutedTextColor = isDark ? AppColors.darkMutedText : AppColors.mutedText;

    return Scaffold(
      backgroundColor: isDark ? AppColors.obsidian : AppColors.warmIvory,
      appBar: AppBar(
        title: Text(
          'Experiences',
          style: AppTypography.titleLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: primaryTextColor,
          ),
        ),
        actions: [
          // Worldwide Location Pill
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => LocationVenuePickerSheet.show(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkElevated : AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.divider,
                  ),
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
                    Text(
                      userLoc.city,
                      style: AppTypography.labelSmall.copyWith(
                        color: primaryTextColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        backgroundColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: isDark ? AppColors.luminousMauve : AppColors.deepPlum,
          labelColor: isDark ? AppColors.luminousMauve : AppColors.deepPlum,
          unselectedLabelColor: mutedTextColor,
          labelStyle: AppTypography.labelLarge.copyWith(
            fontWeight: FontWeight.w700,
          ),
          tabs: const [
            Tab(text: 'Browse All'),
            Tab(text: 'My Experiences'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Browse All
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppConstants.spacingLG),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: TextStyle(color: primaryTextColor),
                  decoration: InputDecoration(
                    hintText: 'Search experiences, venues, or places...',
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: isDark ? AppColors.luminousMauve : AppColors.mauve,
                    ),
                    filled: true,
                    fillColor: isDark ? AppColors.darkSurface : AppColors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppConstants.buttonRadiusLarge,
                      ),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.darkBorder : AppColors.divider,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: filteredAll.isEmpty
                    ? const EmptyStateWidget(
                        icon: Icons.explore_off_outlined,
                        title: 'No experiences found',
                        message:
                            'Nothing matches your search just yet. Explore another category or check back soon.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(
                          left: AppConstants.spacingLG,
                          right: AppConstants.spacingLG,
                          bottom: 100, // Bottom padding for glassmorphic navbar
                        ),
                        itemCount: filteredAll.length,
                        itemBuilder: (context, index) {
                          final exp = filteredAll[index];
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
                        },
                      ),
              ),
            ],
          ),

          // Tab 2: My Experiences
          myExperiences.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.calendar_today_outlined,
                  title: 'No joined experiences yet',
                  message:
                      'Your next great connection starts with your next experience. Browse activities to join your first micro-group!',
                  actionLabel: 'Discover Activities',
                  onActionPressed: () => _tabController.animateTo(0),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(
                    left: AppConstants.spacingLG,
                    right: AppConstants.spacingLG,
                    top: AppConstants.spacingLG,
                    bottom: 100, // Bottom padding for glassmorphic navbar
                  ),
                  itemCount: myExperiences.length,
                  itemBuilder: (context, index) {
                    final exp = myExperiences[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ExperienceCard(
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
                        ),
                        if (exp.isCompleted) ...[
                          Container(
                            margin: const EdgeInsets.only(
                              bottom: AppConstants.spacingLG,
                            ),
                            padding: const EdgeInsets.all(
                              AppConstants.spacingMD,
                            ),
                            decoration: BoxDecoration(
                              color: (isDark ? AppColors.darkElevated : AppColors.sage)
                                  .withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(
                                AppConstants.cardRadiusSmall,
                              ),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.luminousMauve
                                    : AppColors.sage,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      color: isDark
                                          ? AppColors.luminousMauve
                                          : AppColors.mauve,
                                      size: 20,
                                    ),
                                    const SizedBox(width: AppConstants.spacingSM),
                                    Text(
                                      'Activity Completed!',
                                      style: AppTypography.titleSmall.copyWith(
                                        color: primaryTextColor,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppConstants.spacingXS),
                                Text(
                                  'Choose privately who you enjoyed meeting and would like to reconnect with.',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: mutedTextColor,
                                  ),
                                ),
                                const SizedBox(height: AppConstants.spacingMD),
                                PrimaryButton(
                                  label: 'Select People to Reconnect',
                                  height: 40,
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            PostExperienceChoiceScreen(
                                              experience: exp,
                                            ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
        ],
      ),
    );
  }
}
