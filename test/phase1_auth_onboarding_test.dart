import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:melsava/app/app_router.dart';
import 'package:melsava/app/app_theme.dart';
import 'package:melsava/core/utils/auth_validators.dart';
import 'package:melsava/features/auth/data/auth_repository.dart';
import 'package:melsava/features/auth/domain/app_user.dart';
import 'package:melsava/features/auth/presentation/adults_only_screen.dart';
import 'package:melsava/features/auth/presentation/auth_providers.dart';
import 'package:melsava/features/auth/presentation/forgot_password_screen.dart';
import 'package:melsava/features/auth/presentation/sign_in_screen.dart';
import 'package:melsava/features/auth/presentation/sign_up_screen.dart';
import 'package:melsava/features/auth/presentation/verify_email_screen.dart';
import 'package:melsava/features/onboarding/data/onboarding_repository.dart';
import 'package:melsava/features/onboarding/domain/onboarding_models.dart';
import 'package:melsava/features/onboarding/presentation/onboarding_providers.dart';
import 'package:melsava/features/onboarding/presentation/profile_onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _InMemoryAuthRepository implements AuthRepository {
  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _user;
  String? _pendingEmail;
  bool resendCalled = false;
  bool resetCalled = false;
  bool signOutCalled = false;
  bool nextSignInCompletedProfile = false;
  bool verifiedOnRefresh = false;

  _InMemoryAuthRepository({AppUser? initialUser}) : _user = initialUser;

  @override
  Stream<AppUser?> get authStateChanges => _controller.stream;

  @override
  AppUser? get currentUser => _user;

  @override
  String? get pendingVerificationEmail => _pendingEmail;

  @override
  bool get isDebugMockMode => false;

  @override
  Future<void> restoreSession() async {
    _controller.add(_user);
  }

  @override
  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    _pendingEmail = email;
    _user = AppUser(
      id: 'user-new-1',
      email: email,
      displayName: email.split('@').first,
      isEmailVerified: false,
      ageVerified: false,
      onboardingCompleted: false,
    );
    _controller.add(_user);
    return _user!;
  }

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _user = AppUser(
      id: 'user-login-1',
      email: email,
      displayName: 'Alex',
      city: nextSignInCompletedProfile ? 'Mumbai' : null,
      isEmailVerified: true,
      ageVerified: true,
      guidelinesAccepted: nextSignInCompletedProfile,
      onboardingCompleted: nextSignInCompletedProfile,
    );
    _controller.add(_user);
    return _user!;
  }

  @override
  Future<AppUser?> signInWithGoogle() async => null;

  @override
  Future<void> sendMagicLinkEmail({required String email}) async {}

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    resetCalled = true;
  }

  @override
  Future<void> resendVerificationEmail({required String email}) async {
    resendCalled = true;
  }

  @override
  Future<AppUser?> refreshEmailVerificationStatus() async {
    if (verifiedOnRefresh && _user != null) {
      _user = _user!.copyWith(isEmailVerified: true);
      _pendingEmail = null;
      _controller.add(_user);
    }
    return _user;
  }

  @override
  Future<AppUser?> refreshCurrentUser() async => _user;

  @override
  Future<AppUser?> debugVerifyEmailIfAllowed() async => null;

  @override
  Future<void> signOut() async {
    signOutCalled = true;
    _user = null;
    _pendingEmail = null;
    _controller.add(null);
  }

  @override
  Future<void> deactivateAccount() async {
    signOutCalled = true;
    _user = null;
    _pendingEmail = null;
    _controller.add(null);
  }

  @override
  Future<void> deleteAccountPermanent() async {
    signOutCalled = true;
    _user = null;
    _pendingEmail = null;
    _controller.add(null);
  }

  @override
  Future<void> updateProfile(AppUser updatedUser) async {
    _user = updatedUser;
    _controller.add(_user);
  }

  @override
  Future<String?> uploadAvatar(dynamic file) async {
    return 'https://example.com/uploaded_avatar.png';
  }

  @override
  void syncCachedUser(AppUser user) {
    _user = user;
    _controller.add(_user);
  }

  void dispose() => _controller.close();
}

class _InMemoryOnboardingRepository implements OnboardingRepository {
  final _InMemoryAuthRepository authRepo;
  DateTime? savedDob;
  OnboardingProfileDraft? savedDraft;

  _InMemoryOnboardingRepository(this.authRepo);

