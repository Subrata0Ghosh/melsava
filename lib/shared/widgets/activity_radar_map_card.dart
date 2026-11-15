import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/services/worldwide_location_service.dart';
import 'location_venue_picker_sheet.dart';

/// Interactive Activity Radar & Curated Meetup Venue Map
/// Inspired by modern dark map concepts on Dribbble.
/// Visualizes verified public meetup venues (Cafes, Lounges, Board Game spots)
/// in the user's active city anywhere in the world.
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
  late AnimationController _pulseController;
  int _selectedVenueIndex = 0;
  List<MeetupVenue> _venues = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    _loadVenues();
  }

  @override
  void didUpdateWidget(covariant ActivityRadarMapCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location.city != widget.location.city) {
      _loadVenues();
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
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeVenue = _venues.isNotEmpty
        ? _venues[_selectedVenueIndex.clamp(0, _venues.length - 1)]
        : null;

    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.deepPlum;
    final mutedTextColor = isDark ? AppColors.darkMutedText : AppColors.mutedText;

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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Map Canvas Stack
            SizedBox(
              height: 220,
              child: Stack(
                children: [
                  // Stylized Map Background Painter
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _StylizedRadarMapPainter(
                        isDark: isDark,
                        pulseValue: _pulseController.value,
                      ),
                    ),
                  ),

                  // Top Pill Overlay: City & Status
                  Positioned(
                    top: 14,
                    left: 14,
                    right: 14,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: (isDark
                                    ? const Color(0xFF151022)
                                    : Colors.white)
                                .withValues(alpha: 0.88),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.12)
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
                        const Spacer(),
                        GestureDetector(
                          onTap: () => LocationVenuePickerSheet.show(
                            context,
                            selectVenueMode: true,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: (isDark
                                      ? AppColors.luminousMauve
                                      : AppColors.mauve)
                                  .withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: (isDark
                                        ? AppColors.luminousMauve
                                        : AppColors.mauve)
                                    .withValues(alpha: 0.35),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.tune_rounded,
                                  size: 13,
                                  color: isDark
                                      ? AppColors.luminousMauve
                                      : AppColors.mauve,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Change Area',
                                  style: AppTypography.labelSmall.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? AppColors.luminousMauve
                                        : AppColors.mauve,
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

                  // Pins on the radar
                  if (_isLoading)
                    const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.mauve,
                      ),
                    )
                  else ...[
                    // Pin 1 (Center-Left)
                    if (_venues.isNotEmpty)
                      _buildMapPin(
                        index: 0,
                        top: 75,
                        left: 65,
                        venue: _venues[0],
                        icon: _getVenueIcon(_venues[0].category),
                        isDark: isDark,
                      ),

                    // Pin 2 (Center-Right)
                    if (_venues.length > 1)
                      _buildMapPin(
                        index: 1,
                        top: 95,
                        left: 210,
                        venue: _venues[1],
                        icon: _getVenueIcon(_venues[1].category),
                        isDark: isDark,
                      ),

                    // Pin 3 (Bottom-Center)
                    if (_venues.length > 2)
                      _buildMapPin(
                        index: 2,
                        top: 140,
                        left: 135,
                        venue: _venues[2],
                        icon: _getVenueIcon(_venues[2].category),
                        isDark: isDark,
                      ),

                    // Pin 4 (Top-Right)
                    if (_venues.length > 3)
                      _buildMapPin(
                        index: 3,
                        top: 60,
                        left: 280,
                        venue: _venues[3],
                        icon: _getVenueIcon(_venues[3].category),
                        isDark: isDark,
                      ),
                  ],
                ],
              ),
            ),

            // Active Venue Bottom Drawer / Info Box
            if (activeVenue != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E182D)
                      : const Color(0xFFFAF7F2),
                  border: Border(
                    top: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.divider,
                      width: 0.8,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            isDark
                                ? AppColors.luminousMauve
                                : AppColors.mauve,
                            AppColors.softCoral,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                activeVenue.category.toUpperCase(),
                                style: AppTypography.labelSmall.copyWith(
                                  fontSize: 10,
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.softCoral
                                      : AppColors.mauve,
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
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Vetted Public Spot',
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
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${activeVenue.address} • 3-5 small group capacity',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySmall.copyWith(
                              color: mutedTextColor,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? AppColors.luminousMauve
                            : AppColors.mauve,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        widget.onVenueSelected?.call(activeVenue);
                      },
                      child: const Text(
                        'View Meetup',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapPin({
    required int index,
    required double top,
    required double left,
    required MeetupVenue venue,
    required IconData icon,
    required bool isDark,
  }) {
    final isSelected = _selectedVenueIndex == index;

    return Positioned(
      top: top,
      left: left,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() => _selectedVenueIndex = index);
          widget.onVenueSelected?.call(venue);
        },
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final pulseScale = 1.0 + (_pulseController.value * 0.4);
            final pulseAlpha = (1.0 - _pulseController.value).clamp(0.0, 1.0);

            return Stack(
              alignment: Alignment.center,
              children: [
                // Pulse ripple
                if (isSelected)
                  Transform.scale(
                    scale: pulseScale,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (isDark
                                ? AppColors.vividCoral
                                : AppColors.mauve)
                            .withValues(alpha: 0.35 * pulseAlpha),
                      ),
                    ),
                  ),

                // Pin Body
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isSelected ? 38 : 32,
                  height: isSelected ? 38 : 32,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark ? AppColors.vividCoral : AppColors.deepPlum)
                        : (isDark
                            ? const Color(0xFF282038)
                            : Colors.white),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? Colors.white
                          : (isDark
                              ? AppColors.luminousMauve
                              : AppColors.mauve),
                      width: isSelected ? 2.2 : 1.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      size: isSelected ? 18 : 15,
                      color: isSelected
                          ? Colors.white
                          : (isDark
                              ? AppColors.luminousMauve
                              : AppColors.mauve),
                    ),
                  ),
                ),
              ],
            );
          },
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

