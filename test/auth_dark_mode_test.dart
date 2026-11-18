import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melsava/shared/widgets/custom_text_field.dart';
import 'package:melsava/shared/widgets/melsava_logo.dart';

void main() {
  testWidgets(
    'CustomTextField renders dark obsidian glass background and light text in dark mode',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: CustomTextField(
              label: 'Email address',
              hintText: 'name@example.com',
            ),
          ),
        ),
      );

      expect(find.text('Email address'), findsOneWidget);
      expect(find.text('name@example.com'), findsOneWidget);

      // Verify label style is bright and high contrast
      final labelText = tester.widget<Text>(find.text('Email address'));
      expect(labelText.style?.color, const Color(0xFFF1ECF9));

      // Verify input text field decoration is not solid white
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.decoration?.fillColor, isNot(Colors.white));
    },
  );

  testWidgets(
    'MelsavaLogo renders luminous colors and glowing wordmark in dark mode',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(body: MelsavaLogo(size: 80, showWordmark: true)),
        ),
      );

      expect(find.text('MELSAVA'), findsOneWidget);

      final wordmark = tester.widget<Text>(find.text('MELSAVA'));
      expect(wordmark.style?.color, const Color(0xFFF7F5FC));
      expect(wordmark.style?.shadows, isNotNull);
    },
  );
}
