import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/primary_button.dart';
import 'auth_providers.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isSent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Please enter your account email');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.sendPasswordResetEmail(email: email);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSent = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingLG),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppConstants.spacingMD),
              Text(
                'Forgot your password?',
                style: AppTypography.headlineLarge.copyWith(
                  color: AppColors.deepPlum,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppConstants.spacingSM),
              Text(
                'Enter the email associated with your account, and we will send you a reset link.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.mutedText,
                ),
              ),
              const SizedBox(height: AppConstants.spacingXL),

              if (_isSent) ...[
                Container(
                  padding: const EdgeInsets.all(AppConstants.spacingLG),
                  decoration: BoxDecoration(
                    color: AppColors.sage.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(
                      AppConstants.cardRadiusSmall,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.mark_email_read_outlined,
                        size: 48,
                        color: AppColors.mauve,
                      ),
                      const SizedBox(height: AppConstants.spacingMD),
                      Text(
                        'Password reset email sent!',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingXS),
                      Text(
                        'Please check your inbox and follow the instructions to set a new password.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppConstants.spacingXL),
                PrimaryButton(
                  label: 'Return to Sign In',
                  onPressed: () => context.go('/sign-in'),
                ),
              ] else ...[
                if (_errorMessage != null) ...[
                  Text(
                    _errorMessage!,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingMD),
                ],
                CustomTextField(
                  controller: _emailController,
                  label: 'Email address',
                  hintText: 'name@example.com',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(
                    Icons.mail_outline_rounded,
                    color: AppColors.mutedText,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingXL),
                PrimaryButton(
                  label: 'Send Reset Link',
                  isLoading: _isLoading,
                  onPressed: _handleReset,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
