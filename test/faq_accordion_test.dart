import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melsava/features/profile/presentation/settings_screen.dart';

void main() {
  testWidgets('FaqAccordion expands tapped item and auto-collapses others', (tester) async {
    final testFaqs = [
      {'q': 'Question 1', 'a': 'Answer 1'},
      {'q': 'Question 2', 'a': 'Answer 2'},
      {'q': 'Question 3', 'a': 'Answer 3'},
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FaqAccordion(
            faqs: testFaqs,
            cardBg: Colors.white,
            borderColor: Colors.grey,
            primaryTextColor: Colors.black,
            mutedTextColor: Colors.grey,
          ),
        ),
      ),
    );

    // Initially all are collapsed
    expect(find.text('Question 1'), findsOneWidget);
    expect(find.text('Question 2'), findsOneWidget);
    expect(find.text('Question 3'), findsOneWidget);

    // Tap Question 1 to expand it
    await tester.tap(find.text('Question 1'));
    await tester.pumpAndSettle();

    // Question 1 answer should be visible
    expect(find.text('Answer 1'), findsOneWidget);

    // Tap Question 2: Question 2 should expand, and Question 1 should auto-collapse!
    await tester.tap(find.text('Question 2'));
    await tester.pumpAndSettle();

    expect(find.text('Answer 2'), findsOneWidget);

    // Tap Question 2 again: should collapse Question 2
    await tester.tap(find.text('Question 2'));
    await tester.pumpAndSettle();

    // Verify all collapsed
    final q2Text = tester.widget<AnimatedRotation>(
      find.byType(AnimatedRotation).at(1),
    );
    expect(q2Text.turns, 0.0);
  });
}
