import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/services/location_providers.dart';
import '../../core/services/worldwide_location_service.dart';

/// Interactive modal sheet to search & select any city, neighborhood,
/// or specific meetup venue (cafe, restaurant, park, etc.) worldwide.
class LocationVenuePickerSheet extends ConsumerStatefulWidget {
  final bool selectVenueMode;
  final Function(MeetupVenue venue)? onVenueSelected;

  const LocationVenuePickerSheet({
    super.key,
    this.selectVenueMode = false,
    this.onVenueSelected,
  });

  static Future<void> show(
    BuildContext context, {
    bool selectVenueMode = false,
    Function(MeetupVenue venue)? onVenueSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LocationVenuePickerSheet(
        selectVenueMode: selectVenueMode,
        onVenueSelected: onVenueSelected,
      ),
    );
  }

  @override
  ConsumerState<LocationVenuePickerSheet> createState() =>
      _LocationVenuePickerSheetState();
}

class _LocationVenuePickerSheetState
    extends ConsumerState<LocationVenuePickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  int _activeTab = 0; // 0: Cities worldwide, 1: Meetup Venues
  String _selectedCategory = 'all';
  bool _isLoading = false;

  List<WorldLocation> _cityResults = [];
  List<MeetupVenue> _venueResults = [];

  @override
  void initState() {
    super.initState();
    _activeTab = widget.selectVenueMode ? 1 : 0;
    _cityResults = WorldwideLocationService.featuredWorldCities;
    _loadVenues();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchCities(String q) async {
    setState(() => _isLoading = true);
    final service = ref.read(worldwideLocationServiceProvider);
    final results = await service.searchCities(q);
    if (mounted) {
      setState(() {
        _cityResults = results;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadVenues([String query = '']) async {
    setState(() => _isLoading = true);
    final service = ref.read(worldwideLocationServiceProvider);
    final currentLocation = ref.read(userLocationProvider);
    final results = await service.searchVenues(
      query: query,
      location: currentLocation,
      categoryFilter: _selectedCategory == 'all' ? null : _selectedCategory,
    );
    if (mounted) {
      setState(() {
        _venueResults = results;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentLocation = ref.watch(userLocationProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              color: isDark ? const Color(0xFF161224) : AppColors.warmIvory,
              child: Column(
                children: [
                  // Drag Handle
                  const SizedBox(height: 12),
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.2)
                          : AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Worldwide Location & Venues',
                              style: AppTypography.titleMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.deepPlum,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Current: ${currentLocation.shortLabel}',
                              style: AppTypography.bodySmall.copyWith(
                                color: isDark
                                    ? AppColors.luminousMauve
                                    : AppColors.mauve,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                          color: isDark ? Colors.white70 : AppColors.deepPlum,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Tab switch: Cities vs Venues
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkElevated
                            : AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.divider,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildPillTab(
                              title: '🌍 World Cities',
                              index: 0,
                              isDark: isDark,
                            ),
                          ),
                          Expanded(
                            child: _buildPillTab(
                              title: '☕ Meetup Spots',
                              index: 1,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Search input
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        if (_activeTab == 0) {
                          _searchCities(val);
                        } else {
                          _loadVenues(val);
                        }
                      },
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.deepPlum,
                      ),
                      decoration: InputDecoration(
                        hintText: _activeTab == 0
                            ? 'Search any city or neighborhood worldwide...'
                            : 'Search cafes, restaurants, spots in ${currentLocation.city}...',
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppColors.mauve,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  if (_activeTab == 0) {
                                    _searchCities('');
                                  } else {
                                    _loadVenues('');
                                  }
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),

                  // Category filter chips for Meetup Venues
                  if (_activeTab == 1) ...[
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          _buildCategoryChip('all', '🌟 All Spots', isDark),
                          _buildCategoryChip('cafe', '☕ Cafes & Coffee', isDark),
                          _buildCategoryChip('restaurant', '🍽️ Dining', isDark),
                          _buildCategoryChip('board_games', '🎲 Board Games', isDark),
                          _buildCategoryChip('park', '🌿 Parks & Trails', isDark),
                          _buildCategoryChip('culture', '🎨 Art & Studios', isDark),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 10),

                  // Content list
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.mauve,
                            ),
                          )
                        : _activeTab == 0
                            ? _buildCityList(scrollController, isDark)
                            : _buildVenueList(scrollController, isDark),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPillTab({
    required String title,
    required int index,
    required bool isDark,
  }) {
    final isSelected = _activeTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeTab = index;
          _searchController.clear();
        });
        if (index == 0) {
          _searchCities('');
        } else {
          _loadVenues('');
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.luminousMauve : AppColors.mauve)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: AppTypography.labelMedium.copyWith(
            color: isSelected
                ? Colors.white
                : (isDark ? AppColors.darkMutedText : AppColors.mutedText),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String id, String label, bool isDark) {
    final isSelected = _selectedCategory == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (sel) {
          setState(() => _selectedCategory = id);
          _loadVenues(_searchController.text);
        },
        selectedColor: isDark ? AppColors.luminousMauve : AppColors.mauve,
        backgroundColor: isDark ? AppColors.darkElevated : AppColors.white,
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected
              ? Colors.white
              : (isDark ? AppColors.darkTextPrimary : AppColors.deepPlum),
        ),
      ),
    );
  }

  Widget _buildCityList(ScrollController controller, bool isDark) {
    return ListView.separated(
      controller: controller,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: _cityResults.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        color: isDark ? AppColors.darkBorder : AppColors.divider,
      ),
      itemBuilder: (context, index) {
        final loc = _cityResults[index];
        final isSelected =
            ref.watch(userLocationProvider).city.toLowerCase() ==
                loc.city.toLowerCase();

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkElevated : AppColors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.divider,
              ),
            ),
            child: const Icon(
              Icons.location_city_rounded,
              size: 20,
              color: AppColors.mauve,
            ),
          ),
          title: Text(
            loc.name,
            style: AppTypography.titleSmall.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.deepPlum,
            ),
          ),
          subtitle: Text(
            loc.country,
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? AppColors.darkMutedText : AppColors.mutedText,
            ),
          ),
          trailing: isSelected
              ? const Icon(Icons.check_circle_rounded, color: AppColors.mintAccent)
              : (loc.countryCode.isNotEmpty
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkElevated : AppColors.sage,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        loc.countryCode,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.deepPlum,
                        ),
                      ),
                    )
                  : null),
          onTap: () {
            ref.read(userLocationProvider.notifier).setLocation(loc);
            Navigator.pop(context);
          },
        );
      },
    );
  }

  Widget _buildVenueList(ScrollController controller, bool isDark) {
    if (_venueResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No matching venues found.\nTry a different search or category.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? AppColors.darkMutedText : AppColors.mutedText,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      controller: controller,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: _venueResults.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        color: isDark ? AppColors.darkBorder : AppColors.divider,
      ),
      itemBuilder: (context, index) {
        final venue = _venueResults[index];
        IconData icon = Icons.coffee_rounded;
        if (venue.category == 'restaurant') icon = Icons.restaurant_rounded;
        if (venue.category == 'board_games') icon = Icons.casino_rounded;
        if (venue.category == 'park') icon = Icons.park_rounded;
        if (venue.category == 'culture') icon = Icons.palette_rounded;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkElevated : AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.divider,
              ),
            ),
            child: Icon(icon, size: 20, color: AppColors.mauve),
          ),
          title: Text(
            venue.name,
            style: AppTypography.titleSmall.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.deepPlum,
            ),
          ),
          subtitle: Text(
            venue.address,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? AppColors.darkMutedText : AppColors.mutedText,
            ),
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: AppColors.mutedText,
          ),
          onTap: () {
            if (widget.onVenueSelected != null) {
              widget.onVenueSelected!(venue);
            }
            Navigator.pop(context);
          },
        );
      },
    );
  }
}
