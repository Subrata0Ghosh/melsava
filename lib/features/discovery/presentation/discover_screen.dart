import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/services/location_providers.dart';
import '../../../shared/models/experience_model.dart';
import '../../../shared/widgets/activity_radar_map_card.dart';
import '../../../shared/widgets/app_smart_image.dart';
import '../../../shared/widgets/botanical_leaf_decoration.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/experience_card.dart';
import '../../../shared/widgets/explore_all_intents_sheet.dart';
import '../../../shared/widgets/explore_all_categories_sheet.dart';
import '../../../shared/widgets/intent_3d_cards_section.dart';
import '../../../shared/widgets/location_venue_picker_sheet.dart';
import '../../../shared/widgets/offline_notice_bar.dart';
import '../../../shared/widgets/popular_categories_row.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/stacked_trending_cards_deck.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../experiences/data/experiences_repository.dart';
import '../../experiences/presentation/experience_detail_sheet.dart';
import '../../experiences/presentation/experience_hub_sheet.dart';
import '../../experiences/presentation/join_experience_sheet.dart';
import '../../experiences/presentation/post_experience_choice_screen.dart';

/// Screen 1: Discover Screen
///
/// High-fidelity experience discovery powered by real Supabase data:
/// - Friendly user greeting & unread notification counter
/// - Worldwide location pill & live search
/// - Real 3D Stacked Trending Cards Deck
/// - Explore by Intent pastel cards
/// - Real published experiences with live spots, venue/online details
/// - Interactive Live Area Radar mode
/// - Loading, error with retry, and empty states
class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String? _selectedIntent;
  String _selectedCategory = 'All';
  int _viewMode = 0; // 0: Curated Feed, 1: Live Radar

  final List<String> _defaultCategories = [
    'All',
    'Outdoors',
    'Social',
    'Food & Drink',
    'Sports',
    'Wellness',
    'Arts & Culture',
  ];

  @override
  void dispose() {
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

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _selectedCategory = 'All';
      _selectedIntent = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);
    final userLoc = ref.watch(userLocationProvider);

    final publishedAsync = ref.watch(publishedExperiencesProvider);
    final categoriesAsync = ref.watch(activityCategoriesProvider);

    final allExperiences =
        publishedAsync.valueOrNull ?? const <ExperienceModel>[];
    final categories = categoriesAsync.valueOrNull ?? _defaultCategories;

    // Filter experiences based on active search, category, and intent
    final filteredExperiences = allExperiences.where((e) {
      final matchesQuery =
          _searchQuery.isEmpty ||
          e.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.venueName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.city.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCategory =
          _selectedCategory == 'All' ||
          e.categoryName.toLowerCase().contains(
            _selectedCategory.toLowerCase(),
          );

      final matchesIntent =
          _selectedIntent == null ||
          (_selectedIntent == 'Friendship' &&
              (e.categoryName.toLowerCase().contains('social') ||
                  e.categoryName.toLowerCase().contains('outdoor'))) ||
          (_selectedIntent == 'Activity Partner' &&
              (e.categoryName.toLowerCase().contains('sport') ||
                  e.categoryName.toLowerCase().contains('outdoor') ||
                  e.categoryName.toLowerCase().contains('art'))) ||
          (_selectedIntent == 'Dating' &&
              (e.categoryName.toLowerCase().contains('social') ||
                  e.categoryName.toLowerCase().contains('food'))) ||
          (_selectedIntent == 'Serious Relationship' &&
              (e.categoryName.toLowerCase().contains('social') ||
                  e.categoryName.toLowerCase().contains('wellness')));

      return matchesQuery && matchesCategory && matchesIntent;
    }).toList();

    final heroExperiences = filteredExperiences.take(5).toList();
    final primaryTextColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.deepPlum;
    final mutedTextColor = isDark
        ? AppColors.darkMutedText
        : AppColors.mutedText;

    final displayName = user?.displayName ?? 'Friend';
    final isOffline = ref.watch(isOfflineExperiencesProvider);
    final lastSyncedAt = ref.watch(experiencesLastSyncedProvider);
    final featuredExp =
        filteredExperiences.firstOrNull ?? allExperiences.firstOrNull;
    final dateFormat = DateFormat('EEE, MMM d • h:mm a');

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF1D142E)
          : const Color(0xFFFFFDF9),
      body: AmbientNatureBackdrop(
        showTopLeaf: true,
        showBottomLeaf: true,
        leafStyle: BotanicalLeafStyle.eucalyptus,
        leafColors: BotanicalLeafDecoration.mintDew,
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: isDark ? AppColors.brightViolet : AppColors.primaryPurple,
            backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
            onRefresh: () async {
              HapticFeedback.lightImpact();
              ref.invalidate(publishedExperiencesProvider);
              ref.invalidate(activityCategoriesProvider);
              await ref.read(publishedExperiencesProvider.future);
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: ClampingScrollPhysics(),
              ),
              slivers: [
                if (isOffline)
                  SliverToBoxAdapter(
                    child: OfflineNoticeBar(
                      lastSyncedAt: lastSyncedAt,
                      onRetry: () {
                        ref.invalidate(publishedExperiencesProvider);
                        ref.invalidate(activityCategoriesProvider);
                      },
                    ),
                  ),
                // ── Top Header: User Greeting, Notifications & Location ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Greeting text
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text.rich(
                                TextSpan(
                                  text: 'Hello, $displayName ',
                                  style: AppTypography.titleLarge.copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: displayName.length > 18
                                        ? 15.5
                                        : (displayName.length > 12 ? 17 : 20),
                                    color: primaryTextColor,
                                    height: 1.15,
                                  ),
                                  children: const [
                                    TextSpan(
                                      text: '👋',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontStyle: FontStyle.normal,
                                      ),
                                    ),
                                  ],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Let\'s explore experiences!',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodySmall.copyWith(
                                  color: mutedTextColor,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Worldwide Location Button
                        GestureDetector(
                          onTap: () => LocationVenuePickerSheet.show(context),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkElevated
                                  : AppColors.white,
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
                        const SizedBox(width: 8),

                        // Notification Bell
                        GestureDetector(
                          onTap: () => context.push('/inbox'),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.darkElevated
                                      : AppColors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color:
                                        (isDark
                                                ? const Color(0xFFF59E0B)
                                                : const Color(0xFFD97706))
                                            .withValues(alpha: 0.32),
                                    width: 1.0,
                                  ),
                                ),
                                child: Icon(
                                  Icons.notifications_none_rounded,
                                  size: 20,
                                  color: primaryTextColor,
                                ),
                              ),
                              Positioned(
                                top: 2,
                                right: 2,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: AppColors.error,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFFFFE082),
                                      width: 1.4,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // User Avatar
                        GestureDetector(
                          onTap: () => context.go('/profile'),
                          child: Container(
                            width: 39,
                            height: 39,
                            padding: const EdgeInsets.all(1.8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFFFFD700),
                                  Color(0xFFA855F7),
                                  Color(0xFFF59E0B),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFF59E0B,
                                  ).withValues(alpha: 0.35),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark
                                    ? AppColors.darkSurface
                                    : Colors.white,
                              ),
                              padding: const EdgeInsets.all(1.0),
                              child: ClipOval(
                                child: AppSmartImage(
                                  imagePath: user?.avatarUrl,
                                  isAvatar: true,
                                  nameHint: user?.displayName,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Search Bar ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkElevated
                            : AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.divider,
                          width: 0.9,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black26
                                : Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        style: AppTypography.bodyMedium.copyWith(
                          color: primaryTextColor,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search experiences, venues...',
                          hintStyle: AppTypography.bodyMedium.copyWith(
                            color: mutedTextColor,
                            fontSize: 13.5,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: isDark
                                ? const Color(0xFFC084FC)
                                : const Color(0xFF8B5CF6),
                            size: 21,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear_rounded,
                                    size: 18,
                                  ),
                                  color: mutedTextColor,
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : Container(
                                  margin: const EdgeInsets.all(8),
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color:
                                        (isDark
                                                ? const Color(0xFFF59E0B)
                                                : const Color(0xFFEAB308))
                                            .withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.tune_rounded,
                                    color: isDark
                                        ? const Color(0xFFFBBF24)
                                        : const Color(0xFFD97706),
                                    size: 16,
                                  ),
                                ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          filled: false,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Loading & Error State Banners ──
                if (publishedAsync.isLoading && allExperiences.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  )
                else if (publishedAsync.hasError && allExperiences.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurface
                              : const Color(0xFFFFF1F2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(
                              0xFFEF4444,
                            ).withValues(alpha: 0.4),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.wifi_off_rounded,
                              size: 32,
                              color: Color(0xFFEF4444),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Unable to load experiences',
                              style: AppTypography.titleSmall.copyWith(
                                color: primaryTextColor,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Please check your network connection and try again.',
                              textAlign: TextAlign.center,
                              style: AppTypography.bodySmall.copyWith(
                                color: mutedTextColor,
                              ),
                            ),
                            const SizedBox(height: 12),
                            PrimaryButton(
                              label: 'Retry',
                              height: 38,
                              backgroundColor: isDark
                                  ? AppColors.brightViolet
                                  : AppColors.primaryPurple,
                              onPressed: () =>
                                  ref.invalidate(publishedExperiencesProvider),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else ...[
                  // ── 3D Stacked Trending Cards Deck ──
                  if (heroExperiences.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: StackedTrendingCardsDeck(
                          experiences: heroExperiences,
                          onCardTap: (exp) {
                            ExperienceDetailSheet.show(
                              context,
                              experience: exp,
                            );
                          },
                          onJoinTap: (exp) => _openJoinFlow(exp),
                        ),
                      ),
                    ),

                  // ── Popular Categories ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: PopularCategoriesRow(
                        selectedCategory: _selectedCategory,
                        onCategorySelected: (cat) {
                          setState(() => _selectedCategory = cat);
                        },
                        onSeeAllTap: () {
                          ExploreAllCategoriesSheet.show(
                            context,
                            selectedCategory: _selectedCategory,
                            onSelectCategory: (cat) {
                              setState(() => _selectedCategory = cat);
                            },
                          );
                        },
                      ),
                    ),
                  ),

                  // ── New in Your Area Section (Cold-Start Fairness) ──
                  ref
                      .watch(newInYourAreaExperiencesProvider)
                      .when(
                        data: (newCircles) {
                          if (newCircles.isEmpty) {
                            return const SliverToBoxAdapter(
                              child: SizedBox.shrink(),
                            );
                          }
                          return SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 7,
                                                    vertical: 3,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(
                                                  0xFF10B981,
                                                ).withValues(alpha: 0.15),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: const Text(
                                                'NEW',
                                                style: TextStyle(
                                                  color: Color(0xFF10B981),
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 10,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'New in your area',
                                              style: AppTypography.titleMedium
                                                  .copyWith(
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 16.5,
                                                    color: primaryTextColor,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          user?.city != null &&
                                                  user!.city!.isNotEmpty
                                              ? user.city!
                                              : 'Nearby',
                                          style: AppTypography.labelSmall
                                              .copyWith(
                                                color: mutedTextColor,
                                                fontSize: 12,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    height: 165,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                      ),
                                      itemCount: newCircles.length,
                                      separatorBuilder: (_, _) =>
                                          const SizedBox(width: 14),
                                      itemBuilder: (ctx, idx) {
                                        final circle = newCircles[idx];
                                        return _buildNewCircleCard(
                                          circle,
                                          isDark: isDark,
                                          borderColor: isDark
                                              ? AppColors.darkBorder
                                              : const Color(0xFFEDE9FE),
                                          primaryTextColor: primaryTextColor,
                                          mutedTextColor: mutedTextColor,
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        loading: () =>
                            const SliverToBoxAdapter(child: SizedBox.shrink()),
                        error: (_, _) =>
                            const SliverToBoxAdapter(child: SizedBox.shrink()),
                      ),

                  // ── Featured Upcoming Experience Preview ──
                  if (featuredExp != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Upcoming Experiences',
                                  style: AppTypography.titleMedium.copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16.5,
                                    color: primaryTextColor,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => context.go('/experiences'),
                                  child: Text(
                                    'See all →',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: isDark
                                          ? AppColors.brightViolet
                                          : AppColors.primaryPurple,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: () {
                                ExperienceDetailSheet.show(
                                  context,
                                  experience: featuredExp,
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.darkElevated
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isDark
                                        ? AppColors.darkBorder
                                        : const Color(0xFFEDE9FE),
                                    width: 0.9,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: isDark ? 0.25 : 0.035,
                                      ),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: SizedBox(
                                        width: 66,
                                        height: 66,
                                        child: AppSmartImage(
                                          imagePath: featuredExp.coverImageUrl,
                                          categoryHint:
                                              '${featuredExp.title} ${featuredExp.categoryName}',
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            featuredExp.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTypography.titleSmall
                                                .copyWith(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 14.5,
                                                  color: primaryTextColor,
                                                ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            dateFormat.format(
                                              featuredExp.startsAt,
                                            ),
                                            style: AppTypography.bodySmall
                                                .copyWith(
                                                  color: mutedTextColor,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            featuredExp.isOnline
                                                ? 'Online Experience'
                                                : (featuredExp
                                                          .venueName
                                                          .isNotEmpty
                                                      ? featuredExp.venueName
                                                      : featuredExp.city),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTypography.bodySmall
                                                .copyWith(
                                                  color: isDark
                                                      ? AppColors.brightViolet
                                                      : AppColors.primaryPurple,
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            (isDark
                                                    ? AppColors.brightViolet
                                                    : AppColors.primaryPurple)
                                                .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${featuredExp.currentParticipants} Joined',
                                        style: TextStyle(
                                          color: isDark
                                              ? AppColors.brightViolet
                                              : AppColors.primaryPurple,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // ── Section: Explore by Intent ──
                  SliverToBoxAdapter(
                    child: Intent3DCardsSection(
                      selectedIntent: _selectedIntent,
                      onIntentSelected: (intent) {
                        setState(() => _selectedIntent = intent);
                      },
                      onSeeAllTap: () {
                        ExploreAllIntentsSheet.show(
                          context,
                          currentIntent: _selectedIntent,
                          onSelectIntent: (intent) {
                            setState(() => _selectedIntent = intent);
                          },
                        );
                      },
                    ),
                  ),

                  // ── Section: Experiences Header & Radar Toggle ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'All Experiences',
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 16.5,
                              color: primaryTextColor,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(
                                () => _viewMode = _viewMode == 0 ? 1 : 0,
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _viewMode == 1
                                    ? (isDark
                                          ? AppColors.brightViolet
                                          : AppColors.primaryPurple)
                                    : (isDark
                                          ? AppColors.darkElevated
                                          : AppColors.creamElevated),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _viewMode == 1
                                        ? Icons.map_rounded
                                        : Icons.radar_rounded,
                                    size: 13,
                                    color: _viewMode == 1
                                        ? Colors.white
                                        : mutedTextColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _viewMode == 1
                                        ? 'Show Cards'
                                        : 'Live Radar',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: _viewMode == 1
                                          ? Colors.white
                                          : mutedTextColor,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Category Chips (Horizontal Scroll)
                  if (_viewMode == 0)
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 38,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
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
                                  vertical: 8,
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
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                  // ── Experiences List or Live Radar ──
                  if (_viewMode == 1)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                        child: ActivityRadarMapCard(
                          location: userLoc,
                          onVenueSelected: (venue) {
                            final match = allExperiences.firstWhere(
                              (e) => e.venueName.toLowerCase().contains(
                                venue.name.toLowerCase(),
                              ),
                              orElse: () => allExperiences.first,
                            );
                            ExperienceDetailSheet.show(
                              context,
                              experience: match,
                            );
                          },
                        ),
                      ),
                    )
                  else if (filteredExperiences.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 30, 20, 30),
                        child: EmptyStateWidget(
                          icon: Icons.explore_off_outlined,
                          title: 'No experiences found yet.',
                          message:
                              'Try another category or clear filters to see more upcoming activities.',
                          actionLabel: 'Clear Filters',
                          onActionPressed: _clearFilters,
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final exp = filteredExperiences[index];
                          return ExperienceCard(
                            experience: exp,
                            onTap: () => ExperienceDetailSheet.show(
                              context,
                              experience: exp,
                            ),
                            onJoinTap: () => _openJoinFlow(exp),
                          );
                        }, childCount: filteredExperiences.length),
                      ),
                    ),
                ],

                // ── 120dp bottom clearance for floating navbar ──
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNewCircleCard(
    ExperienceModel exp, {
    required bool isDark,
    required Color borderColor,
    required Color primaryTextColor,
    required Color mutedTextColor,
  }) {
    return GestureDetector(
      onTap: () => ExperienceDetailSheet.show(context, experience: exp),
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkElevated : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: 0.9),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      exp.categoryIcon,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exp.categoryName,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryPurple,
                        ),
                      ),
                      Text(
                        exp.area?.isNotEmpty == true
                            ? exp.area!
                            : (exp.city.isNotEmpty ? exp.city : 'Local'),
                        style: TextStyle(fontSize: 11, color: mutedTextColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (exp.isNewHost)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEC4899).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'New Host',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFEC4899),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              exp.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.titleSmall.copyWith(
                color: primaryTextColor,
                fontWeight: FontWeight.w800,
                fontSize: 13,
                height: 1.25,
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  exp.spotsLeft > 0 ? '${exp.spotsLeft} spots' : 'Waitlist',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: exp.spotsLeft > 0
                        ? const Color(0xFF10B981)
                        : AppColors.softCoral,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'View →',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
