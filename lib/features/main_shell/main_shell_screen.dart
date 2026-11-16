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
    final allExp = ref.read(experiencesRepositoryProvider).getExperiences();
    final activeExp = allExp.firstWhere(
      (e) => e.hasJoined || e.isCompleted,
      orElse: () => allExp.first,
    );

    ExperienceHubSheet.show(
      context,
      experience: activeExp,
    );
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
          left: 16,
          right: 16,
          bottom: bottomInset > 0 ? 4 : 14,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(34),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, 6),
                spreadRadius: 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(34),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF161224).withValues(alpha: 0.90)
                      : Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(34),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.white.withValues(alpha: 0.85),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Tab 0: Home / Discover
                    _buildNavItem(
                      branchIndex: 0,
                      currentIndex: currentIndex,
                      label: 'Home',
                      icon: Icons.home_outlined,
                      activeIcon: Icons.home_rounded,
                      isDark: isDark,
                    ),

                    // Tab 1: Discover / Experiences
                    _buildNavItem(
                      branchIndex: 1,
                      currentIndex: currentIndex,
                      label: 'Discover',
                      icon: Icons.explore_outlined,
                      activeIcon: Icons.explore_rounded,
                      isDark: isDark,
                    ),

                    // Center (+) Elevated Action Button
                    GestureDetector(
                      onTap: () => _openQuickAction(context, ref),
                      child: Container(
                        width: 44,
                        height: 44,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          gradient: AppColors.purpleGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryPurple.withValues(alpha: 0.45),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),

                    // Tab 2: Connections
                    _buildNavItem(
                      branchIndex: 2,
                      currentIndex: currentIndex,
                      label: 'Connections',
                      icon: Icons.people_outline_rounded,
                      activeIcon: Icons.people_rounded,
                      isDark: isDark,
                    ),

                    // Tab 4: Profile
                    _buildNavItem(
                      branchIndex: 4,
                      currentIndex: currentIndex,
                      label: 'Profile',
                      icon: Icons.person_outline_rounded,
                      activeIcon: Icons.person_rounded,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int branchIndex,
    required int currentIndex,
    required String label,
    required IconData icon,
    required IconData activeIcon,
    required bool isDark,
  }) {
    // If currentIndex is 3 (Inbox), highlight Connections as closest category
    final isSelected = branchIndex == currentIndex ||
        (branchIndex == 2 && currentIndex == 3);

    final activeColor = isDark ? AppColors.brightViolet : AppColors.primaryPurple;
    final inactiveColor = isDark ? AppColors.darkMutedText : AppColors.mutedText;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onBranchTap(branchIndex),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.12 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              child: Icon(
                isSelected ? activeIcon : icon,
                size: 22,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              style: AppTypography.labelSmall.copyWith(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
