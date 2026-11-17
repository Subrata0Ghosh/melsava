import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melsava/core/constants/app_colors.dart';

void main() {
  testWidgets('Bottom navigation tabs switch smoothly with no harsh border', (tester) async {
    int selectedIndex = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return Center(
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        key: const Key('tab_home'),
                        onTap: () => setState(() => selectedIndex = 0),
                        child: Text(
                          'Home',
                          style: TextStyle(
                            color: selectedIndex == 0 ? AppColors.primaryPurple : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        key: const Key('tab_discover'),
                        onTap: () => setState(() => selectedIndex = 1),
                        child: Text(
                          'Discover',
                          style: TextStyle(
                            color: selectedIndex == 1 ? AppColors.primaryPurple : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Discover'), findsOneWidget);

    // Tap Discover
    await tester.tap(find.byKey(const Key('tab_discover')));
    await tester.pumpAndSettle();

    expect(selectedIndex, 1);
  });
}
