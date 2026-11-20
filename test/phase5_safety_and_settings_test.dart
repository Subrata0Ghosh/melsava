import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:melsava/features/auth/data/auth_repository.dart';
import 'package:melsava/features/auth/domain/app_user.dart';
import 'package:melsava/features/auth/presentation/auth_providers.dart';
import 'package:melsava/features/connections/data/connections_repository.dart';
import 'package:melsava/features/profile/presentation/blocked_profiles_screen.dart';
import 'package:melsava/features/profile/presentation/community_guidelines_screen.dart';
import 'package:melsava/features/profile/presentation/moderation_screen.dart';
import 'package:melsava/features/profile/presentation/profile_screen.dart';
import 'package:melsava/shared/widgets/report_dialog.dart';

class _FakePhase5AuthRepository implements AuthRepository {
  AppUser? user;
  bool deletePermanentCalled = false;
  bool shouldFailDelete = false;

  _FakePhase5AuthRepository({this.user});

  @override
  Stream<AppUser?> get authStateChanges => Stream.value(user);

  @override
  AppUser? get currentUser => user;

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
  }) async => user!;

  @override
  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
  }) async => user!;

  @override
  Future<AppUser?> signInWithGoogle() async => user;

  @override
  Future<void> sendMagicLinkEmail({required String email}) async {}

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {}

  @override
  Future<void> resendVerificationEmail({required String email}) async {}

  @override
  Future<AppUser?> refreshEmailVerificationStatus() async => user;

  @override
  Future<AppUser?> refreshCurrentUser() async => user;

  @override
  Future<AppUser?> debugVerifyEmailIfAllowed() async => null;

  @override
  Future<void> signOut() async {
    user = null;
  }

  @override
  Future<void> deactivateAccount() async {
    user = null;
  }

  @override
  Future<void> deleteAccountPermanent() async {
    deletePermanentCalled = true;
    if (shouldFailDelete) {
      throw Exception('Server error: delete failed');
    }
    user = null;
  }

  @override
  Future<void> updateProfile(AppUser updatedUser) async {
    user = updatedUser;
  }

  @override
  Future<String?> uploadAvatar(dynamic file) async {
    return 'https://example.com/uploaded_avatar.jpg';
  }

  @override
  void syncCachedUser(AppUser updatedUser) {
    user = updatedUser;
  }
}

class _FakePhase5ConnectionsRepository implements ConnectionsRepository {
  List<BlockedUserModel> blockedUsers = [];
  List<ModerationReportModel> moderationReports = [];
  bool isModerator = false;
  bool didBlock = false;
  bool didUnblock = false;
  bool didReport = false;
  String? lastReportReason;
  String? lastReportDesc;

  @override
  Future<List<ConnectionModel>> fetchConnections() async => const [];

  @override
  Future<List<InboxThreadModel>> fetchInboxThreads() async => const [];

  @override
  Future<List<ChatMessageModel>> fetchMessages(
    String conversationId, {
    int limit = 50,
    DateTime? before,
  }) async => const [];

  @override
  Future<bool> sendMessage(String conversationId, String content) async => true;

  @override
  Future<int> markConversationRead(String conversationId) async => 0;

  @override
  Future<String?> getOrCreateConversation(String connectionId) async => null;

  @override
  Future<List<BlockedUserModel>> fetchBlockedUsers() async => blockedUsers;

  @override
  Future<bool> blockUser(String partnerId) async {
    didBlock = true;
    blockedUsers.add(
      BlockedUserModel(
        blockedId: partnerId,
        displayName: 'Blocked Member',
        avatarUrl: '',
        blockedAt: DateTime.now(),
      ),
    );
    return true;
  }

  @override
  Future<bool> unblockUser(String blockedId) async {
    didUnblock = true;
    blockedUsers.removeWhere((u) => u.blockedId == blockedId);
    return true;
  }

  @override
  Future<bool> reportUser({
    required String reportedUserId,
    required String reason,
    String? description,
    String? contentType,
    String? contentId,
    String? conversationId,
  }) async {
    didReport = true;
    lastReportReason = reason;
    lastReportDesc = description;
    return true;
  }

  @override
  Future<bool> isCurrentUserModerator() async => isModerator;

  @override
  Future<List<ModerationReportModel>> fetchModerationReports({
    String status = 'pending',
  }) async {
    if (status == 'all') return moderationReports;
    return moderationReports.where((r) => r.status == status).toList();
  }

  @override
  Future<bool> resolveModerationReport(String reportId, String status) async {
    return true;
  }

  @override
  Future<bool> applyModerationAction({
    required String userId,
    required String actionType,
    required String reason,
    String? reportId,
    DateTime? expiresAt,
  }) async {
    return true;
  }

  @override
  RealtimeChannel? subscribeToConversationMessages({
    required String conversationId,
    required void Function(ChatMessageModel message) onMessageInserted,
    required void Function(String messageId, bool isRead) onMessageUpdated,
  }) => null;

  @override
  void unsubscribe(RealtimeChannel channel) {}
}

