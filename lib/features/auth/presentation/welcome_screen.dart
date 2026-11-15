import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/widgets/melsava_logo.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/secondary_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingLG,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),

              // Brand Logo & Wordmark
              const Center(
                child: MelsavaLogo(
                  size: 80,
                  showWordmark: true,
                  showTagline: false,
                ),
              ),

              const SizedBox(height: AppConstants.spacingXL),

              // Hero copy
              Text(
                'Meet people through experiences,\nnot endless swiping.',
                textAlign: TextAlign.center,
                style: AppTypography.displaySmall.copyWith(
                  color: AppColors.deepPlum,
                  height: 1.3,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: AppConstants.spacingMD),

              Text(
                'Discover activities, enjoy genuine moments, and choose who you\'d like to meet again.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.mutedText,
                  height: 1.5,
                ),
              ),

              const Spacer(flex: 3),

              // Call to Actions
              PrimaryButton(
                label: 'Get Started',
                onPressed: () => context.push('/sign-up'),
              ),

              const SizedBox(height: AppConstants.spacingMD),

              SecondaryButton(
                label: 'I already have an account',
                onPressed: () => context.push('/sign-in'),
              ),

              const SizedBox(height: AppConstants.spacingLG),

              // Footer Legal / Terms
              Center(
                child: Text(
                  'By continuing, you agree to our Terms of Service, Privacy Policy, and Community Guidelines.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.mutedText.withOpacity(0.8),
                    fontSize: 11,
                  ),
                ),
              ),

              const SizedBox(height: AppConstants.spacingMD),
            ],
          ),
        ),
      ),
    );
  }
}
