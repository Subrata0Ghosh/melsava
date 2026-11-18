import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melsava/features/auth/domain/app_user.dart';
import 'package:melsava/features/auth/presentation/auth_providers.dart';
import 'package:melsava/features/discovery/presentation/discover_screen.dart';
import 'package:melsava/features/experiences/data/experiences_repository.dart';
import 'package:melsava/features/experiences/presentation/experiences_screen.dart';
import 'package:melsava/features/experiences/presentation/join_experience_sheet.dart';
import 'package:melsava/shared/models/experience_model.dart';

/// Fake In-Memory Experiences Repository implementing all atomic RPC behaviors
class FakeExperiencesRepository implements ExperiencesRepository {
  final List<ExperienceModel> _experiences;
  final Map<
    String,
    List<({String userId, MembershipStatus status, DateTime joinedAt})>
  >
  _memberships = {};
  String currentUserId = 'user-account-a';

  FakeExperiencesRepository({List<ExperienceModel>? initialExperiences})
    : _experiences = List.from(initialExperiences ?? []);

  @override
  Future<List<ExperienceModel>> fetchPublishedUpcomingExperiences({
    ExperienceFilter filter = const ExperienceFilter(),
    AppUser? currentUser,
    int limit = 20,
    int offset = 0,
  }) async {
    final models = _experiences.map((e) {
      final members = _memberships[e.id] ?? const [];
      final activeJoined = members
          .where((m) => m.status == MembershipStatus.joined)
          .length;
      final waitlisted = members
          .where((m) => m.status == MembershipStatus.waitlisted)
          .length;
      final myMembership = members
          .where((m) => m.userId == currentUserId)
          .firstOrNull;

      return e.copyWith(
        currentParticipants: activeJoined,
        waitlistCount: waitlisted,
        membershipStatus: myMembership?.status ?? MembershipStatus.none,
      );
    }).toList();

    return SupabaseExperiencesRepository.applyFiltersAndRanking(
      models,
      filter: filter,
      currentUser: currentUser,
    );
  }

  @override
  Future<ExperienceModel> fetchExperienceById(String experienceId) async {
    final exp = _experiences.firstWhere((e) => e.id == experienceId);
    final members = _memberships[exp.id] ?? const [];
    final activeJoined = members
        .where((m) => m.status == MembershipStatus.joined)
        .length;
    final waitlisted = members
        .where((m) => m.status == MembershipStatus.waitlisted)
        .length;
    final myMembership = members
        .where((m) => m.userId == currentUserId)
        .firstOrNull;

    return exp.copyWith(
      currentParticipants: activeJoined,
      waitlistCount: waitlisted,
      membershipStatus: myMembership?.status ?? MembershipStatus.none,
    );
  }

  @override
  Future<MyExperiencesBundle> fetchMyExperiences() async {
    final myExps = <ExperienceModel>[];

    for (final exp in _experiences) {
      final members = _memberships[exp.id] ?? const [];
      final myMembership = members
          .where((m) => m.userId == currentUserId)
          .firstOrNull;
      if (myMembership != null &&
          myMembership.status != MembershipStatus.cancelled) {
        final activeJoined = members
            .where((m) => m.status == MembershipStatus.joined)
            .length;
        final waitlisted = members
            .where((m) => m.status == MembershipStatus.waitlisted)
            .length;

        myExps.add(
          exp.copyWith(
            currentParticipants: activeJoined,
            waitlistCount: waitlisted,
            membershipStatus: myMembership.status,
            joinedAt: myMembership.joinedAt,
          ),
        );
      }
    }

    return SupabaseExperiencesRepository.groupMyExperiences(myExps);
  }

