import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melsava/core/services/worldwide_location_service.dart';
import 'package:melsava/shared/widgets/activity_radar_map_card.dart';

void main() {
  testWidgets(
    'ActivityRadarMapCard renders inside CustomScrollView without layout exception',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(
              body: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: ActivityRadarMapCard(
                        location: WorldLocation.defaultLocation,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(ActivityRadarMapCard), findsOneWidget);
    },
  );
}
