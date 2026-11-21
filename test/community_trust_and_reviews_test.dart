import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melsava/features/auth/domain/app_user.dart';
import 'package:melsava/features/experiences/data/experiences_repository.dart';
import 'package:melsava/features/experiences/domain/circle_creation_model.dart';
import 'package:melsava/features/profile/data/reputation_repository.dart';
import 'package:melsava/features/profile/domain/reputation_model.dart';
import 'package:melsava/features/profile/presentation/widgets/host_trust_card.dart';
import 'package:melsava/features/reviews/domain/review_model.dart';
import 'package:melsava/shared/models/experience_model.dart';

void main() {
  group('CircleCreationInput Validation & Constraints', () {
    test('validates correct input successfully', () {
      final input = CircleCreationInput(
        title: 'Morning Yoga in Central Park',
        description: 'Join us for a relaxing 60-minute outdoor yoga session.',
        categoryId: 'cat_wellness_123',
        startsAt: DateTime.now().add(const Duration(days: 2)),
        durationMinutes: 60,
        city: 'New York',
        area: 'Manhattan',
        venueName: 'Sheep Meadow',
        venueAddress: 'Central Park West',
        maxParticipants: 8,
        isOnline: false,
        isFree: true,
      );

      expect(input.validate(), isNull);
    });

    test('rejects short title or description', () {
      final inputShortTitle = CircleCreationInput(
        title: 'Yoga',
        description: 'Join us for a relaxing session.',
        categoryId: 'cat_wellness_123',
        venueName: 'Central Park',
        startsAt: DateTime.now().add(const Duration(days: 2)),
        durationMinutes: 60,
        city: 'New York',
        maxParticipants: 8,
      );
      expect(inputShortTitle.validate(), contains('at least 5 characters'));

      final inputShortDesc = CircleCreationInput(
        title: 'Morning Yoga',
        description: 'Short',
        categoryId: 'cat_wellness_123',
        venueName: 'Central Park',
        startsAt: DateTime.now().add(const Duration(days: 2)),
        durationMinutes: 60,
        city: 'New York',
        maxParticipants: 8,
      );
      expect(inputShortDesc.validate(), contains('at least 15 characters'));
    });

    test('rejects invalid duration or past start date', () {
      final pastInput = CircleCreationInput(
        title: 'Morning Yoga Session',
        description: 'Join us for a relaxing session outdoors in the park.',
        categoryId: 'cat_wellness_123',
        venueName: 'Central Park',
        startsAt: DateTime.now().subtract(const Duration(hours: 1)),
        durationMinutes: 60,
        city: 'New York',
        maxParticipants: 8,
      );
      expect(pastInput.validate(), contains('must be in the future'));

      final badDurationInput = CircleCreationInput(
        title: 'Morning Yoga Session',
        description: 'Join us for a relaxing session outdoors in the park.',
        categoryId: 'cat_wellness_123',
        venueName: 'Central Park',
        startsAt: DateTime.now().add(const Duration(days: 1)),
        durationMinutes: 10,
        city: 'New York',
        maxParticipants: 8,
      );
      expect(
        badDurationInput.validate(),
        contains('between 15 and 480 minutes'),
      );
    });

    test('enforces initial capacity limits (max 30 participants)', () {
      final excessiveInput = CircleCreationInput(
        title: 'Massive City Gathering',
        description:
            'Join hundreds of people for an open public concert meetup.',
        categoryId: 'cat_music_123',
        venueName: 'Central Park',
        startsAt: DateTime.now().add(const Duration(days: 1)),
        durationMinutes: 120,
        city: 'New York',
        maxParticipants: 50,
      );
      expect(excessiveInput.validate(), contains('cannot exceed 30'));
    });
  });

  group('HostReputationModel & Trust Calculations', () {
    test('correctly parses new host without average rating until 5 reviews', () {
      final model = HostReputationModel.fromMap({
        'user_id': 'user_new_1',
        'reputation_level': 'new_host',
        'is_new_host': true,
        'completed_hosted_count': 1,
        'review_count': 3,
        'average_rating': 4.67,
        'positive_ratings_percentage': 100.0,
        'hosting_attendance_rate': 100.0,
      });

      expect(model.level, HostReputationLevel.newHost);
      expect(model.isNewHost, isTrue);
      // Cold-start principle: Never display numeric average rating before 5 reviews
      expect(model.ratingDisplay, 'Not yet rated');
      expect(model.levelDisplayName, 'New Host');
    });

    test(
      'displays average rating only once threshold of 5 reviews is reached',
      () {
        final model = HostReputationModel.fromMap({
          'user_id': 'user_trusted_1',
          'reputation_level': 'trusted_host',
          'is_new_host': false,
          'completed_hosted_count': 8,
          'review_count': 12,
          'average_rating': 4.9,
          'positive_ratings_percentage': 95.0,
          'hosting_attendance_rate': 98.0,
        });

        expect(model.level, HostReputationLevel.trustedHost);
        expect(model.isNewHost, isFalse);
        expect(model.ratingDisplay, '4.9 ★');
        expect(model.levelDisplayName, 'Trusted Host');
      },
    );
  });

  group('ReviewModel & ReviewInput Validation', () {
    test('ReviewInput validates rating bounds and structured questions', () {
      final valid = ReviewInput(
        experienceId: 'exp_1',
        rating: 5,
        wasAsDescribed: true,
        wasHostRespectful: true,
        didHostArrive: true,
        feltSafeComfortable: true,
        wouldJoinAgain: true,
        feedback: 'Fantastic experience, great host!',
      );
      expect(valid.validate(), isNull);

      final invalidRating = ReviewInput(
        experienceId: 'exp_1',
        rating: 6,
        wasAsDescribed: true,
        wasHostRespectful: true,
        didHostArrive: true,
        feltSafeComfortable: true,
        wouldJoinAgain: true,
      );
      expect(invalidRating.validate(), contains('between 1 and 5'));
    });

    test('ReviewModel parses attendee feedback correctly', () {
      final review = ReviewModel.fromMap({
        'review_id': 'rev_1',
        'experience_id': 'exp_1',
        'experience_title': 'Photography Walk',
        'reviewer_id': 'user_2',
        'reviewer_name': 'Subrata',
        'reviewer_avatar_url': 'https://example.com/avatar.jpg',
        'rating': 5,
        'was_as_described': true,
        'was_host_respectful': true,
        'did_host_arrive': true,
        'felt_safe_comfortable': true,
        'would_join_again': true,
        'review_feedback': 'Very well organised and safe!',
        'created_at': DateTime.now().toIso8601String(),
      });

      expect(review.rating, 5);
      expect(review.reviewerName, 'Subrata');
      expect(review.feedbackText, contains('well organised'));
    });
  });

  group('Fair Discovery Ranking & Cold-Start Boost', () {
    test(
      'boosts new hosts and nearby area in ranking without excluding established hosts',
      () {
        final now = DateTime.now();
        final user = const AppUser(
          id: 'user_seeker',
          email: 'user@melsava.com',
          city: 'Kolkata',
        );

        final circleNewHost = ExperienceModel(
          id: 'exp_new',
          title: 'New Host Book Club',
          description: 'A cozy book club for passionate readers.',
          categoryName: 'Books & Literature',
          categoryIcon: '📚',
          coverImageUrl: 'assets/images/placeholder.jpg',
          venueName: 'Park Street Cafe',
          venueAddress: '15 Park Street',
          startsAt: now.add(const Duration(hours: 10)),
          durationMinutes: 90,
          city: 'Kolkata',
          area: 'Park Street',
          isNewHost: true,
          reputationLevel: 'new_host',
          currentParticipants: 2,
          maxParticipants: 8,
          hostName: 'Priya',
          hostAvatar: 'assets/images/avatar.png',
          attendeeAvatars: const [],
        );

        final circleFarAway = ExperienceModel(
          id: 'exp_far',
          title: 'Outstation Trek',
          description: 'Trekking deep in the countryside.',
          categoryName: 'Outdoors',
          categoryIcon: '🥾',
          coverImageUrl: 'assets/images/placeholder.jpg',
          venueName: 'Sahyadri Base Camp',
          venueAddress: 'Western Ghats',
          startsAt: now.add(const Duration(hours: 12)),
          durationMinutes: 180,
          city: 'Mumbai',
          isNewHost: false,
          reputationLevel: 'reliable_host',
          currentParticipants: 5,
          maxParticipants: 10,
          hostName: 'Arjun',
          hostAvatar: 'assets/images/avatar.png',
          attendeeAvatars: const [],
        );

        final ranked = SupabaseExperiencesRepository.applyFiltersAndRanking(
          [circleFarAway, circleNewHost],
          currentUser: user,
          referenceNow: now,
        );

        // Kolkata circle by new host appears first due to location match and cold-start boost
        expect(ranked.first.id, 'exp_new');
      },
    );
  });

  group('HostTrustCard Widget Tests', () {
    testWidgets('renders New Host banner without fake ratings or demo badges', (
      tester,
    ) async {
      final fakeNewHostRep = const HostReputationModel(
        userId: 'host_new_1',
        level: HostReputationLevel.newHost,
        isNewHost: true,
        completedHostedCount: 0,
        reviewCount: 0,
        averageRating: null,
        positiveRatingsPercentage: 100.0,
        hostingAttendanceRate: 100.0,
        activityCreationRestricted: false,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            hostReputationProvider(
              'host_new_1',
            ).overrideWith((ref) => Future.value(fakeNewHostRep)),
          ],
          child: const MaterialApp(
            home: Scaffold(body: HostTrustCard(hostId: 'host_new_1')),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('New Host'), findsOneWidget);
      expect(find.text('Not yet rated'), findsOneWidget);
      expect(find.text('No completed circles yet'), findsOneWidget);
      expect(find.text('0.0'), findsNothing);
      expect(find.text('0 ★'), findsNothing);
    });

    testWidgets('renders verified metrics for trusted host with >= 5 reviews', (
      tester,
    ) async {
      final fakeTrustedRep = const HostReputationModel(
        userId: 'host_trusted_1',
        level: HostReputationLevel.trustedHost,
        isNewHost: false,
        completedHostedCount: 12,
        reviewCount: 15,
        averageRating: 4.9,
        positiveRatingsPercentage: 98.0,
        hostingAttendanceRate: 100.0,
        activityCreationRestricted: false,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            hostReputationProvider(
              'host_trusted_1',
            ).overrideWith((ref) => Future.value(fakeTrustedRep)),
          ],
          child: const MaterialApp(
            home: Scaffold(body: HostTrustCard(hostId: 'host_trusted_1')),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Trusted Host'), findsOneWidget);
      expect(find.text('4.9'), findsOneWidget);
      expect(find.text('12 circles hosted'), findsOneWidget);
    });
  });
}
