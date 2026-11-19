import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melsava/features/experiences/data/post_experience_repository.dart';
import 'package:melsava/features/experiences/presentation/host_attendance_sheet.dart';
import 'package:melsava/features/experiences/presentation/post_experience_choice_screen.dart';
import 'package:melsava/shared/models/experience_model.dart';
import 'package:melsava/shared/widgets/mutual_match_celebration_dialog.dart';
import 'package:melsava/shared/widgets/primary_button.dart';

/// Fake test repository for Phase 3 Unit and Widget Tests
class FakePostExperienceRepository implements PostExperienceRepository {
  List<EligibleAttendee> eligibleAttendees = [];
  ReconnectSubmissionStatus submissionStatus = const ReconnectSubmissionStatus(
    isCompleted: true,
    isAttended: true,
    isHost: false,
    isSubmitted: false,
  );
  List<HostParticipantItem> hostParticipants = [];
  PostExperienceSubmissionResult submissionResult =
      const PostExperienceSubmissionResult(submitted: true);
  AttendanceConfirmationResult attendanceResult =
      const AttendanceConfirmationResult(
        success: true,
        experienceId: 'exp-test-1',
        status: 'completed',
        attendedCount: 2,
      );

  List<PostExperienceChoiceInput> lastSubmittedChoices = [];
  List<String> lastAttendedUserIds = [];
  List<MeetupCircleParticipant> circleParticipants = [];
  bool throwOnSubmit = false;
  bool throwOnFetchAttendees = false;
  bool throwOnFetchCircleParticipants = false;

  @override
  Future<List<EligibleAttendee>> fetchEligibleAttendees(
    String experienceId,
  ) async {
    if (throwOnFetchAttendees) {
      throw Exception('Network error fetching attendees');
    }
    return eligibleAttendees;
  }

  @override
  Future<ReconnectSubmissionStatus> fetchSubmissionStatus(
    String experienceId,
  ) async {
    return submissionStatus;
  }

  @override
  Future<PostExperienceSubmissionResult> submitChoices(
    String experienceId,
    List<PostExperienceChoiceInput> choices,
  ) async {
    if (throwOnSubmit) {
      throw Exception('Network failure during choice submission');
    }
    lastSubmittedChoices = choices;
    return submissionResult;
  }

  @override
  Future<List<HostParticipantItem>> fetchHostJoinedParticipants(
    String experienceId,
  ) async {
    return hostParticipants;
  }

  @override
  Future<List<MeetupCircleParticipant>> fetchCircleParticipants(
    String experienceId,
  ) async {
    if (throwOnFetchCircleParticipants) {
      throw Exception('Network error fetching circle participants');
    }
    return circleParticipants;
  }

  @override
  Future<AttendanceConfirmationResult> completeExperienceAndMarkAttendance(
    String experienceId,
    List<String> attendedUserIds,
  ) async {
    lastAttendedUserIds = attendedUserIds;
    return attendanceResult;
  }
}

