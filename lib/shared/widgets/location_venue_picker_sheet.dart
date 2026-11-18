import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/services/location_providers.dart';
import '../../core/services/worldwide_location_service.dart';

/// Interactive modal sheet to search & select any city, neighborhood,
/// village, district, or specific meetup venue (store, shop, cafe, restaurant, etc.) worldwide.
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
    HapticFeedback.lightImpact();
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
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
  int _activeTab = 0; // 0: Any Area / City worldwide, 1: Meetup Venues / Shops
  String _selectedCategory = 'all';
  bool _isLoading = false;
  bool _isGpsLocating = false;

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

  Future<void> _useCurrentGpsLocation() async {
    HapticFeedback.lightImpact();
    setState(() => _isGpsLocating = true);
    final service = ref.read(worldwideLocationServiceProvider);
    final gpsLoc = await service.getCurrentGpsLocation();
    if (mounted) {
      setState(() => _isGpsLocating = false);
      if (gpsLoc != null) {
        await ref.read(userLocationProvider.notifier).setLocation(gpsLoc);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('📍 Location updated to ${gpsLoc.displayName}!'),
              duration: const Duration(seconds: 2),
            ),
          );
          Navigator.pop(context);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not access GPS. Please ensure location service is turned ON and permission is granted.',
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showAddCustomSpotDialog(bool isDark) {
    final nameCtrl = TextEditingController(text: _searchController.text.trim());
    final addressCtrl = TextEditingController();
    String category = 'shop';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final currentLocation = ref.read(userLocationProvider);
          return AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1E162F) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Add Custom Meetup Spot',
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.deepPlum,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: nameCtrl,
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.deepPlum,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Store / Shop / Spot Name',
                      labelStyle: TextStyle(
                        color: isDark
                            ? const Color(0xFFBDB2D4)
                            : AppColors.mutedText,
                      ),
                      hintText: 'e.g. Royal Bakery, City Center Cafe',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addressCtrl,
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.deepPlum,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Address / Landmark',
                      labelStyle: TextStyle(
                        color: isDark
                            ? const Color(0xFFBDB2D4)
                            : AppColors.mutedText,
                      ),
                      hintText: 'e.g. Near Station Gate 2, Main Market',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Category',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? const Color(0xFFBDB2D4)
                          : AppColors.mutedText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: [
                      _buildDialogChoiceChip(
                        'shop',
                        '🛍️ Shop / Store',
                        category,
                        isDark,
                        (cat) {
                          setDialogState(() => category = cat);
                        },
                      ),
                      _buildDialogChoiceChip(
                        'cafe',
                        '☕ Cafe',
                        category,
                        isDark,
                        (cat) {
                          setDialogState(() => category = cat);
                        },
                      ),
                      _buildDialogChoiceChip(
                        'restaurant',
                        '🍽️ Restaurant',
                        category,
                        isDark,
                        (cat) {
                          setDialogState(() => category = cat);
                        },
                      ),
                      _buildDialogChoiceChip(
                        'park',
                        '🌿 Park / Trail',
                        category,
                        isDark,
                        (cat) {
                          setDialogState(() => category = cat);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: isDark ? Colors.white60 : AppColors.mutedText,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark
                      ? AppColors.brightViolet
                      : AppColors.primaryPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) return;
                  final addr = addressCtrl.text.trim().isNotEmpty
                      ? addressCtrl.text.trim()
                      : 'Local Spot, ${currentLocation.city}';

                  final newVenue = MeetupVenue(
                    name: name,
                    category: category,
                    address: addr,
                    city: currentLocation.city,
                    country: currentLocation.country,
                    lat: currentLocation.lat,
                    lon: currentLocation.lon,
                  );

                  Navigator.pop(dialogCtx);
                  widget.onVenueSelected?.call(newVenue);
                  Navigator.pop(context);
                },
                child: const Text('Add Spot'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDialogChoiceChip(
    String id,
    String label,
    String selectedId,
    bool isDark,
    ValueChanged<String> onSelect,
  ) {
    final isSelected = selectedId == id;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: isSelected,
      onSelected: (_) => onSelect(id),
      selectedColor: isDark ? AppColors.brightViolet : AppColors.primaryPurple,
      labelStyle: TextStyle(
        color: isSelected
            ? Colors.white
            : (isDark ? Colors.white70 : AppColors.deepPlum),
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentLocation = ref.watch(userLocationProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      maxChildSize: 0.96,
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Worldwide Location & Spots',
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
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                          color: isDark ? Colors.white70 : AppColors.deepPlum,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Tab switch: Any Area / City vs Shops & Spots
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
                              title: '🌍 Any Area / City',
                              index: 0,
                              isDark: isDark,
                            ),
                          ),
                          Expanded(
                            child: _buildPillTab(
                              title: '☕ Shops & Spots',
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
                            ? 'Search any village, town, district, or city...'
                            : 'Search any shop, store, or cafe in ${currentLocation.city}...',
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
                          _buildCategoryChip(
                            'shop',
                            '🛍️ Stores & Shops',
                            isDark,
                          ),
                          _buildCategoryChip(
                            'cafe',
                            '☕ Cafes & Coffee',
                            isDark,
                          ),
                          _buildCategoryChip(
                            'restaurant',
                            '🍽️ Dining',
                            isDark,
                          ),
                          _buildCategoryChip('bakery', '🥐 Bakeries', isDark),
                          _buildCategoryChip(
                            'board_games',
                            '🎲 Board Games',
                            isDark,
                          ),
                          _buildCategoryChip(
                            'park',
                            '🌿 Parks & Trails',
                            isDark,
                          ),
                          _buildCategoryChip(
                            'culture',
                            '🎨 Art & Studios',
                            isDark,
                          ),
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
    final queryText = _searchController.text.trim();

    return ListView(
      controller: controller,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        // ── Option 1: Live Device GPS Button ──
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (isDark ? AppColors.brightViolet : AppColors.primaryPurple)
                  .withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color:
                    (isDark ? AppColors.brightViolet : AppColors.primaryPurple)
                        .withValues(alpha: 0.4),
              ),
            ),
            child: _isGpsLocating
                ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryPurple,
                    ),
                  )
                : Icon(
                    Icons.my_location_rounded,
                    size: 20,
                    color: isDark
                        ? AppColors.brightViolet
                        : AppColors.primaryPurple,
                  ),
          ),
          title: Text(
            'Use My Current GPS Location',
            style: AppTypography.titleSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.brightViolet : AppColors.primaryPurple,
            ),
          ),
          subtitle: Text(
            _isGpsLocating
                ? 'Requesting GPS permissions & coordinates...'
                : 'Auto-detect your neighborhood, town, or district',
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? AppColors.darkMutedText : AppColors.mutedText,
            ),
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: AppColors.mutedText,
          ),
          onTap: _isGpsLocating ? null : _useCurrentGpsLocation,
        ),

        // ── Option 2: Custom Location Option if Query is Typed ──
        if (queryText.isNotEmpty) ...[
          const SizedBox(height: 4),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                ),
              ),
              child: const Icon(
                Icons.pin_drop_rounded,
                size: 20,
                color: Color(0xFFF59E0B),
              ),
            ),
            title: Text(
              'Set as: "$queryText"',
              style: AppTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.deepPlum,
              ),
            ),
            subtitle: Text(
              'Use this custom area/neighborhood for your dates & meetups',
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? AppColors.darkMutedText : AppColors.mutedText,
              ),
            ),
            trailing: const Icon(
              Icons.check_circle_outline_rounded,
              size: 20,
              color: Color(0xFFF59E0B),
            ),
            onTap: () {
              final customLoc = WorldLocation(
                name: queryText.split(',').first.trim(),
                city: queryText,
                country: '',
                lat: 0.0,
                lon: 0.0,
              );
              ref.read(userLocationProvider.notifier).setLocation(customLoc);
              Navigator.pop(context);
            },
          ),
        ],

        Divider(
          height: 16,
          color: isDark ? AppColors.darkBorder : AppColors.divider,
        ),

        // ── Option 3: Search Results List ──
        if (_cityResults.isEmpty && queryText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              children: [
                Icon(
                  Icons.travel_explore_rounded,
                  size: 44,
                  color: isDark ? Colors.white38 : AppColors.mutedText,
                ),
                const SizedBox(height: 10),
                Text(
                  'No direct match found for "$queryText"',
                  textAlign: TextAlign.center,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : AppColors.deepPlum,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'You can tap the gold pin above to use "$queryText" as your custom location.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.darkMutedText
                        : AppColors.mutedText,
                  ),
                ),
              ],
            ),
          )
        else
          ..._cityResults.map((loc) {
            final isSelected =
                ref.watch(userLocationProvider).city.toLowerCase() ==
                loc.city.toLowerCase();

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkElevated : AppColors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.divider,
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
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.deepPlum,
                    ),
                  ),
                  subtitle: Text(
                    loc.country.isNotEmpty ? loc.country : loc.city,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.darkMutedText
                          : AppColors.mutedText,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.mintAccent,
                        )
                      : (loc.countryCode.isNotEmpty
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.darkElevated
                                      : AppColors.sage,
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
                ),
                Divider(
                  height: 1,
                  color: isDark ? AppColors.darkBorder : AppColors.divider,
                ),
              ],
            );
          }),
      ],
    );
  }

  Widget _buildVenueList(ScrollController controller, bool isDark) {
    final queryText = _searchController.text.trim();
    final currentLocation = ref.watch(userLocationProvider);

    return ListView(
      controller: controller,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        // ── Action: + Add Custom Meetup Spot / Store ──
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: (isDark ? AppColors.brightViolet : AppColors.primaryPurple)
                  .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    (isDark ? AppColors.brightViolet : AppColors.primaryPurple)
                        .withValues(alpha: 0.4),
              ),
            ),
            child: Icon(
              Icons.add_location_alt_rounded,
              size: 22,
              color: isDark ? AppColors.brightViolet : AppColors.primaryPurple,
            ),
          ),
          title: Text(
            '+ Add Custom Meetup Spot / Store',
            style: AppTypography.titleSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.brightViolet : AppColors.primaryPurple,
            ),
          ),
          subtitle: Text(
            'Add any local shop, bakery, or cafe in ${currentLocation.city}',
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? AppColors.darkMutedText : AppColors.mutedText,
            ),
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: AppColors.mutedText,
          ),
          onTap: () => _showAddCustomSpotDialog(isDark),
        ),

        // If query is typed, provide a quick direct meetup selector
        if (queryText.isNotEmpty) ...[
          const SizedBox(height: 4),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
            leading: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                ),
              ),
              child: const Icon(
                Icons.storefront_rounded,
                size: 22,
                color: Color(0xFFF59E0B),
              ),
            ),
            title: Text(
              'Meet at: "$queryText"',
              style: AppTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.deepPlum,
              ),
            ),
            subtitle: Text(
              'Set this shop/store as your meetup venue',
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? AppColors.darkMutedText : AppColors.mutedText,
              ),
            ),
            trailing: const Icon(
              Icons.check_circle_outline_rounded,
              size: 20,
              color: Color(0xFFF59E0B),
            ),
            onTap: () {
              final customVenue = MeetupVenue(
                name: queryText,
                category: 'shop',
                address: 'Custom Meetup Spot, ${currentLocation.city}',
                city: currentLocation.city,
                country: currentLocation.country,
                lat: currentLocation.lat,
                lon: currentLocation.lon,
              );
              widget.onVenueSelected?.call(customVenue);
              Navigator.pop(context);
            },
          ),
        ],

        Divider(
          height: 16,
          color: isDark ? AppColors.darkBorder : AppColors.divider,
        ),

        // ── Venue Results List ──
        if (_venueResults.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.store_mall_directory_outlined,
                    size: 42,
                    color: isDark ? Colors.white30 : AppColors.mutedText,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'No spots found matching your filter.\nTap "+ Add Custom Meetup Spot" to add any store or shop!',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark
                          ? AppColors.darkMutedText
                          : AppColors.mutedText,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ..._venueResults.map((venue) {
            IconData icon = Icons.storefront_rounded;
            if (venue.category == 'restaurant') icon = Icons.restaurant_rounded;
            if (venue.category == 'cafe') icon = Icons.coffee_rounded;
            if (venue.category == 'bakery') icon = Icons.bakery_dining_rounded;
            if (venue.category == 'board_games') icon = Icons.casino_rounded;
            if (venue.category == 'park') icon = Icons.park_rounded;
            if (venue.category == 'culture') icon = Icons.palette_rounded;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkElevated : AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.divider,
                      ),
                    ),
                    child: Icon(icon, size: 20, color: AppColors.mauve),
                  ),
                  title: Text(
                    venue.name,
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.deepPlum,
                    ),
                  ),
                  subtitle: Text(
                    venue.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.darkMutedText
                          : AppColors.mutedText,
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
                ),
                Divider(
                  height: 1,
                  color: isDark ? AppColors.darkBorder : AppColors.divider,
                ),
              ],
            );
          }),
      ],
    );
  }
}
