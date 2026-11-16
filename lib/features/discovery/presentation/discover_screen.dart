import 'package:cached_network_image/cached_network_image.dart';
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
import '../../../shared/widgets/experience_card.dart';
import '../../../shared/widgets/location_venue_picker_sheet.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../experiences/data/experiences_repository.dart';
import '../../experiences/presentation/experience_detail_sheet.dart';
import '../../experiences/presentation/join_experience_sheet.dart';

/// Screen 1: Discover Screen
///
/// High-fidelity experience discovery matching the approved MELSAVA design system:
/// - Friendly user greeting & unread notification counter
/// - Worldwide location pill & live search
/// - Featured Experience Hero Carousel with slide indicator (1/3) & Join Now CTA
/// - Explore by Intent pastel cards (Friendship, Activity Partner, Dating, Serious Relationship)
/// - Popular Experiences with Trending badges & direct Join actions
/// - Interactive Live Area Radar mode
class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String? _selectedIntent; // 'Friendship', 'Activity Partner', 'Dating', 'Serious Relationship'
  String _selectedCategory = 'All';
  int _viewMode = 0; // 0: Curated Feed, 1: Live Radar

  final List<Map<String, dynamic>> _intents = [
    {
      'name': 'Friendship',
      'icon': Icons.people_alt_rounded,
      'bg': AppColors.intentFriendshipBg,
      'color': AppColors.intentFriendshipText,
    },
    {
      'name': 'Activity Partner',
      'icon': Icons.extension_rounded,
      'bg': AppColors.intentActivityBg,
      'color': AppColors.intentActivityText,
    },
    {
      'name': 'Dating',
      'icon': Icons.bolt_rounded,
      'bg': AppColors.intentDatingBg,
      'color': AppColors.intentDatingText,
    },
    {
      'name': 'Serious Relationship',
      'icon': Icons.workspace_premium_rounded,
      'bg': AppColors.intentRelationshipBg,
      'color': AppColors.intentRelationshipText,
    },
  ];

  final List<String> _categories = [
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
    _pageController.dispose();
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

    // Filter experiences
    final filteredExperiences = allExperiences.where((e) {
      final matchesQuery = _searchQuery.isEmpty ||
          e.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.venueName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.city.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCategory = _selectedCategory == 'All' ||
          e.categoryName.toLowerCase().contains(_selectedCategory.toLowerCase());

      final matchesIntent = _selectedIntent == null ||
          (_selectedIntent == 'Friendship' && (e.categoryName == 'Social' || e.categoryName == 'Outdoors')) ||
          (_selectedIntent == 'Activity Partner' && (e.categoryName == 'Sports' || e.categoryName == 'Outdoors' || e.categoryName == 'Arts & Culture')) ||
          (_selectedIntent == 'Dating' && (e.categoryName == 'Social' || e.categoryName == 'Food & Drink')) ||
          (_selectedIntent == 'Serious Relationship' && (e.categoryName == 'Social' || e.categoryName == 'Wellness'));

      return matchesQuery && matchesCategory && matchesIntent;
    }).toList();

    final heroExperiences = allExperiences.take(3).toList();
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.deepPlum;
    final mutedTextColor = isDark ? AppColors.darkMutedText : AppColors.mutedText;

    final displayName = user?.displayName?.split(' ').first ?? 'Sneha';

    return Scaffold(
      backgroundColor: isDark ? AppColors.obsidian : AppColors.warmIvory,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
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
                        children: [
                          Row(
                            children: [
                              Text(
                                'Hello, $displayName',
                                style: AppTypography.titleLarge.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 20,
                                  color: primaryTextColor,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text('👋', style: TextStyle(fontSize: 18)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Let\'s explore experiences!',
                            style: AppTypography.bodySmall.copyWith(
                              color: mutedTextColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Worldwide Location Pill
                    GestureDetector(
                      onTap: () => LocationVenuePickerSheet.show(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkElevated : AppColors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.divider,
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 14,
                              color: isDark ? AppColors.luminousMauve : AppColors.mauve,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              userLoc.city,
                              style: AppTypography.labelSmall.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 11.5,
                                color: primaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Notification Bell with Unread Dot (routes to Inbox)
                    GestureDetector(
                      onTap: () => context.push('/inbox'),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkElevated : AppColors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? AppColors.darkBorder : AppColors.divider,
                                width: 0.8,
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
                              width: 9,
                              height: 9,
                              decoration: const BoxDecoration(
                                color: AppColors.error,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // User Avatar with Online Dot
                    GestureDetector(
                      onTap: () => context.go('/profile'),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? AppColors.brightViolet : AppColors.primaryPurple,
                            width: 1.8,
                          ),
                        ),
                        child: ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: user?.avatarUrl ??
                                'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80',
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(color: AppColors.mauve),
                            errorWidget: (context, url, error) => const Icon(Icons.person, size: 20),
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
                    color: isDark ? AppColors.darkElevated : AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.divider,
                      width: 0.9,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: AppTypography.bodyMedium.copyWith(color: primaryTextColor),
                    decoration: InputDecoration(
                      hintText: 'Search activities...',
                      hintStyle: AppTypography.bodyMedium.copyWith(color: mutedTextColor, fontSize: 13.5),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: mutedTextColor,
                        size: 21,
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
                          : Icon(
                              Icons.tune_rounded,
                              color: mutedTextColor,
                              size: 19,
                            ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
            ),

            // ── Featured Experience Carousel (1/3 indicator, Join Now ->) ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: SizedBox(
                  height: 200,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: heroExperiences.length,
                    itemBuilder: (context, index) {
                      final exp = heroExperiences[index];
                      return _buildFeaturedHeroCard(
                        context,
                        exp,
                        index + 1,
                        heroExperiences.length,
                        isDark,
                        primaryTextColor,
                      );
                    },
                  ),
                ),
              ),
            ),

            // ── Section: Explore by Intent ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Explore by Intent',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 16.5,
                        color: primaryTextColor,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() => _selectedIntent = null);
                      },
                      child: Text(
                        _selectedIntent != null ? 'Clear filter' : 'See all →',
                        style: AppTypography.labelSmall.copyWith(
                          color: isDark ? AppColors.brightViolet : AppColors.primaryPurple,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Intent Cards Grid
            SliverToBoxAdapter(
              child: SizedBox(
                height: 94,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _intents.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final item = _intents[index];
                    final name = item['name'] as String;
                    final isSelected = _selectedIntent == name;

                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _selectedIntent = isSelected ? null : name;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 82,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkElevated : item['bg'] as Color,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected
                                ? (item['color'] as Color)
                                : (isDark ? AppColors.darkBorder : Colors.transparent),
                            width: isSelected ? 2.0 : 1.0,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: (item['color'] as Color).withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              item['icon'] as IconData,
                              size: 26,
                              color: item['color'] as Color,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              name,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : (item['color'] as Color),
                                height: 1.15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // ── Section: Popular Experiences ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Popular Experiences',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 16.5,
                        color: primaryTextColor,
                      ),
                    ),
                    // Quick Toggle: Feed vs Live Area Radar
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _viewMode = _viewMode == 0 ? 1 : 0);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _viewMode == 1
                              ? (isDark ? AppColors.brightViolet : AppColors.primaryPurple)
                              : (isDark ? AppColors.darkElevated : AppColors.creamElevated),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _viewMode == 1 ? Icons.map_rounded : Icons.radar_rounded,
                              size: 13,
                              color: _viewMode == 1 ? Colors.white : mutedTextColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _viewMode == 1 ? 'Show Cards' : 'Live Radar',
                              style: AppTypography.labelSmall.copyWith(
                                color: _viewMode == 1 ? Colors.white : mutedTextColor,
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
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                          child: Text(
                            cat,
                            style: AppTypography.labelSmall.copyWith(
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? AppColors.darkTextPrimary : AppColors.deepPlum),
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
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
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
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

            // ── CRITICAL: 120dp bottom clearance so no button is ever overlapped by bottom nav ──
            const SliverToBoxAdapter(
              child: SizedBox(height: 120),
            ),
          ],
        ),
      ),
    );
  }

  // ── Featured Hero Card (1/3 indicator, Join Now ->) ──
  Widget _buildFeaturedHeroCard(
    BuildContext context,
    ExperienceModel exp,
    int pageNum,
    int totalPages,
    bool isDark,
    Color primaryTextColor,
  ) {
    final dateFormat = DateFormat('EEE, MMM d · h:mm a');

    return GestureDetector(
      onTap: () => ExperienceDetailSheet.show(
        context,
        experience: exp,
        onToggleJoin: () => _openJoinFlow(exp),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black45 : Colors.black.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Hero Image
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
                      Colors.black.withValues(alpha: 0.25),
                      Colors.black.withValues(alpha: 0.45),
                      Colors.black.withValues(alpha: 0.88),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),

              // Top row: Category tag & 1/3 indicator
              Positioned(
                top: 14,
                left: 14,
                right: 14,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24, width: 0.8),
                      ),
                      child: Row(
                        children: [
                          const Text('🔥', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Text(
                            'Trending',
                            style: AppTypography.labelSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 1/3 indicator pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24, width: 0.8),
                      ),
                      child: Text(
                        '$pageNum/$totalPages',
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

              // Bottom Info: Title, Date, Venue, Join Now ->
              Positioned(
                bottom: 14,
                left: 14,
                right: 14,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            exp.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.titleLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 12, color: Colors.white70),
                              const SizedBox(width: 4),
                              Text(
                                dateFormat.format(exp.startsAt),
                                style: AppTypography.labelSmall.copyWith(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded, size: 12, color: Colors.white70),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  exp.venueName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.labelSmall.copyWith(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Join Now -> pill button
                    GestureDetector(
                      onTap: () => _openJoinFlow(exp),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: AppColors.purpleGradient,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryPurple.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          exp.hasJoined ? 'Joined ✓' : 'Join Now →',
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 11.5,
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
}