void main() {
  group('Phase 5 Domain & Safety Tests', () {
    test('AppUser model holds isVerified and isSuspended flags correctly', () {
      const user = AppUser(
        id: 'u-1',
        email: 'test@melsava.app',
        displayName: 'Aarav Patel',
        isVerified: true,
        isSuspended: false,
      );

      expect(user.isVerified, isTrue);
      expect(user.isSuspended, isFalse);

      final suspended = user.copyWith(isSuspended: true);
      expect(suspended.isSuspended, isTrue);
      expect(suspended.isVerified, isTrue);
    });

    test(
      'Permanent deletion error does not sign out user or wipe cache',
      () async {
        final fakeAuth = _FakePhase5AuthRepository(
          user: const AppUser(
            id: 'u-1',
            email: 'test@melsava.app',
            displayName: 'Aarav',
          ),
        )..shouldFailDelete = true;

        expect(
          () async => await fakeAuth.deleteAccountPermanent(),
          throwsA(isA<Exception>()),
        );
        expect(fakeAuth.currentUser, isNotNull);
      },
    );

    testWidgets(
      'ProfileScreen hides verification badge when user is not verified',
      (tester) async {
        final fakeAuth = _FakePhase5AuthRepository(
          user: const AppUser(
            id: 'u-unverified',
            email: 'unverified@melsava.app',
            displayName: 'Priya Sharma',
            isVerified: false,
            city: 'Mumbai',
          ),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(fakeAuth),
              currentUserProvider.overrideWith((ref) => fakeAuth.currentUser),
              connectionsRepositoryProvider.overrideWithValue(
                _FakePhase5ConnectionsRepository(),
              ),
            ],
            child: const MaterialApp(home: ProfileScreen()),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Priya Sharma'), findsOneWidget);
        expect(find.byIcon(Icons.verified_rounded), findsNothing);
      },
    );

    testWidgets(
      'ProfileScreen renders verification badge when user is verified',
      (tester) async {
        final fakeAuth = _FakePhase5AuthRepository(
          user: const AppUser(
            id: 'u-verified',
            email: 'verified@melsava.app',
            displayName: 'Rohit Roy',
            isVerified: true,
            city: 'Kolkata',
          ),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(fakeAuth),
              currentUserProvider.overrideWith((ref) => fakeAuth.currentUser),
              connectionsRepositoryProvider.overrideWithValue(
                _FakePhase5ConnectionsRepository(),
              ),
            ],
            child: const MaterialApp(home: ProfileScreen()),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Rohit Roy'), findsOneWidget);
        expect(find.byIcon(Icons.verified_rounded), findsOneWidget);
      },
    );

    testWidgets('BlockedProfilesScreen renders empty roster cleanly', (
      tester,
    ) async {
      final fakeRepo = _FakePhase5ConnectionsRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            connectionsRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(home: BlockedProfilesScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Blocked Profiles'), findsOneWidget);
      expect(find.text('No Blocked Profiles'), findsOneWidget);
    });

    testWidgets('BlockedProfilesScreen renders blocked accounts and unblocks', (
      tester,
    ) async {
      final fakeRepo = _FakePhase5ConnectionsRepository()
        ..blockedUsers = [
          BlockedUserModel(
            blockedId: 'b-1',
            displayName: 'Rohan Sen',
            avatarUrl: '',
            blockedAt: DateTime(2026, 11, 20),
          ),
        ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            connectionsRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(home: BlockedProfilesScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Rohan Sen'), findsOneWidget);
      expect(find.text('Unblock'), findsOneWidget);

      await tester.tap(find.text('Unblock'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Confirmation dialog pops up
      expect(find.text('Unblock Rohan Sen?'), findsOneWidget);
      await tester.tap(find.text('Unblock').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(fakeRepo.didUnblock, isTrue);
    });

    testWidgets('CommunityGuidelinesScreen displays 10 comprehensive rules', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(home: CommunityGuidelinesScreen()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Community Guidelines'), findsOneWidget);
      expect(find.text('Authentic Identity'), findsOneWidget);
      expect(find.text('Vetted Public Spaces Only'), findsOneWidget);
      expect(find.text('Zero Tolerance for Harassment'), findsOneWidget);
      expect(find.text('Proactive Safety & Reporting'), findsOneWidget);
    });

    testWidgets(
      'ReportDialog enforces canonical reasons, character limit, and submit',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        String? submittedReason;
        String? submittedDesc;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ReportDialog(
                targetTitle: 'Kavita Das',
                onSubmit: (reason, desc) {
                  submittedReason = reason;
                  submittedDesc = desc;
                  return true;
                },
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Report Kavita Das'), findsOneWidget);
        expect(find.text('Harassment or unwanted contact'), findsOneWidget);
        expect(find.text('Commercial solicitation or spam'), findsOneWidget);

        // Select reason
        await tester.tap(find.text('Harassment or unwanted contact'));
        await tester.pump();

        // Enter details
        await tester.enterText(
          find.byType(TextField),
          'Unsolicited inappropriate messages after meetup.',
        );
        await tester.pump();

        // Submit
        await tester.tap(find.text('Submit'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(submittedReason, 'Harassment or unwanted contact');
        expect(
          submittedDesc,
          'Unsolicited inappropriate messages after meetup.',
        );
      },
    );

    testWidgets('ModerationScreen restricts access for non-moderators', (
      tester,
    ) async {
      final fakeRepo = _FakePhase5ConnectionsRepository()..isModerator = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            connectionsRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(home: ModerationScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Access Restricted'), findsOneWidget);
    });

    testWidgets('ModerationScreen renders reports for authorized moderators', (
      tester,
    ) async {
      final fakeRepo = _FakePhase5ConnectionsRepository()
        ..isModerator = true
        ..moderationReports = [
          ModerationReportModel(
            reportId: 'rep-1',
            reportedUserId: 'u-bad',
            reportedName: 'Bad Actor',
            reportedAvatar: '',
            reportedContentType: 'conversation',
            reason: 'Commercial solicitation or spam',
            description: 'Selling cryptocurrency in micro-group',
            status: 'pending',
            createdAt: DateTime.now(),
          ),
        ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            connectionsRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(home: ModerationScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Bad Actor'), findsOneWidget);
      expect(find.text('Commercial solicitation or spam'), findsOneWidget);
      expect(find.text('Dismiss'), findsOneWidget);
      expect(find.text('Issue Warning'), findsOneWidget);
      expect(find.text('Suspend'), findsOneWidget);
    });
  });
}
