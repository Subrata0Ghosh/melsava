import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_typography.dart';
import '../models/experience_model.dart';

class ExperienceCard extends StatelessWidget {
  final ExperienceModel experience;
  final VoidCallback onTap;
  final VoidCallback? onJoinTap;

  const ExperienceCard({
    super.key,
    required this.experience,
    required this.onTap,
    this.onJoinTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE, MMM d • h:mm a');
    final isFull = experience.currentParticipants >= experience.maxParticipants;
    final spotsLeft =
        experience.maxParticipants - experience.currentParticipants;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppConstants.spacingLG),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppConstants.cardRadiusLarge),
          boxShadow: [
            BoxShadow(
              color: AppColors.deepPlum.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppConstants.cardRadiusLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero cover image
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: CachedNetworkImage(
                      imageUrl: experience.coverImageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppColors.sage.withOpacity(0.3),
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.mauve,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.sage.withOpacity(0.4),
                        child: const Icon(
                          Icons.image_outlined,
                          size: 40,
                          color: AppColors.mutedText,
                        ),
                      ),
                    ),
                  ),

                  // Category chip pill at top left
                  Positioned(
                    top: AppConstants.spacingMD,
                    left: AppConstants.spacingMD,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.spacingMD,
                        vertical: AppConstants.spacingXS + 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.deepPlum.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(
                          AppConstants.buttonRadiusSmall,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            experience.categoryIcon,
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: AppConstants.spacingXS),
                          Text(
                            experience.categoryName,
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Spots left badge at top right
                  Positioned(
                    top: AppConstants.spacingMD,
                    right: AppConstants.spacingMD,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.spacingMD,
                        vertical: AppConstants.spacingXS + 2,
                      ),
                      decoration: BoxDecoration(
                        color: experience.hasJoined
                            ? AppColors.mauve
                            : (isFull
                                  ? AppColors.mutedText
                                  : AppColors.softCoral),
                        borderRadius: BorderRadius.circular(
                          AppConstants.buttonRadiusSmall,
                        ),
                      ),
                      child: Text(
                        experience.hasJoined
                            ? 'Joined ✓'
                            : (isFull ? 'Full' : '$spotsLeft spots left'),
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Content body
              Padding(
                padding: const EdgeInsets.all(AppConstants.spacingMD),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      experience.title,
                      style: AppTypography.titleLarge.copyWith(
                        color: AppColors.deepPlum,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingSM),

                    // Date & Location metadata
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 14,
                          color: AppColors.mauve,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          dateFormat.format(experience.startsAt),
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.deepPlum,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.spacingXS),
                    Row(
                      children: [
                        const Icon(
                          Icons.place_outlined,
                          size: 14,
                          color: AppColors.mauve,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            experience.venueName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.mutedText,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.spacingMD),

                    // Attendees & Host row
                    Row(
                      children: [
                        // Attendee overlapping circles
                        SizedBox(
                          height: 28,
                          width:
                              (experience.attendeeAvatars.length * 18.0) + 12,
                          child: Stack(
                            children: [
                              for (
                                int i = 0;
                                i < experience.attendeeAvatars.length;
                                i++
                              )
                                Positioned(
                                  left: i * 18.0,
                                  child: CircleAvatar(
                                    radius: 14,
                                    backgroundColor: AppColors.white,
                                    child: CircleAvatar(
                                      radius: 12,
                                      backgroundImage: NetworkImage(
                                        experience.attendeeAvatars[i],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppConstants.spacingSM),
                        Text(
                          '${experience.currentParticipants}/${experience.maxParticipants} attending',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.mutedText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),

                        // Action button
                        if (onJoinTap != null)
                          TextButton(
                            onPressed: onJoinTap,
                            style: TextButton.styleFrom(
                              backgroundColor: experience.hasJoined
                                  ? AppColors.sage
                                  : AppColors.deepPlum,
                              foregroundColor: experience.hasJoined
                                  ? AppColors.deepPlum
                                  : AppColors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppConstants.spacingMD,
                                vertical: AppConstants.spacingSM,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppConstants.buttonRadiusSmall,
                                ),
                              ),
                            ),
                            child: Text(
                              experience.hasJoined ? 'Leave' : 'Join',
                              style: AppTypography.labelSmall.copyWith(
                                fontWeight: FontWeight.w700,
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
      ),
    );
  }
}
