import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/widgets/animated_melsava_brand_logo.dart';
import '../../../shared/widgets/fluid_wave_ribbon.dart';
import 'auth_providers.dart';

/// Screen 1: Scenic Twilight Mountain Sunset Splash Screen
///
/// Features:
/// - Scenic twilight hillside backdrop with 4 friends looking at the sunset
/// - Centered animated glowing MELSAVA brand logo
/// - Brand title and tagline: "Meet through moments. Less swiping. More living."
/// - Soft circular progress ring and connection status
/// - Fluid layered wave ribbons at the bottom
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _navigationTimer;
  bool _sessionChecked = false;
  bool _animationCompleted = false;
  String _nextRoute = '/onboarding';

  @override
  void initState() {
    super.initState();
    _checkAuthSession();

    // Start timer only after first frame is drawn on screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigationTimer = Timer(const Duration(milliseconds: 3200), () {
        if (mounted) {
          setState(() => _animationCompleted = true);
          _attemptNavigation();
        }
      });
    });
  }

  Future<void> _checkAuthSession() async {
    final authRepo = ref.read(authRepositoryProvider);
    await authRepo.restoreSession();
    final user = authRepo.currentUser;
    if (user != null) {
      ref.read(currentUserProvider.notifier).state = user;
      _nextRoute = user.nextRequiredRoute;
    } else {
      ref.read(currentUserProvider.notifier).state = null;
      _nextRoute = '/onboarding';
    }
    _sessionChecked = true;
    _attemptNavigation();
  }

  void _attemptNavigation() {
    if (!mounted || !_sessionChecked || !_animationCompleted) return;
    context.go(_nextRoute);
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF151226),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Scenic Twilight Mountain & Hillside Backdrop ───────────────
          Image.asset(
            'assets/images/splash_scenic_backdrop.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF151226),
                    Color(0xFF3B1E54),
                    Color(0xFF8A2BE2),
                    Color(0xFF140D24),
                  ],
                ),
              ),
            ),
          ),

          // ── Soft Top & Center Lighting Vignette ─────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.45, 0.75, 1.0],
                colors: [
                  Colors.black.withValues(alpha: 0.25),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.15),
                  Colors.black.withValues(alpha: 0.55),
                ],
              ),
            ),
          ),

          // ── Upper Brand & Logo Section ──────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 3),

                // Animated glowing MELSAVA brand logo (Iconic 'M' meeting circles & Glowing Wordmark)
                const AnimatedMelsavaBrandLogo(size: 92, isDark: true),

                const Spacer(flex: 7),

                // Connecting status indicator cleanly elevated above bottom fluid waves
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Connecting people through shared experiences...',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.8),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 64),
              ],
            ),
          ),

          // ── Fluid Layered Wave Ribbon at Bottom ─────────────────────────
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: FluidWaveRibbon(height: 70, opacity: 0.95),
          ),
        ],
      ),
    );
  }
}
