import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../experiences/presentation/experience_hub_sheet.dart';
import '../experiences/data/experiences_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MainShellScreen extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainShellScreen({super.key, required this.navigationShell});

  void _onBranchTap(int branchIndex) {
    if (branchIndex != navigationShell.currentIndex) {
      HapticFeedback.lightImpact();
      navigationShell.goBranch(
        branchIndex,
        initialLocation: branchIndex == navigationShell.currentIndex,
      );
    }
  }

  void _openQuickAction(BuildContext context, WidgetRef ref) {
    HapticFeedback.mediumImpact();
    final myBundle = ref.read(myExperiencesProvider).valueOrNull;
    final activeExp =
        myBundle?.upcoming.firstOrNull ??
        myBundle?.waitlisted.firstOrNull ??
        ref.read(publishedExperiencesProvider).valueOrNull?.firstOrNull;

    if (activeExp != null) {
      ExperienceHubSheet.show(context, experience: activeExp);
    } else {
      context.go('/experiences');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentIndex = navigationShell.currentIndex;

    return Scaffold(
      extendBody: true, // Content flows behind floating glass navbar
      body: navigationShell,
      bottomNavigationBar: _buildGlassmorphicNavBar(
        context,
        ref,
        isDark,
        currentIndex,
      ),
    );
  }

  Widget _buildGlassmorphicNavBar(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    int currentIndex,
  ) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 14,
          right: 14,
          bottom: bottomInset > 0 ? 4 : 14,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(36),
            boxShadow: [
              // 1. Warm Gold Ambient Halo Shadow
              BoxShadow(
                color: const Color(
                  0xFFF59E0B,
                ).withValues(alpha: isDark ? 0.22 : 0.16),
                blurRadius: 28,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
              // 2. Radiant Royal Violet/Magenta Aura
              BoxShadow(
                color: const Color(
                  0xFF8B5CF6,
                ).withValues(alpha: isDark ? 0.28 : 0.14),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
              // 3. Grounding Subtle Drop Shadow
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          // ── Rotating Iridescent Gradient Border Outer Rim ──
          child: _RotatingBorderNavBar(
            isDark: isDark,
            strokeWidth: 0.95, // Thinner, sleek 0.95px metallic border
            child: ClipRRect(
              borderRadius: BorderRadius.circular(33),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                child: Container(
                  height: 66,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF151024).withValues(alpha: 0.82)
                        : const Color(0xFFFCFAFF).withValues(alpha: 0.84),
                    borderRadius: BorderRadius.circular(33),
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withValues(
                          alpha: isDark ? 0.20 : 0.70,
                        ),
                        width: 0.6,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Tab 0: Home / Discover
                      _AnimatedNavTabItem(
                        branchIndex: 0,
                        currentIndex: currentIndex,
                        label: 'Home',
                        icon: Icons.home_outlined,
                        activeIcon: Icons.home_rounded,
                        isDark: isDark,
                        onTap: _onBranchTap,
                      ),

                      // Tab 1: Discover / Experiences
                      _AnimatedNavTabItem(
                        branchIndex: 1,
                        currentIndex: currentIndex,
                        label: 'Discover',
                        icon: Icons.explore_outlined,
                        activeIcon: Icons.explore_rounded,
                        isDark: isDark,
                        onTap: _onBranchTap,
                      ),

                      // Center (+) 3D Jewel Floating Action Button
                      _JewelActionButton(
                        onTap: () => _openQuickAction(context, ref),
                      ),

                      // Tab 2: Connections
                      _AnimatedNavTabItem(
                        branchIndex: 2,
                        currentIndex: currentIndex,
                        label: 'Connections',
                        icon: Icons.people_outline_rounded,
                        activeIcon: Icons.people_rounded,
                        isDark: isDark,
                        onTap: _onBranchTap,
                      ),

                      // Tab 4: Profile
                      _AnimatedNavTabItem(
                        branchIndex: 4,
                        currentIndex: currentIndex,
                        label: 'Profile',
                        icon: Icons.person_outline_rounded,
                        activeIcon: Icons.person_rounded,
                        isDark: isDark,
                        onTap: _onBranchTap,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedNavTabItem extends StatefulWidget {
  final int branchIndex;
  final int currentIndex;
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool isDark;
  final ValueChanged<int> onTap;

  const _AnimatedNavTabItem({
    required this.branchIndex,
    required this.currentIndex,
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_AnimatedNavTabItem> createState() => _AnimatedNavTabItemState();
}

class _AnimatedNavTabItemState extends State<_AnimatedNavTabItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    // If currentIndex is 3 (Inbox), highlight Connections as closest category
    final isSelected =
        widget.branchIndex == widget.currentIndex ||
        (widget.branchIndex == 2 && widget.currentIndex == 3);

    final activeColor = widget.isDark
        ? AppColors.brightViolet
        : AppColors.primaryPurple;
    final inactiveColor = widget.isDark
        ? const Color(0xFF9A91B0)
        : const Color(0xFF7E7394);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: () => widget.onTap(widget.branchIndex),
        child: AnimatedScale(
          scale: _isPressed ? 0.92 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  (widget.isDark
                          ? const Color(0xFF8B5CF6)
                          : const Color(0xFF7C3AED))
                      .withValues(
                        alpha: isSelected ? (widget.isDark ? 0.22 : 0.12) : 0.0,
                      ),
                  (widget.isDark
                          ? const Color(0xFFC026D3)
                          : const Color(0xFFEC4899))
                      .withValues(
                        alpha: isSelected ? (widget.isDark ? 0.12 : 0.05) : 0.0,
                      ),
                ],
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color:
                            (widget.isDark
                                    ? const Color(0xFF8B5CF6)
                                    : const Color(0xFF7C3AED))
                                .withValues(alpha: widget.isDark ? 0.25 : 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : const [],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Floating & Scaling Icon with Crossfade Morph
                AnimatedSlide(
                  offset: isSelected ? const Offset(0, -0.08) : Offset.zero,
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutBack,
                  child: AnimatedScale(
                    scale: isSelected ? 1.14 : 1.0,
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutBack,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: Tween<double>(
                              begin: 0.85,
                              end: 1.0,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: Icon(
                        isSelected ? widget.activeIcon : widget.icon,
                        key: ValueKey<bool>(isSelected),
                        size: 21,
                        color: isSelected ? activeColor : inactiveColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                // Smooth Text Styling
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  style: AppTypography.labelSmall.copyWith(
                    fontSize: 10.5,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                    letterSpacing: isSelected ? -0.1 : 0.0,
                    color: isSelected ? activeColor : inactiveColor,
                  ),
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 3),
                // Smoothly Expanding Active Indicator Capsule
                AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  width: isSelected ? 14 : 0,
                  height: 3,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF8B5CF6), // Royal Violet
                        Color(0xFFF59E0B), // Warm Amber Sparkle
                      ],
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(
                                0xFFF59E0B,
                              ).withValues(alpha: 0.65),
                              blurRadius: 5,
                              offset: const Offset(0, 1),
                            ),
                            BoxShadow(
                              color: const Color(
                                0xFF8B5CF6,
                              ).withValues(alpha: 0.50),
                              blurRadius: 4,
                            ),
                          ]
                        : const [],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _JewelActionButton extends StatefulWidget {
  final VoidCallback onTap;
  const _JewelActionButton({required this.onTap});

  @override
  State<_JewelActionButton> createState() => _JewelActionButtonState();
}

class _JewelActionButtonState extends State<_JewelActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.90 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutBack,
        child: Container(
          width: 46,
          height: 46,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFFFE082), // Champagne Gold Rim
              width: 1.6,
            ),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF9333EA), Color(0xFFC026D3), Color(0xFFFF5E7E)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF5E7E).withValues(alpha: 0.48),
                blurRadius: 14,
                offset: const Offset(0, 3),
              ),
              BoxShadow(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.36),
                blurRadius: 8,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Top Specular Glass Sheen
              Positioned(
                top: 2,
                child: Container(
                  width: 26,
                  height: 12,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.55),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              const Icon(Icons.add_rounded, color: Colors.white, size: 26),
            ],
          ),
        ),
      ),
    );
  }
}

