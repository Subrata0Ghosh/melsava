import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/widgets/botanical_leaf_decoration.dart';
import '../../../shared/widgets/google_sign_in_button.dart';
import '../../../shared/widgets/melsava_logo.dart';
import '../../../shared/widgets/primary_button.dart';
import 'auth_providers.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  bool _isGoogleLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final user = await authRepo.signInWithGoogle();
      if (user == null) {
        if (mounted) setState(() => _isGoogleLoading = false);
        return;
      }
      ref.read(currentUserProvider.notifier).state = user;
      if (mounted) {
        context.go('/discover');
      }
    } catch (e) {
      if (mounted) {
        String msg = e.toString().replaceAll('Exception: ', '');
        if (e is AuthException) {
          msg = e.message;
        }
        setState(() => _isGoogleLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.deepPlum;
    final mutedTextColor = isDark ? AppColors.darkMutedText : AppColors.mutedText;

    return Scaffold(
      backgroundColor: isDark ? AppColors.obsidian : const Color(0xFFFBF8F5),
      body: AmbientNatureBackdrop(
        showTopLeaf: true,
        showBottomLeaf: true,
        leafStyle: BotanicalLeafStyle.eucalyptus,
        leafColors: BotanicalLeafDecoration.mintDew,
        child: SafeArea(
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
                    color: primaryTextColor,
                    height: 1.3,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: AppConstants.spacingMD),

                Text(
                  'Discover activities, enjoy genuine moments, and choose who you\'d like to meet again.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyLarge.copyWith(
                    color: mutedTextColor,
                    height: 1.5,
                  ),
                ),

                const Spacer(flex: 3),

                // Call to Actions
                PrimaryButton(
                  label: 'Get Started',
                  gradient: AppColors.purpleGradient,
                  onPressed: () => context.push('/sign-up'),
                ),

                const SizedBox(height: 12),

                // Native Google Sign-In CTA
                GoogleSignInButton(
                  label: 'Continue with Google',
                  isLoading: _isGoogleLoading,
                  onPressed: _handleGoogleSignIn,
                ),

                const SizedBox(height: 12),

                // Frosted Glass "I already have an account" Button
                Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.white.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.16)
                          : const Color(0xFFE5DEED),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(26),
                      onTap: () => context.push('/sign-in'),
                      child: Center(
                        child: Text(
                          'I already have an account',
                          style: AppTypography.labelLarge.copyWith(
                            color: primaryTextColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppConstants.spacingLG),

                // Footer Legal / Terms
                Center(
                  child: Text(
                    'By continuing, you agree to our Terms of Service, Privacy Policy, and Community Guidelines.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(
                      color: mutedTextColor.withValues(alpha: 0.8),
                      fontSize: 11,
                    ),
                  ),
                ),

                const SizedBox(height: AppConstants.spacingMD),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
