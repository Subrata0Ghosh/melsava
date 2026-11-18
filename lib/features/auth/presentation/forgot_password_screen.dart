import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/auth_validators.dart';
import '../../../shared/widgets/botanical_leaf_decoration.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/glass_back_button.dart';
import '../../../shared/widgets/melsava_logo.dart';
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
    final emailErr = AuthValidators.validateEmail(email);
    if (emailErr != null) {
      setState(() => _errorMessage = emailErr);
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
        String msg = e.toString().replaceAll('Exception: ', '');
        if (e is AuthException) {
          msg = e.message;
        }
        setState(() {
          _errorMessage = msg;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.deepPlum;
    final mutedTextColor = isDark
        ? AppColors.darkMutedText
        : AppColors.mutedText;

    return Scaffold(
      backgroundColor: isDark ? AppColors.obsidian : const Color(0xFFFBF8F5),
      body: AmbientNatureBackdrop(
        showTopLeaf: true,
        showBottomLeaf: true,
        leafStyle: BotanicalLeafStyle.eucalyptus,
        leafColors: BotanicalLeafDecoration.mintDew,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Top Bar with Frosted Glass Back Button ─────────────────
                Align(
                  alignment: Alignment.centerLeft,
                  child: GlassBackButton(
                    isDark: isDark,
                    iconColor: primaryTextColor,
                    onTap: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        context.go('/sign-in');
                      }
                    },
                  ),
                ),
                const SizedBox(height: 6),

                // ── Centered Melsava Logo ───────────────────────────────────
                const Center(child: MelsavaLogo(size: 58, showWordmark: false)),
                const SizedBox(height: 18),

                // ── Header Titles ───────────────────────────────────────────
                Text(
                  'Forgot Password?',
                  textAlign: TextAlign.center,
                  style: AppTypography.headlineLarge.copyWith(
                    color: primaryTextColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 26,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Enter the email associated with your account, and we will send you a reset link.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    color: mutedTextColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 28),

                if (_isSent) ...[
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.white.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? AppColors.brightViolet.withValues(alpha: 0.30)
                            : AppColors.primaryPurple.withValues(alpha: 0.20),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.25 : 0.05,
                          ),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                (isDark
                                        ? AppColors.brightViolet
                                        : AppColors.primaryPurple)
                                    .withValues(alpha: 0.12),
                          ),
                          child: Icon(
                            Icons.mark_email_read_outlined,
                            size: 32,
                            color: isDark
                                ? AppColors.brightViolet
                                : AppColors.primaryPurple,
                          ),
                        ),
                        const SizedBox(height: AppConstants.spacingMD),
                        Text(
                          'Password reset email sent!',
                          textAlign: TextAlign.center,
                          style: AppTypography.titleMedium.copyWith(
                            color: primaryTextColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: AppConstants.spacingXS),
                        Text(
                          'Please check your inbox and follow the instructions to set a new password.',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmall.copyWith(
                            color: mutedTextColor,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Return to Sign In',
                    gradient: AppColors.purpleGradient,
                    onPressed: () => context.go('/sign-in'),
                  ),
                ] else ...[
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(AppConstants.spacingMD),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(
                          AppConstants.buttonRadiusSmall,
                        ),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: AppColors.error,
                            size: 20,
                          ),
                          const SizedBox(width: AppConstants.spacingSM),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
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
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Send Reset Link',
                    isLoading: _isLoading,
                    gradient: AppColors.reverseSunsetCtaGradient,
                    onPressed: _handleReset,
                  ),
                ],
                const SizedBox(height: 22),

                // ── Switch to Sign In ───────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Remember your password? ',
                      style: AppTypography.bodyMedium.copyWith(
                        color: mutedTextColor,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        } else {
                          context.go('/sign-in');
                        }
                      },
                      child: Text(
                        'Sign In',
                        style: AppTypography.labelLarge.copyWith(
                          color: isDark
                              ? AppColors.brightViolet
                              : AppColors.primaryPurple,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
