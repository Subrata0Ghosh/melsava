import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/services/worldwide_location_service.dart';
import 'full_screen_radar_map_sheet.dart';
import 'location_venue_picker_sheet.dart';

/// Interactive Real-World Activity Radar Map Card
/// Powered by live OpenStreetMap / CartoDB tiles with real GPS coordinates,
/// interactive pan/zoom, animated radar pulse, and verified venue pins.
class ActivityRadarMapCard extends StatefulWidget {
  final WorldLocation location;
  final Function(MeetupVenue venue)? onVenueSelected;

  const ActivityRadarMapCard({
    super.key,
    required this.location,
    this.onVenueSelected,
  });

  @override
  State<ActivityRadarMapCard> createState() => _ActivityRadarMapCardState();
}

class _ActivityRadarMapCardState extends State<ActivityRadarMapCard>
    with SingleTickerProviderStateMixin {
  late final MapController _mapController;
  late final AnimationController _pulseController;
  int _selectedVenueIndex = 0;
  List<MeetupVenue> _venues = [];
  bool _isLoading = true;

  LatLng get _cityCenter => LatLng(
    widget.location.lat != 0.0 ? widget.location.lat : 19.0760,
    widget.location.lon != 0.0 ? widget.location.lon : 72.8777,
  );

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    _loadVenues();
  }

  @override
  void didUpdateWidget(covariant ActivityRadarMapCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location.city != widget.location.city ||
        oldWidget.location.lat != widget.location.lat) {
      _loadVenues();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(_cityCenter, 14.5);
      });
    }
  }

  void _loadVenues() async {
    setState(() => _isLoading = true);
    final venues = await WorldwideLocationService.instance.searchVenues(
      query: '',
      location: widget.location,
    );
    if (mounted) {
      setState(() {
        _venues = venues;
        _isLoading = false;
        _selectedVenueIndex = 0;
      });
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _selectVenue(int index) {
    HapticFeedback.selectionClick();
    setState(() => _selectedVenueIndex = index);
    final venue = _venues[index];
    if (venue.lat != 0.0 && venue.lon != 0.0) {
      _mapController.move(LatLng(venue.lat, venue.lon), 15.5);
    }
    widget.onVenueSelected?.call(venue);
  }

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom + 1.0);
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom - 1.0);
  }

  Future<void> _recenter() async {
    HapticFeedback.lightImpact();
    _mapController.move(_cityCenter, 14.5);
    final gpsLoc = await WorldwideLocationService.instance
        .getCurrentGpsLocation();
    if (mounted && gpsLoc != null) {
      _mapController.move(LatLng(gpsLoc.lat, gpsLoc.lon), 15.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeVenue = _venues.isNotEmpty
        ? _venues[_selectedVenueIndex.clamp(0, _venues.length - 1)]
        : null;

    final primaryTextColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.deepPlum;
    final mutedTextColor = isDark
        ? AppColors.darkMutedText
        : AppColors.mutedText;

    // OpenStreetMap official tiles: 100% Free, Zero Sign-In, Zero API key required, Zero watermarks!
    const tileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.divider,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.35)
                : AppColors.deepPlum.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Live Real Map Canvas Stack ─────────────────────────────────
            SizedBox(
              height: 240,
              child: Stack(
                children: [
                  // Ambient baseline canvas background (matching theme while tiles load)
                  Positioned.fill(
                    child: ColoredBox(
                      color: isDark
                          ? const Color(0xFF130E1F)
                          : const Color(0xFFF3EFEA),
                    ),
                  ),

                  // Real Interactive FlutterMap
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _cityCenter,
                      initialZoom: 14.5,
                      minZoom: 11.0,
                      maxZoom: 18.0,
                      interactionOptions: const InteractionOptions(
                        flags:
                            InteractiveFlag.pinchZoom |
                            InteractiveFlag.drag |
                            InteractiveFlag.doubleTapZoom,
                      ),
                    ),
                    children: [
                      // Tile Layer (Real OpenStreetMap Street Data — 100% Zero Sign-In & Watermark-Free)
                      TileLayer(
                        urlTemplate: tileUrl,
                        userAgentPackageName: 'com.melsava.app',
                        tileProvider: NetworkTileProvider(),
                        tileBuilder: (context, tileWidget, tile) {
                          if (isDark) {
                            return ColorFiltered(
                              colorFilter: const ColorFilter.matrix(<double>[
                                // Obsidian Inversion & Midnight Violet Tint Matrix:
                                // Turns white land into sleek dark obsidian (#120E1C),
                                // roads into crisp silver/lavender ribbons, and water into deep indigo
                                -0.22, -0.45, -0.10, 0.0, 220.0,
                                -0.22, -0.45, -0.10, 0.0, 210.0,
                                -0.15, -0.35, -0.10, 0.0, 238.0,
                                0.00, 0.00, 0.00, 1.0, 0.0,
                              ]),
                              child: tileWidget,
                            );
                          }
                          return tileWidget;
                        },
                      ),

                      // Animated Radar Pulse Circles Layer
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          final pulseRadius =
                              180.0 + (_pulseController.value * 280.0);
                          final pulseAlpha =
                              (1.0 - _pulseController.value) * 0.22;

                          return CircleLayer(
                            circles: [
                              // Fixed inner radar boundary
                              CircleMarker(
                                point: _cityCenter,
                                radius: 260,
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
                              // Expanding pulse ripple
                              CircleMarker(
                                point: _cityCenter,
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

                      // Interactive Venue Markers Layer
                      if (!_isLoading && _venues.isNotEmpty)
                        MarkerLayer(
                          markers: List.generate(_venues.length, (index) {
                            final venue = _venues[index];
                            final pos = LatLng(
                              venue.lat != 0.0
                                  ? venue.lat
                                  : _cityCenter.latitude,
                              venue.lon != 0.0
                                  ? venue.lon
                                  : _cityCenter.longitude,
                            );

                            return Marker(
                              point: pos,
                              width: 48,
                              height: 48,
                              child: _buildVenueMarker(
                                index: index,
                                venue: venue,
                                isDark: isDark,
                              ),
                            );
                          }),
                        ),
                    ],
                  ),

                  // Top Pill Overlay: City & Status
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: Row(
                      children: [
                        // Live Radar Status Pill
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    (isDark
                                            ? const Color(0xFF130F1F)
                                            : Colors.white)
                                        .withValues(alpha: 0.88),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.15)
                                      : AppColors.divider,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: AppColors.mintAccent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${widget.location.city} Activity Radar',
                                    style: AppTypography.labelSmall.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: primaryTextColor,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),

                        // "Change Area" Button
                        GestureDetector(
                          onTap: () => LocationVenuePickerSheet.show(
                            context,
                            selectVenueMode: true,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      (isDark
                                              ? AppColors.brightViolet
                                              : AppColors.primaryPurple)
                                          .withValues(alpha: 0.20),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color:
                                        (isDark
                                                ? AppColors.brightViolet
                                                : AppColors.primaryPurple)
                                            .withValues(alpha: 0.40),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.tune_rounded,
                                      size: 13,
                                      color: isDark
                                          ? AppColors.brightViolet
                                          : AppColors.primaryPurple,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Change Area',
                                      style: AppTypography.labelSmall.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? AppColors.brightViolet
                                            : AppColors.primaryPurple,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Floating Map Navigation Controls (Fullscreen, Zoom & Recenter)
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildFloatingMapButton(
                          icon: Icons.fullscreen_rounded,
                          onTap: () => FullScreenRadarMapSheet.show(
                            context,
                            location: widget.location,
                            onVenueSelected: widget.onVenueSelected,
                          ),
                          isDark: isDark,
                        ),
                        const SizedBox(height: 6),
                        _buildFloatingMapButton(
                          icon: Icons.add_rounded,
                          onTap: _zoomIn,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 6),
                        _buildFloatingMapButton(
                          icon: Icons.remove_rounded,
                          onTap: _zoomOut,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 6),
                        _buildFloatingMapButton(
                          icon: Icons.my_location_rounded,
                          onTap: _recenter,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),

                  // Loading indicator
                  if (_isLoading)
                    Container(
                      color: (isDark ? Colors.black : Colors.white).withValues(
                        alpha: 0.4,
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.primaryPurple,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Active Venue Bottom Drawer / Info Box ──────────────────────
            if (activeVenue != null)
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onVenueSelected?.call(activeVenue);
                },
                child: Container(
                  height: 84,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E182D)
                        : const Color(0xFFFAF7F2),
                    border: Border(
                      top: BorderSide(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.divider,
                        width: 0.8,
                      ),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
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
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryPurple.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          _getVenueIcon(activeVenue.category),
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    activeVenue.category.toUpperCase(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.labelSmall.copyWith(
                                      fontSize: 10,
                                      letterSpacing: 1.2,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? AppColors.vividCoral
                                          : AppColors.primaryPurple,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.mintAccent.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Verified Spot',
                                    style: AppTypography.labelSmall.copyWith(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? AppColors.mintAccent
                                          : const Color(0xFF28795A),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              activeVenue.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.titleSmall.copyWith(
                                fontWeight: FontWeight.w700,
                                color: primaryTextColor,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              activeVenue.address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodySmall.copyWith(
                                color: mutedTextColor,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark
                              ? AppColors.brightViolet
                              : AppColors.primaryPurple,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: const Size(0, 32),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          widget.onVenueSelected?.call(activeVenue);
                        },
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Meetup',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 2),
                            Icon(Icons.arrow_forward_rounded, size: 12),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVenueMarker({
    required int index,
    required MeetupVenue venue,
    required bool isDark,
  }) {
    final isSelected = _selectedVenueIndex == index;
    final icon = _getVenueIcon(venue.category);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _selectVenue(index),
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final pulseScale = 1.0 + (_pulseController.value * 0.35);
          final pulseAlpha = (1.0 - _pulseController.value).clamp(0.0, 1.0);

          return Stack(
            alignment: Alignment.center,
            children: [
              // Glowing Ripple on Selected Pin
              if (isSelected)
                Transform.scale(
                  scale: pulseScale,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          (isDark
                                  ? AppColors.brightViolet
                                  : AppColors.primaryPurple)
                              .withValues(alpha: 0.35 * pulseAlpha),
                    ),
                  ),
                ),

              // Volumetric 3D Map Pin Badge
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isSelected ? 40 : 34,
                height: isSelected ? 40 : 34,
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark
                            ? const Color(0xFF281E38)
                            : const Color(0xFF2A1C3E))
                      : (isDark ? const Color(0xFF282038) : Colors.white),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? Colors.white
                        : (isDark
                              ? AppColors.brightViolet
                              : AppColors.primaryPurple),
                    width: isSelected ? 2.2 : 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isSelected ? 0.40 : 0.22,
                      ),
                      blurRadius: isSelected ? 10 : 6,
                      offset: const Offset(0, 3),
                    ),
                    if (isSelected)
                      BoxShadow(
                        color: AppColors.primaryPurple.withValues(alpha: 0.45),
                        blurRadius: 12,
                      ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: isSelected ? 19 : 16,
                    color: isSelected
                        ? Colors.white
                        : (isDark
                              ? AppColors.brightViolet
                              : AppColors.primaryPurple),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFloatingMapButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: (isDark ? const Color(0xFF130F1F) : Colors.white)
                  .withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : AppColors.divider,
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 18,
              color: isDark ? Colors.white : AppColors.deepPlum,
            ),
          ),
        ),
      ),
    );
  }

  IconData _getVenueIcon(String category) {
    switch (category.toLowerCase()) {
      case 'cafe':
        return Icons.coffee_rounded;
      case 'board_games':
      case 'board games':
        return Icons.casino_rounded;
      case 'restaurant':
      case 'lounge':
        return Icons.local_bar_rounded;
      case 'park':
      case 'nature':
        return Icons.park_rounded;
      case 'culture':
      case 'art':
        return Icons.palette_rounded;
      default:
        return Icons.place_rounded;
    }
  }
}
