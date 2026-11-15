import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/secondary_button.dart';

class VerifyEmailScreen extends StatelessWidget {
  final String email;

  const VerifyEmailScreen({super.key, this.email = 'your email'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingXL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.sage.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.outgoing_mail,
                  size: 40,
                  color: AppColors.mauve,
                ),
              ),
              const SizedBox(height: AppConstants.spacingXL),
              Text(
                'Verify your email',
                textAlign: TextAlign.center,
                style: AppTypography.headlineLarge.copyWith(
                  color: AppColors.deepPlum,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppConstants.spacingMD),
              Text(
                'We have sent a verification confirmation to:\n$email\n\nPlease tap the link in the message to activate your MELSAVA account.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.mutedText,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppConstants.spacingXXL),
              PrimaryButton(
                label: 'I Have Verified',
                onPressed: () => context.go('/discover'),
              ),
              const SizedBox(height: AppConstants.spacingMD),
              SecondaryButton(
                label: 'Back to Sign In',
                onPressed: () => context.go('/sign-in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