/// Custom painter that creates a beautiful minimalist architectural dark/light map
class _StylizedRadarMapPainter extends CustomPainter {
  final bool isDark;
  final double pulseValue;

  _StylizedRadarMapPainter({
    required this.isDark,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Base background
    final bgPaint = Paint()
      ..color = isDark ? const Color(0xFF130F1F) : const Color(0xFFEBE5DC);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // Subtle city block polygons
    final blockPaint = Paint()
      ..color = isDark ? const Color(0xFF191429) : const Color(0xFFF3ECE3)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(20, 25, 90, 75),
        const Radius.circular(8),
      ),
      blockPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(130, 20, 110, 60),
        const Radius.circular(8),
      ),
      blockPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(260, 30, 110, 80),
        const Radius.circular(8),
      ),
      blockPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(40, 120, 120, 80),
        const Radius.circular(8),
      ),
      blockPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(180, 100, 160, 95),
        const Radius.circular(8),
      ),
      blockPaint,
    );

    // Architectural Road Network Lines
    final roadPaint = Paint()
      ..color = (isDark ? const Color(0xFF261F3B) : const Color(0xFFDDD5C8))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final secondaryRoadPaint = Paint()
      ..color = (isDark ? const Color(0xFF201A33) : const Color(0xFFE4DDD2))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    // Major Arteries
    final mainRoad1 = Path()
      ..moveTo(0, 50)
      ..cubicTo(w * 0.35, 60, w * 0.65, 30, w, 40);
    canvas.drawPath(mainRoad1, roadPaint);

    final mainRoad2 = Path()
      ..moveTo(0, 155)
      ..cubicTo(w * 0.40, 140, w * 0.70, 175, w, 150);
    canvas.drawPath(mainRoad2, roadPaint);

    final crossRoad = Path()
      ..moveTo(125, 0)
      ..cubicTo(115, h * 0.45, 145, h * 0.75, 135, h);
    canvas.drawPath(crossRoad, roadPaint);

    final crossRoad2 = Path()
      ..moveTo(250, 0)
      ..cubicTo(260, h * 0.50, 240, h * 0.85, 255, h);
    canvas.drawPath(crossRoad2, secondaryRoadPaint);

    // Subtle radar sweep circle in center
    final center = Offset(w * 0.50, h * 0.50);
    final radarRingPaint = Paint()
      ..color = (isDark ? AppColors.luminousMauve : AppColors.mauve)
          .withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(center, 60, radarRingPaint);
    canvas.drawCircle(center, 120, radarRingPaint);

    // Subtle glowing sweep line
    final sweepAngle = pulseValue * 2 * math.pi;
    final sweepEnd = Offset(
      center.dx + 120 * math.cos(sweepAngle),
      center.dy + 120 * math.sin(sweepAngle),
    );
    final sweepPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          (isDark ? AppColors.luminousMauve : AppColors.mauve)
              .withValues(alpha: 0.25),
          Colors.transparent,
        ],
      ).createShader(Rect.fromPoints(center, sweepEnd))
      ..strokeWidth = 1.5;
    canvas.drawLine(center, sweepEnd, sweepPaint);
  }

  @override
  bool shouldRepaint(covariant _StylizedRadarMapPainter oldDelegate) {
    return oldDelegate.isDark != isDark || oldDelegate.pulseValue != pulseValue;
  }
}
