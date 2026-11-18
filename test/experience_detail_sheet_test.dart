import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melsava/features/experiences/presentation/experience_detail_sheet.dart';
import 'package:melsava/shared/models/experience_model.dart';

void main() {
  testWidgets(
    'ExperienceDetailSheet opens on root navigator and shows Join CTA',
    (tester) async {
      final exp = ExperienceModel(
        id: 'test-1',
        title: 'Weekend Trek to Mukutmanipur',
        description:
            'A refreshing trekking experience with like-minded people.',
        categoryName: 'Outdoors & Trekking',
        categoryIcon: '⛰️',
        coverImageUrl: 'assets/images/nature.png',
        city: 'Kolkata',
        venueName: 'Mukutmanipur Lake Ridge',
        venueAddress: 'Bankura',
        startsAt: DateTime.now().add(const Duration(days: 2)),
        durationMinutes: 180,
        maxParticipants: 20,
        currentParticipants: 18,
        hostName: 'Rahul',
        hostAvatar: 'assets/images/avatar.png',
        attendeeAvatars: const [],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      ExperienceDetailSheet.show(
                        context,
                        experience: exp,
                        onToggleJoin: () {},
                      );
                    },
                    child: const Text('Open Detail'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Detail'));
      await tester.pumpAndSettle();

      expect(find.text('Weekend Trek to Mukutmanipur'), findsOneWidget);
      expect(find.text('Join Experience →'), findsOneWidget);
    },
  );
}
