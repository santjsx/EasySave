import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amma_nanna_app/widgets/easy_number_pad.dart';

void main() {
  group('Tactile EasyNumberPad - Widget Tests', () {
    testWidgets('1. Renders all 0-9 digits, backspace, and clear sweep actions', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EasyNumberPad(
              onDigitTap: (_) {},
              onBackspaceTap: () {},
              onClearTap: () {},
            ),
          ),
        ),
      );

      // Verify that all standard numerical digits from 0 to 9 render successfully
      for (int i = 0; i <= 9; i++) {
        expect(find.text('$i'), findsOneWidget);
      }

      // Verify that backspace (Delete) and sweep (Clear) icons render cleanly
      expect(find.byIcon(Icons.backspace_outlined), findsOneWidget);
      expect(find.byIcon(Icons.delete_forever_outlined), findsOneWidget);
    });

    testWidgets('2. Pressing digit buttons triggers onDigitTap callback', (WidgetTester tester) async {
      String tappedDigit = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EasyNumberPad(
              onDigitTap: (digit) {
                tappedDigit = digit;
              },
              onBackspaceTap: () {},
              onClearTap: () {},
            ),
          ),
        ),
      );

      // Tap on the '7' digit button
      await tester.tap(find.text('7'));
      await tester.pump();

      expect(tappedDigit, equals('7'));

      // Tap on the '0' digit button
      await tester.tap(find.text('0'));
      await tester.pump();

      expect(tappedDigit, equals('0'));
    });

    testWidgets('3. Tapping Backspace icon triggers onBackspaceTap callback', (WidgetTester tester) async {
      bool backspaceTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EasyNumberPad(
              onDigitTap: (_) {},
              onBackspaceTap: () {
                backspaceTapped = true;
              },
              onClearTap: () {},
            ),
          ),
        ),
      );

      // Tap the backspace button
      await tester.tap(find.byIcon(Icons.backspace_outlined));
      await tester.pump();

      expect(backspaceTapped, isTrue);
    });

    testWidgets('4. Tapping Clear All icon triggers onClearTap callback', (WidgetTester tester) async {
      bool clearTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EasyNumberPad(
              onDigitTap: (_) {},
              onBackspaceTap: () {},
              onClearTap: () {
                clearTapped = true;
              },
            ),
          ),
        ),
      );

      // Tap the clear (Sweep) button
      await tester.tap(find.byIcon(Icons.delete_forever_outlined));
      await tester.pump();

      expect(clearTapped, isTrue);
    });
  });
}
