import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/experience_card.dart';
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
    final allExperiences = ref.watch(experiencesListProvider);
    final myExperiences = allExperiences
        .where((e) => e.hasJoined || e.isCompleted)
        .toList();

    final filteredAll = _searchQuery.isEmpty
        ? allExperiences
        : allExperiences
              .where(
                (e) =>
                    e.title.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    e.categoryName.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ),
              )
              .toList();

    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      appBar: AppBar(
        title: Text(
          'Experiences',
          style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.deepPlum,
          labelColor: AppColors.deepPlum,
          unselectedLabelColor: AppColors.mutedText,
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
                  style: AppTypography.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'Search experiences, categories, or places...',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.mauve,
                    ),
                    filled: true,
                    fillColor: AppColors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppConstants.buttonRadiusLarge,
                      ),
                      borderSide: const BorderSide(color: AppColors.divider),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.spacingLG,
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
                  padding: const EdgeInsets.all(AppConstants.spacingLG),
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
                              color: AppColors.sage.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(
                                AppConstants.cardRadiusSmall,
                              ),
                              border: Border.all(color: AppColors.sage),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle_outline,
                                      color: AppColors.mauve,
                                      size: 20,
                                    ),
                                    const SizedBox(
                                      width: AppConstants.spacingSM,
                                    ),
                                    Text(
                                      'Activity Completed!',
                                      style: AppTypography.titleSmall.copyWith(
                                        color: AppColors.deepPlum,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppConstants.spacingXS),
                                Text(
                                  'Choose privately who you enjoyed meeting and would like to reconnect with.',
                                  style: AppTypography.bodySmall,
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
