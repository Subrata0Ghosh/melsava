import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/presentation/sign_in_screen.dart';
import '../features/auth/presentation/sign_up_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/auth/presentation/verify_email_screen.dart';
import '../features/auth/presentation/welcome_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/chat/presentation/conversation_screen.dart';
import '../features/chat/presentation/inbox_screen.dart';
import '../features/connections/presentation/connections_screen.dart';
import '../features/discovery/presentation/discover_screen.dart';
import '../features/experiences/presentation/experiences_screen.dart';
import '../features/main_shell/main_shell_screen.dart';
import '../features/profile/presentation/profile_screen.dart';

/// Global navigation key
final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

/// MELSAVA complete GoRouter configuration
class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: false,
    routes: [
      // Splash
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),

      // Onboarding
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Welcome & Auth routes
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/sign-in',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/sign-up',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) {
          final email = state.extra as String? ?? 'your email';
          return VerifyEmailScreen(email: email);
        },
      ),

      // Chat thread route
      GoRoute(
        path: '/chat/:name',
        builder: (context, state) {
          final name = state.pathParameters['name'] ?? 'Friend';
          return ConversationScreen(participantName: name);
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
