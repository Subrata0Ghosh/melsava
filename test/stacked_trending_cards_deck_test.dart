import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melsava/shared/models/experience_model.dart';
import 'package:melsava/shared/widgets/stacked_trending_cards_deck.dart';

void main() {
  testWidgets('StackedTrendingCardsDeck renders and allows swipe interaction', (
    tester,
  ) async {
    final experiences = [
      ExperienceModel(
        id: 'exp-1',
        title: 'Sunset Sailing',
        description: 'Enjoy sunset',
        categoryName: 'Adventure',
        categoryIcon: '⛵',
        coverImageUrl: 'assets/images/placeholder.jpg',
        city: 'Mumbai',
        venueName: 'Marine Drive',
        venueAddress: 'South Mumbai',
        startsAt: DateTime(2026, 11, 20, 18, 0),
        durationMinutes: 120,
        maxParticipants: 10,
        currentParticipants: 4,
        hostName: 'Captain Jack',
        hostAvatar: 'assets/images/placeholder.jpg',
        attendeeAvatars: const [],
      ),
      ExperienceModel(
        id: 'exp-2',
        title: 'Coffee & Conversation',
        description: 'Meet over coffee',
        categoryName: 'Social',
        categoryIcon: '☕',
        coverImageUrl: 'assets/images/placeholder.jpg',
        city: 'Mumbai',
        venueName: 'Artisan Cafe',
        venueAddress: 'Bandra West',
        startsAt: DateTime(2026, 11, 21, 10, 0),
        durationMinutes: 90,
        maxParticipants: 8,
        currentParticipants: 6,
        hostName: 'Sarah',
        hostAvatar: 'assets/images/placeholder.jpg',
        attendeeAvatars: const [],
      ),
      ExperienceModel(
        id: 'exp-3',
        title: 'Art Gallery Walk',
        description: 'Explore local art',
        categoryName: 'Arts & Culture',
        categoryIcon: '🎨',
        coverImageUrl: 'assets/images/placeholder.jpg',
        city: 'Mumbai',
        venueName: 'Kala Ghoda',
        venueAddress: 'Fort',
        startsAt: DateTime(2026, 11, 22, 14, 0),
        durationMinutes: 150,
        maxParticipants: 6,
        currentParticipants: 2,
        hostName: 'David',
        hostAvatar: 'assets/images/placeholder.jpg',
        attendeeAvatars: const [],
      ),
    ];

    ExperienceModel? tappedJoin;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StackedTrendingCardsDeck(
            experiences: experiences,
            onJoinTap: (exp) => tappedJoin = exp,
          ),
        ),
      ),
    );

    // Initial render: first experience visible
    expect(find.text('Sunset Sailing'), findsOneWidget);
    expect(find.text('1/3'), findsOneWidget);
    expect(find.text('Join Now →'), findsOneWidget);

    // Tap Join Now
    await tester.tap(find.text('Join Now →'));
    await tester.pump();
    expect(tappedJoin?.id, 'exp-1');

    // Drag / swipe left to advance
    await tester.drag(find.text('Sunset Sailing'), const Offset(-250, 0));
    await tester.pumpAndSettle();

    // Now second card should be active
    expect(find.text('Coffee & Conversation'), findsOneWidget);
    expect(find.text('2/3'), findsOneWidget);
  });
}
