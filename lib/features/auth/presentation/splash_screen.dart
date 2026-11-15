import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/animated_melsava_brand_logo.dart';
import 'auth_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _navigationTimer;
  bool _sessionChecked = false;
  bool _animationCompleted = false;
  bool _hasUser = false;

  @override
  void initState() {
    super.initState();
    _checkAuthSession();

    // 2.6s brand logo sequence
    _navigationTimer = Timer(const Duration(milliseconds: 2600), () {
      _animationCompleted = true;
      _attemptNavigation();
    });
  }

  Future<void> _checkAuthSession() async {
    final authRepo = ref.read(authRepositoryProvider);
    await authRepo.restoreSession();
    final user = authRepo.currentUser;
    _hasUser = user != null;
    if (_hasUser) {
      ref.read(currentUserProvider.notifier).state = user;
    }
    _sessionChecked = true;
    _attemptNavigation();
  }

  void _attemptNavigation() {
    if (!mounted || !_sessionChecked || !_animationCompleted) return;

    if (_hasUser) {
      context.go('/discover');
    } else {
      context.go('/onboarding');
    }
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    const Color(0xFF161224),
                    AppColors.obsidian,
                  ]
                : [
                    const Color(0xFFFAF6F2),
                    AppColors.warmIvory,
                  ],
          ),
        ),
        child: Center(
          child: AnimatedMelsavaBrandLogo(
            size: 110,
            isDark: isDark,
            onAnimationComplete: () {
              if (mounted) {
                setState(() => _animationCompleted = true);
                _attemptNavigation();
              }
            },
          ),
        ),
      ),
    );
  }
}
