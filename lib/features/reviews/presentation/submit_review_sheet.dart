import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/models/experience_model.dart';
import '../data/reviews_repository.dart';
import '../domain/review_model.dart';

/// Modal bottom sheet allowing verified attendees of a completed circle
/// to leave an honest, constructive review for the host.
class SubmitReviewSheet extends ConsumerStatefulWidget {
  final ExperienceModel experience;

  const SubmitReviewSheet({super.key, required this.experience});

  static Future<void> show(
    BuildContext context, {
    required ExperienceModel experience,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SubmitReviewSheet(experience: experience),
    );
  }

  @override
  ConsumerState<SubmitReviewSheet> createState() => _SubmitReviewSheetState();
}

class _SubmitReviewSheetState extends ConsumerState<SubmitReviewSheet> {
  double _rating = 5.0;
  bool _wasAsDescribed = true;
  bool _wasHostRespectful = true;
  bool _didHostArrive = true;
  bool _feltSafeComfortable = true;
  bool _wouldJoinAgain = true;
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final input = ReviewInput(
        experienceId: widget.experience.id,
        rating: _rating,
        wasAsDescribed: _wasAsDescribed,
        wasHostRespectful: _wasHostRespectful,
        didHostArrive: _didHostArrive,
        feltSafeComfortable: _feltSafeComfortable,
        wouldJoinAgain: _wouldJoinAgain,
        feedbackText: _feedbackController.text.trim().isEmpty
            ? null
            : _feedbackController.text.trim(),
      );

      await ref.read(reviewsRepositoryProvider).submitReview(input);

      // Invalidate eligibility and host review cache
      ref.invalidate(canReviewExperienceProvider(widget.experience.id));
      if (widget.experience.hostId != null) {
        ref.invalidate(hostReviewsProvider(widget.experience.hostId!));
      }

      if (!mounted) return;
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF10B981),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Thank you! Your verified review has been published.',
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Widget _buildQuestionToggle({
    required String question,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              question,
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? Colors.white70 : AppColors.darkSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Yes')),
              ButtonSegment(value: false, label: Text('No')),
            ],
            selected: {value},
            onSelectionChanged: (set) => onChanged(set.first),
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.primaryPurple;
                }
                return null;
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return isDark ? Colors.white70 : AppColors.darkSurface;
              }),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Review Your Experience',
              style: AppTypography.headlineSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.darkSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.experience.title} • Hosted by ${widget.experience.hostName}',
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white54 : AppColors.mutedText,
              ),
            ),
            const SizedBox(height: 16),

            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEF4444)),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: Color(0xFFEF4444),
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Star Rating
            Center(
              child: Column(
                children: [
                  Text(
                    'Overall Rating',
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.darkSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starValue = index + 1;
                      return IconButton(
                        iconSize: 36,
                        icon: Icon(
                          _rating >= starValue
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: const Color(0xFFF59E0B),
                        ),
                        onPressed: () =>
                            setState(() => _rating = starValue.toDouble()),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const Divider(height: 24),

            // Structured Questions
            Text(
              'Attendee Verification Questions',
              style: AppTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.darkSurface,
              ),
            ),
            const SizedBox(height: 8),

            _buildQuestionToggle(
              question: 'Was the activity as described?',
              value: _wasAsDescribed,
              onChanged: (val) => setState(() => _wasAsDescribed = val),
              isDark: isDark,
            ),
            _buildQuestionToggle(
              question: 'Was the host respectful & welcoming?',
              value: _wasHostRespectful,
              onChanged: (val) => setState(() => _wasHostRespectful = val),
              isDark: isDark,
            ),
            _buildQuestionToggle(
              question: 'Did the host arrive as planned?',
              value: _didHostArrive,
              onChanged: (val) => setState(() => _didHostArrive = val),
              isDark: isDark,
            ),
            _buildQuestionToggle(
              question: 'Did you feel comfortable and safe?',
              value: _feltSafeComfortable,
              onChanged: (val) => setState(() => _feltSafeComfortable = val),
              isDark: isDark,
            ),
            _buildQuestionToggle(
              question: 'Would you join another circle with this host?',
              value: _wouldJoinAgain,
              onChanged: (val) => setState(() => _wouldJoinAgain = val),
              isDark: isDark,
            ),
            const SizedBox(height: 16),

            // Optional Written Feedback
            Text(
              'Written Feedback (Optional)',
              style: AppTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.darkSurface,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _feedbackController,
              maxLines: 3,
              maxLength: 500,
              decoration: InputDecoration(
                hintText:
                    'Share highlights or constructive suggestions for future attendees...',
                hintStyle: TextStyle(
                  color: isDark ? Colors.white38 : Colors.grey,
                  fontSize: 13,
                ),
                filled: true,
                fillColor: isDark ? AppColors.darkSurface : AppColors.warmIvory,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Colors.grey.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            PrimaryButton(
              label: 'Submit Verified Review',
              isLoading: _isSubmitting,
              onPressed: _handleSubmit,
            ),
          ],
        ),
      ),
    );
  }
}
