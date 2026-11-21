import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/auth_validators.dart';
import '../../../shared/widgets/botanical_leaf_decoration.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/glass_back_button.dart';
import '../../../shared/widgets/melsava_logo.dart';
import '../../../shared/widgets/primary_button.dart';
import 'auth_providers.dart';

/// Screen allowing users arriving from a password reset deep link
/// (`melsava://reset-password`) to choose and confirm a new password.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _isSuccess = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdatePassword() async {
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    final passwordErr = AuthValidators.validatePassword(password);
    if (passwordErr != null) {
      setState(() => _errorMessage = passwordErr);
      return;
    }

    if (password != confirm) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.updatePassword(newPassword: password);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSuccess = true;
        });
      }
    } catch (e) {
      if (mounted) {
        String msg = e.toString().replaceAll('Exception: ', '').trim();
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
                Align(
                  alignment: Alignment.centerLeft,
                  child: GlassBackButton(
                    isDark: isDark,
                    iconColor: primaryTextColor,
                    onTap: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/sign-in');
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
                const Center(child: MelsavaLogo(size: 52)),
                const SizedBox(height: 24),

                if (_isSuccess) ...[
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurface
                          : Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          color: Color(0xFF10B981),
                          size: 56,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Password Updated',
                          style: AppTypography.headlineMedium.copyWith(
                            color: primaryTextColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your password has been changed securely. You can now continue with your updated credentials.',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium.copyWith(
                            color: mutedTextColor,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        PrimaryButton(
                          label: 'Continue to Sign In',
                          onPressed: () => context.go('/sign-in'),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Text(
                    'Create New Password',
                    style: AppTypography.displayMedium.copyWith(
                      color: primaryTextColor,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose a strong password to protect your MELSAVA account.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: mutedTextColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
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
                          const SizedBox(width: 8),
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
                    const SizedBox(height: 16),
                  ],

                  CustomTextField(
                    label: 'New Password',
                    hintText: 'At least 8 characters',
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: mutedTextColor,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    label: 'Confirm New Password',
                    hintText: 'Re-enter your password',
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirm,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: mutedTextColor,
                      ),
                      onPressed: () {
                        setState(() => _obscureConfirm = !_obscureConfirm);
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  PrimaryButton(
                    label: 'Update Password',
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : _handleUpdatePassword,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
