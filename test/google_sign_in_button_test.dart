import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:melsava/features/auth/data/auth_repository.dart';
import 'package:melsava/features/auth/domain/app_user.dart';
import 'package:melsava/features/auth/presentation/auth_providers.dart';
import 'package:melsava/features/auth/presentation/sign_in_screen.dart';
import 'package:melsava/shared/widgets/google_sign_in_button.dart';

class _FakeGoogleAuthRepository implements AuthRepository {
  bool googleSignInCalled = false;
  AppUser? _user;

  @override
  Stream<AppUser?> get authStateChanges => const Stream.empty();

  @override
  AppUser? get currentUser => _user;

  @override
  String? get pendingVerificationEmail => null;

  @override
  bool get isDebugMockMode => false;

  @override
  Future<void> restoreSession() async {}

  @override
  Future<void> sendMagicLinkEmail({required String email}) async {}

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {}

  @override
  Future<void> updatePassword({required String newPassword}) async {}

  @override
  Future<void> resendVerificationEmail({required String email}) async {}

  @override
  Future<AppUser?> refreshEmailVerificationStatus() async => _user;

  @override
  Future<AppUser?> refreshCurrentUser() async => _user;

  @override
  Future<AppUser?> debugVerifyEmailIfAllowed() async => null;

  @override
  void syncCachedUser(AppUser user) {
    _user = user;
  }

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<AppUser?> signInWithGoogle() async {
    googleSignInCalled = true;
    _user = const AppUser(
      id: 'google-123',
      email: 'testuser@gmail.com',
      displayName: 'Test User',
      avatarUrl: 'https://example.com/avatar.png',
      city: 'Mumbai',
      isEmailVerified: true,
      ageVerified: true,
      guidelinesAccepted: true,
      onboardingCompleted: true,
    );
    return _user;
  }

  @override
  Future<void> signOut() async {
    _user = null;
  }

  @override
  Future<void> deactivateAccount() async {
    _user = null;
  }

  @override
  Future<void> deleteAccountPermanent() async {
    _user = null;
  }

  @override
  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> updateProfile(AppUser updatedUser) async {
    _user = updatedUser;
  }

  @override
  Future<String?> uploadAvatar(dynamic file) async {
    return 'https://example.com/uploaded_avatar.png';
  }

  @override
  Future<Map<String, dynamic>> getPrivacySettings() async => const {
    'public_radar': true,
    'ghost_mode': false,
    'show_city': true,
  };

  @override
  Future<void> updatePrivacySettings(Map<String, dynamic> settings) async {}
}

void main() {
  testWidgets(
    'GoogleSignInButton renders label, loading spinner, and handles tap',
    (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GoogleSignInButton(onPressed: () => tapped = true),
          ),
        ),
      );

      expect(find.text('Continue with Google'), findsOneWidget);
      await tester.tap(find.text('Continue with Google'));
      await tester.pump();
      expect(tapped, isTrue);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GoogleSignInButton(isLoading: true, onPressed: null),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    },
  );

  testWidgets(
    'SignInScreen triggers Google Sign-In and navigates to /discover',
    (tester) async {
      final fakeRepo = _FakeGoogleAuthRepository();

      final router = GoRouter(
        initialLocation: '/sign-in',
        routes: [
          GoRoute(
            path: '/sign-in',
            builder: (context, state) => const SignInScreen(),
          ),
          GoRoute(
            path: '/discover',
            builder: (context, state) =>
                const Scaffold(body: Text('Discover Home')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [authRepositoryProvider.overrideWithValue(fakeRepo)],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));

      final googleBtn = find.text('Continue with Google');
      expect(googleBtn, findsOneWidget);

      await tester.ensureVisible(googleBtn);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(googleBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(fakeRepo.googleSignInCalled, isTrue);
      expect(find.text('Discover Home'), findsOneWidget);
    },
  );
}