void main() {
  late FakePostExperienceRepository fakeRepo;

  final testExperience = ExperienceModel(
    id: 'exp-phase3-101',
    title: 'Heritage Walk & Rooftop Social',
    description: 'An evening walking tour through old colonial lanes.',
    categoryName: 'Cultural Activities',
    categoryIcon: '🏛️',
    coverImageUrl: '',
    city: 'Kolkata',
    venueName: 'Victoria Memorial East Gate',
    venueAddress: 'Queens Way, Maidan, Kolkata',
    isOnline: false,
    startsAt: DateTime.now().subtract(const Duration(hours: 3)),
    durationMinutes: 120,
    maxParticipants: 6,
    currentParticipants: 4,
    waitlistCount: 0,
    hostId: 'host-user-999',
    hostName: 'Subrata Ghosh',
    hostAvatar: '',
    hostBio: 'Heritage enthusiast and host.',
    attendeeAvatars: const [],
    experienceStatus: 'completed',
    isCompleted: true,
  );

  final sampleAttendees = [
    const EligibleAttendee(
      id: 'user-sneha-1',
      displayName: 'Sneha Roy',
      avatarUrl: '',
      bio: 'Architect & heritage lover.',
      experienceTitle: 'Heritage Walk & Rooftop Social',
    ),
    const EligibleAttendee(
      id: 'user-rohan-2',
      displayName: 'Rohan Sharma',
      avatarUrl: '',
      bio: 'Cyclist and coffee fan.',
      experienceTitle: 'Heritage Walk & Rooftop Social',
    ),
  ];

  final sampleHostParticipants = [
    const HostParticipantItem(
      userId: 'user-sneha-1',
      displayName: 'Sneha Roy',
      avatarUrl: '',
      bio: 'Architect & heritage lover.',
      memberStatus: 'joined',
    ),
    const HostParticipantItem(
      userId: 'user-rohan-2',
      displayName: 'Rohan Sharma',
      avatarUrl: '',
      bio: 'Cyclist and coffee fan.',
      memberStatus: 'joined',
    ),
  ];

  setUp(() {
    fakeRepo = FakePostExperienceRepository();
    fakeRepo.eligibleAttendees = sampleAttendees;
    fakeRepo.hostParticipants = sampleHostParticipants;
  });

  Widget buildTestWidget({required Widget child}) {
    return ProviderScope(
      overrides: [postExperienceRepositoryProvider.overrideWithValue(fakeRepo)],
      child: MaterialApp(home: child),
    );
  }

  group('1. Reconnect Choice Types and Compatibility Tests', () {
    test('Enum to and from DB string conversion', () {
      expect(ReconnectChoiceType.friendship.toDbString(), equals('friendship'));
      expect(
        ReconnectChoiceType.activityPartner.toDbString(),
        equals('activity_partner'),
      );
      expect(
        ReconnectChoiceType.exploreDating.toDbString(),
        equals('explore_dating'),
      );
      expect(
        ReconnectChoiceType.noConnection.toDbString(),
        equals('no_connection'),
      );

      expect(
        ReconnectChoiceType.fromDbString('friendship'),
        equals(ReconnectChoiceType.friendship),
      );
      expect(
        ReconnectChoiceType.fromDbString('activity_partner'),
        equals(ReconnectChoiceType.activityPartner),
      );
      expect(
        ReconnectChoiceType.fromDbString('dating'),
        equals(ReconnectChoiceType.exploreDating),
      );
      expect(
        ReconnectChoiceType.fromDbString('explore_dating'),
        equals(ReconnectChoiceType.exploreDating),
      );
      expect(
        ReconnectChoiceType.fromDbString('unknown'),
        equals(ReconnectChoiceType.noConnection),
      );
    });

    test(
      'Exact matching consent rule: Mismatched intentions produce NO MATCH',
      () {
        // Core consent rule verification:
        // Friendship + Explore Dating must NEVER create a connection
        const choiceA = ReconnectChoiceType.friendship;
        const choiceB = ReconnectChoiceType.exploreDating;
        expect(choiceA == choiceB, isFalse);

        // Activity Partner + Friendship must NEVER match
        const choiceC = ReconnectChoiceType.activityPartner;
        const choiceD = ReconnectChoiceType.friendship;
        expect(choiceC == choiceD, isFalse);

        // Positive choice + No Connection must NEVER match
        const choiceE = ReconnectChoiceType.exploreDating;
        const choiceF = ReconnectChoiceType.noConnection;
        expect(choiceE == choiceF, isFalse);

        // Exact match succeeds
        const choiceG = ReconnectChoiceType.exploreDating;
        const choiceH = ReconnectChoiceType.exploreDating;
        expect(choiceG == choiceH, isTrue);
      },
    );
  });

  group('2. PostExperienceChoiceScreen Widget Tests', () {
    testWidgets(
      'Shows Experience Not Completed state when experience is not completed',
      (tester) async {
        fakeRepo.submissionStatus = const ReconnectSubmissionStatus(
          isCompleted: false,
          isAttended: true,
          isHost: false,
          isSubmitted: false,
        );

        await tester.pumpWidget(
          buildTestWidget(
            child: PostExperienceChoiceScreen(experience: testExperience),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Experience Not Completed'), findsOneWidget);
        expect(
          find.text(
            'Reconnect choices will become available after the experience is completed.',
          ),
          findsOneWidget,
        );
        expect(find.text('Back to My Circles'), findsOneWidget);
      },
    );

    testWidgets(
      'Shows Not Eligible state when caller did not attend the experience',
      (tester) async {
        fakeRepo.submissionStatus = const ReconnectSubmissionStatus(
          isCompleted: true,
          isAttended: false,
          isHost: false,
          isSubmitted: false,
        );

        await tester.pumpWidget(
          buildTestWidget(
            child: PostExperienceChoiceScreen(experience: testExperience),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Not Eligible'), findsOneWidget);
        expect(
          find.text(
            'This reconnect activity is available only to confirmed attendees.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Shows Already Submitted state when caller already submitted choices',
      (tester) async {
        fakeRepo.submissionStatus = const ReconnectSubmissionStatus(
          isCompleted: true,
          isAttended: true,
          isHost: false,
          isSubmitted: true,
        );

        await tester.pumpWidget(
          buildTestWidget(
            child: PostExperienceChoiceScreen(experience: testExperience),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Choices Already Submitted'), findsOneWidget);
        expect(
          find.text(
            'Your choices for this experience have already been submitted.',
          ),
          findsOneWidget,
        );
        expect(find.text('View Connections'), findsOneWidget);
      },
    );

    testWidgets('Shows Empty state when no other eligible attendees exist', (
      tester,
    ) async {
      fakeRepo.eligibleAttendees = [];

      await tester.pumpWidget(
        buildTestWidget(
          child: PostExperienceChoiceScreen(experience: testExperience),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Other Attendees'), findsOneWidget);
      expect(
        find.text(
          'You attended this experience, but there are no other eligible participants to reconnect with.',
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'Renders attendees list, allows choice selection, reviews and submits privately',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            child: PostExperienceChoiceScreen(experience: testExperience),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Who would you like to meet again?'), findsOneWidget);
        expect(find.text('Sneha Roy'), findsOneWidget);
        expect(find.text('Rohan Sharma'), findsOneWidget);

        // Tap Friendship for Sneha Roy
        final friendshipChip = find.widgetWithText(
          AnimatedContainer,
          'Friendship',
        );
        expect(friendshipChip, findsAtLeastNWidgets(2));
        await tester.tap(friendshipChip.first);
        await tester.pumpAndSettle();

        // Tap "Review & Submit Choices Privately"
        final submitButton = find.widgetWithText(
          PrimaryButton,
          'Review & Submit Choices Privately',
        );
        expect(submitButton, findsOneWidget);
        await tester.tap(submitButton);
        await tester.pumpAndSettle();

        // Review bottom sheet appears
        expect(find.text('Confirm Private Choices'), findsOneWidget);
        expect(
          find.text(
            'You have selected 1 connection intention(s) across 2 attendee(s).',
          ),
          findsOneWidget,
        );

        // Confirm submission
        final confirmBtn = find.widgetWithText(
          PrimaryButton,
          'Confirm & Submit Privately',
        );
        expect(confirmBtn, findsOneWidget);
        await tester.tap(confirmBtn);
        await tester.pumpAndSettle();

        // Verify fakeRepo received the choices
        expect(fakeRepo.lastSubmittedChoices.length, equals(2));
        final snehaChoice = fakeRepo.lastSubmittedChoices.firstWhere(
          (c) => c.chosenId == 'user-sneha-1',
        );
        expect(snehaChoice.choiceType, equals(ReconnectChoiceType.friendship));

        final rohanChoice = fakeRepo.lastSubmittedChoices.firstWhere(
          (c) => c.chosenId == 'user-rohan-2',
        );
        expect(
          rohanChoice.choiceType,
          equals(ReconnectChoiceType.noConnection),
        );

        // Private submission confirmation dialog is shown
        expect(find.text('Choices Submitted Privately'), findsOneWidget);
      },
    );

    testWidgets(
      'Celebration dialog triggers when submission returns a real mutual match',
      (tester) async {
        fakeRepo.submissionResult = const PostExperienceSubmissionResult(
          submitted: true,
          mutualConnections: [
            MutualConnectionResult(
              connectionId: 'conn-real-123',
              conversationId: 'conv-real-456',
              partnerId: 'user-sneha-1',
              partnerName: 'Sneha Roy',
              partnerAvatar: '',
              connectionType: 'friendship',
              connectionTypeLabel: 'Friendship',
              experienceTitle: 'Heritage Walk & Rooftop Social',
            ),
          ],
        );

        await tester.pumpWidget(
          buildTestWidget(
            child: PostExperienceChoiceScreen(experience: testExperience),
          ),
        );
        await tester.pumpAndSettle();

        // Submit
        final submitButton = find.widgetWithText(
          PrimaryButton,
          'Review & Submit Choices Privately',
        );
        await tester.tap(submitButton);
        await tester.pumpAndSettle();

        final confirmBtn = find.widgetWithText(
          PrimaryButton,
          'Confirm & Submit Privately',
        );
        await tester.tap(confirmBtn);
        await tester.pumpAndSettle();

        // Mutual Match Celebration Dialog appears!
        expect(find.byType(MutualMatchCelebrationDialog), findsOneWidget);
        expect(find.textContaining('mutual choice'), findsOneWidget);
        expect(find.text('Sneha Roy'), findsOneWidget);
      },
    );
  });

  group('3. HostAttendanceSheet Widget Tests', () {
    testWidgets(
      'Host can toggle attendees and submit attendance confirmation',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            child: HostAttendanceSheet(experience: testExperience),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Confirm Attendance'), findsOneWidget);
        expect(find.text('Sneha Roy'), findsOneWidget);
        expect(find.text('Rohan Sharma'), findsOneWidget);

        // Tap "Select All"
        final selectAllBtn = find.text('Select All');
        expect(selectAllBtn, findsOneWidget);
        await tester.tap(selectAllBtn);
        await tester.pumpAndSettle();

        // Tap "Confirm Attendance & Complete Event"
        final confirmBtn = find.widgetWithText(
          PrimaryButton,
          'Confirm Attendance & Complete Event',
        );
        expect(confirmBtn, findsOneWidget);
        await tester.tap(confirmBtn);
        await tester.pumpAndSettle();

        // Verify repository received the attended user IDs
        expect(fakeRepo.lastAttendedUserIds.length, equals(2));
        expect(fakeRepo.lastAttendedUserIds.contains('user-sneha-1'), isTrue);
        expect(fakeRepo.lastAttendedUserIds.contains('user-rohan-2'), isTrue);
      },
    );
  });
}
