import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melsava/app/app_router.dart';
import 'package:melsava/features/auth/data/auth_repository.dart';
import 'package:melsava/features/auth/domain/app_user.dart';
import 'package:melsava/features/auth/presentation/auth_providers.dart';
import 'package:melsava/features/auth/presentation/reset_password_screen.dart';
import 'package:melsava/shared/models/experience_model.dart';
import 'package:melsava/shared/widgets/offline_notice_bar.dart';

class _FakePhase6AuthRepo implements AuthRepository {
  bool updatePasswordCalled = false;
  String? lastUpdatedPassword;

  @override
  Stream<AppUser?> get authStateChanges => const Stream.empty();

  @override
  AppUser? get currentUser => null;

  @override
  String? get pendingVerificationEmail => null;

  @override
  bool get isDebugMockMode => false;

  @override
  Future<void> restoreSession() async {}

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async => throw UnimplementedError();

  @override
  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
  }) async => throw UnimplementedError();

  @override
  Future<AppUser?> signInWithGoogle() async => null;

  @override
  Future<void> sendMagicLinkEmail({required String email}) async {}

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {}

  @override
  Future<void> updatePassword({required String newPassword}) async {
    updatePasswordCalled = true;
    lastUpdatedPassword = newPassword;
  }

  @override
  Future<void> resendVerificationEmail({required String email}) async {}

  @override
  Future<AppUser?> refreshEmailVerificationStatus() async => null;

  @override
  Future<AppUser?> refreshCurrentUser() async => null;

  @override
  Future<AppUser?> debugVerifyEmailIfAllowed() async => null;

  @override
  Future<void> signOut() async {}

  @override
  Future<void> deactivateAccount() async {}

  @override
  Future<void> deleteAccountPermanent() async {}

  @override
  Future<void> updateProfile(AppUser updatedUser) async {}

  @override
  Future<String?> uploadAvatar(dynamic file) async => null;

  @override
  Future<Map<String, dynamic>> getPrivacySettings() async => {};

  @override
  Future<void> updatePrivacySettings(Map<String, dynamic> settings) async {}

  @override
  void syncCachedUser(AppUser user) {}
}

void main() {
  group('Phase 6: Deep Links & Auth Redirect Tests', () {
    test(
      'computeRedirect allows /reset-password for unauthenticated users',
      () {
        final redirect = AppRouter.computeRedirect(
          location: '/reset-password',
          user: null,
        );
        expect(redirect, isNull);
      },
    );

    test('computeRedirect allows /auth-callback without interference', () {
      final redirect = AppRouter.computeRedirect(
        location: '/auth-callback',
        user: null,
      );
      expect(redirect, isNull);
    });
  });

  group('Phase 6: ResetPasswordScreen Widget Tests', () {
    testWidgets('Validates password length and matching confirm field', (
      tester,
    ) async {
      final fakeAuth = _FakePhase6AuthRepo();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [authRepositoryProvider.overrideWithValue(fakeAuth)],
          child: const MaterialApp(home: ResetPasswordScreen()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Create New Password'), findsOneWidget);

      // Enter short password (< 6 chars)
      await tester.enterText(
        find.widgetWithText(TextField, 'At least 8 characters'),
        '123',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Re-enter your password'),
        '123',
      );
      await tester.tap(find.text('Update Password'));
      await tester.pump(const Duration(milliseconds: 200));

      expect(
        find.text('Password must be at least 6 characters'),
        findsOneWidget,
      );
      expect(fakeAuth.updatePasswordCalled, isFalse);

      // Enter mismatched password
      await tester.enterText(
        find.widgetWithText(TextField, 'At least 8 characters'),
        'validPassword123!',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Re-enter your password'),
        'differentPassword123!',
      );
      await tester.tap(find.text('Update Password'));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Passwords do not match.'), findsOneWidget);
      expect(fakeAuth.updatePasswordCalled, isFalse);

      // Enter valid matching password
      await tester.enterText(
        find.widgetWithText(TextField, 'Re-enter your password'),
        'validPassword123!',
      );
      await tester.tap(find.text('Update Password'));
      await tester.pump(const Duration(milliseconds: 200));

      expect(fakeAuth.updatePasswordCalled, isTrue);
      expect(fakeAuth.lastUpdatedPassword, equals('validPassword123!'));
      expect(find.text('Password Updated'), findsOneWidget);
    });
  });

  group('Phase 6: Offline Resilience & Notice Bar Tests', () {
    testWidgets('OfflineNoticeBar renders sync time and handles retry tap', (
      tester,
    ) async {
      bool retryTapped = false;
      final syncTime = DateTime(2026, 11, 21, 14, 30);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OfflineNoticeBar(
              lastSyncedAt: syncTime,
              onRetry: () => retryTapped = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Offline Mode • Cached at 14:30'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      expect(retryTapped, isTrue);
    });

    test('ExperienceModel serializes to and deserializes from JSON', () {
      final exp = ExperienceModel(
        id: 'test-exp-01',
        title: 'Sunset Photography Walk',
        description: 'Vetted outdoor photo session',
        categoryName: 'Photography',
        categoryIcon: '📸',
        coverImageUrl: 'https://images.unsplash.com/photo-test',
        city: 'Kolkata',
        venueName: 'Victoria Memorial',
        venueAddress: 'Queens Way, Maidan',
        isOnline: false,
        startsAt: DateTime(2026, 11, 22, 16, 0),
        durationMinutes: 120,
        maxParticipants: 10,
        currentParticipants: 4,
        waitlistCount: 1,
        hostName: 'MELSAVA Host',
        hostAvatar: 'https://images.unsplash.com/avatar',
        attendeeAvatars: const [],
        experienceStatus: 'published',
        membershipStatus: MembershipStatus.joined,
        hasJoined: true,
      );

      final json = exp.toJson();
      final restored = ExperienceModel.fromJson(json);

      expect(restored.id, equals(exp.id));
      expect(restored.title, equals(exp.title));
      expect(restored.categoryName, equals(exp.categoryName));
      expect(restored.city, equals(exp.city));
      expect(restored.currentParticipants, equals(4));
      expect(restored.membershipStatus, equals(MembershipStatus.joined));
      expect(restored.hasJoined, isTrue);
    });
  });
}
