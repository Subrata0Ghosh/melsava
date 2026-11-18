import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/services/worldwide_location_service.dart';
import 'glass_back_button.dart';

/// Full-Screen Interactive Activity Radar Map
///
/// Features:
/// - True edge-to-edge interactive OpenStreetMap canvas with zero sign-in & zero watermarks
/// - Top search bar to search ANY store, shop, cafe, landmark, or neighborhood worldwide
/// - Device GPS permission button to locate user live
/// - Floating zoom controls and recenter
/// - Tap anywhere on the map to set a Custom Meetup Pin
/// - Bottom interactive venue drawer with direct meetup selection
class FullScreenRadarMapSheet extends StatefulWidget {
  final WorldLocation location;
  final ValueChanged<MeetupVenue>? onVenueSelected;

  const FullScreenRadarMapSheet({
    super.key,
    required this.location,
    this.onVenueSelected,
  });

  static Future<MeetupVenue?> show(
    BuildContext context, {
    required WorldLocation location,
    ValueChanged<MeetupVenue>? onVenueSelected,
  }) {
    HapticFeedback.mediumImpact();
    return Navigator.of(context, rootNavigator: true).push<MeetupVenue>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => FullScreenRadarMapSheet(
          location: location,
          onVenueSelected: onVenueSelected,
        ),
      ),
    );
  }

  @override
  State<FullScreenRadarMapSheet> createState() =>
      _FullScreenRadarMapSheetState();
}

