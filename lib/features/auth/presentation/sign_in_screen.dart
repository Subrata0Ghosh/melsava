import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/auth_validators.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/glass_back_button.dart';
import '../../../shared/widgets/google_sign_in_button.dart';
import '../../../shared/widgets/melsava_logo.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/botanical_leaf_decoration.dart';
import 'auth_providers.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isMagicLinkLoading = false;
  String? _errorMessage;
  String? _infoMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final emailErr = AuthValidators.validateEmail(email);
    if (emailErr != null) {
      setState(() {
        _errorMessage = emailErr;
        _infoMessage = null;
      });
      return;
    }

    final passErr = AuthValidators.validatePassword(
      password,
      requireMinLength: false,
    );
    if (passErr != null) {
      setState(() {
        _errorMessage = passErr;
        _infoMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final user = await authRepo.signInWithEmail(
        email: email,
        password: password,
      );
      ref.read(currentUserProvider.notifier).state = user;
      if (mounted) {
        if (!user.isEmailVerified) {
          context.go('/verify-email', extra: user.email);
        } else {
          context.go(user.nextRequiredRoute);
        }
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

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final user = await authRepo.signInWithGoogle();
      if (user == null) {
        if (mounted) {
          setState(() => _isGoogleLoading = false);
        }
        return;
      }
      ref.read(currentUserProvider.notifier).state = user;
      if (mounted) {
        context.go(user.nextRequiredRoute);
      }
    } catch (e) {
      if (mounted) {
        String msg = e.toString().replaceAll('Exception: ', '');
        if (e is AuthException) {
          msg = e.message;
        }
        setState(() {
          _errorMessage = msg;
          _isGoogleLoading = false;
        });
      }
    }
  }

  Future<void> _handleMagicLink() async {
    final email = _emailController.text.trim();
    final emailErr = AuthValidators.validateEmail(email);
    if (emailErr != null) {
      setState(() {
        _errorMessage = 'Enter your email above to receive a sign-in link.';
        _infoMessage = null;
      });
      return;
    }

    setState(() {
      _isMagicLinkLoading = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    try {
      await ref.read(authRepositoryProvider).sendMagicLinkEmail(email: email);
      if (mounted) {
        setState(() {
          _isMagicLinkLoading = false;
          _infoMessage = 'Magic sign-in link sent to $email. Check your inbox!';
        });
      }
    } catch (e) {
      if (mounted) {
        String msg = e.toString().replaceAll('Exception: ', '');
        if (e is AuthException) msg = e.message;
        setState(() {
          _isMagicLinkLoading = false;
          _errorMessage = msg;
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
                        context.go('/welcome');
                      }
                    },
                  ),
                ),
                const SizedBox(height: 6),

                // ── Centered Melsava Logo ───────────────────────────────────
                const Center(child: MelsavaLogo(size: 58, showWordmark: false)),
                const SizedBox(height: 18),

                // ── Header Titles (Image 3 Screen 3) ────────────────────────
                Text(
                  'Welcome Back!',
                  textAlign: TextAlign.center,
                  style: AppTypography.headlineLarge.copyWith(
                    color: primaryTextColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 26,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Sign in to continue your journey',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    color: mutedTextColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 28),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AppConstants.spacingMD),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(
                        AppConstants.buttonRadiusSmall,
                      ),
                      border: Border.all(
                        color: AppColors.error.withOpacity(0.3),
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

                // ── Email Input ─────────────────────────────────────────────
                CustomTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  hintText: 'name@example.com',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.mail_outline_rounded, size: 20),
                ),
                const SizedBox(height: AppConstants.spacingMD),

                // ── Password Input ──────────────────────────────────────────
                CustomTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hintText: '••••••••',
                  obscureText: true,
                  prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                ),
                const SizedBox(height: AppConstants.spacingSM),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/forgot-password'),
                    child: Text(
                      'Forgot Password?',
                      style: AppTypography.labelMedium.copyWith(
                        color: isDark
                            ? AppColors.brightViolet
                            : AppColors.primaryPurple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.spacingMD),

                // ── "Sign In" Button (Gradient) ─────────────────────────────
                PrimaryButton(
                  label: 'Sign In',
                  isLoading: _isLoading,
                  gradient: AppColors.reverseSunsetCtaGradient,
                  onPressed: _handleSignIn,
                ),
                const SizedBox(height: 18),

                // ── "or" Divider ────────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: isDark ? Colors.white12 : AppColors.divider,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'or',
                        style: AppTypography.bodySmall.copyWith(
                          color: mutedTextColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: isDark ? Colors.white12 : AppColors.divider,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // ── "Continue with Google" Button ───────────────────────────
                GoogleSignInButton(
                  label: 'Continue with Google',
                  isLoading: _isGoogleLoading,
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                ),
                const SizedBox(height: 12),

                // ── "Continue with Email Link" Button ───────────────────────
                if (_infoMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.mintAccent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.mintAccent.withValues(alpha: 0.40),
                      ),
                    ),
                    child: Text(
                      _infoMessage!,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall.copyWith(
                        color: primaryTextColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                Container(
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.divider,
                      width: 1.2,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(26),
                      onTap:
                          (_isLoading ||
                              _isGoogleLoading ||
                              _isMagicLinkLoading)
                          ? null
                          : _handleMagicLink,
                      child: _isMagicLinkLoading
                          ? Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: primaryTextColor,
                                ),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.mail_outline_rounded,
                                  size: 18,
                                  color: primaryTextColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Continue with Email Link',
                                  style: AppTypography.labelLarge.copyWith(
                                    color: primaryTextColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── "Don't have an account? Sign Up" ─────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Don\'t have an account? ',
                      style: AppTypography.bodyMedium.copyWith(
                        color: mutedTextColor,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.pushReplacement('/sign-up'),
                      child: Text(
                        'Sign Up',
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
