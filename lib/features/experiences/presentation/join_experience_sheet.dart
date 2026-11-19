import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/models/experience_model.dart';
import '../../../shared/widgets/app_smart_image.dart';
import '../../../shared/widgets/botanical_leaf_decoration.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/experiences_repository.dart';

/// Join / Waitlist Confirmation Bottom Sheet
///
/// Preserves the MELSAVA watercolor ambient gradient, botanical foliage accents,
/// and rounded summary card while executing real server-side atomic joining:
/// - Displays the selected experience and live capacity status clearly
/// - Relies on the user's saved profile intentions (never defaults to Dating)
/// - Prevents duplicate taps while submitting
/// - Shows success only after Supabase confirms Joined or Waitlisted status
/// - Displays a clear error and Retry action on failure
class JoinExperienceSheet extends ConsumerStatefulWidget {
  final ExperienceModel experience;
  final Future<JoinExperienceResult> Function() onConfirmJoin;

  const JoinExperienceSheet({
    super.key,
    required this.experience,
    required this.onConfirmJoin,
  });

  static Future<JoinExperienceResult?> show(
    BuildContext context, {
    required ExperienceModel experience,
    required Future<JoinExperienceResult> Function() onConfirmJoin,
  }) {
    return showModalBottomSheet<JoinExperienceResult>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => JoinExperienceSheet(
        experience: experience,
        onConfirmJoin: onConfirmJoin,
      ),
    );
  }

  @override
  ConsumerState<JoinExperienceSheet> createState() =>
      _JoinExperienceSheetState();
}

class _JoinExperienceSheetState extends ConsumerState<JoinExperienceSheet> {
  bool _isSubmitting = false;
  JoinExperienceResult? _result;
  String? _errorMessage;

