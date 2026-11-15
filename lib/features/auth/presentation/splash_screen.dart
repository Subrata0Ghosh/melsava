import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/melsava_logo.dart';
import 'auth_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppConstants.animSlow,
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();

    // Check auth session before routing
    _navigationTimer = Timer(const Duration(milliseconds: 1800), () async {
      if (!mounted) return;

      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.restoreSession();
      final user = authRepo.currentUser;

      if (!mounted) return;

      if (user != null) {
        ref.read(currentUserProvider.notifier).state = user;
        context.go('/discover');
      } else {
        context.go('/welcome');
      }
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: const MelsavaLogo(
            size: 96,
            showWordmark: true,
            showTagline: true,
          ),
        ),
      ),
    );
  }
}