  @override
  Future<AppUser> saveAdultEligibility({
    required AppUser currentUser,
    required DateTime dateOfBirth,
  }) async {
    if (!AuthValidators.isAdult(dateOfBirth)) {
      throw const UnderageUserException();
    }
    savedDob = dateOfBirth;
    final updated = currentUser.copyWith(ageVerified: true);
    authRepo.syncCachedUser(updated);
    return updated;
  }

  @override
  Future<String> uploadProfilePhoto({
    required String userId,
    required Uint8List bytes,
    required String fileExtension,
    String? localFallbackPath,
  }) async {
    return 'https://example.com/avatars/$userId/avatar.$fileExtension';
  }

  @override
  Future<OnboardingReferenceData> fetchReferenceOptions() async {
    return const OnboardingReferenceData(
      interests: SupabaseOnboardingRepository.defaultInterests,
      intentions: SupabaseOnboardingRepository.defaultIntentions,
      activityCategories:
          SupabaseOnboardingRepository.defaultActivityCategories,
    );
  }

  @override
  Future<AppUser> completeProfileOnboarding({
    required AppUser currentUser,
    required OnboardingProfileDraft draft,
  }) async {
    savedDraft = draft;
    final updated = currentUser.copyWith(
      displayName: draft.displayName,
      avatarUrl: draft.avatarUrl,
      city: draft.city,
      bio: draft.bio,
      interests: draft.interests,
      preferredActivityCategories: draft.preferredActivityCategories,
      primaryIntent: draft.primaryIntention,
      availability: draft.availability,
      discoveryMinAge: draft.discoveryMinAge,
      discoveryMaxAge: draft.discoveryMaxAge,
      discoveryMaxDistanceKm: draft.discoveryMaxDistanceKm,
      discoveryFormat: draft.discoveryFormat,
      ageVerified: true,
      guidelinesAccepted: true,
      onboardingCompleted: true,
    );
    authRepo.syncCachedUser(updated);
    return updated;
  }
}