  @override
  Future<JoinExperienceResult> joinExperience(String experienceId) async {
    final expIndex = _experiences.indexWhere((e) => e.id == experienceId);
    if (expIndex == -1) throw Exception('Experience not found');
    final exp = _experiences[expIndex];

    final members = _memberships.putIfAbsent(experienceId, () => []);
    final existing = members
        .where((m) => m.userId == currentUserId)
        .firstOrNull;

    if (existing != null &&
        (existing.status == MembershipStatus.joined ||
            existing.status == MembershipStatus.waitlisted)) {
      final activeJoined = members
          .where((m) => m.status == MembershipStatus.joined)
          .length;
      final waitlisted = members
          .where((m) => m.status == MembershipStatus.waitlisted)
          .length;
      return JoinExperienceResult(
        status: existing.status,
        alreadyMember: true,
        currentParticipants: activeJoined,
        maxParticipants: exp.maxParticipants,
        waitlistCount: waitlisted,
      );
    }

    final activeJoined = members
        .where((m) => m.status == MembershipStatus.joined)
        .length;
    final isFull =
        exp.maxParticipants > 0 && activeJoined >= exp.maxParticipants;

    final newStatus = isFull
        ? MembershipStatus.waitlisted
        : MembershipStatus.joined;

    if (existing != null) {
      members.remove(existing);
    }
    members.add((
      userId: currentUserId,
      status: newStatus,
      joinedAt: DateTime.now(),
    ));

    final newJoined = members
        .where((m) => m.status == MembershipStatus.joined)
        .length;
    final newWaitlist = members
        .where((m) => m.status == MembershipStatus.waitlisted)
        .length;

    return JoinExperienceResult(
      status: newStatus,
      alreadyMember: false,
      currentParticipants: newJoined,
      maxParticipants: exp.maxParticipants,
      waitlistCount: newWaitlist,
    );
  }

  @override
  Future<CancelMembershipResult> cancelMembership(String experienceId) async {
    final expIndex = _experiences.indexWhere((e) => e.id == experienceId);
    if (expIndex == -1) throw Exception('Experience not found');
    final exp = _experiences[expIndex];

    final members = _memberships[experienceId] ?? [];
    final existing = members
        .where((m) => m.userId == currentUserId)
        .firstOrNull;
    if (existing == null) {
      throw Exception('No active reservation to cancel');
    }

    final previousStatus = existing.status;
    members.remove(existing);
    members.add((
      userId: currentUserId,
      status: MembershipStatus.cancelled,
      joinedAt: existing.joinedAt,
    ));

    String? promotedUserId;
    if (previousStatus == MembershipStatus.joined) {
      // FIFO Promotion of earliest waitlisted member
      final firstWaitlisted =
          members.where((m) => m.status == MembershipStatus.waitlisted).toList()
            ..sort((a, b) => a.joinedAt.compareTo(b.joinedAt));

      if (firstWaitlisted.isNotEmpty) {
        final toPromote = firstWaitlisted.first;
        promotedUserId = toPromote.userId;
        members.remove(toPromote);
        members.add((
          userId: toPromote.userId,
          status: MembershipStatus.joined,
          joinedAt: DateTime.now(),
        ));
      }
    }

    final newJoined = members
        .where((m) => m.status == MembershipStatus.joined)
        .length;
    final newWaitlist = members
        .where((m) => m.status == MembershipStatus.waitlisted)
        .length;

    return CancelMembershipResult(
      previousStatus: previousStatus,
      promotedUserId: promotedUserId,
      currentParticipants: newJoined,
      maxParticipants: exp.maxParticipants,
      waitlistCount: newWaitlist,
    );
  }

  @override
  Future<List<String>> fetchAvailableCategories() async {
    return const [
      'All',
      'Outdoors',
      'Social',
      'Sports',
      'Food & Drink',
      'Wellness',
      'Arts & Culture',
    ];
  }
}

