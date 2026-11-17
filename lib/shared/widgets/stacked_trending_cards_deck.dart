import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../models/experience_model.dart';
import 'app_smart_image.dart';
import 'trending_badge.dart';

/// 3D Stacked Trending Cards Deck with Interactive Swiping & Auto-Play
///
/// Features:
/// - Visual 3D card deck with layered cards visible at the bottom
/// - Interactive left/right swipe gestures with natural rotation tilt
/// - Smooth auto-swipe every 4.5 seconds with auto-pause during user touch
/// - Preserves cover photos, "🔥 Trending" badge, page indicator, date, title,
///   and gradient "Join Now →" CTA button
class StackedTrendingCardsDeck extends StatefulWidget {
  final List<ExperienceModel> experiences;
  final ValueChanged<ExperienceModel>? onCardTap;
  final ValueChanged<ExperienceModel>? onJoinTap;
  final Duration autoSwipeDuration;

  const StackedTrendingCardsDeck({
    super.key,
    required this.experiences,
    this.onCardTap,
    this.onJoinTap,
    this.autoSwipeDuration = const Duration(seconds: 5),
  });

  @override
  State<StackedTrendingCardsDeck> createState() =>
      _StackedTrendingCardsDeckState();
}

class _StackedTrendingCardsDeckState extends State<StackedTrendingCardsDeck>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;
  Timer? _autoSwipeTimer;

  late final AnimationController _animController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    _startAutoSwipe();
  }

  @override
  void dispose() {
    _autoSwipeTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _startAutoSwipe() {
    _autoSwipeTimer?.cancel();
    if (widget.experiences.length <= 1) return;

    _autoSwipeTimer = Timer.periodic(widget.autoSwipeDuration, (_) {
      if (!_isDragging && mounted) {
        _autoSwipeNext();
      }
    });
  }

  void _resetAutoSwipe() {
    _startAutoSwipe();
  }

  void _autoSwipeNext() {
    if (widget.experiences.isEmpty || !mounted) return;

    final screenWidth = MediaQuery.of(context).size.width;
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(-screenWidth * 1.05, -15),
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOutCubic,
    ));

    _animController.forward(from: 0.0).then((_) {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % widget.experiences.length;
          _dragOffset = Offset.zero;
        });
        _animController.reset();
      }
    });
  }

  void _handleManualSwipe(bool isNext) {
    if (widget.experiences.isEmpty) return;
    HapticFeedback.lightImpact();

    final screenWidth = MediaQuery.of(context).size.width;
    final targetX = isNext ? -screenWidth * 1.1 : screenWidth * 1.1;

    _slideAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset(targetX, _dragOffset.dy),
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutQuad,
    ));

    _animController.forward(from: 0.0).then((_) {
      if (mounted) {
        setState(() {
          if (isNext) {
            _currentIndex = (_currentIndex + 1) % widget.experiences.length;
          } else {
            _currentIndex = (_currentIndex - 1 + widget.experiences.length) %
                widget.experiences.length;
          }
          _dragOffset = Offset.zero;
          _isDragging = false;
        });
        _animController.reset();
        _resetAutoSwipe();
      }
    });
  }

  void _snapBackToCenter() {
    _slideAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    ));

    _animController.forward(from: 0.0).then((_) {
      if (mounted) {
        setState(() {
          _dragOffset = Offset.zero;
          _isDragging = false;
        });
        _animController.reset();
        _resetAutoSwipe();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.experiences.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = widget.experiences.length;
    const cardHeight = 195.0;
    const totalHeight = 222.0; // Provides room for the stacked bottom cards

    return SizedBox(
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // ── Layer 2: Deepest card (shown if 3+ cards available) ──
          if (total >= 3)
            _buildBackLayerCard(
              index: (_currentIndex + 2) % total,
              topOffset: 18.0,
              horizontalInset: 36.0,
              opacity: 0.55,
              isDark: isDark,
              cardHeight: cardHeight,
            ),

          // ── Layer 1: Middle card (shown if 2+ cards available) ──
          if (total >= 2)
            _buildMiddleLayerCard(
              index: (_currentIndex + 1) % total,
              topOffset: 9.0,
              horizontalInset: 28.0,
              opacity: 0.88,
              isDark: isDark,
              cardHeight: cardHeight,
            ),

          // ── Layer 0: Active Interactive Top Card ──
          _buildActiveTopCard(
            index: _currentIndex % total,
            isDark: isDark,
            cardHeight: cardHeight,
            totalCount: total,
          ),
        ],
      ),
    );
  }

  /// Deepest layer (bottom edge showing beneath middle card)
  Widget _buildBackLayerCard({
    required int index,
    required double topOffset,
    required double horizontalInset,
    required double opacity,
    required bool isDark,
    required double cardHeight,
  }) {
    final exp = widget.experiences[index];
    final progress = (_dragOffset.dx.abs() / 200).clamp(0.0, 1.0);
    final interpolatedTop = topOffset - (progress * 9.0);
    final interpolatedInset = horizontalInset - (progress * 8.0);

    return Positioned(
      top: interpolatedTop,
      left: interpolatedInset,
      right: interpolatedInset,
      height: cardHeight,
      child: Opacity(
        opacity: (opacity + (progress * 0.25)).clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: isDark ? const Color(0xFF1E1530) : const Color(0xFFDED7E8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                AppSmartImage(
                  imagePath: exp.coverImageUrl,
                  categoryHint: exp.categoryName,
                  fit: BoxFit.cover,
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.black : Colors.white)
                        .withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Middle layer (peeks out right behind the active card)
  Widget _buildMiddleLayerCard({
    required int index,
    required double topOffset,
    required double horizontalInset,
    required double opacity,
    required bool isDark,
    required double cardHeight,
  }) {
    final exp = widget.experiences[index];
    final progress = (_dragOffset.dx.abs() / 200).clamp(0.0, 1.0);
    final interpolatedTop = topOffset - (progress * 9.0);
    final interpolatedInset = horizontalInset - (progress * 8.0);

    return Positioned(
      top: interpolatedTop,
      left: interpolatedInset,
      right: interpolatedInset,
      height: cardHeight,
      child: Opacity(
        opacity: (opacity + (progress * 0.12)).clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: isDark ? const Color(0xFF241A3A) : const Color(0xFFEDE8F5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.10),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                AppSmartImage(
                  imagePath: exp.coverImageUrl,
                  categoryHint: exp.categoryName,
                  fit: BoxFit.cover,
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.25),
                        Colors.black.withValues(alpha: 0.60),
                        Colors.black.withValues(alpha: 0.90),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Front Interactive Top Card with Drag Gestures & Full Content
  Widget _buildActiveTopCard({
    required int index,
    required bool isDark,
    required double cardHeight,
    required int totalCount,
  }) {
    final exp = widget.experiences[index];
    final dateFormat = DateFormat('EEE, MMM d • h:mm a');
    final isCoffeeExp =
        exp.id == 'exp-2' || exp.title.toLowerCase().contains('coffee');

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        final currentOffset = _animController.isAnimating
            ? _slideAnimation.value
            : _dragOffset;

        final rotation = (currentOffset.dx / 320.0) * 0.12; // Natural tilt
        final opacity =
            (1.0 - (currentOffset.dx.abs() / 480.0)).clamp(0.0, 1.0);

        return Positioned(
          top: 0,
          left: 20,
          right: 20,
          height: cardHeight,
          child: Transform.translate(
            offset: currentOffset,
            child: Transform.rotate(
              angle: rotation,
              child: Opacity(
                opacity: opacity,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragStart: (_) {
                    _autoSwipeTimer?.cancel();
                    setState(() => _isDragging = true);
                  },
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      _dragOffset += details.delta;
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    final velocity = details.primaryVelocity ?? 0;
                    if (_dragOffset.dx < -70 || velocity < -500) {
                      _handleManualSwipe(true); // Swipe left -> next
                    } else if (_dragOffset.dx > 70 || velocity > 500) {
                      _handleManualSwipe(false); // Swipe right -> prev
                    } else {
                      _snapBackToCenter();
                    }
                  },
                  onHorizontalDragCancel: _snapBackToCenter,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    widget.onCardTap?.call(exp);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: isCoffeeExp
                          ? const LinearGradient(
                              colors: [Color(0xFF293C2F), Color(0xFF152119)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black54
                              : Colors.black.withValues(alpha: 0.16),
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
                          // ── Background Image ──
                          AppSmartImage(
                            imagePath: exp.coverImageUrl,
                            categoryHint: exp.categoryName,
                            fit: BoxFit.cover,
                          ),

                          // ── Dark readability gradient ──
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.20),
                                  Colors.black.withValues(alpha: 0.40),
                                  Colors.black.withValues(alpha: 0.88),
                                ],
                                stops: const [0.0, 0.42, 1.0],
                              ),
                            ),
                          ),

                          // ── Top Bar: Trending Badge & Counter (1/3) ──
                          Positioned(
                            top: 14,
                            left: 14,
                            right: 14,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const TrendingBadge(
                                  fontSize: 10.5,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 9, vertical: 4.5),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.48),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: Colors.white30, width: 0.8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${index + 1}/$totalCount',
                                        style:
                                            AppTypography.labelSmall.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ── Bottom Content: Title, Date & Join CTA ──
                          Positioned(
                            bottom: 14,
                            left: 14,
                            right: 14,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        exp.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style:
                                            AppTypography.titleLarge.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 17.5,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.calendar_today_rounded,
                                            size: 11.5,
                                            color: Colors.white70,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              dateFormat.format(exp.startsAt),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: AppTypography.labelSmall
                                                  .copyWith(
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

                                // "Join Now →" CTA button
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.mediumImpact();
                                    widget.onJoinTap?.call(exp);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      gradient: AppColors.sunsetCtaGradient,
                                      borderRadius: BorderRadius.circular(22),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.vividCoral
                                              .withValues(alpha: 0.45),
                                          blurRadius: 10,
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
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
