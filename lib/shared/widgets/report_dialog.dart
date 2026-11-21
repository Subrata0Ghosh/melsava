import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_typography.dart';
import 'primary_button.dart';
import 'secondary_button.dart';

/// Modal dialog allowing users to safely report inappropriate behavior,
/// safety concerns, or guideline violations.
class ReportDialog extends StatefulWidget {
  final String targetTitle;
  final bool isE2eeConversation;
  final FutureOr<dynamic> Function(String reason, String description) onSubmit;

  const ReportDialog({
    super.key,
    required this.targetTitle,
    this.isE2eeConversation = false,
    required this.onSubmit,
  });

  static Future<void> show(
    BuildContext context, {
    required String targetTitle,
    bool isE2eeConversation = false,
    required FutureOr<dynamic> Function(String reason, String description)
    onSubmit,
  }) {
    return showDialog(
      context: context,
      builder: (context) =>
          ReportDialog(
            targetTitle: targetTitle,
            isE2eeConversation: isE2eeConversation,
            onSubmit: onSubmit,
          ),
    );
  }

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  static const List<String> _reasons = [
    'Harassment or unwanted contact',
    'Commercial solicitation or spam',
    'Spam or fake activity',
    'Fake identity or impersonation',
    'Inappropriate behaviour',
    'Unsafe meetup or suspicious location',
    'Scam or payment fraud',
    'Activity did not happen',
    'Underage user concern',
    'Other',
  ];

  String? _selectedReason;
  final TextEditingController _descController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_selectedReason == null || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final result = await widget.onSubmit(
        _selectedReason!,
        _descController.text.trim(),
      );

      // If callback explicitly returned false, treat as failure
      if (result == false) {
        if (!mounted) return;
        setState(() {
          _isSubmitting = false;
          _errorMessage =
              'Could not submit report right now. Please check your connection and try again.';
        });
        return;
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
                  'Report submitted safely. Our moderation team will review it immediately.',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
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
        _errorMessage = 'Report submission failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF221A33) : AppColors.white;
    final primaryTextColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.deepPlum;
    final mutedTextColor = isDark
        ? AppColors.darkMutedText
        : AppColors.mutedText;

    return Dialog(
      backgroundColor: dialogBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardRadiusLarge),
      ),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingLG,
        vertical: 24,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingLG),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.flag_rounded,
                      color: AppColors.error,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Report ${widget.targetTitle}',
                      style: AppTypography.headlineSmall.copyWith(
                        color: primaryTextColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spacingSM),
              Text(
                'Your report is strictly confidential. The other member will never be notified who submitted it.',
                style: AppTypography.bodySmall.copyWith(
                  color: mutedTextColor,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),

              // Community Guidelines direct shortcut
              InkWell(
                onTap: () {
                  context.push('/community-guidelines');
                },
                child: Row(
                  children: [
                    const Icon(
                      Icons.menu_book_rounded,
                      size: 14,
                      color: AppColors.brightViolet,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Review Community Guidelines',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brightViolet,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.isE2eeConversation) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primaryPurple.withValues(alpha: 0.2),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        size: 16,
                        color: AppColors.primaryPurple,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'E2EE Safety Notice: MELSAVA messages are end-to-end encrypted; moderators cannot read chat history. The reason and details you provide below will serve as official moderation evidence.',
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.35,
                            color: isDark ? Colors.white70 : AppColors.deepPlum,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppConstants.spacingMD),

              Text(
                'Reason for report',
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: AppConstants.spacingXS),
              ..._reasons.map((reason) {
                return RadioListTile<String>(
                  value: reason,
                  groupValue: _selectedReason,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.mauve,
                  title: Text(
                    reason,
                    style: AppTypography.bodyMedium.copyWith(
                      color: primaryTextColor,
                      fontSize: 13,
                    ),
                  ),
                  onChanged: _isSubmitting
                      ? null
                      : (val) => setState(() => _selectedReason = val),
                );
              }),
              const SizedBox(height: AppConstants.spacingSM),

              TextField(
                controller: _descController,
                maxLines: 3,
                maxLength: 500,
                enabled: !_isSubmitting,
                style: AppTypography.bodyMedium.copyWith(
                  color: primaryTextColor,
                ),
                decoration: InputDecoration(
                  hintText:
                      'Provide additional context (optional, max 500 chars)...',
                  hintStyle: AppTypography.bodySmall.copyWith(
                    color: mutedTextColor,
                  ),
                  counterStyle: TextStyle(color: mutedTextColor, fontSize: 11),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : const Color(0xFFF9F7FB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppConstants.buttonRadiusSmall,
                    ),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white24 : const Color(0xFFE5DEFF),
                    ),
                  ),
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
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
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppConstants.spacingLG),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: 'Cancel',
                      height: 44,
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingMD),
                  Expanded(
                    child: PrimaryButton(
                      label: _isSubmitting ? 'Submitting...' : 'Submit',
                      height: 44,
                      backgroundColor: AppColors.deepPlum,
                      isLoading: _isSubmitting,
                      onPressed: (_selectedReason == null || _isSubmitting)
                          ? null
                          : _handleSubmit,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
