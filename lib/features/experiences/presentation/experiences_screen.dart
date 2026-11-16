import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/services/location_providers.dart';
import '../../../shared/models/experience_model.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/experience_card.dart';
import '../../../shared/widgets/location_venue_picker_sheet.dart';
import '../../../shared/widgets/primary_button.dart';
import '../data/experiences_repository.dart';
import 'experience_detail_sheet.dart';
import 'experience_hub_sheet.dart';
import 'join_experience_sheet.dart';
import 'post_experience_choice_screen.dart';

/// Screen 4: Experiences Screen
///
/// High-fidelity layout matching Image 8 Screen 4:
/// - Top Search & Location bar
/// - Horizontal filter pills (All, Sports, Arts & Culture, Food, Outdoors, Wellness)
/// - Vertical cards with "Join" pill button and Trending badges
/// - My Joined / Completed Experiences tab with direct Hub & Choice flow access
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
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Sports',
    'Arts & Culture',
    'Food',
    'Outdoors',
    'Wellness',
  ];

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
    final userLoc = ref.watch(userLocationProvider);
    final allExperiences = ref.watch(experiencesListProvider);
    final myExperiences = allExperiences
        .where((e) => e.hasJoined || e.isCompleted)
        .toList();

    final filteredAll = allExperiences.where((e) {
      final matchesQuery = _searchQuery.isEmpty ||
          e.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.categoryName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.venueName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.city.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCategory = _selectedCategory == 'All' ||
          e.categoryName.toLowerCase().contains(_selectedCategory.toLowerCase());

      return matchesQuery && matchesCategory;
    }).toList();

    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.deepPlum;
    final mutedTextColor = isDark ? AppColors.darkMutedText : AppColors.mutedText;

    return Scaffold(
      backgroundColor: isDark ? AppColors.obsidian : AppColors.warmIvory,
      appBar: AppBar(
        title: Text(
          'Experiences',
          style: AppTypography.titleLarge.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 22,
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                      color: isDark ? AppColors.brightViolet : AppColors.primaryPurple,
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
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: isDark ? AppColors.brightViolet : AppColors.primaryPurple,
          indicatorWeight: 3,
          labelColor: isDark ? AppColors.brightViolet : AppColors.primaryPurple,
          unselectedLabelColor: mutedTextColor,
          labelStyle: AppTypography.labelLarge.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: 'Explore All'),
            Tab(text: 'My RSVPs'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Tab 1: Explore All ──
          Column(
            children: [
              // Search Input
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkElevated : AppColors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.divider,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: TextStyle(color: primaryTextColor, fontSize: 13.5),
                    decoration: InputDecoration(
                      hintText: 'Search experiences, venues...',
                      hintStyle: TextStyle(color: mutedTextColor, fontSize: 13),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: isDark ? AppColors.brightViolet : AppColors.primaryPurple,
                        size: 20,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),

              // Horizontal Category Filter Pills (Image 8 Screen 4)
              SizedBox(
                height: 36,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _categories.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = _selectedCategory == cat;

                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedCategory = cat);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          gradient: isSelected ? AppColors.purpleGradient : null,
                          color: isSelected
                              ? null
                              : (isDark ? AppColors.darkElevated : AppColors.white),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : (isDark ? AppColors.darkBorder : AppColors.divider),
                            width: 0.9,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              cat,
                              style: AppTypography.labelSmall.copyWith(
                                color: isSelected
                                    ? Colors.white
                                    : (isDark ? AppColors.darkTextPrimary : AppColors.deepPlum),
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                fontSize: 11.5,
                              ),
                            ),
                            if (isSelected && cat == 'All') ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward_rounded, size: 12, color: Colors.white),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),

              // Experiences List
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
                          left: 18,
                          right: 18,
                          bottom: 120, // Guaranteed 120dp clearance for floating navbar
                        ),
                        physics: const BouncingScrollPhysics(),
                        itemCount: filteredAll.length,
                        itemBuilder: (context, index) {
                          final exp = filteredAll[index];
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
                      ),
              ),
            ],
          ),

          // ── Tab 2: My RSVPs & Completed Experiences ──
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
                    left: 18,
                    right: 18,
                    top: 14,
                    bottom: 120, // Guaranteed 120dp clearance for floating navbar
                  ),
                  physics: const BouncingScrollPhysics(),
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
                            onToggleJoin: () => _openJoinFlow(exp),
                          ),
                          onJoinTap: () => _openJoinFlow(exp),
                        ),
                        if (!exp.isCompleted && exp.hasJoined) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurface : AppColors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? AppColors.darkBorder : AppColors.divider,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Live Experience Room Active',
                                        style: AppTypography.titleSmall.copyWith(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12.5,
                                          color: isDark ? AppColors.brightViolet : AppColors.primaryPurple,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'View attendees, break the ice, and share instant live reactions.',
                                        style: AppTypography.bodySmall.copyWith(
                                          color: mutedTextColor,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: () => ExperienceHubSheet.show(context, experience: exp),
                                  icon: const Icon(Icons.hub_rounded, size: 14),
                                  label: const Text('Open Hub', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDark ? AppColors.brightViolet : AppColors.primaryPurple,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (exp.isCompleted) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: (isDark ? AppColors.brightViolet : AppColors.primaryPurple)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: (isDark ? AppColors.brightViolet : AppColors.primaryPurple)
                                    .withValues(alpha: 0.35),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.celebration_rounded,
                                      size: 18,
                                      color: AppColors.softCoral,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Experience Complete!',
                                      style: AppTypography.titleSmall.copyWith(
                                        color: primaryTextColor,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Choose privately who you\'d like to reconnect with.',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: mutedTextColor,
                                    fontSize: 11.5,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: PrimaryButton(
                                    label: 'Make Reconnect Choices →',
                                    backgroundColor:
                                        isDark ? AppColors.brightViolet : AppColors.primaryPurple,
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => PostExperienceChoiceScreen(
                                            experience: exp,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
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
