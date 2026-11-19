import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/models/experience_model.dart';
import '../../../shared/widgets/app_smart_image.dart';
import '../../../shared/widgets/primary_button.dart';
import '../data/post_experience_repository.dart';

/// Host Attendance Confirmation Sheet (Screen 3 host action)
///
/// Enables the verified experience host to confirm which joined members
/// actually showed up in person / attended the completed event.
class HostAttendanceSheet extends ConsumerStatefulWidget {
  final ExperienceModel experience;

  const HostAttendanceSheet({super.key, required this.experience});

  static Future<void> show(
    BuildContext context, {
    required ExperienceModel experience,
  }) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => HostAttendanceSheet(experience: experience),
    );
  }

  @override
  ConsumerState<HostAttendanceSheet> createState() =>
      _HostAttendanceSheetState();
}

class _HostAttendanceSheetState extends ConsumerState<HostAttendanceSheet> {
  final Set<String> _attendedUserIds = {};
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final exp = widget.experience;

    final sheetBg = isDark ? const Color(0xFF130F1E) : AppColors.white;
    final primaryTextColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.deepPlum;
    final mutedTextColor = isDark
        ? AppColors.darkMutedText
        : AppColors.mutedText;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.warmIvory;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.divider;

    final participantsAsync = ref.watch(hostJoinedParticipantsProvider(exp.id));

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 32,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Confirm Attendance',
                        style: AppTypography.headlineSmall.copyWith(
                          color: primaryTextColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        exp.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.luminousMauve
                              : AppColors.primaryPurple,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  color: mutedTextColor,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Body
          Expanded(
            child: participantsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryPurple,
                ),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 40,
                        color: Color(0xFFEF4444),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Unable to load participants',
                        style: AppTypography.titleMedium.copyWith(
                          color: primaryTextColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        err.toString(),
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall.copyWith(
                          color: mutedTextColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      PrimaryButton(
                        label: 'Retry',
                        height: 38,
                        onPressed: () => ref.invalidate(
                          hostJoinedParticipantsProvider(exp.id),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              data: (participants) {
                if (participants.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.people_outline_rounded,
                            size: 48,
                            color: mutedTextColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No joined participants found',
                            style: AppTypography.titleMedium.copyWith(
                              color: primaryTextColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'No members had joined this experience.',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySmall.copyWith(
                              color: mutedTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            (isDark
                                    ? AppColors.brightViolet
                                    : AppColors.primaryPurple)
                                .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              (isDark
                                      ? AppColors.brightViolet
                                      : AppColors.primaryPurple)
                                  .withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 20,
                            color: isDark
                                ? AppColors.luminousMauve
                                : AppColors.primaryPurple,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Mark everyone who attended. Only confirmed attendees can participate in private reconnect choices.',
                              style: AppTypography.bodySmall.copyWith(
                                color: primaryTextColor,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Participants (${participants.length})',
                          style: AppTypography.titleSmall.copyWith(
                            color: primaryTextColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              if (_attendedUserIds.length ==
                                  participants.length) {
                                _attendedUserIds.clear();
                              } else {
                                _attendedUserIds.addAll(
                                  participants.map((p) => p.userId),
                                );
                              }
                            });
                          },
                          child: Text(
                            _attendedUserIds.length == participants.length
                                ? 'Deselect All'
                                : 'Select All',
                            style: AppTypography.labelMedium.copyWith(
                              color: isDark
                                  ? AppColors.luminousMauve
                                  : AppColors.primaryPurple,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    ...participants.map((item) {
                      final isSelected = _attendedUserIds.contains(item.userId);
                      final isAlreadyAttended = item.isAttended;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected
                                ? (isDark
                                      ? AppColors.brightViolet
                                      : AppColors.primaryPurple)
                                : borderColor,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(18),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                if (isSelected) {
                                  _attendedUserIds.remove(item.userId);
                                } else {
                                  _attendedUserIds.add(item.userId);
                                }
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: SizedBox(
                                      width: 48,
                                      height: 48,
                                      child: AppSmartImage(
                                        imagePath: item.avatarUrl,
                                        isAvatar: true,
                                        nameHint: item.displayName,
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
                                        Row(
                                          children: [
                                            Text(
                                              item.displayName,
                                              style: AppTypography.titleSmall
                                                  .copyWith(
                                                    color: primaryTextColor,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                            if (isAlreadyAttended) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFF10B981,
                                                  ).withValues(alpha: 0.15),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: const Text(
                                                  'Attended',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Color(0xFF10B981),
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        if (item.bio.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            item.bio,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
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
                                  Checkbox(
                                    value: isSelected,
                                    activeColor: isDark
                                        ? AppColors.brightViolet
                                        : AppColors.primaryPurple,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    onChanged: (val) {
                                      setState(() {
                                        if (val == true) {
                                          _attendedUserIds.add(item.userId);
                                        } else {
                                          _attendedUserIds.remove(item.userId);
                                        }
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),

          // Bottom CTA
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  PrimaryButton(
                    label: _isSubmitting
                        ? 'Confirming Attendance...'
                        : 'Confirm Attendance & Complete Event',
                    backgroundColor: isDark
                        ? AppColors.brightViolet
                        : AppColors.primaryPurple,
                    isLoading: _isSubmitting,
                    onPressed: _isSubmitting
                        ? null
                        : () async {
                            HapticFeedback.mediumImpact();
                            setState(() {
                              _isSubmitting = true;
                              _errorMessage = null;
                            });

                            final messenger = ScaffoldMessenger.of(context);
                            final navigator = Navigator.of(context);

                            try {
                              final controller = ref.read(
                                postExperienceActionControllerProvider,
                              );
                              final result = await controller
                                  .completeExperienceAndMarkAttendance(
                                    experienceId: exp.id,
                                    attendedUserIds: _attendedUserIds.toList(),
                                  );

                              if (!mounted) return;

                              if (result.success) {
                                navigator.pop();
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Attendance confirmed! ${result.attendedCount} attendee(s) marked.',
                                    ),
                                    backgroundColor: const Color(0xFF10B981),
                                  ),
                                );
                              } else {
                                setState(() {
                                  _isSubmitting = false;
                                  _errorMessage =
                                      'Could not complete attendance confirmation.';
                                });
                              }
                            } catch (e) {
                              if (!mounted) return;
                              setState(() {
                                _isSubmitting = false;
                                _errorMessage = e
                                    .toString()
                                    .replaceAll('Exception:', '')
                                    .trim();
                              });
                            }
                          },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
