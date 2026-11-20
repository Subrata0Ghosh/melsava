import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/models/experience_model.dart';
import '../../../shared/widgets/confirmation_dialog.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/experience_card.dart';
import '../../../shared/widgets/location_venue_picker_sheet.dart';
import '../../../shared/widgets/primary_button.dart';
import '../data/experiences_repository.dart';
import '../../auth/presentation/auth_providers.dart';
import 'experience_detail_sheet.dart';
import 'experience_hub_sheet.dart';
import 'host_attendance_sheet.dart';
import 'join_experience_sheet.dart';
import 'post_experience_choice_screen.dart';

/// Screen 4: Experiences & My Circles Screen
///
/// Features:
/// - Tab 1 ("Explore All"): Real published experiences with live search,
///   category filters, format filters (In-Person / Online), spots filter,
///   pull-to-refresh, loading/error/empty states.
/// - Tab 2 ("My Circles"): Real Supabase memberships organized into
///   Upcoming, Waitlisted, Attended, and Past with real cancellation & FIFO waitlist.
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
  ExperienceFormatFilter _selectedFormat = ExperienceFormatFilter.all;
  bool _onlyAvailablePlaces = false;

  // My Circles sub-filter: 0 = Upcoming, 1 = Waitlisted, 2 = Attended, 3 = Past
  int _selectedMyCircleTab = 0;

  final List<String> _defaultCategories = [
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

  Future<void> _openJoinFlow(ExperienceModel experience) async {
    if (experience.hasJoined) {
      ExperienceHubSheet.show(context, experience: experience);
      return;
    }
    if (experience.isAttended || experience.isCompleted) {
      PostExperienceChoiceScreen.show(context, experience);
      return;
    }
    if (experience.isWaitlisted) {
      ExperienceDetailSheet.show(context, experience: experience);
      return;
    }

    await JoinExperienceSheet.show(
      context,
      experience: experience,
      onConfirmJoin: () => ref
          .read(experienceActionControllerProvider)
          .joinExperience(experience.id),
    );
  }

  Future<void> _handleCancelMembership(ExperienceModel exp) async {
    final isWaitlist = exp.isWaitlisted;
    final confirmed = await ConfirmationDialog.show(
      context,
      title: isWaitlist ? 'Leave Waitlist?' : 'Cancel Your RSVP?',
      message: isWaitlist
          ? 'You will give up your spot on the waitlist for "${exp.title}".'
          : 'Are you sure you want to cancel your attendance? If there is a waitlist, the next person will automatically be invited.',
      confirmLabel: isWaitlist ? 'Leave' : 'Cancel RSVP',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      try {
        await ref
            .read(experienceActionControllerProvider)
            .cancelMembership(exp.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isWaitlist
                    ? 'You have left the waitlist.'
                    : 'Your RSVP was cancelled successfully.',
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          final msg = e.toString().replaceAll('Exception: ', '').trim();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                msg.isNotEmpty
                    ? msg
                    : 'We couldn\'t cancel your reservation. Please try again.',
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _selectedCategory = 'All';
      _selectedFormat = ExperienceFormatFilter.all;
      _onlyAvailablePlaces = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.deepPlum;
    final mutedTextColor = isDark
        ? AppColors.darkMutedText
        : AppColors.mutedText;

    final publishedAsync = ref.watch(publishedExperiencesProvider);
    final categoriesAsync = ref.watch(activityCategoriesProvider);
    final myAsync = ref.watch(myExperiencesProvider);

    final allPublished =
        publishedAsync.valueOrNull ?? const <ExperienceModel>[];
    final categories = categoriesAsync.valueOrNull ?? _defaultCategories;
    final myBundle = myAsync.valueOrNull ?? const MyExperiencesBundle();

    // Filter published experiences
    final filteredPublished = allPublished.where((e) {
      final matchesQuery =
          _searchQuery.isEmpty ||
          e.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.categoryName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.venueName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.city.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCategory =
          _selectedCategory == 'All' ||
          e.categoryName.toLowerCase().contains(
            _selectedCategory.toLowerCase(),
          );

      final matchesFormat = switch (_selectedFormat) {
        ExperienceFormatFilter.all => true,
        ExperienceFormatFilter.inPerson => !e.isOnline,
        ExperienceFormatFilter.online => e.isOnline,
      };

      final matchesAvailable = !_onlyAvailablePlaces || !e.isFull;

      return matchesQuery &&
          matchesCategory &&
          matchesFormat &&
          matchesAvailable;
    }).toList();

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
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => LocationVenuePickerSheet.show(context),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkElevated : AppColors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        (isDark
                                ? const Color(0xFFF59E0B)
                                : const Color(0xFFD97706))
                            .withValues(alpha: 0.38),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(
                        0xFFF59E0B,
                      ).withValues(alpha: isDark ? 0.12 : 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  size: 19,
                  color: Color(0xFFF59E0B),
                ),
              ),
            ),
          ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: isDark
              ? AppColors.brightViolet
              : AppColors.primaryPurple,
          indicatorWeight: 3,
          labelColor: isDark ? AppColors.brightViolet : AppColors.primaryPurple,
          unselectedLabelColor: mutedTextColor,
          labelStyle: AppTypography.labelLarge.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
          tabs: [
            const Tab(text: 'Explore All'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('My Circles'),
                  if (myBundle.totalActiveCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.brightViolet
                            : AppColors.primaryPurple,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${myBundle.totalActiveCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
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
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
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
                        color: isDark
                            ? AppColors.brightViolet
                            : AppColors.primaryPurple,
                        size: 20,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              color: mutedTextColor,
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      filled: false,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),

              // Horizontal Category Filter Pills
              SizedBox(
                height: 36,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  itemCount: categories.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final isSelected = _selectedCategory == cat;

                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedCategory = cat);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? AppColors.purpleGradient
                              : null,
                          color: isSelected
                              ? null
                              : (isDark
                                    ? AppColors.darkElevated
                                    : AppColors.white),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : (isDark
                                      ? AppColors.darkBorder
                                      : AppColors.divider),
                            width: 0.9,
                          ),
                        ),
                        child: Text(
                          cat,
                          style: AppTypography.labelSmall.copyWith(
                            color: isSelected
                                ? Colors.white
                                : (isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.deepPlum),
                            fontWeight: isSelected
                                ? FontWeight.w800
                                : FontWeight.w600,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Simple Secondary Filters: In-Person / Online / Has Spots
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildFilterChip(
                        label: 'All Formats',
                        isSelected:
                            _selectedFormat == ExperienceFormatFilter.all,
                        isDark: isDark,
                        onTap: () => setState(
                          () => _selectedFormat = ExperienceFormatFilter.all,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _buildFilterChip(
                        label: 'In-Person',
                        isSelected:
                            _selectedFormat == ExperienceFormatFilter.inPerson,
                        isDark: isDark,
                        onTap: () => setState(
                          () =>
                              _selectedFormat = ExperienceFormatFilter.inPerson,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _buildFilterChip(
                        label: 'Online',
                        isSelected:
                            _selectedFormat == ExperienceFormatFilter.online,
                        isDark: isDark,
                        onTap: () => setState(
                          () => _selectedFormat = ExperienceFormatFilter.online,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _buildFilterChip(
                        label: 'Spots Available',
                        isSelected: _onlyAvailablePlaces,
                        isDark: isDark,
                        onTap: () => setState(
                          () => _onlyAvailablePlaces = !_onlyAvailablePlaces,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Experiences List or States
              Expanded(
                child: RefreshIndicator(
                  color: isDark
                      ? AppColors.brightViolet
                      : AppColors.primaryPurple,
                  onRefresh: () async {
                    ref.invalidate(publishedExperiencesProvider);
                    ref.invalidate(activityCategoriesProvider);
                    await ref.read(publishedExperiencesProvider.future);
                  },
                  child: Builder(
                    builder: (context) {
                      if (publishedAsync.isLoading && allPublished.isEmpty) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (publishedAsync.hasError && allPublished.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  size: 40,
                                  color: Color(0xFFEF4444),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'We couldn\'t load experiences right now.',
                                  style: AppTypography.titleMedium.copyWith(
                                    color: primaryTextColor,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Please check your internet connection and try again.',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: mutedTextColor,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                PrimaryButton(
                                  label: 'Retry',
                                  height: 40,
                                  backgroundColor: isDark
                                      ? AppColors.brightViolet
                                      : AppColors.primaryPurple,
                                  onPressed: () => ref.invalidate(
                                    publishedExperiencesProvider,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      if (filteredPublished.isEmpty) {
                        return Center(
                          child: EmptyStateWidget(
                            icon: Icons.explore_off_outlined,
                            title: 'No experiences found yet.',
                            message:
                                'Try another category or check back soon for newly published experiences.',
                            actionLabel: 'Clear Filters',
                            onActionPressed: _clearFilters,
                          ),
                        );
                      }

                      return ListView.builder(
                        key: const PageStorageKey('explore_all_list'),
                        primary: false,
                        padding: const EdgeInsets.only(
                          left: 18,
                          right: 18,
                          bottom: 120,
                        ),
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        itemCount: filteredPublished.length,
                        itemBuilder: (context, index) {
                          final exp = filteredPublished[index];
                          return ExperienceCard(
                            experience: exp,
                            onTap: () => ExperienceDetailSheet.show(
                              context,
                              experience: exp,
                            ),
                            onJoinTap: () => _openJoinFlow(exp),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),

          // ── Tab 2: My Circles ──
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sub-Tabs: Upcoming, Waitlisted, Attended, Past
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildSubTabChip(
                        label: 'Upcoming (${myBundle.upcoming.length})',
                        isSelected: _selectedMyCircleTab == 0,
                        isDark: isDark,
                        onTap: () => setState(() => _selectedMyCircleTab = 0),
                      ),
                      const SizedBox(width: 8),
                      _buildSubTabChip(
                        label: 'Waitlist (${myBundle.waitlisted.length})',
                        isSelected: _selectedMyCircleTab == 1,
                        isDark: isDark,
                        onTap: () => setState(() => _selectedMyCircleTab = 1),
                      ),
                      const SizedBox(width: 8),
                      _buildSubTabChip(
                        label: 'Attended (${myBundle.attended.length})',
                        isSelected: _selectedMyCircleTab == 2,
                        isDark: isDark,
                        onTap: () => setState(() => _selectedMyCircleTab = 2),
                      ),
                      const SizedBox(width: 8),
                      _buildSubTabChip(
                        label: 'Past (${myBundle.past.length})',
                        isSelected: _selectedMyCircleTab == 3,
                        isDark: isDark,
                        onTap: () => setState(() => _selectedMyCircleTab = 3),
                      ),
                    ],
                  ),
                ),
              ),

              // Sub-Tab Content
              Expanded(
                child: RefreshIndicator(
                  color: isDark
                      ? AppColors.brightViolet
                      : AppColors.primaryPurple,
                  onRefresh: () async {
                    ref.invalidate(myExperiencesProvider);
                    await ref.read(myExperiencesProvider.future);
                  },
                  child: Builder(
                    builder: (context) {
                      if (myAsync.isLoading && !myAsync.hasValue) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (myAsync.hasError && !myAsync.hasValue) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  size: 40,
                                  color: Color(0xFFEF4444),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Unable to load your experiences.',
                                  style: AppTypography.titleMedium.copyWith(
                                    color: primaryTextColor,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                PrimaryButton(
                                  label: 'Retry',
                                  height: 40,
                                  backgroundColor: isDark
                                      ? AppColors.brightViolet
                                      : AppColors.primaryPurple,
                                  onPressed: () =>
                                      ref.invalidate(myExperiencesProvider),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final currentUser = ref.watch(currentUserProvider);
                      final activeList = switch (_selectedMyCircleTab) {
                        0 => myBundle.upcoming,
                        1 => myBundle.waitlisted,
                        2 => myBundle.attended,
                        3 => myBundle.past,
                        _ => myBundle.upcoming,
                      };

                      if (activeList.isEmpty) {
                        final emptyTitle = switch (_selectedMyCircleTab) {
                          0 => 'No upcoming experiences joined yet',
                          1 => 'No waitlisted experiences',
                          2 => 'No attended experiences yet',
                          3 => 'No past experiences yet',
                          _ => 'No experiences found',
                        };

                        final emptyMsg = switch (_selectedMyCircleTab) {
                          0 =>
                            'Your next great connection starts with your next experience. Browse activities to join your first micro-group!',
                          1 =>
                            'When a popular experience is full, joining its waitlist will queue you up for automatic spots if someone cancels.',
                          2 =>
                            'Once you attend a micro-group meetup, you\'ll find it here to make private reconnect choices.',
                          _ =>
                            'Experiences that have concluded will be archived here.',
                        };

                        return Center(
                          child: EmptyStateWidget(
                            icon: _selectedMyCircleTab == 1
                                ? Icons.hourglass_empty_rounded
                                : Icons.calendar_today_outlined,
                            title: emptyTitle,
                            message: emptyMsg,
                            actionLabel: _selectedMyCircleTab == 0
                                ? 'Discover Activities'
                                : null,
                            onActionPressed: () => _tabController.animateTo(0),
                          ),
                        );
                      }

                      return ListView.builder(
                        key: PageStorageKey(
                          'my_circles_list_$_selectedMyCircleTab',
                        ),
                        primary: false,
                        padding: const EdgeInsets.only(
                          left: 18,
                          right: 18,
                          top: 6,
                          bottom: 120,
                        ),
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        itemCount: activeList.length,
                        itemBuilder: (context, index) {
                          final exp = activeList[index];

                          Widget? cardFooter;
                          if (_selectedMyCircleTab == 0) {
                            cardFooter = Row(
                              children: [
                                TextButton(
                                  onPressed: () => _handleCancelMembership(exp),
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFFEF4444),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 6,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    'Cancel RSVP',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Flexible(
                                  child: Wrap(
                                    alignment: WrapAlignment.end,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      if (currentUser?.id == exp.hostId)
                                        ElevatedButton.icon(
                                          onPressed: () =>
                                              HostAttendanceSheet.show(
                                                context,
                                                experience: exp,
                                              ),
                                          icon: const Icon(
                                            Icons.fact_check_rounded,
                                            size: 14,
                                          ),
                                          label: const Text('Attendance'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF10B981,
                                            ),
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                      ElevatedButton.icon(
                                        onPressed: () =>
                                            ExperienceHubSheet.show(
                                              context,
                                              experience: exp,
                                            ),
                                        icon: const Icon(
                                          Icons.hub_rounded,
                                          size: 15,
                                        ),
                                        label: const Text('Open Hub'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isDark
                                              ? AppColors.brightViolet
                                              : AppColors.primaryPurple,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8.5,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          } else if (_selectedMyCircleTab == 1) {
                            cardFooter = Row(
                              children: [
                                const Icon(
                                  Icons.hourglass_top_rounded,
                                  size: 16,
                                  color: Color(0xFF8B5CF6),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Waiting for open spot',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: mutedTextColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => _handleCancelMembership(exp),
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFFEF4444),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 6,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    'Leave Waitlist',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          } else if (_selectedMyCircleTab == 2 ||
                              exp.isCompleted) {
                            cardFooter = Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.celebration_rounded,
                                      size: 17,
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
                                const SizedBox(height: 3),
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
                                    backgroundColor: isDark
                                        ? AppColors.brightViolet
                                        : AppColors.primaryPurple,
                                    onPressed: () {
                                      PostExperienceChoiceScreen.show(
                                        context,
                                        exp,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            );
                          }

                          return ExperienceCard(
                            experience: exp,
                            onTap: () => ExperienceDetailSheet.show(
                              context,
                              experience: exp,
                            ),
                            onJoinTap: () => ExperienceDetailSheet.show(
                              context,
                              experience: exp,
                            ),
                            footer: cardFooter,
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                    ? AppColors.brightViolet.withValues(alpha: 0.22)
                    : const Color(0xFFEDE9FE))
              : (isDark ? AppColors.darkElevated : AppColors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? (isDark ? AppColors.brightViolet : AppColors.primaryPurple)
                : (isDark ? AppColors.darkBorder : AppColors.divider),
            width: 0.9,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? (isDark ? AppColors.brightViolet : AppColors.primaryPurple)
                : (isDark ? AppColors.darkMutedText : AppColors.mutedText),
          ),
        ),
      ),
    );
  }

  Widget _buildSubTabChip({
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.purpleGradient : null,
          color: isSelected
              ? null
              : (isDark ? AppColors.darkElevated : AppColors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isDark ? AppColors.darkBorder : AppColors.divider),
            width: 0.9,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isSelected
                ? Colors.white
                : (isDark ? AppColors.darkTextPrimary : AppColors.deepPlum),
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
