import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:melsava/app/melsava_app.dart';

void main() {
  testWidgets('MELSAVA app smoke test & onboarding flow', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(child: MelsavaApp()));

    expect(find.text('MELSAVA'), findsWidgets);

    // Advance past splash animation (2.6s)
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // Verifies onboarding screen loaded with primary action
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
  });
}