void main() {
  group('AuthValidators & Adult Eligibility Logic', () {
    test('rejects underage DOB and accepts exact 18+ DOB', () {
      final refDate = DateTime(2026, 11, 18);

      // 17 years, 364 days old -> underage
      expect(
        AuthValidators.isAdult(DateTime(2008, 11, 19), referenceDate: refDate),
        isFalse,
      );
      // Exactly 18 years old -> eligible
      expect(
        AuthValidators.isAdult(DateTime(2008, 11, 18), referenceDate: refDate),
        isTrue,
      );
      // Future date -> invalid
      expect(
        AuthValidators.isAdult(DateTime(2027, 1, 1), referenceDate: refDate),
        isFalse,
      );
      expect(AuthValidators.formatIsoDate(DateTime(1998, 4, 7)), '1998-04-07');
    });

    test('validates email, password, and display name cleanly', () {
      expect(AuthValidators.validateEmail(''), isNotNull);
      expect(AuthValidators.validateEmail('not-an-email'), isNotNull);
      expect(AuthValidators.validateEmail('alex@example.com'), isNull);
      expect(AuthValidators.validatePassword('12345'), isNotNull);
      expect(AuthValidators.validatePassword('123456'), isNull);
      expect(AuthValidators.validateDisplayName('A'), isNotNull);
      expect(AuthValidators.validateDisplayName('Aarav'), isNull);
    });
  });

  group('Auth-Aware GoRouter Redirects', () {
    test(
      'redirects unauthenticated users away from protected routes to /welcome',
      () {
        expect(
          AppRouter.computeRedirect(location: '/discover', user: null),
          '/welcome',
        );
        expect(
          AppRouter.computeRedirect(
            location: '/profile-onboarding',
            user: null,
          ),
          '/welcome',
        );
        expect(
          AppRouter.computeRedirect(location: '/sign-in', user: null),
          isNull,
        );
        expect(
          AppRouter.computeRedirect(
            location: '/verify-email',
            user: null,
            pendingVerificationEmail: 'new@example.com',
          ),
          isNull,
        );
      },
    );

    test(
      'enforces strict step progression: verify-email -> adults-only -> profile-onboarding -> discover',
      () {
        const unverified = AppUser(
          id: '1',
          email: 'u@example.com',
          isEmailVerified: false,
          ageVerified: false,
          onboardingCompleted: false,
        );
        expect(
          AppRouter.computeRedirect(location: '/discover', user: unverified),
          '/verify-email',
        );
        expect(
          AppRouter.computeRedirect(location: '/adults-only', user: unverified),
          '/verify-email',
        );

        const needAge = AppUser(
          id: '1',
          email: 'u@example.com',
          isEmailVerified: true,
          ageVerified: false,
          onboardingCompleted: false,
        );
        expect(
          AppRouter.computeRedirect(location: '/discover', user: needAge),
          '/adults-only',
        );
        expect(
          AppRouter.computeRedirect(
            location: '/profile-onboarding',
            user: needAge,
          ),
          '/adults-only',
        );

        const needProfile = AppUser(
          id: '1',
          email: 'u@example.com',
          isEmailVerified: true,
          ageVerified: true,
          onboardingCompleted: false,
        );
        expect(
          AppRouter.computeRedirect(location: '/discover', user: needProfile),
          '/profile-onboarding',
        );
        expect(
          AppRouter.computeRedirect(
            location: '/profile-onboarding',
            user: needProfile,
          ),
          isNull,
        );

        const completed = AppUser(
          id: '1',
          email: 'u@example.com',
          isEmailVerified: true,
          ageVerified: true,
          onboardingCompleted: true,
        );
        expect(
          AppRouter.computeRedirect(location: '/sign-in', user: completed),
          '/discover',
        );
        expect(
          AppRouter.computeRedirect(location: '/discover', user: completed),
          isNull,
        );
      },
    );
  });

  group('Session Restoration Truth (No Fake SharedPreferences Auth)', () {
    test(
      'SupabaseAuthRepository does not restore fake user from SharedPreferences',
      () async {
        SharedPreferences.setMockInitialValues({
          'melsava_user_id': 'fake-id',
          'melsava_user_email': 'fake@melsava.com',
          'melsava_user_name': 'Fake User',
        });

        final repo = SupabaseAuthRepository();
        await repo.restoreSession();
        expect(repo.currentUser, isNull);
        repo.dispose();
      },
    );
  });

  group('Sign-In, Sign-Up, Verification, Forgot Password & Logout Flows', () {
    testWidgets('SignInScreen has no pre-filled hard-coded demo credentials', (
      tester,
    ) async {
      final authRepo = _InMemoryAuthRepository();
      addTearDown(authRepo.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [authRepositoryProvider.overrideWithValue(authRepo)],
          child: MaterialApp(theme: AppTheme.light, home: const SignInScreen()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('admin@melsava.com'), findsNothing);
      expect(find.text('Melsava2026'), findsNothing);
    });

    testWidgets(
      'SignUp routes to VerifyEmail -> blocks until verified -> advances to AdultsOnly',
      (tester) async {
        final authRepo = _InMemoryAuthRepository();
        addTearDown(authRepo.dispose);

        final router = GoRouter(
          initialLocation: '/sign-up',
          routes: [
            GoRoute(
              path: '/sign-up',
              builder: (context, state) => const SignUpScreen(),
            ),
            GoRoute(
              path: '/verify-email',
              builder: (context, state) =>
                  VerifyEmailScreen(email: state.extra as String? ?? ''),
            ),
            GoRoute(
              path: '/adults-only',
              builder: (context, state) =>
                  const Scaffold(body: Text('Adults Only Gate')),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [authRepositoryProvider.overrideWithValue(authRepo)],
            child: MaterialApp.router(
              theme: AppTheme.light,
              routerConfig: router,
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 200));

        final fields = find.byType(TextField);
        await tester.enterText(fields.at(0), 'riya@example.com');
        await tester.enterText(fields.at(1), 'SecurePass123');
        await tester.enterText(fields.at(2), 'SecurePass123');

        final checkbox = find.byType(Checkbox);
        await tester.ensureVisible(checkbox);
        await tester.tap(checkbox);
        await tester.pump();

        final createBtn = find.text('Create Account').last;
        await tester.ensureVisible(createBtn);
        await tester.tap(createBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        // Must land on VerifyEmailScreen, NOT Discover
        expect(find.text('Verify your email'), findsOneWidget);
        expect(
          find.textContaining(
            'We sent a verification link to:\nriya@example.com',
          ),
          findsOneWidget,
        );

        // Tapping "I Have Verified My Email" before actual verification stays blocked
        final checkBtn = find.text('I Have Verified My Email');
        await tester.ensureVisible(checkBtn);
        await tester.tap(checkBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.textContaining('not verified yet'), findsOneWidget);

        // Resend verification email works
        final resendBtn = find.text('Resend Verification Email');
        await tester.ensureVisible(resendBtn);
        await tester.tap(resendBtn);
        await tester.pump();
        expect(authRepo.resendCalled, isTrue);

        // Once verified on server, checking advances to Adults Only
        authRepo.verifiedOnRefresh = true;
        await tester.tap(checkBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text('Adults Only Gate'), findsOneWidget);
      },
    );

    testWidgets(
      'Login routes incomplete profile to /profile-onboarding and completed profile to /discover',
      (tester) async {
        final authRepo = _InMemoryAuthRepository();
        addTearDown(authRepo.dispose);

        GoRouter buildTestRouter() => GoRouter(
          initialLocation: '/sign-in',
          routes: [
            GoRoute(
              path: '/sign-in',
              builder: (context, state) => const SignInScreen(),
            ),
            GoRoute(
              path: '/profile-onboarding',
              builder: (context, state) =>
                  const Scaffold(body: Text('Onboarding Wizard')),
            ),
            GoRoute(
              path: '/discover',
              builder: (context, state) =>
                  const Scaffold(body: Text('Discover Feed')),
            ),
          ],
        );

        // Case 1: Incomplete profile -> /profile-onboarding
        authRepo.nextSignInCompletedProfile = false;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [authRepositoryProvider.overrideWithValue(authRepo)],
            child: MaterialApp.router(
              theme: AppTheme.light,
              routerConfig: buildTestRouter(),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 200));

        await tester.enterText(
          find.byType(TextField).at(0),
          'alex@example.com',
        );
        await tester.enterText(find.byType(TextField).at(1), 'Password123');
        await tester.tap(find.text('Sign In').first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text('Onboarding Wizard'), findsOneWidget);

        // Case 2: Completed profile -> /discover
        authRepo.nextSignInCompletedProfile = true;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [authRepositoryProvider.overrideWithValue(authRepo)],
            child: MaterialApp.router(
              theme: AppTheme.dark,
              routerConfig: buildTestRouter(),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 200));

        await tester.enterText(
          find.byType(TextField).at(0),
          'alex@example.com',
        );
        await tester.enterText(find.byType(TextField).at(1), 'Password123');
        await tester.tap(find.text('Sign In').first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text('Discover Feed'), findsOneWidget);
      },
    );

    testWidgets(
      'ForgotPasswordScreen validates and sends password reset email',
      (tester) async {
        final authRepo = _InMemoryAuthRepository();
        addTearDown(authRepo.dispose);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [authRepositoryProvider.overrideWithValue(authRepo)],
            child: MaterialApp(
              theme: AppTheme.dark,
              home: const ForgotPasswordScreen(),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 200));

        await tester.enterText(find.byType(TextField), 'reset@example.com');
        await tester.tap(find.text('Send Reset Link'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(authRepo.resetCalled, isTrue);
      },
    );
  });

  group(
    'Adult Eligibility & Complete Profile Onboarding Wizard (Light & Dark)',
    () {
      testWidgets('AdultsOnlyScreen blocks under-18 and requires DOB', (
        tester,
      ) async {
        const user = AppUser(
          id: 'u-age',
          email: 'age@example.com',
          isEmailVerified: true,
          ageVerified: false,
          onboardingCompleted: false,
        );
        final authRepo = _InMemoryAuthRepository(initialUser: user);
        final onboardingRepo = _InMemoryOnboardingRepository(authRepo);
        addTearDown(authRepo.dispose);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(authRepo),
              onboardingRepositoryProvider.overrideWithValue(onboardingRepo),
            ],
            child: MaterialApp(
              theme: AppTheme.light,
              home: const AdultsOnlyScreen(),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 200));

        // Tapping continue without DOB shows validation error
        await tester.tap(find.text('I am 18 or Older'));
        await tester.pump();
        expect(
          find.text('Please select your date of birth to continue.'),
          findsOneWidget,
        );

        // Tapping "I am under 18" blocks continuation
        final under18 = find.text('I am under 18');
        await tester.ensureVisible(under18);
        await tester.pump();
        await tester.tap(under18);
        await tester.pump();
        expect(find.text('Age Requirement (18+)'), findsOneWidget);
      });

      testWidgets(
        'ProfileOnboardingScreen completes all 6 steps in Dark Mode and navigates to /discover',
        (tester) async {
          const user = AppUser(
            id: 'u-onb',
            email: 'maya@example.com',
            isEmailVerified: true,
            ageVerified: true,
            onboardingCompleted: false,
          );
          final authRepo = _InMemoryAuthRepository(initialUser: user);
          final onboardingRepo = _InMemoryOnboardingRepository(authRepo);
          addTearDown(authRepo.dispose);

          final router = GoRouter(
            initialLocation: '/profile-onboarding',
            routes: [
              GoRoute(
                path: '/profile-onboarding',
                builder: (context, state) => const ProfileOnboardingScreen(),
              ),
              GoRoute(
                path: '/discover',
                builder: (context, state) =>
                    const Scaffold(body: Text('Discover Ready')),
              ),
            ],
          );

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                authRepositoryProvider.overrideWithValue(authRepo),
                onboardingRepositoryProvider.overrideWithValue(onboardingRepo),
              ],
              child: MaterialApp.router(
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                themeMode: ThemeMode.dark,
                routerConfig: router,
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 250));

          // Step 1: Display Name
          expect(find.text('Step 1 of 6'), findsOneWidget);
          await tester.enterText(find.byType(TextField).first, 'Maya');
          await tester.tap(find.text('Continue'));
          await tester.pump(const Duration(milliseconds: 200));

          // Step 2: City & Bio
          expect(find.text('Step 2 of 6'), findsOneWidget);
          await tester.enterText(find.byType(TextField).at(0), 'Mumbai');
          await tester.enterText(
            find.byType(TextField).at(1),
            'Coffee walks and weekend trails.',
          );
          await tester.tap(find.text('Continue'));
          await tester.pump(const Duration(milliseconds: 200));

          // Step 3: Interests & Activity Preferences
          expect(find.text('Step 3 of 6'), findsOneWidget);
          await tester.tap(find.text('Travel'));
          await tester.pump();
          final catChip = find.text('Coffee & Conversation');
          await tester.ensureVisible(catChip);
          await tester.tap(catChip);
          await tester.pump();
          await tester.tap(find.text('Continue'));
          await tester.pump(const Duration(milliseconds: 200));

          // Step 4: Connection Intentions
          expect(find.text('Step 4 of 6'), findsOneWidget);
          await tester.tap(find.text('Genuine friendship'));
          await tester.pump();
          await tester.tap(find.text('Continue'));
          await tester.pump(const Duration(milliseconds: 200));

          // Step 5: Availability & Discovery Preferences
          expect(find.text('Step 5 of 6'), findsOneWidget);
          await tester.tap(find.text('Continue'));
          await tester.pump(const Duration(milliseconds: 200));

          // Step 6: Community Guidelines
          expect(find.text('Step 6 of 6'), findsOneWidget);
          final acceptCheckbox = find.byType(Checkbox);
          await tester.ensureVisible(acceptCheckbox);
          await tester.tap(acceptCheckbox);
          await tester.pump();

          await tester.tap(find.text('Complete Profile & Explore →'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));

          expect(onboardingRepo.savedDraft, isNotNull);
          expect(onboardingRepo.savedDraft!.displayName, 'Maya');
          expect(onboardingRepo.savedDraft!.city, 'Mumbai');
          expect(onboardingRepo.savedDraft!.guidelinesAccepted, isTrue);
          expect(authRepo.currentUser?.onboardingCompleted, isTrue);
          expect(find.text('Discover Ready'), findsOneWidget);
        },
      );

      testWidgets(
        'ProfileOnboardingScreen Sign Out clears session and navigates to /welcome in Light Mode',
        (tester) async {
          const user = AppUser(
            id: 'u-logout',
            email: 'logout@example.com',
            isEmailVerified: true,
            ageVerified: true,
            onboardingCompleted: false,
          );
          final authRepo = _InMemoryAuthRepository(initialUser: user);
          final onboardingRepo = _InMemoryOnboardingRepository(authRepo);
          addTearDown(authRepo.dispose);

          final router = GoRouter(
            initialLocation: '/profile-onboarding',
            routes: [
              GoRoute(
                path: '/profile-onboarding',
                builder: (context, state) => const ProfileOnboardingScreen(),
              ),
              GoRoute(
                path: '/welcome',
                builder: (context, state) =>
                    const Scaffold(body: Text('Welcome Back Screen')),
              ),
            ],
          );

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                authRepositoryProvider.overrideWithValue(authRepo),
                onboardingRepositoryProvider.overrideWithValue(onboardingRepo),
              ],
              child: MaterialApp.router(
                theme: AppTheme.light,
                themeMode: ThemeMode.light,
                routerConfig: router,
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 250));

          await tester.tap(find.text('Sign Out'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));

          expect(authRepo.signOutCalled, isTrue);
          expect(authRepo.currentUser, isNull);
          expect(find.text('Welcome Back Screen'), findsOneWidget);
        },
      );
    },
  );
}
