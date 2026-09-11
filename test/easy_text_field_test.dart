import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:amma_nanna_app/widgets/easy_text_field.dart';

void main() {
  group('EasyTextField Widget Tests', () {
    testWidgets('Renders label, hint, and text input properly', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EasyTextField(
              controller: controller,
              label: 'పేరు',
              hintText: 'పేరును టైప్ చేయండి',
            ),
          ),
        ),
      );

      expect(find.text('పేరు'), findsOneWidget);
      expect(find.text('పేరును టైప్ చేయండి'), findsOneWidget);
    });

    testWidgets('Clear button appears when text is entered and clears on tap', (tester) async {
      final controller = TextEditingController(text: 'రాము');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EasyTextField(
              controller: controller,
              label: 'పేరు',
            ),
          ),
        ),
      );

      // Verify clear icon is visible
      expect(find.byIcon(Icons.cancel_rounded), findsOneWidget);

      // Tap clear icon
      await tester.tap(find.byIcon(Icons.cancel_rounded));
      await tester.pumpAndSettle();

      expect(controller.text, isEmpty);
      expect(find.byIcon(Icons.cancel_rounded), findsNothing);
    });

    testWidgets('Calls onVoiceTap when voice mic button is tapped', (tester) async {
      bool voiceTapped = false;
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EasyTextField(
              controller: controller,
              label: 'పేరు',
              onVoiceTap: () => voiceTapped = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.mic_none_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.mic_none_rounded));
      await tester.pump();

      expect(voiceTapped, isTrue);
    });

    testWidgets('Calls onPasteTap when paste button is tapped', (tester) async {
      bool pasteTapped = false;
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EasyTextField(
              controller: controller,
              label: 'ఫోన్ నంబర్',
              onPasteTap: () => pasteTapped = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.paste_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.paste_rounded));
      await tester.pump();

      expect(pasteTapped, isTrue);
    });
  });
}
