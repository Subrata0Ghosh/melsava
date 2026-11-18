import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:melsava/features/profile/presentation/profile_screen.dart';

void main() {
  testWidgets('Profile back button navigates back or falls back to /discover', (
    tester,
  ) async {
    bool navigatedToDiscover = false;

    final router = GoRouter(
      initialLocation: '/profile',
      routes: [
        GoRoute(
          path: '/discover',
          builder: (context, state) {
            navigatedToDiscover = true;
            return const Scaffold(body: Text('Discover Screen'));
          },
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );

    await tester.pump(const Duration(milliseconds: 300));

    // Verify profile screen is rendered
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);

    // Tap back button
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify it navigated to discover screen
    expect(navigatedToDiscover, isTrue);
    expect(find.text('Discover Screen'), findsOneWidget);
  });
}
