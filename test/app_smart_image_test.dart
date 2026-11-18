import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melsava/shared/widgets/app_smart_image.dart';

void main() {
  group('AppFallbackAssets Tests', () {
    test('resolves correct category fallback covers', () {
      expect(
        AppFallbackAssets.getCategoryCover('Sports'),
        AppFallbackAssets.sportsCover,
      );
      expect(
        AppFallbackAssets.getCategoryCover('Cycling Club Ride'),
        AppFallbackAssets.sportsCover,
      );
      expect(
        AppFallbackAssets.getCategoryCover('Weekend Trekking'),
        AppFallbackAssets.outdoorsCover,
      );
      expect(
        AppFallbackAssets.getCategoryCover('Coffee & Books'),
        AppFallbackAssets.coffeeCover,
      );
      expect(
        AppFallbackAssets.getCategoryCover('Sourdough Baking'),
        AppFallbackAssets.foodCover,
      );
      expect(
        AppFallbackAssets.getCategoryCover('Morning Yoga'),
        AppFallbackAssets.wellnessCover,
      );
      expect(
        AppFallbackAssets.getCategoryCover('Acoustic Concert'),
        AppFallbackAssets.musicCultureCover,
      );
      expect(
        AppFallbackAssets.getCategoryCover(null),
        AppFallbackAssets.defaultExperienceCover,
      );
    });

    test('resolves correct avatar fallbacks', () {
      expect(
        AppFallbackAssets.getAvatar(null),
        AppFallbackAssets.defaultProfileAvatar,
      );
      expect(
        AppFallbackAssets.getAvatar(''),
        AppFallbackAssets.defaultProfileAvatar,
      );
      expect(
        AppFallbackAssets.getAvatar('Rohan Sen'),
        'assets/images/rohan_avatar.png',
      );
      expect(
        AppFallbackAssets.getAvatar('Aditi Sharma'),
        'assets/images/aditi_avatar.png',
      );
      expect(
        AppFallbackAssets.getAvatar('Priya'),
        'assets/images/priya_avatar.png',
      );
      expect(
        AppFallbackAssets.getAvatar('Vikram'),
        'assets/images/vikram_avatar.png',
      );
      expect(
        AppFallbackAssets.getAvatar('Sneha'),
        'assets/images/sneha_avatar.png',
      );
    });
  });

  group('AppSmartImage Widget Tests', () {
    testWidgets('renders fallback Image.asset when imagePath is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppSmartImage(imagePath: null, categoryHint: 'Sports'),
          ),
        ),
      );

      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);
    });

    testWidgets(
      'renders avatar fallback when isAvatar is true and imagePath is empty',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AppSmartImage(
                imagePath: '',
                isAvatar: true,
                nameHint: 'Rohan',
              ),
            ),
          ),
        );

        final imageFinder = find.byType(Image);
        expect(imageFinder, findsOneWidget);
      },
    );
  });
}