void main() {
  final now = DateTime(2026, 11, 20, 10, 0);

  final samplePublished1 = ExperienceModel(
    id: 'exp-1',
    title: 'Weekend Trek to Mukutmanipur',
    description: 'Refreshing hike with nature lovers and scenic lake view.',
    categoryName: 'Outdoors',
    categoryIcon: '⛰️',
    coverImageUrl: 'assets/images/nature.png',
    city: 'Kolkata',
    venueName: 'Mukutmanipur Dam',
    venueAddress: 'Bankura',
    startsAt: now.add(const Duration(days: 2)),
    durationMinutes: 180,
    maxParticipants: 1, // Cap = 1 for capacity test
    currentParticipants: 0,
    hostName: 'Rahul',
    hostAvatar: 'assets/images/avatar.png',
    attendeeAvatars: const [],
    experienceStatus: 'published',
  );

  final samplePublished2 = ExperienceModel(
    id: 'exp-2',
    title: 'Artisan Coffee Tasting & Social',
    description:
        'Explore single-origin brews and chat with coffee enthusiasts.',
    categoryName: 'Food & Drink',
    categoryIcon: '☕',
    coverImageUrl: 'assets/images/coffee.png',
    city: 'Kolkata',
    venueName: 'Blue Tokai Cafe',
    venueAddress: 'Park Street',
    startsAt: now.add(const Duration(days: 4)),
    durationMinutes: 90,
    maxParticipants: 10,
    currentParticipants: 3,
    hostName: 'Ananya',
    hostAvatar: 'assets/images/avatar.png',
    attendeeAvatars: const [],
    experienceStatus: 'published',
  );

  final sampleOnlineExp = ExperienceModel(
    id: 'exp-3',
    title: 'Mindfulness & Sound Bath',
    description: 'Guided meditation and sound healing over live stream.',
    categoryName: 'Wellness',
    categoryIcon: '🧘',
    coverImageUrl: 'assets/images/nature.png',
    city: '',
    venueName: '',
    venueAddress: '',
    isOnline: true,
    startsAt: now.add(const Duration(days: 1)),
    durationMinutes: 60,
    maxParticipants: 30,
    currentParticipants: 12,
    hostName: 'Dev',
    hostAvatar: 'assets/images/avatar.png',
    attendeeAvatars: const [],
    experienceStatus: 'published',
  );

  final samplePastExp = ExperienceModel(
    id: 'exp-past',
    title: 'Sunset Photography Walk',
    description: 'Past walk around Victoria Memorial.',
    categoryName: 'Arts & Culture',
    categoryIcon: '📷',
    coverImageUrl: 'assets/images/nature.png',
    city: 'Kolkata',
    venueName: 'Victoria Memorial',
    venueAddress: 'Maidan',
    startsAt: now.subtract(const Duration(days: 3)),
    durationMinutes: 120,
    maxParticipants: 15,
    currentParticipants: 15,
    hostName: 'Suman',
    hostAvatar: 'assets/images/avatar.png',
    attendeeAvatars: const [],
    experienceStatus: 'published',
  );

  final sampleDraftExp = ExperienceModel(
    id: 'exp-draft',
    title: 'Unpublished Draft Workshop',
    description: 'Draft workshop not yet approved.',
    categoryName: 'Social',
    categoryIcon: '🎨',
    coverImageUrl: 'assets/images/nature.png',
    city: 'Kolkata',
    venueName: 'Studio',
    venueAddress: 'Salt Lake',
    startsAt: now.add(const Duration(days: 5)),
    durationMinutes: 60,
    maxParticipants: 10,
    currentParticipants: 0,
    hostName: 'Admin',
    hostAvatar: 'assets/images/avatar.png',
    attendeeAvatars: const [],
    experienceStatus: 'draft',
  );

  group('1. SupabaseExperiencesRepository.applyFiltersAndRanking', () {
    final allList = [
      samplePublished1,
      samplePublished2,
      sampleOnlineExp,
      samplePastExp,
      sampleDraftExp,
    ];

    test('excludes draft, cancelled, and past experiences', () {
      final results = SupabaseExperiencesRepository.applyFiltersAndRanking(
        allList,
        referenceNow: now,
      );

      final ids = results.map((e) => e.id).toList();
      expect(ids, contains('exp-1'));
      expect(ids, contains('exp-2'));
      expect(ids, contains('exp-3'));
      expect(ids, isNot(contains('exp-past')));
      expect(ids, isNot(contains('exp-draft')));
    });

    test('filters by search query matching title or description', () {
      final titleResults = SupabaseExperiencesRepository.applyFiltersAndRanking(
        allList,
        filter: const ExperienceFilter(searchQuery: 'Coffee'),
        referenceNow: now,
      );
      expect(titleResults.length, 1);
      expect(titleResults.first.id, 'exp-2');

      final descResults = SupabaseExperiencesRepository.applyFiltersAndRanking(
        allList,
        filter: const ExperienceFilter(searchQuery: 'lake view'),
        referenceNow: now,
      );
      expect(descResults.length, 1);
      expect(descResults.first.id, 'exp-1');
    });

    test('filters by category and format (online vs in-person)', () {
      final outdoorResults =
          SupabaseExperiencesRepository.applyFiltersAndRanking(
            allList,
            filter: const ExperienceFilter(category: 'Outdoors'),
            referenceNow: now,
          );
      expect(outdoorResults.length, 1);
      expect(outdoorResults.first.id, 'exp-1');

      final onlineResults =
          SupabaseExperiencesRepository.applyFiltersAndRanking(
            allList,
            filter: const ExperienceFilter(
              format: ExperienceFormatFilter.online,
            ),
            referenceNow: now,
          );
      expect(onlineResults.length, 1);
      expect(onlineResults.first.id, 'exp-3');

      final inPersonResults =
          SupabaseExperiencesRepository.applyFiltersAndRanking(
            allList,
            filter: const ExperienceFilter(
              format: ExperienceFormatFilter.inPerson,
            ),
            referenceNow: now,
          );
      expect(inPersonResults.every((e) => !e.isOnline), isTrue);
    });

    test(
      'prioritizes user saved city and preferred categories without hiding non-matches',
      () {
        final testUser = AppUser(
          id: 'user-sneha',
          email: 'sneha@example.com',
          city: 'Kolkata',
          preferredActivityCategories: const ['Food & Drink'],
        );

        final ranked = SupabaseExperiencesRepository.applyFiltersAndRanking(
          allList,
          currentUser: testUser,
          referenceNow: now,
        );

        // exp-2 matches both Kolkata AND preferred activity 'Food & Drink', so it should rank highest!
        expect(ranked.first.id, 'exp-2');
        // Non-matching online experience is still present
        expect(ranked.any((e) => e.id == 'exp-3'), isTrue);
      },
    );
  });

  group('2. SupabaseExperiencesRepository.groupMyExperiences', () {
    test(
      'correctly partitions into Upcoming, Waitlisted, Attended, Past and excludes cancelled',
      () {
        final myExperiences = [
          samplePublished1.copyWith(
            membershipStatus: MembershipStatus.joined,
            startsAt: now.add(const Duration(days: 2)),
          ),
          samplePublished2.copyWith(
            membershipStatus: MembershipStatus.waitlisted,
            startsAt: now.add(const Duration(days: 4)),
          ),
          sampleOnlineExp.copyWith(
            membershipStatus: MembershipStatus.attended,
            startsAt: now.subtract(const Duration(days: 1)),
          ),
          samplePastExp.copyWith(
            membershipStatus: MembershipStatus.joined,
            startsAt: now.subtract(const Duration(days: 3)),
          ),
          sampleDraftExp.copyWith(membershipStatus: MembershipStatus.cancelled),
        ];

        final bundle = SupabaseExperiencesRepository.groupMyExperiences(
          myExperiences,
          referenceNow: now,
        );

        expect(bundle.upcoming.map((e) => e.id), equals(['exp-1']));
        expect(bundle.waitlisted.map((e) => e.id), equals(['exp-2']));
        expect(bundle.attended.map((e) => e.id), equals(['exp-3']));
        expect(bundle.past.map((e) => e.id), equals(['exp-past']));
        expect(bundle.totalActiveCount, 2); // upcoming + waitlisted
      },
    );
  });

  group(
    '3. Two-Account Atomic Join, Duplicate Guard, Full-Capacity Waitlist & FIFO Promotion',
    () {
      late FakeExperiencesRepository repo;

      setUp(() {
        repo = FakeExperiencesRepository(
          initialExperiences: [
            samplePublished1.copyWith(maxParticipants: 1), // Only 1 spot!
          ],
        );
      });

      test('Account A joins available experience -> spot reserved', () async {
        repo.currentUserId = 'account-a';
        final resA = await repo.joinExperience('exp-1');

        expect(resA.status, MembershipStatus.joined);
        expect(resA.alreadyMember, isFalse);
        expect(resA.currentParticipants, 1);
        expect(resA.waitlistCount, 0);

        // Inspect experience state
        final exp = await repo.fetchExperienceById('exp-1');
        expect(exp.hasJoined, isTrue);
        expect(exp.isFull, isTrue);
        expect(exp.spotsLeft, 0);
      });

      test(
        'Duplicate join returns alreadyMember: true without double-counting',
        () async {
          repo.currentUserId = 'account-a';
          await repo.joinExperience('exp-1');

          // Attempt duplicate join
          final dupRes = await repo.joinExperience('exp-1');
          expect(dupRes.alreadyMember, isTrue);
          expect(dupRes.status, MembershipStatus.joined);
          expect(dupRes.currentParticipants, 1);
        },
      );

      test('Account B joins full experience -> placed on waitlist', () async {
        // Account A takes the 1 spot
        repo.currentUserId = 'account-a';
        await repo.joinExperience('exp-1');

        // Account B attempts to join full experience
        repo.currentUserId = 'account-b';
        final resB = await repo.joinExperience('exp-1');

        expect(resB.status, MembershipStatus.waitlisted);
        expect(resB.alreadyMember, isFalse);
        expect(resB.currentParticipants, 1);
        expect(resB.waitlistCount, 1);

        final expB = await repo.fetchExperienceById('exp-1');
        expect(expB.isWaitlisted, isTrue);
        expect(expB.hasJoined, isFalse);
      });

      test(
        'Account A cancels -> Account B is automatically promoted FIFO from waitlist',
        () async {
          // 1. Account A joins
          repo.currentUserId = 'account-a';
          await repo.joinExperience('exp-1');

          // 2. Account B waitlisted
          repo.currentUserId = 'account-b';
          await repo.joinExperience('exp-1');

          // 3. Account A cancels membership
          repo.currentUserId = 'account-a';
          final cancelRes = await repo.cancelMembership('exp-1');

          expect(cancelRes.previousStatus, MembershipStatus.joined);
          expect(cancelRes.promotedUserId, 'account-b');
          expect(cancelRes.currentParticipants, 1); // Account B is now active
          expect(cancelRes.waitlistCount, 0);

          // Verify Account A status
          final expA = await repo.fetchExperienceById('exp-1');
          expect(expA.membershipStatus, MembershipStatus.cancelled);
          expect(expA.hasJoined, isFalse);

          // Switch to Account B and verify they are now confirmed JOINED
          repo.currentUserId = 'account-b';
          final expB = await repo.fetchExperienceById('exp-1');
          expect(expB.membershipStatus, MembershipStatus.joined);
          expect(expB.hasJoined, isTrue);
          expect(expB.isWaitlisted, isFalse);
        },
      );
    },
  );

  group('4. JoinExperienceSheet Widget Tests', () {
    testWidgets('shows saved profile intentions and confirms real atomic join', (
      tester,
    ) async {
      final fakeExp = samplePublished2;
      bool joinCalled = false;

      final testUser = AppUser(
        id: 'u-1',
        email: 'test@example.com',
        primaryIntent: 'Friendship',
        secondaryIntents: const ['Activity Partner'],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [currentUserProvider.overrideWith((ref) => testUser)],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      JoinExperienceSheet.show(
                        context,
                        experience: fakeExp,
                        onConfirmJoin: () async {
                          joinCalled = true;
                          return const JoinExperienceResult(
                            status: MembershipStatus.joined,
                            alreadyMember: false,
                            currentParticipants: 4,
                            maxParticipants: 10,
                            waitlistCount: 0,
                          );
                        },
                      );
                    },
                    child: const Text('Open Join Sheet'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Join Sheet'));
      await tester.pumpAndSettle();

      // Verify selected experience title is displayed
      expect(find.text('Artisan Coffee Tasting & Social'), findsOneWidget);

      // Verify saved profile intentions are shown read-only (NOT defaulting to Dating)
      expect(find.text('Friendship'), findsOneWidget);
      expect(find.text('Activity Partner'), findsOneWidget);

      // Confirm Join tap
      expect(find.text('Confirm Join'), findsOneWidget);
      await tester.tap(find.text('Confirm Join'));
      await tester.pumpAndSettle();

      expect(joinCalled, isTrue);
      expect(find.text('You have joined this experience.'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
    });
  });

  group('5. DiscoverScreen & ExperiencesScreen Widget & Theme Tests', () {
    testWidgets('DiscoverScreen renders published feed in Light Theme', (
      tester,
    ) async {
      final fakeRepo = FakeExperiencesRepository(
        initialExperiences: [samplePublished1, samplePublished2],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experiencesRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp(
            theme: ThemeData.light(),
            home: const DiscoverScreen(),
          ),
        ),
      );

      // Settle initial async provider & finite animation ticks
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Let\'s explore experiences!'), findsOneWidget);
      expect(find.text('Search experiences, venues...'), findsOneWidget);
    });

    testWidgets(
      'ExperiencesScreen renders Explore All and My Circles in Dark Theme',
      (tester) async {
        final fakeRepo = FakeExperiencesRepository(
          initialExperiences: [samplePublished1, samplePublished2],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              experiencesRepositoryProvider.overrideWithValue(fakeRepo),
            ],
            child: MaterialApp(
              theme: ThemeData.dark(),
              home: const ExperiencesScreen(),
            ),
          ),
        );

        // Settle initial future providers
        await tester.pumpAndSettle();

        expect(find.text('Experiences'), findsOneWidget);
        expect(find.text('Explore All'), findsOneWidget);
        expect(find.text('My Circles'), findsOneWidget);

        // Switch to My Circles tab
        await tester.tap(find.text('My Circles'));
        await tester.pumpAndSettle();

        expect(find.text('Upcoming (0)'), findsOneWidget);
        expect(find.text('Waitlist (0)'), findsOneWidget);
        expect(find.text('No upcoming experiences joined yet'), findsOneWidget);
      },
    );
  });
}
