import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/domain/app_user.dart';
import '../features/auth/presentation/adults_only_screen.dart';
import '../features/auth/presentation/auth_providers.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/presentation/sign_in_screen.dart';
import '../features/auth/presentation/sign_up_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/auth/presentation/verify_email_screen.dart';
import '../features/auth/presentation/welcome_screen.dart';
import '../features/chat/presentation/conversation_screen.dart';
import '../features/chat/presentation/inbox_screen.dart';
import '../features/connections/presentation/connections_screen.dart';
import '../features/discovery/presentation/discover_screen.dart';
import '../features/experiences/presentation/experiences_screen.dart';
import '../features/main_shell/main_shell_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/onboarding/presentation/profile_onboarding_screen.dart';
import '../features/profile/presentation/about_melsava_screen.dart';
import '../features/profile/presentation/blocked_profiles_screen.dart';
import '../features/profile/presentation/community_guidelines_screen.dart';
import '../features/profile/presentation/moderation_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/profile/presentation/settings_screen.dart';

/// Listenable bridge that refreshes GoRouter whenever authentication or onboarding state changes.
class AuthRouterRefreshListenable extends ChangeNotifier {
  late final StreamSubscription<AppUser?> _subscription;

  AuthRouterRefreshListenable(Stream<AppUser?> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Riverpod provider exposing the authentication-aware GoRouter instance.
final appRouterProvider = Provider<GoRouter>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  final refreshListenable = AuthRouterRefreshListenable(
    authRepo.authStateChanges,
  );
  ref.onDispose(refreshListenable.dispose);

  final router = AppRouter.createRouter(
    authRepository: authRepo,
    refreshListenable: refreshListenable,
  );
  ref.onDispose(router.dispose);
  return router;
});

/// MELSAVA complete authentication-aware GoRouter configuration.
class AppRouter {
  AppRouter._();

  static const Set<String> _publicAuthRoutes = {
    '/onboarding',
    '/welcome',
    '/sign-in',
    '/sign-up',
    '/forgot-password',
  };

  static const Set<String> _gateRoutes = {
    '/onboarding',
    '/welcome',
    '/sign-in',
    '/sign-up',
    '/forgot-password',
    '/verify-email',
    '/adults-only',
    '/profile-onboarding',
  };

  /// Pure redirect resolver used by GoRouter and verified by unit/widget tests.
  static String? computeRedirect({
    required String location,
    required AppUser? user,
    String? pendingVerificationEmail,
  }) {
    // Allow Splash and About routes without redirect interference
    if (location == '/' || location == '/about') {
      return null;
    }

    // 1. Unauthenticated state
    if (user == null) {
      if (_publicAuthRoutes.contains(location)) {
        return null;
      }
      if (location == '/verify-email' &&
          pendingVerificationEmail != null &&
          pendingVerificationEmail.isNotEmpty) {
        return null;
      }
      return '/welcome';
    }

    // 2. Authenticated but email not verified
    if (!user.isEmailVerified) {
      return location == '/verify-email' ? null : '/verify-email';
    }

    // 3. Verified email, but adult eligibility (18+ DOB) not completed
    if (!user.ageVerified) {
      return location == '/adults-only' ? null : '/adults-only';
    }

    // 4. Adult eligible, but profile onboarding not completed
    if (!user.onboardingCompleted) {
      return location == '/profile-onboarding' ? null : '/profile-onboarding';
    }

    // 5. Fully authenticated and onboarded
    if (_gateRoutes.contains(location)) {
      return '/discover';
    }

    return null;
  }

  static GoRouter createRouter({
    required AuthRepository authRepository,
    required Listenable refreshListenable,
    String initialLocation = '/',
  }) {
    final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

    return GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: initialLocation,
      debugLogDiagnostics: false,
      refreshListenable: refreshListenable,
      redirect: (context, state) => computeRedirect(
        location: state.matchedLocation,
        user: authRepository.currentUser,
        pendingVerificationEmail: authRepository.pendingVerificationEmail,
      ),
      routes: [
        // Splash
        GoRoute(path: '/', builder: (context, state) => const SplashScreen()),

        // Brand Intro Carousel
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),

        // Adults Only Age Eligibility (18+ Date of Birth Gate)
        GoRoute(
          path: '/adults-only',
          builder: (context, state) => const AdultsOnlyScreen(),
        ),

        // Multi-Step Profile Onboarding Wizard
        GoRoute(
          path: '/profile-onboarding',
          pageBuilder: (context, state) => _buildAuthPageTransition(
            key: state.pageKey,
            child: const ProfileOnboardingScreen(),
          ),
        ),

        // About MELSAVA (Screen 15)
        GoRoute(
          path: '/about',
          builder: (context, state) => const AboutMelsavaScreen(),
        ),

        // Settings (Screen 13)
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),