/// Animated rotating gradient outer border that smoothly orbits the pill perimeter
class _RotatingBorderNavBar extends StatefulWidget {
  final Widget child;
  final bool isDark;
  final double strokeWidth;

  const _RotatingBorderNavBar({
    required this.child,
    required this.isDark,
    this.strokeWidth = 0.95,
  });

  @override
  State<_RotatingBorderNavBar> createState() => _RotatingBorderNavBarState();
}

class _RotatingBorderNavBarState extends State<_RotatingBorderNavBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    // Continuous perpetual 8-second rotation around the navbar rim
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        return CustomPaint(
          foregroundPainter: _RotatingGradientBorderPainter(
            animationValue: _rotationController.value,
            isDark: widget.isDark,
            strokeWidth: widget.strokeWidth,
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _RotatingGradientBorderPainter extends CustomPainter {
  final double animationValue;
  final bool isDark;
  final double strokeWidth;

  const _RotatingGradientBorderPainter({
    required this.animationValue,
    required this.isDark,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final rect = Offset.zero & size;
    final radius = Radius.circular(size.height / 2);
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(strokeWidth / 2),
      radius,
    );

    final angle = animationValue * 2 * math.pi;

    // Prismatic iridescent palette seamlessly looped (starts and ends on the same color)
    final colors = isDark
        ? const [
            Color(0xFFFFDF73), // Champagne Gold
            Color(0xFFFF80BF), // Rose Shimmer
            Color(0xFFA855F7), // Royal Violet
            Color(0xFF38BDF8), // Cyan Glint
            Color(0xFFFBBF24), // Warm Amber Gold
            Color(0xFFFFDF73), // Seamless loop back to Champagne Gold
          ]
        : const [
            Color(0xFFEAB308), // Rich Gold
            Color(0xFFFF6584), // Coral Rose
            Color(0xFF8B5CF6), // Royal Violet
            Color(0xFF38BDF8), // Cyan Glint
            Color(0xFFF59E0B), // Amber Gold
            Color(0xFFEAB308), // Seamless loop back to Rich Gold
          ];

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = SweepGradient(
        colors: colors,
        transform: GradientRotation(angle),
      ).createShader(rect);

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool? hitTest(Offset position) => false;

  @override
  bool shouldRepaint(covariant _RotatingGradientBorderPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.isDark != isDark ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
