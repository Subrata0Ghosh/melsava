import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/widgets/botanical_leaf_decoration.dart';
import '../../../shared/widgets/melsava_logo.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/secondary_button.dart';
import 'auth_providers.dart';

/// Email Verification Screen
///
/// Connects signup to real Supabase email verification:
/// - Resend verification email with cooldown & error/success feedback
/// - Checks actual email confirmation status before continuing to Adult Eligibility
/// - Never silently bypasses email verification
class VerifyEmailScreen extends ConsumerStatefulWidget {
  final String email;

  const VerifyEmailScreen({super.key, this.email = ''});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _isChecking = false;
  bool _isResending = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;
  String? _statusMessage;
  bool _isError = false;

  String get _effectiveEmail {
    if (widget.email.isNotEmpty && widget.email != 'your email') {
      return widget.email;
    }
    final repo = ref.read(authRepositoryProvider);
    return repo.pendingVerificationEmail ??
        repo.currentUser?.email ??
        'your email';
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _resendCooldown = 30);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCooldown <= 1) {
        timer.cancel();
        setState(() => _resendCooldown = 0);
      } else {
        setState(() => _resendCooldown--);
      }
    });
  }

  Future<void> _handleCheckVerification() async {
    setState(() {
      _isChecking = true;
      _statusMessage = null;
      _isError = false;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final updatedUser = await authRepo.refreshEmailVerificationStatus();

      if (!mounted) return;

      if (updatedUser != null && updatedUser.isEmailVerified) {
        ref.read(currentUserProvider.notifier).state = updatedUser;
        context.go(updatedUser.nextRequiredRoute);
      } else {
        setState(() {
          _isChecking = false;
          _isError = true;
          _statusMessage =
              'Your email is not verified yet. Please tap the verification link in your inbox, or sign in again once confirmed.';
        });
      }
    } catch (e) {
      if (mounted) {
        String msg = e.toString().replaceAll('Exception: ', '');
        if (e is AuthException) msg = e.message;
        setState(() {
          _isChecking = false;
          _isError = true;
          _statusMessage = msg;
        });
      }
    }
  }

  Future<void> _handleResendEmail() async {
    final targetEmail = _effectiveEmail;
    if (targetEmail == 'your email' || !targetEmail.contains('@')) {
      setState(() {
        _isError = true;
        _statusMessage = 'No valid email address found. Please sign up again.';
      });
      return;
    }

    setState(() {
      _isResending = true;
      _statusMessage = null;
      _isError = false;
    });

    try {
      await ref
          .read(authRepositoryProvider)
          .resendVerificationEmail(email: targetEmail);
      if (mounted) {
        setState(() {
          _isResending = false;
          _isError = false;
          _statusMessage = 'Verification email resent to $targetEmail.';
        });
        _startCooldown();
      }
    } catch (e) {
      if (mounted) {
        String msg = e.toString().replaceAll('Exception: ', '');
        if (e is AuthException) msg = e.message;
        setState(() {
          _isResending = false;
          _isError = true;
          _statusMessage = msg;
        });
      }
    }
  }

  Future<void> _handleDebugMockVerify() async {
    final authRepo = ref.read(authRepositoryProvider);
    final verifiedUser = await authRepo.debugVerifyEmailIfAllowed();
    if (!mounted) return;
    if (verifiedUser != null && verifiedUser.isEmailVerified) {
      ref.read(currentUserProvider.notifier).state = verifiedUser;
      context.go(verifiedUser.nextRequiredRoute);
    }
  }

  Future<void> _handleBackToSignIn() async {
    await ref.read(authRepositoryProvider).signOut();
    ref.read(currentUserProvider.notifier).state = null;
    if (mounted) {
      context.go('/sign-in');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkTextPrimary : AppColors.deepPlum;
    final mutedText = isDark ? AppColors.darkMutedText : AppColors.mutedText;
    final authRepo = ref.watch(authRepositoryProvider);
    final displayEmail = _effectiveEmail;

    return Scaffold(
      backgroundColor: isDark ? AppColors.obsidian : AppColors.warmIvory,
      body: AmbientNatureBackdrop(
        showTopLeaf: true,
        showBottomLeaf: true,
        leafStyle: BotanicalLeafStyle.eucalyptus,
        leafColors: BotanicalLeafDecoration.mintDew,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.spacingXL),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                const Center(child: MelsavaLogo(size: 56, showWordmark: false)),
                const SizedBox(height: 28),
                Center(
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: (isDark ? AppColors.luminousMauve : AppColors.sage)
                          .withValues(alpha: isDark ? 0.18 : 0.70),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.mark_email_unread_outlined,
                      size: 42,
                      color: isDark ? AppColors.luminousMauve : AppColors.mauve,
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.spacingLG),
                Text(
                  'Verify your email',
                  textAlign: TextAlign.center,
                  style: AppTypography.headlineLarge.copyWith(
                    color: primaryText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingMD),
                Text(
                  'We sent a verification link to:\n$displayEmail\n\nOpen your inbox and tap the link to activate your MELSAVA account, then continue to age eligibility.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    color: mutedText,
                    height: 1.55,
                  ),
                ),
                if (_statusMessage != null) ...[
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: (_isError ? AppColors.error : AppColors.mintAccent)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color:
                            (_isError ? AppColors.error : AppColors.mintAccent)
                                .withValues(alpha: 0.40),
                      ),
                    ),
                    child: Text(
                      _statusMessage!,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall.copyWith(
                        color: _isError
                            ? AppColors.error
                            : (isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.deepPlum),
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppConstants.spacingXL),
                PrimaryButton(
                  label: 'I Have Verified My Email',
                  isLoading: _isChecking,
                  gradient: AppColors.sunsetCtaGradient,
                  onPressed: _isChecking ? null : _handleCheckVerification,
                ),
                const SizedBox(height: AppConstants.spacingMD),
                SecondaryButton(
                  label: _resendCooldown > 0
                      ? 'Resend Email (${_resendCooldown}s)'
                      : 'Resend Verification Email',
                  isLoading: _isResending,
                  onPressed: (_isResending || _resendCooldown > 0)
                      ? null
                      : _handleResendEmail,
                ),
                if (kDebugMode && authRepo.isDebugMockMode) ...[
                  const SizedBox(height: AppConstants.spacingMD),
                  TextButton(
                    onPressed: _handleDebugMockVerify,
                    child: Text(
                      '[Debug Mode Only] Simulate Email Verified',
                      style: AppTypography.labelMedium.copyWith(
                        color: isDark ? AppColors.softCoral : AppColors.mauve,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppConstants.spacingSM),
                TextButton(
                  onPressed: _handleBackToSignIn,
                  child: Text(
                    'Back to Sign In',
                    style: AppTypography.labelLarge.copyWith(
                      color: mutedText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
