import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_typography.dart';
import 'primary_button.dart';
import 'secondary_button.dart';

/// Modal dialog allowing users to safely report inappropriate behavior,
/// safety concerns, or guideline violations.
class ReportDialog extends StatefulWidget {
  final String targetTitle;
  final Function(String reason, String description) onSubmit;

  const ReportDialog({
    super.key,
    required this.targetTitle,
    required this.onSubmit,
  });

  static Future<void> show(
    BuildContext context, {
    required String targetTitle,
    required Function(String reason, String description) onSubmit,
  }) {
    return showDialog(
      context: context,
      builder: (context) =>
          ReportDialog(targetTitle: targetTitle, onSubmit: onSubmit),
    );
  }

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  final List<String> _reasons = [
    'Inappropriate or offensive behavior',
    'Commercial solicitation or spam',
    'Harassment or unwanted contact',
    'Misrepresentation or fake profile',
    'Safety concern at an activity',
    'Other concern',
  ];

  String? _selectedReason;
  final TextEditingController _descController = TextEditingController();

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardRadiusLarge),
      ),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingLG,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingLG),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Report ${widget.targetTitle}',
                style: AppTypography.headlineSmall.copyWith(
                  color: AppColors.deepPlum,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppConstants.spacingSM),
              Text(
                'Your report is strictly confidential. The other person will never be told who submitted it.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.mutedText,
                ),
              ),
              const SizedBox(height: AppConstants.spacingMD),
              Text(
                'Reason',
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppConstants.spacingSM),
              ..._reasons.map((reason) {
                return RadioListTile<String>(
                  value: reason,
                  groupValue: _selectedReason,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.mauve,
                  title: Text(reason, style: AppTypography.bodyMedium),
                  onChanged: (val) => setState(() => _selectedReason = val),
                );
              }),
              const SizedBox(height: AppConstants.spacingMD),
              TextField(
                controller: _descController,
                maxLines: 3,
                style: AppTypography.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Additional details (optional)...',
                  hintStyle: AppTypography.bodySmall,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppConstants.buttonRadiusSmall,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.spacingLG),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: 'Cancel',
                      height: 44,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingMD),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Submit',
                      height: 44,
                      backgroundColor: AppColors.deepPlum,
                      onPressed: _selectedReason == null
                          ? null
                          : () {
                              widget.onSubmit(
                                _selectedReason!,
                                _descController.text,
                              );
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Report submitted. Thank you for keeping our community safe.',
                                  ),
                                ),
                              );
                            },
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
