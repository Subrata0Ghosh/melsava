import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/models/experience_model.dart';
import '../../../shared/widgets/app_smart_image.dart';
import '../../../shared/widgets/mutual_match_celebration_dialog.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/post_experience_repository.dart';

/// Post-Experience Reconnect Screen (Screen 4 real companion flow)
///
/// Enables confirmed attendees to privately select who they enjoyed meeting
/// and with what compatible intention (Friendship, Activity Partner, Explore Dating,
/// or No Connection).
///
/// Fully server-backed via atomic Supabase RPCs with exact intention matching.
class PostExperienceChoiceScreen extends ConsumerStatefulWidget {
  final ExperienceModel experience;

  const PostExperienceChoiceScreen({super.key, required this.experience});

  static Future<void> show(BuildContext context, ExperienceModel experience) {
    HapticFeedback.mediumImpact();
    return Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) =>
            PostExperienceChoiceScreen(experience: experience),
      ),
    );
  }

  @override
  ConsumerState<PostExperienceChoiceScreen> createState() =>
      _PostExperienceChoiceScreenState();
}

class _PostExperienceChoiceScreenState
    extends ConsumerState<PostExperienceChoiceScreen> {
  final Map<String, ReconnectChoiceType> _selectedChoices = {};
  bool _isSubmitting = false;
  String? _errorMessage;

  ReconnectChoiceType _getChoiceFor(String userId) {
    return _selectedChoices[userId] ?? ReconnectChoiceType.noConnection;
  }

  void _setChoiceFor(String userId, ReconnectChoiceType type) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedChoices[userId] = type;
    });
  }

  Future<void> _handleConfirmAndSubmit(List<EligibleAttendee> attendees) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.deepPlum;
    final mutedTextColor = isDark
        ? AppColors.darkMutedText
        : AppColors.mutedText;

    // Build choice inputs for all attendees (defaulting to noConnection)
    final choiceInputs = attendees.map((a) {
      return PostExperienceChoiceInput(
        chosenId: a.id,
        choiceType: _getChoiceFor(a.id),
      );
    }).toList();

    final positiveCount = choiceInputs
        .where((c) => c.choiceType != ReconnectChoiceType.noConnection)
        .length;

    // Show confirmation review sheet
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBorder : AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Confirm Private Choices',
                style: AppTypography.headlineSmall.copyWith(
                  color: primaryTextColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You have selected $positiveCount connection intention(s) across ${attendees.length} attendee(s).',
                style: AppTypography.bodyMedium.copyWith(
                  color: mutedTextColor,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color:
                      (isDark
                              ? AppColors.brightViolet
                              : AppColors.primaryPurple)
                          .withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        (isDark
                                ? AppColors.brightViolet
                                : AppColors.primaryPurple)
                            .withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 20,
                      color: isDark
                          ? AppColors.luminousMauve
                          : AppColors.primaryPurple,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your choices are 100% confidential. No participant is ever notified of a rejection or one-sided choice.',
                        style: AppTypography.bodySmall.copyWith(
                          color: primaryTextColor,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Confirm & Submit Privately',
                backgroundColor: isDark
                    ? AppColors.brightViolet
                    : AppColors.primaryPurple,
                onPressed: () => Navigator.of(ctx).pop(true),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(
                  'Review Again',
                  style: TextStyle(
                    color: mutedTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final controller = ref.read(postExperienceActionControllerProvider);
      final result = await controller.submitChoices(
        experienceId: widget.experience.id,
        choices: choiceInputs,
      );

      if (!mounted) return;

      setState(() => _isSubmitting = false);

      final currentUser = ref.read(currentUserProvider);

      if (result.hasMutualMatch) {
        // Show celebration dialog for the first mutual connection
        final firstMatch = result.mutualConnections.first;
        await MutualMatchCelebrationDialog.show(
          context,
          userName: currentUser?.displayName ?? 'You',
          userAvatarUrl: currentUser?.avatarUrl ?? '',
          matchName: firstMatch.partnerName,
          matchAvatarUrl: firstMatch.partnerAvatar,
          mutualIntention: firstMatch.connectionTypeLabel,
          experienceTitle: firstMatch.experienceTitle,
        );

        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        // Show successful private submission dialog
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.cardRadiusLarge),
            ),
            title: Text(
              'Choices Submitted Privately',
              style: AppTypography.headlineSmall.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.deepPlum,
                fontWeight: FontWeight.w800,
              ),
            ),
            content: Text(
              'Your choices have been submitted privately. When another person\'s choice is mutual and compatible, you\'ll be notified.',
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? AppColors.darkMutedText : AppColors.mutedText,
                height: 1.5,
              ),
            ),
            actions: [
              PrimaryButton(
                label: 'Back to My Circles',
                height: 44,
                backgroundColor: isDark
                    ? AppColors.brightViolet
                    : AppColors.primaryPurple,
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage =
            'We couldn\'t submit your choices. Please check your connection and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final exp = widget.experience;

    final primaryTextColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.deepPlum;
    final mutedTextColor = isDark
        ? AppColors.darkMutedText
        : AppColors.mutedText;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.divider;

    final statusAsync = ref.watch(reconnectSubmissionStatusProvider(exp.id));
    final attendeesAsync = ref.watch(eligibleAttendeesProvider(exp.id));

    return Scaffold(
      backgroundColor: isDark ? AppColors.obsidian : AppColors.warmIvory,
      appBar: AppBar(
        title: Text(
          'Post-Experience Reconnect',
          style: AppTypography.titleLarge.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: primaryTextColor,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: primaryTextColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: statusAsync.when(
          loading: () => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: isDark
                      ? AppColors.brightViolet
                      : AppColors.primaryPurple,
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading your experience participants...',
                  style: AppTypography.bodyMedium.copyWith(
                    color: mutedTextColor,
                  ),
                ),
              ],
            ),
          ),
          error: (err, _) => _buildErrorScreen(
            'Unable to load reconnect status. Please try again.',
            onRetry: () =>
                ref.invalidate(reconnectSubmissionStatusProvider(exp.id)),
            isDark: isDark,
            primaryTextColor: primaryTextColor,
            mutedTextColor: mutedTextColor,
          ),
          data: (status) {
            // State: Experience not completed
            if (!status.isCompleted) {
              return _buildInfoScreen(
                icon: Icons.event_available_rounded,
                iconColor: const Color(0xFFF59E0B),
                title: 'Experience Not Completed',
                message:
                    'Reconnect choices will become available after the experience is completed.',
                actionLabel: 'Back to My Circles',
                onAction: () => Navigator.of(context).pop(),
                isDark: isDark,
                primaryTextColor: primaryTextColor,
                mutedTextColor: mutedTextColor,
              );
            }

            // State: User did not attend
            if (!status.isAttended) {
              return _buildInfoScreen(
                icon: Icons.lock_outline_rounded,
                iconColor: const Color(0xFFEF4444),
                title: 'Not Eligible',
                message:
                    'This reconnect activity is available only to confirmed attendees.',
                actionLabel: 'Back to My Circles',
                onAction: () => Navigator.of(context).pop(),
                isDark: isDark,
                primaryTextColor: primaryTextColor,
                mutedTextColor: mutedTextColor,
              );
            }

            // State: Already submitted
            if (status.isSubmitted) {
              return _buildInfoScreen(
                icon: Icons.check_circle_outline_rounded,
                iconColor: const Color(0xFF10B981),
                title: 'Choices Already Submitted',
                message:
                    'Your choices for this experience have already been submitted.',
                actionLabel: 'View Connections',
                onAction: () {
                  Navigator.of(context).pop();
                  context.go('/connections');
                },
                isDark: isDark,
                primaryTextColor: primaryTextColor,
                mutedTextColor: mutedTextColor,
              );
            }

            // Active State: Load and display eligible attendees
            return attendeesAsync.when(
              loading: () => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: isDark
                          ? AppColors.brightViolet
                          : AppColors.primaryPurple,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading your experience participants...',
                      style: AppTypography.bodyMedium.copyWith(
                        color: mutedTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              error: (err, _) => _buildErrorScreen(
                'Unable to load participants. Please try again.',
                onRetry: () =>
                    ref.invalidate(eligibleAttendeesProvider(exp.id)),
                isDark: isDark,
                primaryTextColor: primaryTextColor,
                mutedTextColor: mutedTextColor,
              ),
              data: (attendees) {
                if (attendees.isEmpty) {
                  return _buildInfoScreen(
                    icon: Icons.people_outline_rounded,
                    iconColor: mutedTextColor,
                    title: 'No Other Attendees',
                    message:
                        'You attended this experience, but there are no other eligible participants to reconnect with.',
                    actionLabel: 'Back to My Circles',
                    onAction: () => Navigator.of(context).pop(),
                    isDark: isDark,
                    primaryTextColor: primaryTextColor,
                    mutedTextColor: mutedTextColor,
                  );
                }

                return Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        padding: const EdgeInsets.all(AppConstants.spacingLG),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Glowing Checkmark Circle Header
                            Center(
                              child: Container(
                                width: 68,
                                height: 68,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.mintAccent.withValues(
                                    alpha: 0.15,
                                  ),
                                  border: Border.all(
                                    color: AppColors.mintAccent,
                                    width: 2.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.mintAccent.withValues(
                                        alpha: 0.35,
                                      ),
                                      blurRadius: 18,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.favorite_rounded,
                                  color: AppColors.mintAccent,
                                  size: 34,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Who would you like to meet again?',
                              textAlign: TextAlign.center,
                              style: AppTypography.headlineMedium.copyWith(
                                color: primaryTextColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 21,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Your choices are private. A connection happens only when both people choose each other with compatible intentions.',
                              textAlign: TextAlign.center,
                              style: AppTypography.bodyMedium.copyWith(
                                color: mutedTextColor,
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 24),

                            if (_errorMessage != null)
                              Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFEF4444,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(
                                      0xFFEF4444,
                                    ).withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: Color(0xFFEF4444),
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),

                            // List of Real Attended Participants
                            ...attendees.map((attendee) {
                              final currentChoice = _getChoiceFor(attendee.id);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: borderColor,
                                    width: 0.9,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isDark
                                          ? Colors.black26
                                          : AppColors.deepPlum.withValues(
                                              alpha: 0.04,
                                            ),
                                      blurRadius: 14,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        SizedBox(
                                          width: 52,
                                          height: 52,
                                          child: ClipOval(
                                            child: AppSmartImage(
                                              imagePath: attendee.avatarUrl,
                                              isAvatar: true,
                                              nameHint: attendee.displayName,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                attendee.displayName,
                                                style: AppTypography.titleMedium
                                                    .copyWith(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      fontSize: 15,
                                                      color: primaryTextColor,
                                                    ),
                                              ),
                                              if (attendee.bio.isNotEmpty) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  attendee.bio,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: AppTypography.bodySmall
                                                      .copyWith(
                                                        color: mutedTextColor,
                                                        fontSize: 12,
                                                      ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    Divider(height: 1, color: borderColor),
                                    const SizedBox(height: 12),

                                    Text(
                                      'How would you like to stay in touch?',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: isDark
                                            ? AppColors.softCoral
                                            : AppColors.mauve,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                    const SizedBox(height: 10),

                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        _buildChoiceChip(
                                          attendeeId: attendee.id,
                                          type: ReconnectChoiceType.friendship,
                                          currentChoice: currentChoice,
                                          label: 'Friendship',
                                          icon: Icons.people_outline_rounded,
                                          isDark: isDark,
                                        ),
                                        _buildChoiceChip(
                                          attendeeId: attendee.id,
                                          type: ReconnectChoiceType
                                              .activityPartner,
                                          currentChoice: currentChoice,
                                          label: 'Activity Partner',
                                          icon: Icons.sports_tennis_rounded,
                                          isDark: isDark,
                                        ),
                                        _buildChoiceChip(
                                          attendeeId: attendee.id,
                                          type:
                                              ReconnectChoiceType.exploreDating,
                                          currentChoice: currentChoice,
                                          label: 'Explore Dating',
                                          icon: Icons.favorite_rounded,
                                          isDark: isDark,
                                        ),
                                        _buildChoiceChip(
                                          attendeeId: attendee.id,
                                          type:
                                              ReconnectChoiceType.noConnection,
                                          currentChoice: currentChoice,
                                          label: 'No Connection',
                                          icon: Icons.close_rounded,
                                          isDark: isDark,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),

                    // Sticky Bottom Submission CTA
                    ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                (isDark
                                        ? const Color(0xFF130F1E)
                                        : Colors.white)
                                    .withValues(alpha: 0.72),
                                (isDark
                                        ? const Color(0xFF130F1E)
                                        : Colors.white)
                                    .withValues(alpha: 0.95),
                              ],
                            ),
                            border: Border(
                              top: BorderSide(
                                color: isDark
                                    ? AppColors.darkBorder
                                    : AppColors.divider,
                                width: 0.8,
                              ),
                            ),
                          ),
                          child: PrimaryButton(
                            label: _isSubmitting
                                ? 'Submitting Privately...'
                                : 'Review & Submit Choices Privately',
                            height: 48,
                            isLoading: _isSubmitting,
                            backgroundColor: isDark
                                ? AppColors.brightViolet
                                : AppColors.primaryPurple,
                            onPressed: _isSubmitting
                                ? null
                                : () => _handleConfirmAndSubmit(attendees),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildChoiceChip({
    required String attendeeId,
    required ReconnectChoiceType type,
    required ReconnectChoiceType currentChoice,
    required String label,
    required IconData icon,
    required bool isDark,
  }) {
    final isSelected = currentChoice == type;

    final Color activeColor = isDark
        ? AppColors.brightViolet
        : AppColors.primaryPurple;
    final Color inactiveBg = isDark ? AppColors.obsidian : AppColors.warmIvory;
    final Color inactiveBorder = isDark
        ? AppColors.darkBorder
        : AppColors.divider;
    final Color inactiveText = isDark
        ? AppColors.darkMutedText
        : AppColors.mutedText;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isSubmitting ? null : () => _setChoiceFor(attendeeId, type),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withValues(alpha: isDark ? 0.22 : 0.12)
                : inactiveBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? activeColor : inactiveBorder,
              width: isSelected ? 1.5 : 0.9,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? activeColor : inactiveText,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: isSelected
                      ? (isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.deepPlum)
                      : inactiveText,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoScreen({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
    required bool isDark,
    required Color primaryTextColor,
    required Color mutedTextColor,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconColor.withValues(alpha: 0.12),
                border: Border.all(
                  color: iconColor.withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              child: Icon(icon, size: 36, color: iconColor),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.headlineSmall.copyWith(
                color: primaryTextColor,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: mutedTextColor,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: actionLabel,
              height: 44,
              backgroundColor: isDark
                  ? AppColors.brightViolet
                  : AppColors.primaryPurple,
              onPressed: onAction,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(
    String message, {
    required VoidCallback onRetry,
    required bool isDark,
    required Color primaryTextColor,
    required Color mutedTextColor,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Color(0xFFEF4444),
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to proceed',
              style: AppTypography.headlineSmall.copyWith(
                color: primaryTextColor,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: mutedTextColor,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Retry',
              height: 44,
              backgroundColor: isDark
                  ? AppColors.brightViolet
                  : AppColors.primaryPurple,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
