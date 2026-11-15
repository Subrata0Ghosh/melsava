import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/models/experience_model.dart';
import '../../../shared/widgets/mutual_match_celebration_dialog.dart';
import '../../../shared/widgets/primary_button.dart';

class AttendeeChoice {
  final String name;
  final String avatarUrl;
  final String bio;
  String selectedOption; // 'friendship', 'activity_partner', 'dating', 'none'

  AttendeeChoice({
    required this.name,
    required this.avatarUrl,
    required this.bio,
    this.selectedOption = 'none',
  });
}

class PostExperienceChoiceScreen extends StatefulWidget {
  final ExperienceModel experience;

  const PostExperienceChoiceScreen({super.key, required this.experience});

  @override
  State<PostExperienceChoiceScreen> createState() =>
      _PostExperienceChoiceScreenState();
}

class _PostExperienceChoiceScreenState
    extends State<PostExperienceChoiceScreen> {
  late List<AttendeeChoice> _attendees;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _attendees = [
      AttendeeChoice(
        name: 'Rhea Sen',
        avatarUrl:
            'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=200&q=80',
        bio:
            'Product designer & street photographer. Loves espresso and calm books.',
        selectedOption: 'friendship',
      ),
      AttendeeChoice(
        name: 'Aarav Mehta',
        avatarUrl:
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=200&q=80',
        bio: 'Architect, jazz enthusiast, and weekend runner.',
        selectedOption: 'activity_partner',
      ),
      AttendeeChoice(
        name: 'Meera Nair',
        avatarUrl:
            'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=200&q=80',
        bio: 'Writer and botanist. Always hunting for vintage stationery.',
        selectedOption: 'dating',
      ),
    ];
  }

  void _handleSubmit() async {
    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    // Find any attendee with an active selection
    final selectedMatch = _attendees.firstWhere(
      (a) => a.selectedOption != 'none',
      orElse: () => _attendees.first,
    );

    if (selectedMatch.selectedOption != 'none') {
      final intentionLabel = selectedMatch.selectedOption == 'dating'
          ? 'Exploring Dating'
          : selectedMatch.selectedOption == 'friendship'
              ? 'Friendship'
              : 'Activity Partner';

      await MutualMatchCelebrationDialog.show(
        context,
        userName: 'You',
        userAvatarUrl:
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=300&q=80',
        matchName: selectedMatch.name,
        matchAvatarUrl: selectedMatch.avatarUrl,
        mutualIntention: intentionLabel,
        experienceTitle: widget.experience.title,
      );
    } else {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkSurface
              : AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.cardRadiusLarge),
          ),
          title: Text(
            'Choices Recorded Privately',
            style: AppTypography.headlineSmall.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkTextPrimary
                  : AppColors.deepPlum,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Your preferences have been securely saved. If any compatible mutual matches occur, a connection will appear in your Connections tab. No one is ever informed of an unreturned choice.',
            style: AppTypography.bodyMedium.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkMutedText
                  : AppColors.mutedText,
              height: 1.5,
            ),
          ),
          actions: [
            PrimaryButton(
              label: 'View Connections',
              height: 44,
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/connections');
              },
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      appBar: AppBar(
        title: const Text('Post-Experience Reconnect'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppConstants.spacingLG),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Who would you like to meet again?',
                      style: AppTypography.headlineMedium.copyWith(
                        color: AppColors.deepPlum,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingSM),
                    Text(
                      'From "${widget.experience.title}". All selections are 100% private. A connection and private conversation are created ONLY when choices are mutual.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.mutedText,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingXL),

                    ..._attendees.map((attendee) {
                      return Container(
                        margin: const EdgeInsets.only(
                          bottom: AppConstants.spacingLG,
                        ),
                        padding: const EdgeInsets.all(AppConstants.spacingMD),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(
                            AppConstants.cardRadiusSmall,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.deepPlum.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 26,
                                  backgroundImage: NetworkImage(
                                    attendee.avatarUrl,
                                  ),
                                ),
                                const SizedBox(width: AppConstants.spacingMD),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        attendee.name,
                                        style: AppTypography.titleMedium
                                            .copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        attendee.bio,
                                        style: AppTypography.bodySmall.copyWith(
                                          color: AppColors.mutedText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppConstants.spacingMD),
                            const Divider(height: 1),
                            const SizedBox(height: AppConstants.spacingSM),

                            Text(
                              'How would you like to reconnect?',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.deepPlum,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: AppConstants.spacingSM),

                            Wrap(
                              spacing: AppConstants.spacingSM,
                              runSpacing: AppConstants.spacingSM,
                              children: [
                                _buildChoiceChip(
                                  attendee,
                                  'friendship',
                                  'Friendship',
                                  Icons.people_outline,
                                ),
                                _buildChoiceChip(
                                  attendee,
                                  'activity_partner',
                                  'Activity Partner',
                                  Icons.sports_tennis_outlined,
                                ),
                                _buildChoiceChip(
                                  attendee,
                                  'dating',
                                  'Explore Dating',
                                  Icons.favorite_border,
                                ),
                                _buildChoiceChip(
                                  attendee,
                                  'none',
                                  'No Connection',
                                  Icons.close,
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

            Container(
              padding: const EdgeInsets.all(AppConstants.spacingLG),
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              child: PrimaryButton(
                label: 'Save My Private Choices',
                isLoading: _isSubmitting,
                onPressed: _handleSubmit,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceChip(
    AttendeeChoice attendee,
    String value,
    String label,
    IconData icon,
  ) {
    final isSelected = attendee.selectedOption == value;
    return GestureDetector(
      onTap: () {
        setState(() => attendee.selectedOption = value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.deepPlum : AppColors.warmIvory,
          borderRadius: BorderRadius.circular(AppConstants.buttonRadiusSmall),
          border: Border.all(
            color: isSelected ? AppColors.deepPlum : AppColors.divider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? AppColors.white : AppColors.mauve,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: isSelected ? AppColors.white : AppColors.deepPlum,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
