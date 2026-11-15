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
    final dateFormat = DateFormat('EEEE, MMMM d • h:mm a');

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.cardRadiusLarge),
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
              color: AppColors.divider,
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
                          color: AppColors.sage,
                          borderRadius: BorderRadius.circular(
                            AppConstants.buttonRadiusSmall,
                          ),
                        ),
                        child: Text(
                          '${experience.categoryIcon} ${experience.categoryName}',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.deepPlum,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${experience.currentParticipants} of ${experience.maxParticipants} spots filled',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.mutedText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.spacingMD),

                  Text(
                    experience.title,
                    style: AppTypography.headlineMedium.copyWith(
                      color: AppColors.deepPlum,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingLG),

                  // Details grid
                  Container(
                    padding: const EdgeInsets.all(AppConstants.spacingMD),
                    decoration: BoxDecoration(
                      color: AppColors.warmIvory,
                      borderRadius: BorderRadius.circular(
                        AppConstants.buttonRadiusSmall,
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildMetaRow(
                          icon: Icons.access_time_rounded,
                          title: 'Date & Time',
                          value: dateFormat.format(experience.startsAt),
                        ),
                        const Divider(height: 20),
                        _buildMetaRow(
                          icon: Icons.timer_outlined,
                          title: 'Duration',
                          value: '${experience.durationMinutes} minutes',
                        ),
                        const Divider(height: 20),
                        _buildMetaRow(
                          icon: Icons.place_outlined,
                          title: 'Public Venue',
                          value:
                              '${experience.venueName}\n${experience.venueAddress}',
                        ),
                        const Divider(height: 20),
                        _buildMetaRow(
                          icon: Icons.group_outlined,
                          title: 'Group Size',
                          value:
                              'Micro-group capped at ${experience.maxParticipants} people',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingLG),

                  Text(
                    'About This Experience',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingSM),
                  Text(
                    experience.description,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.deepPlum,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingLG),

                  // Host info
                  Text(
                    'Curated Host',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
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
                            ),
                          ),
                          Text(
                            'Verified MELSAVA Community Host',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.mutedText,
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
                      color: AppColors.sage.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(
                        AppConstants.buttonRadiusSmall,
                      ),
                      border: Border.all(color: AppColors.sage),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.shield_outlined,
                              size: 18,
                              color: AppColors.mauve,
                            ),
                            const SizedBox(width: AppConstants.spacingSM),
                            Text(
                              'Safe Public Meeting Guarantee',
                              style: AppTypography.labelMedium.copyWith(
                                color: AppColors.deepPlum,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppConstants.spacingXS),
                        Text(
                          'All MELSAVA experiences take place exclusively in public, vetted venues. No private addresses or live GPS tracking. After the event, you choose privately if you wish to reconnect.',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.deepPlum,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingXXL),
                ],
              ),
            ),
          ),

          // Bottom sticky action bar
          Container(
            padding: const EdgeInsets.all(AppConstants.spacingLG),
            decoration: const BoxDecoration(
              color: AppColors.white,
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: PrimaryButton(
              label: experience.hasJoined
                  ? 'Leave Experience'
                  : 'Join Experience',
              backgroundColor: experience.hasJoined
                  ? AppColors.error
                  : AppColors.deepPlum,
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
        ],
      ),
    );
  }

  Widget _buildMetaRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.mauve),
        const SizedBox(width: AppConstants.spacingMD),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.mutedText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.deepPlum,
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
