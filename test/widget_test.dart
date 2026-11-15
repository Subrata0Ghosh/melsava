import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melsava/app/melsava_app.dart';

void main() {
  testWidgets('MELSAVA app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MelsavaApp()));

    expect(find.text('MELSAVA'), findsOneWidget);

    // Advance past splash timer
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    // Verifies welcome screen loaded
    expect(find.text('Get Started'), findsOneWidget);
  });
}