  Future<void> _handleConfirm() async {
    if (_isSubmitting) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final res = await widget.onConfirmJoin();
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _result = res;
      });
    } catch (e) {
      if (!mounted) return;
      final cleanMsg = e.toString().replaceAll('Exception: ', '').trim();
      setState(() {
        _isSubmitting = false;
        _errorMessage = cleanMsg.isNotEmpty
            ? cleanMsg
            : 'We couldn\'t complete that action. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final exp = widget.experience;
    final user = ref.watch(currentUserProvider);
    final dateFormat = DateFormat('EEE, MMM d • h:mm a');

    final primaryTextColor = isDark
        ? AppColors.darkTextPrimary
        : const Color(0xFF1E1435);
    final mutedTextColor = isDark
        ? AppColors.darkMutedText
        : const Color(0xFF7E7394);
    final cardBg = isDark ? const Color(0xFF1F1A2C) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF332A45)
        : const Color(0xFFEDE9FE);

    final isWaitlistAction = exp.isFull;
    final locationLabel = exp.isOnline
        ? 'Online Experience'
        : (exp.venueName.isNotEmpty
              ? '${exp.venueName}${exp.city.isNotEmpty ? ' · ${exp.city}' : ''}'
              : (exp.city.isNotEmpty ? exp.city : 'Public Venue'));

    final savedIntentions = <String>[
      if (user?.primaryIntent != null && user!.primaryIntent!.isNotEmpty)
        user.primaryIntent!,
      ...(user?.secondaryIntents ?? const <String>[]),
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF140F21) : const Color(0xFFFAF7FF),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 36,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: Stack(
          children: [
            // Ambient Watercolor Gradient Glow
            Positioned(
              top: -40,
              left: -40,
              width: 220,
              height: 220,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(
                        0xFF7DD3FC,
                      ).withValues(alpha: isDark ? 0.15 : 0.28),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: -30,
              right: -30,
              width: 240,
              height: 240,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(
                        0xFFFDE047,
                      ).withValues(alpha: isDark ? 0.12 : 0.30),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 80,
              left: 40,
              width: 280,
              height: 280,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(
                        0xFFDDD6FE,
                      ).withValues(alpha: isDark ? 0.10 : 0.35),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Botanical foliage accents peeking from borders
            const Positioned(
              top: 10,
              left: -12,
              child: BotanicalLeafDecoration(
                style: BotanicalLeafStyle.tropicalFoliage,
                width: 58,
                height: 100,
                rotation: 0.15,
                opacity: 0.88,
              ),
            ),
            const Positioned(
              top: 15,
              right: -10,
              child: BotanicalLeafDecoration(
                style: BotanicalLeafStyle.tropicalFoliage,
                width: 50,
                height: 85,
                rotation: -0.25,
                opacity: 0.75,
              ),
            ),
            const Positioned(
              top: 220,
              right: -16,
              child: BotanicalLeafDecoration(
                style: BotanicalLeafStyle.monstera,
                width: 60,
                height: 105,
                rotation: -0.20,
                opacity: 0.90,
              ),
            ),

            // Content
            if (_result != null)
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  child: _buildResultView(
                    isDark,
                    exp,
                    _result!,
                    primaryTextColor,
                    mutedTextColor,
                  ),
                ),
              )
            else
              SafeArea(
                top: false,
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top drag pill
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: 2, bottom: 8),
                          width: 44,
                          height: 4.5,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white24
                                : const Color(0xFFDDD6FE),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),

                      // Top Bar with back arrow & title
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.arrow_back_rounded,
                              color: primaryTextColor,
                              size: 24,
                            ),
                            onPressed: _isSubmitting
                                ? null
                                : () => Navigator.of(context).pop(),
                          ),
                          Expanded(
                            child: Text(
                              isWaitlistAction
                                  ? 'Join Waitlist'
                                  : 'Join Experience',
                              textAlign: TextAlign.center,
                              style: AppTypography.titleLarge.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 18.5,
                                color: primaryTextColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Mini Event Summary Card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: borderColor),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.28 : 0.05,
                              ),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: SizedBox(
                                width: 68,
                                height: 68,
                                child: AppSmartImage(
                                  imagePath: exp.coverImageUrl,
                                  categoryHint:
                                      '${exp.title} ${exp.categoryName}',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    exp.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.titleMedium.copyWith(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: primaryTextColor,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today_rounded,
                                        size: 13,
                                        color: isDark
                                            ? AppColors.luminousMauve
                                            : AppColors.mauve,
                                      ),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: Text(
                                          dateFormat.format(exp.startsAt),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTypography.bodySmall
                                              .copyWith(
                                                color: mutedTextColor,
                                                fontSize: 12,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      Icon(
                                        exp.isOnline
                                            ? Icons.videocam_outlined
                                            : Icons.place_rounded,
                                        size: 13.5,
                                        color: isDark
                                            ? AppColors.brightViolet
                                            : AppColors.primaryPurple,
                                      ),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: Text(
                                          locationLabel,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTypography.bodySmall
                                              .copyWith(
                                                color: isDark
                                                    ? AppColors.brightViolet
                                                    : AppColors.primaryPurple,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Live Capacity & Status Info Card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color:
                              (isWaitlistAction
                                      ? AppColors.softCoral
                                      : AppColors.sage)
                                  .withValues(alpha: isDark ? 0.16 : 0.42),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              isWaitlistAction
                                  ? Icons.hourglass_top_rounded
                                  : Icons.people_outline_rounded,
                              size: 20,
                              color: isWaitlistAction
                                  ? (isDark
                                        ? AppColors.softCoral
                                        : const Color(0xFFB45309))
                                  : (isDark
                                        ? AppColors.luminousMauve
                                        : AppColors.deepPlum),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isWaitlistAction
                                        ? 'Currently Full — Waitlist Open'
                                        : (exp.hasUnlimitedCapacity
                                              ? '${exp.currentParticipants} joined · Open spots available'
                                              : '${exp.spotsLeft} ${exp.spotsLeft == 1 ? 'spot' : 'spots'} available (${exp.currentParticipants}/${exp.maxParticipants})'),
                                    style: AppTypography.titleSmall.copyWith(
                                      color: primaryTextColor,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    isWaitlistAction
                                        ? 'We\'ll place you in the FIFO waitlist queue and promote you automatically if a spot opens up.'
                                        : 'Your spot is confirmed directly with the server and you can cancel anytime from My Circles.',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: mutedTextColor,
                                      fontSize: 12,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Read-only summary of user's saved profile intentions (never defaults to Dating)
                      if (savedIntentions.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Using your saved profile intentions',
                          style: AppTypography.labelMedium.copyWith(
                            color: mutedTextColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: savedIntentions.map((intent) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: borderColor),
                              ),
                              child: Text(
                                intent,
                                style: AppTypography.labelSmall.copyWith(
                                  color: primaryTextColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],

                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.40),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: AppColors.error,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Confirm Join / Waitlist / Retry CTA Button
                      GestureDetector(
                        onTap: _isSubmitting ? null : _handleConfirm,
                        child: Container(
                          height: 54,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: AppColors.sunsetCtaGradient,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFFFF5A78,
                                ).withValues(alpha: 0.38),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _errorMessage != null
                                          ? 'Try Again'
                                          : (isWaitlistAction
                                                ? 'Confirm Waitlist'
                                                : 'Confirm Join'),
                                      style: AppTypography.labelLarge.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Colors.white,
                                      size: 19,
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          exp.cancellationPolicy != null &&
                                  exp.cancellationPolicy!.isNotEmpty
                              ? exp.cancellationPolicy!
                              : 'You can cancel your reservation anytime in My Circles.',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmall.copyWith(
                            color: mutedTextColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultView(
    bool isDark,
    ExperienceModel exp,
    JoinExperienceResult result,
    Color primaryTextColor,
    Color mutedTextColor,
  ) {
    final isWaitlisted = result.isWaitlisted;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isWaitlisted
                  ? const LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFEA580C)],
                    )
                  : AppColors.purpleGradient,
              boxShadow: [
                BoxShadow(
                  color:
                      (isWaitlisted
                              ? const Color(0xFFF59E0B)
                              : AppColors.primaryPurple)
                          .withValues(alpha: 0.40),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              isWaitlisted ? Icons.hourglass_top_rounded : Icons.check_rounded,
              color: Colors.white,
              size: 44,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            result.userMessage,
            textAlign: TextAlign.center,
            style: AppTypography.headlineMedium.copyWith(
              color: primaryTextColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isWaitlisted
                ? 'We\'ve added you to the waitlist for "${exp.title}". If a spot opens, you\'ll be promoted automatically in order.'
                : 'Your spot for "${exp.title}" is confirmed. Manage your reservation anytime in My Circles.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: mutedTextColor,
              fontSize: 14,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(result),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? AppColors.luminousMauve
                    : AppColors.deepPlum,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
              child: const Text(
                'Done',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
