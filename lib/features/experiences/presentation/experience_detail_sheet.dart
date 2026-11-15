import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/models/experience_model.dart';
import '../../../shared/widgets/primary_button.dart';

class ExperienceDetailSheet extends StatelessWidget {
  final ExperienceModel experience;
  final VoidCallback onToggleJoin;

  const ExperienceDetailSheet({
    super.key,
    required this.experience,
    required this.onToggleJoin,
  });

  static Future<void> show(
    BuildContext context, {
    required ExperienceModel experience,
    required VoidCallback onToggleJoin,
  }) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true, // Pushes above the bottom navigation bar
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExperienceDetailSheet(
        experience: experience,
        onToggleJoin: onToggleJoin,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('EEEE, MMMM d • h:mm a');

    final sheetBg = isDark ? const Color(0xFF161224) : AppColors.white;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.deepPlum;
    final mutedTextColor = isDark ? AppColors.darkMutedText : AppColors.mutedText;
    final cardBg = isDark ? AppColors.darkElevated : AppColors.warmIvory;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.divider;

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: AppConstants.spacingMD),
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.spacingLG),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Cover Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(
                      AppConstants.cardRadiusSmall,
                    ),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: CachedNetworkImage(
                        imageUrl: experience.coverImageUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingLG),

                  // Category badge & Status
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.luminousMauve.withValues(alpha: 0.2)
                              : AppColors.sage,
                          borderRadius: BorderRadius.circular(
                            AppConstants.buttonRadiusSmall,
                          ),
                          border: isDark
                              ? Border.all(
                                  color: AppColors.luminousMauve.withValues(alpha: 0.4),
                                  width: 0.8,
                                )
                              : null,
                        ),
                        child: Text(
                          '${experience.categoryIcon} ${experience.categoryName}',
                          style: AppTypography.labelSmall.copyWith(
                            color: isDark ? AppColors.luminousMauve : AppColors.deepPlum,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${experience.currentParticipants} of ${experience.maxParticipants} spots filled',
                        style: AppTypography.labelSmall.copyWith(
                          color: mutedTextColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.spacingMD),

                  Text(
                    experience.title,
                    style: AppTypography.headlineMedium.copyWith(
                      color: primaryTextColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingLG),

                  // Details grid
                  Container(
                    padding: const EdgeInsets.all(AppConstants.spacingMD),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(
                        AppConstants.buttonRadiusSmall,
                      ),
                      border: Border.all(color: borderColor, width: 0.8),
                    ),
                    child: Column(
                      children: [
                        _buildMetaRow(
                          icon: Icons.access_time_rounded,
                          title: 'Date & Time',
                          value: dateFormat.format(experience.startsAt),
                          primaryColor: primaryTextColor,
                          mutedColor: mutedTextColor,
                          isDark: isDark,
                        ),
                        Divider(height: 20, color: borderColor),
                        _buildMetaRow(
                          icon: Icons.timer_outlined,
                          title: 'Duration',
                          value: '${experience.durationMinutes} minutes',
                          primaryColor: primaryTextColor,
                          mutedColor: mutedTextColor,
                          isDark: isDark,
                        ),
                        Divider(height: 20, color: borderColor),
                        _buildMetaRow(
                          icon: Icons.place_outlined,
                          title: 'Public Venue',
                          value:
                              '${experience.venueName}\n${experience.venueAddress}',
                          primaryColor: primaryTextColor,
                          mutedColor: mutedTextColor,
                          isDark: isDark,
                        ),
                        Divider(height: 20, color: borderColor),
                        _buildMetaRow(
                          icon: Icons.group_outlined,
                          title: 'Group Size',
                          value:
                              'Micro-group capped at ${experience.maxParticipants} people',
                          primaryColor: primaryTextColor,
                          mutedColor: mutedTextColor,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingLG),

                  Text(
                    'About This Experience',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingSM),
                  Text(
                    experience.description,
                    style: AppTypography.bodyMedium.copyWith(
                      color: primaryTextColor,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingLG),

                  // Host info
                  Text(
                    'Curated Host',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingSM),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: NetworkImage(experience.hostAvatar),
                      ),
                      const SizedBox(width: AppConstants.spacingMD),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            experience.hostName,
                            style: AppTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: primaryTextColor,
                            ),
                          ),
                          Text(
                            'Verified MELSAVA Community Host',
                            style: AppTypography.bodySmall.copyWith(
                              color: mutedTextColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.spacingLG),

                  // Safety Guidance
                  Container(
                    padding: const EdgeInsets.all(AppConstants.spacingMD),
                    decoration: BoxDecoration(
                      color: (isDark ? AppColors.darkElevated : AppColors.sage)
                          .withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(
                        AppConstants.buttonRadiusSmall,
                      ),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.sage,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.shield_outlined,
                              size: 18,
                              color: isDark ? AppColors.luminousMauve : AppColors.mauve,
                            ),
                            const SizedBox(width: AppConstants.spacingSM),
                            Text(
                              'Safe Public Meeting Guarantee',
                              style: AppTypography.labelMedium.copyWith(
                                color: primaryTextColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppConstants.spacingXS),
                        Text(
                          'All MELSAVA experiences take place exclusively in public, vetted venues. No private addresses or live GPS tracking. After the event, you choose privately if you wish to reconnect.',
                          style: AppTypography.bodySmall.copyWith(
                            color: primaryTextColor,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingXL),
                ],
              ),
            ),
          ),

          // Bottom sticky action bar with SafeArea
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingLG,
                vertical: AppConstants.spacingMD,
              ),
              decoration: BoxDecoration(
                color: sheetBg,
                border: Border(top: BorderSide(color: borderColor, width: 0.8)),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black38
                        : AppColors.deepPlum.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: PrimaryButton(
                label: experience.hasJoined
                    ? 'Leave Experience'
                    : 'Join Experience',
                backgroundColor: experience.hasJoined
                    ? AppColors.error
                    : (isDark ? AppColors.luminousMauve : AppColors.deepPlum),
                onPressed: () {
                  onToggleJoin();
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        experience.hasJoined
                            ? 'You have cancelled your RSVP.'
                            : 'You\'ve joined ${experience.title}! See you there.',
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow({
    required IconData icon,
    required String title,
    required String value,
    required Color primaryColor,
    required Color mutedColor,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: isDark ? AppColors.luminousMauve : AppColors.mauve,
        ),
        const SizedBox(width: AppConstants.spacingMD),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.labelSmall.copyWith(
                  color: mutedColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTypography.bodyMedium.copyWith(
                  color: primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
