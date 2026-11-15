import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/primary_button.dart';
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
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter both email and password');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final user = await authRepo.signInWithEmail(
        email: email,
        password: password,
      );
      ref.read(currentUserProvider.notifier).state = user;
      if (mounted) {
        context.go('/discover');
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
        title: const Text('Sign In'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.spacingLG),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppConstants.spacingMD),
              Text(
                'Welcome back',
                style: AppTypography.headlineLarge.copyWith(
                  color: AppColors.deepPlum,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppConstants.spacingSM),
              Text(
                'Sign in to explore experiences and reconnect with people you\'ve met.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.mutedText,
                ),
              ),
              const SizedBox(height: AppConstants.spacingXL),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppConstants.spacingMD),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(
                      AppConstants.buttonRadiusSmall,
                    ),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
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
                  color: AppColors.mutedText,
                ),
              ),
              const SizedBox(height: AppConstants.spacingMD),

              CustomTextField(
                controller: _passwordController,
                label: 'Password',
                hintText: '••••••••',
                obscureText: true,
                prefixIcon: const Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.mutedText,
                ),
              ),
              const SizedBox(height: AppConstants.spacingSM),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push('/forgot-password'),
                  child: Text(
                    'Forgot password?',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.mauve,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.spacingLG),

              PrimaryButton(
                label: 'Sign In',
                isLoading: _isLoading,
                onPressed: _handleSignIn,
              ),
              const SizedBox(height: AppConstants.spacingXL),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Don\'t have an account?',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.mutedText,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.pushReplacement('/sign-up'),
                    child: Text(
                      'Sign Up',
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.mauve,
                        fontWeight: FontWeight.w700,
                      ),
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
