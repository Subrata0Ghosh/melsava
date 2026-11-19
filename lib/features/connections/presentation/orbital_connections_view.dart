import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/widgets/app_smart_image.dart';
import 'connections_screen.dart';

/// Orbital Cosmic Connection System inspired by Proxima (Dribbble).
///
/// Visualizes connections revolving around the user in concentric orbits
/// based on shared experiences, mutual intentions, and vibe compatibility.
class OrbitalConnectionsView extends StatefulWidget {
  final List<ConnectionItem> connections;
  final String userAvatarUrl;
  final String userName;

  const OrbitalConnectionsView({
    super.key,
    required this.connections,
    this.userAvatarUrl = 'assets/images/sneha_avatar.png',
    this.userName = 'You',
  });

  @override
  State<OrbitalConnectionsView> createState() => _OrbitalConnectionsViewState();
}

class _OrbitalConnectionsViewState extends State<OrbitalConnectionsView>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  ConnectionItem? _selectedConnection;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();

    if (widget.connections.isNotEmpty) {
      _selectedConnection = widget.connections.first;
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
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

    return Column(
      children: [
        // Orbital Visual Canvas
        SizedBox(
          height: 310,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Orbital Rings & Cosmic Star Background
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _rotationController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _OrbitalRingsPainter(
                        isDark: isDark,
                        rotationAngle: _rotationController.value * 2 * math.pi,
                      ),
                    );
                  },
                ),
              ),

              // Central User Node
              _buildCenterUserNode(isDark),

              // Orbiting Connection Nodes
              ...List.generate(widget.connections.length, (index) {
                final conn = widget.connections[index];
                final isSelected = _selectedConnection?.id == conn.id;

                // Orbit configuration: radii & base angles
                final double orbitRadius = index % 2 == 0 ? 105.0 : 135.0;
                final double baseAngle =
                    (index * (2 * math.pi / widget.connections.length)) -
                    (math.pi / 4);

                return AnimatedBuilder(
                  animation: _rotationController,
                  builder: (context, child) {
                    final currentAngle =
                        baseAngle +
                        (_rotationController.value * 2 * math.pi * 0.15);
                    final dx = orbitRadius * math.cos(currentAngle);
                    final dy =
                        (orbitRadius * 0.65) *
                        math.sin(currentAngle); // slight perspective flattening

                    return Transform.translate(
                      offset: Offset(dx, dy),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedConnection = conn);
                        },
                        child: _buildOrbitNode(conn, isSelected, isDark),
                      ),
                    );
                  },
                );
              }),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Selected Connection Compatibility Card (Proxima Style)
        if (_selectedConnection != null)
          _buildCompatibilityCard(
            _selectedConnection!,
            isDark,
            primaryTextColor,
            mutedTextColor,
          ),
      ],
    );
  }

  Widget _buildCenterUserNode(bool isDark) {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            isDark ? AppColors.luminousMauve : AppColors.mauve,
            AppColors.vividCoral,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? AppColors.luminousMauve : AppColors.mauve)
                .withValues(alpha: 0.45),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(2.5),
      child: ClipOval(
        child: AppSmartImage(
          imagePath: widget.userAvatarUrl,
          isAvatar: true,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildOrbitNode(ConnectionItem conn, bool isSelected, bool isDark) {
    final ringColor = _getBadgeColor(conn.connectionType, isDark);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isSelected ? 52 : 44,
      height: isSelected ? 52 : 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? const Color(0xFF1B1629) : Colors.white,
        border: Border.all(
          color: isSelected ? ringColor : ringColor.withValues(alpha: 0.5),
          width: isSelected ? 2.5 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? ringColor.withValues(alpha: 0.45)
                : Colors.black.withValues(alpha: 0.2),
            blurRadius: isSelected ? 12 : 6,
            spreadRadius: isSelected ? 1 : 0,
          ),
        ],
      ),
      padding: const EdgeInsets.all(2),
      child: ClipOval(
        child: AppSmartImage(
          imagePath: conn.avatarUrl,
          isAvatar: true,
          nameHint: conn.name,
          fit: BoxFit.cover,
          placeholder: Container(
            color: isDark ? AppColors.darkElevated : AppColors.sage,
          ),
        ),
      ),
    );
  }

  Widget _buildCompatibilityCard(
    ConnectionItem conn,
    bool isDark,
    Color primaryTextColor,
    Color mutedTextColor,
  ) {
    final badgeColor = _getBadgeColor(conn.connectionType, isDark);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.divider,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.35)
                : AppColors.deepPlum.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Connection Header: Avatar, Name, Mutual Badge
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: badgeColor, width: 2),
                ),
                padding: const EdgeInsets.all(2),
                child: ClipOval(
                  child: AppSmartImage(
                    imagePath: conn.avatarUrl,
                    isAvatar: true,
                    nameHint: conn.name,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          conn.name,
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: primaryTextColor,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.verified_rounded,
                          size: 16,
                          color: isDark
                              ? AppColors.luminousMauve
                              : AppColors.mauve,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Connected via ${conn.experienceName}',
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.35)),
                ),
                child: Text(
                  conn.connectionType,
                  style: AppTypography.labelSmall.copyWith(
                    color: badgeColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Proxima-style Compatibility Breakdown Bars
          Text(
            'ORBIT COMPATIBILITY MATRIX',
            style: AppTypography.labelSmall.copyWith(
              letterSpacing: 1.5,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.softCoral : AppColors.mauve,
            ),
          ),
          const SizedBox(height: 10),

          _buildProgressBar(
            label: 'Social Harmony',
            percent: 0.94,
            barColor: isDark ? AppColors.luminousMauve : AppColors.mauve,
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _buildProgressBar(
            label: 'Values & Intellect',
            percent: 0.88,
            barColor: AppColors.softCoral,
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _buildProgressBar(
            label: 'Activity Chemistry',
            percent: 0.92,
            barColor: AppColors.mintAccent,
            isDark: isDark,
          ),

          const SizedBox(height: 16),

          // Action Row
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? AppColors.luminousMauve
                        : AppColors.deepPlum,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    context.push(
                      '/chat/${_selectedConnection!.name}',
                      extra: {
                        'connectionId': _selectedConnection!.id,
                        'conversationId': _selectedConnection!.conversationId,
                        'partnerId': _selectedConnection!.partnerId,
                        'partnerAvatar': _selectedConnection!.avatarUrl,
                      },
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                  label: const Text(
                    'Open Private Chat',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar({
    required String label,
    required double percent,
    required Color barColor,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                fontSize: 11,
                color: isDark ? AppColors.darkMutedText : AppColors.mutedText,
              ),
            ),
            Text(
              '${(percent * 100).toInt()}%',
              style: AppTypography.labelSmall.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 11,
                color: barColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 5,
            backgroundColor: isDark
                ? const Color(0xFF241D35)
                : const Color(0xFFEBE5DC),
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
      ],
    );
  }

  Color _getBadgeColor(String type, bool isDark) {
    switch (type.toLowerCase()) {
      case 'exploring dating':
      case 'dating':
        return isDark ? AppColors.vividCoral : AppColors.softCoral;
      case 'friendship':
        return isDark ? AppColors.luminousMauve : AppColors.mauve;
      case 'activity partner':
        return AppColors.mintAccent;
      default:
        return isDark ? AppColors.luminousMauve : AppColors.mauve;
    }
  }
}

/// Custom painter for the cosmic orbit rings
class _OrbitalRingsPainter extends CustomPainter {
  final bool isDark;
  final double rotationAngle;

  _OrbitalRingsPainter({required this.isDark, required this.rotationAngle});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.50, size.height * 0.50);

    // Orbit Ring 1 (Inner)
    final ring1Paint = Paint()
      ..color = (isDark ? AppColors.luminousMauve : AppColors.mauve).withValues(
        alpha: isDark ? 0.22 : 0.15,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Draw elliptical orbits for 3D perspective
    final rect1 = Rect.fromCenter(center: center, width: 210, height: 140);
    canvas.drawOval(rect1, ring1Paint);

    // Orbit Ring 2 (Outer)
    final ring2Paint = Paint()
      ..color = (isDark ? AppColors.softCoral : AppColors.mauve).withValues(
        alpha: isDark ? 0.18 : 0.12,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final rect2 = Rect.fromCenter(center: center, width: 275, height: 185);
    canvas.drawOval(rect2, ring2Paint);

    // Micro stars / constellation specks
    final starPaint = Paint()
      ..color = (isDark ? Colors.white : AppColors.mauve).withValues(
        alpha: isDark ? 0.35 : 0.18,
      )
      ..style = PaintingStyle.fill;

    // Fixed background constellation coordinates
    final stars = [
      Offset(center.dx - 110, center.dy - 70),
      Offset(center.dx + 120, center.dy - 60),
      Offset(center.dx - 80, center.dy + 80),
      Offset(center.dx + 90, center.dy + 75),
      Offset(center.dx + 40, center.dy - 95),
      Offset(center.dx - 60, center.dy - 90),
    ];

    for (final s in stars) {
      canvas.drawCircle(s, 1.4, starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitalRingsPainter oldDelegate) {
    return oldDelegate.isDark != isDark ||
        oldDelegate.rotationAngle != rotationAngle;
  }
}