class _FullScreenRadarMapSheetState extends State<FullScreenRadarMapSheet>
    with SingleTickerProviderStateMixin {
  late final MapController _mapController;
  late final AnimationController _pulseController;
  final TextEditingController _searchController = TextEditingController();

  late WorldLocation _currentLocation;
  List<MeetupVenue> _venues = [];
  MeetupVenue? _selectedVenue;
  bool _isLoading = true;
  bool _isGpsLocating = false;
  String _selectedCategory = 'all';

  LatLng get _mapCenter => LatLng(
    _currentLocation.lat != 0.0 ? _currentLocation.lat : 19.0760,
    _currentLocation.lon != 0.0 ? _currentLocation.lon : 72.8777,
  );

  @override
  void initState() {
    super.initState();
    _currentLocation = widget.location;
    _mapController = MapController();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    _loadVenues();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _mapController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVenues([String query = '']) async {
    setState(() => _isLoading = true);
    final results = await WorldwideLocationService.instance.searchVenues(
      query: query,
      location: _currentLocation,
      categoryFilter: _selectedCategory == 'all' ? null : _selectedCategory,
    );
    if (mounted) {
      setState(() {
        _venues = results;
        _isLoading = false;
        if (results.isNotEmpty) {
          _selectedVenue = results.first;
        }
      });
    }
  }

  Future<void> _locateWithGps() async {
    HapticFeedback.lightImpact();
    setState(() => _isGpsLocating = true);
    final gpsLoc = await WorldwideLocationService.instance
        .getCurrentGpsLocation();
    if (mounted) {
      setState(() => _isGpsLocating = false);
      if (gpsLoc != null) {
        setState(() {
          _currentLocation = gpsLoc;
        });
        _mapController.move(LatLng(gpsLoc.lat, gpsLoc.lon), 15.5);
        _loadVenues();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📍 Centered on ${gpsLoc.displayName}!'),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'GPS access unavailable. Please check location permissions.',
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng latLng) {
    HapticFeedback.selectionClick();
    final customVenue = MeetupVenue(
      name: 'Custom Meetup Pin',
      category: 'shop',
      address:
          'Pinned at (${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)})',
      city: _currentLocation.city,
      country: _currentLocation.country,
      lat: latLng.latitude,
      lon: latLng.longitude,
    );

    setState(() {
      _selectedVenue = customVenue;
      _venues.insert(0, customVenue);
    });
  }

  void _confirmMeetupSpot(MeetupVenue venue) {
    HapticFeedback.mediumImpact();
    widget.onVenueSelected?.call(venue);
    Navigator.of(context).pop(venue);
  }

  void _showAddCustomVenueDialog(bool isDark) {
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E162F) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Add Custom Meetup Spot',
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.deepPlum,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.deepPlum,
              ),
              decoration: InputDecoration(
                labelText: 'Store / Shop / Spot Name',
                labelStyle: TextStyle(
                  color: isDark ? const Color(0xFFBDB2D4) : AppColors.mutedText,
                ),
                hintText: 'e.g. Royal Bakery & Cafe',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: addressCtrl,
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.deepPlum,
              ),
              decoration: InputDecoration(
                labelText: 'Area / Street Address',
                labelStyle: TextStyle(
                  color: isDark ? const Color(0xFFBDB2D4) : AppColors.mutedText,
                ),
                hintText: 'e.g. Near Station Gate 2',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brightViolet,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              final customVenue = MeetupVenue(
                name: name,
                category: 'shop',
                address: addressCtrl.text.trim().isNotEmpty
                    ? addressCtrl.text.trim()
                    : _currentLocation.displayName,
                city: _currentLocation.city,
                country: _currentLocation.country,
                lat: _mapController.camera.center.latitude,
                lon: _mapController.camera.center.longitude,
              );
              Navigator.pop(ctx);
              setState(() {
                _venues.insert(0, customVenue);
                _selectedVenue = customVenue;
              });
            },
            child: const Text('Add Spot'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String id, String label, bool isDark) {
    final isSelected = _selectedCategory == id;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedCategory = id);
          _loadVenues(_searchController.text);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.brightViolet : AppColors.primaryPurple)
                : (isDark
                      ? const Color(0xFF1D162C).withValues(alpha: 0.85)
                      : Colors.white.withValues(alpha: 0.90)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.14)
                        : const Color(0xFFE5DEED)),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white70 : AppColors.deepPlum),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const tileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF100B1A)
          : const Color(0xFFFBF8F5),
      body: Stack(
        children: [
          // ── 1. Full-Screen Interactive OpenStreetMap Canvas ─────────────────
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _mapCenter,
                initialZoom: 14.5,
                minZoom: 11.0,
                maxZoom: 18.0,
                onTap: _onMapTap,
                interactionOptions: const InteractionOptions(
                  flags:
                      InteractiveFlag.pinchZoom |
                      InteractiveFlag.drag |
                      InteractiveFlag.doubleTapZoom,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: tileUrl,
                  userAgentPackageName: 'com.melsava.app',
                  tileProvider: NetworkTileProvider(),
                  tileBuilder: (context, tileWidget, tile) {
                    if (isDark) {
                      return ColorFiltered(
                        colorFilter: const ColorFilter.matrix(<double>[
                          -0.22,
                          -0.45,
                          -0.10,
                          0.0,
                          220.0,
                          -0.22,
                          -0.45,
                          -0.10,
                          0.0,
                          210.0,
                          -0.15,
                          -0.35,
                          -0.10,
                          0.0,
                          238.0,
                          0.00,
                          0.00,
                          0.00,
                          1.0,
                          0.0,
                        ]),
                        child: tileWidget,
                      );
                    }
                    return tileWidget;
                  },
                ),

                // Animated Radar Pulse Circles
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final pulseRadius =
                        200.0 + (_pulseController.value * 350.0);
                    final pulseAlpha = (1.0 - _pulseController.value) * 0.22;

                    return CircleLayer(
                      circles: [
                        CircleMarker(
                          point: _mapCenter,
                          radius: 300,
                          useRadiusInMeter: true,
                          color:
                              (isDark
                                      ? AppColors.brightViolet
                                      : AppColors.primaryPurple)
                                  .withValues(alpha: 0.06),
                          borderColor:
                              (isDark
                                      ? AppColors.brightViolet
                                      : AppColors.primaryPurple)
                                  .withValues(alpha: 0.25),
                          borderStrokeWidth: 1.2,
                        ),
                        CircleMarker(
                          point: _mapCenter,
                          radius: pulseRadius,
                          useRadiusInMeter: true,
                          color:
                              (isDark
                                      ? AppColors.brightViolet
                                      : AppColors.primaryPurple)
                                  .withValues(alpha: pulseAlpha),
                          borderColor:
                              (isDark
                                      ? AppColors.brightViolet
                                      : AppColors.primaryPurple)
                                  .withValues(alpha: pulseAlpha * 1.5),
                          borderStrokeWidth: 1.5,
                        ),
                      ],
                    );
                  },
                ),

                // Venue & Shop Pins Layer
                MarkerLayer(
                  markers: List.generate(_venues.length, (index) {
                    final venue = _venues[index];
                    final isSelected = _selectedVenue?.name == venue.name;
                    return Marker(
                      point: LatLng(venue.lat, venue.lon),
                      width: isSelected ? 48 : 38,
                      height: isSelected ? 48 : 38,
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() => _selectedVenue = venue);
                          _mapController.move(
                            LatLng(venue.lat, venue.lon),
                            15.5,
                          );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? (isDark
                                      ? AppColors.brightViolet
                                      : AppColors.primaryPurple)
                                : (isDark
                                      ? const Color(0xFF2A213D)
                                      : Colors.white),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.white
                                  : (isDark
                                        ? AppColors.brightViolet
                                        : AppColors.primaryPurple),
                              width: isSelected ? 2.2 : 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    (isSelected
                                            ? AppColors.brightViolet
                                            : Colors.black)
                                        .withValues(alpha: 0.35),
                                blurRadius: isSelected ? 12 : 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(
                            _getVenueIcon(venue.category),
                            size: isSelected ? 22 : 18,
                            color: isSelected
                                ? Colors.white
                                : (isDark
                                      ? AppColors.brightViolet
                                      : AppColors.primaryPurple),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          // ── 2. Top Floating Search & Location Header ────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        GlassBackButton(
                          isDark: isDark,
                          iconColor: isDark ? Colors.white : AppColors.deepPlum,
                          onTap: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            height: 46,
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
                                      ? Colors.black38
                                      : Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              onSubmitted: _loadVenues,
                              onChanged: (val) {
                                setState(() {});
                                if (val.isEmpty) {
                                  _loadVenues('');
                                }
                              },
                              style: TextStyle(
                                fontSize: 13.5,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.deepPlum,
                              ),
                              decoration: InputDecoration(
                                hintText:
                                    'Search any store, shop, cafe in ${_currentLocation.name}...',
                                hintStyle: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? AppColors.darkMutedText
                                      : AppColors.mutedText,
                                ),
                                prefixIcon: Icon(
                                  Icons.search_rounded,
                                  color: isDark
                                      ? const Color(0xFFC084FC)
                                      : const Color(0xFF8B5CF6),
                                  size: 20,
                                ),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(
                                          Icons.clear_rounded,
                                          size: 18,
                                        ),
                                        color: isDark
                                            ? AppColors.darkMutedText
                                            : AppColors.mutedText,
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() {});
                                          _loadVenues('');
                                        },
                                      )
                                    : null,
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
                        const SizedBox(width: 8),
                        // GPS Button
                        GestureDetector(
                          onTap: _locateWithGps,
                          child: Container(
                            width: 46,
                            height: 46,
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
                                      ? Colors.black38
                                      : Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: _isGpsLocating
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.brightViolet,
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
                        ),
                      ],
                    ),
                    if (_isLoading) ...[
                      const SizedBox(height: 6),
                      const ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(2)),
                        child: LinearProgressIndicator(
                          minHeight: 2.5,
                          color: AppColors.brightViolet,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    // Category filter chips
                    SizedBox(
                      height: 32,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildFilterChip('all', '🌟 All Spots', isDark),
                          _buildFilterChip('shop', '🛍️ Stores', isDark),
                          _buildFilterChip('cafe', '☕ Cafes', isDark),
                          _buildFilterChip('restaurant', '🍽️ Dining', isDark),
                          _buildFilterChip('bakery', '🥐 Bakeries', isDark),
                          _buildFilterChip('park', '🌿 Parks', isDark),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── 3. Floating Right Controls ──────────────────────────────────────
          Positioned(
            right: 16,
            bottom: 230,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFloatingButton(
                  icon: Icons.add_rounded,
                  onTap: () => _mapController.move(
                    _mapController.camera.center,
                    _mapController.camera.zoom + 1.0,
                  ),
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _buildFloatingButton(
                  icon: Icons.remove_rounded,
                  onTap: () => _mapController.move(
                    _mapController.camera.center,
                    _mapController.camera.zoom - 1.0,
                  ),
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _buildFloatingButton(
                  icon: Icons.add_location_alt_outlined,
                  onTap: () => _showAddCustomVenueDialog(isDark),
                  isDark: isDark,
                  tooltip: 'Add Custom Spot',
                ),
              ],
            ),
          ),

          // ── 4. Bottom Selected Venue Drawer Card ────────────────────────────
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SafeArea(
              top: false,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E172E).withValues(alpha: 0.88)
                          : Colors.white.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.12)
                            : const Color(0xFFE5DEED),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.35 : 0.08,
                          ),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_selectedVenue != null) ...[
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      isDark
                                          ? AppColors.brightViolet
                                          : AppColors.primaryPurple,
                                      AppColors.vividCoral,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  _getVenueIcon(_selectedVenue!.category),
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          _selectedVenue!.category
                                              .toUpperCase(),
                                          style: AppTypography.labelSmall
                                              .copyWith(
                                                fontSize: 10,
                                                letterSpacing: 1.2,
                                                fontWeight: FontWeight.w700,
                                                color: isDark
                                                    ? AppColors.vividCoral
                                                    : AppColors.primaryPurple,
                                              ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.mintAccent
                                                .withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: const Text(
                                            'Vetted Spot',
                                            style: TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.mintAccent,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      _selectedVenue!.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                        color: isDark
                                            ? Colors.white
                                            : AppColors.deepPlum,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _selectedVenue!.address,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: isDark
                                            ? const Color(0xFFA69EB8)
                                            : AppColors.mutedText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          // Confirm Meetup Button
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark
                                  ? AppColors.brightViolet
                                  : AppColors.primaryPurple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () =>
                                _confirmMeetupSpot(_selectedVenue!),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_circle_outline_rounded,
                                  size: 18,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Set as Meetup Spot ✓',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          const Text(
                            'Tap any pin on the map or search above to choose a meeting spot.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
    String? tooltip,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1D162C).withValues(alpha: 0.90)
              : Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : const Color(0xFFE5DEED),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 20,
          color: isDark ? Colors.white : AppColors.deepPlum,
        ),
      ),
    );
  }

  IconData _getVenueIcon(String category) {
    switch (category.toLowerCase()) {
      case 'cafe':
        return Icons.coffee_rounded;
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'board_games':
        return Icons.casino_rounded;
      case 'park':
        return Icons.nature_people_rounded;
      case 'culture':
        return Icons.palette_rounded;
      case 'lounge':
        return Icons.local_bar_rounded;
      case 'shop':
        return Icons.storefront_rounded;
      default:
        return Icons.place_rounded;
    }
  }
}