        // Blocked Profiles
        GoRoute(
          path: '/blocked-profiles',
          builder: (context, state) => const BlockedProfilesScreen(),
        ),

        // Community Guidelines
        GoRoute(
          path: '/community-guidelines',
          builder: (context, state) => const CommunityGuidelinesScreen(),
        ),

        // Moderation Console
        GoRoute(
          path: '/moderation',
          builder: (context, state) => const ModerationScreen(),
        ),

        // Welcome & Auth routes (Smooth fluid switching between pages)
        GoRoute(
          path: '/welcome',
          pageBuilder: (context, state) => _buildAuthPageTransition(
            key: state.pageKey,
            child: const WelcomeScreen(),
          ),
        ),
        GoRoute(
          path: '/sign-in',
          pageBuilder: (context, state) => _buildAuthPageTransition(
            key: state.pageKey,
            child: const SignInScreen(),
          ),
        ),
        GoRoute(
          path: '/sign-up',
          pageBuilder: (context, state) => _buildAuthPageTransition(
            key: state.pageKey,
            child: const SignUpScreen(),
          ),
        ),
        GoRoute(
          path: '/forgot-password',
          pageBuilder: (context, state) => _buildAuthPageTransition(
            key: state.pageKey,
            child: const ForgotPasswordScreen(),
          ),
        ),
        GoRoute(
          path: '/verify-email',
          pageBuilder: (context, state) {
            final email =
                state.extra as String? ??
                authRepository.pendingVerificationEmail ??
                authRepository.currentUser?.email ??
                '';
            return _buildAuthPageTransition(
              key: state.pageKey,
              child: VerifyEmailScreen(email: email),
            );
          },
        ),

        // Chat thread route
        GoRoute(
          path: '/chat/:name',
          builder: (context, state) {
            final name = state.pathParameters['name'] ?? 'Friend';
            final extra = state.extra;
            final String? conversationId = extra is Map
                ? extra['conversationId']?.toString()
                : null;
            final String? connectionId = extra is Map
                ? extra['connectionId']?.toString()
                : null;
            final String? partnerAvatar = extra is Map
                ? extra['partnerAvatar']?.toString()
                : null;
            final String? partnerId = extra is Map
                ? extra['partnerId']?.toString()
                : null;
            final String? experienceName = extra is Map
                ? extra['experienceName']?.toString()
                : null;

            return ConversationScreen(
              participantName: name,
              conversationId: conversationId,
              connectionId: connectionId,
              partnerAvatar: partnerAvatar,
              partnerId: partnerId,
              experienceName: experienceName,
            );
          },
        ),

        // Main persistent 5-tab shell route
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return MainShellScreen(navigationShell: navigationShell);
          },
          branches: [
            // Branch 0: Discover
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/discover',
                  builder: (context, state) => const DiscoverScreen(),
                ),
              ],
            ),

            // Branch 1: Experiences
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/experiences',
                  builder: (context, state) => const ExperiencesScreen(),
                ),
              ],
            ),

            // Branch 2: Connections
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/connections',
                  builder: (context, state) => const ConnectionsScreen(),
                ),
              ],
            ),

            // Branch 3: Inbox
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/inbox',
                  builder: (context, state) => const InboxScreen(),
                ),
              ],
            ),

            // Branch 4: Profile
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/profile',
                  builder: (context, state) => const ProfileScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static Page<dynamic> _buildAuthPageTransition({
    required LocalKey key,
    required Widget child,
  }) {
    return CustomTransitionPage(
      key: key,
      child: child,
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 240),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curveAnim = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curveAnim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.06, 0.0),
              end: Offset.zero,
            ).animate(curveAnim),
            child: child,
          ),
        );
      },
    );
  }
}
