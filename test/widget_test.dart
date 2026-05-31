import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amma_nanna_app/app.dart';

void main() {
  testWidgets('AmmaNannaApp Boot Smoke Test - Renders Telugu Home screen', (WidgetTester tester) async {
    // Build our app under ProviderScope to enable Riverpod dependency injection
    await tester.pumpWidget(
      const ProviderScope(
        child: AmmaNannaApp(),
      ),
    );

    // Let any asynchronous router initializations complete
    await tester.pump(const Duration(milliseconds: 500));

    // Verify that our main App Header is successfully found on screen
    expect(find.text('EasySave'), findsOneWidget);
    expect(find.text('మీ సులభమైన సేవ్ యాప్'), findsOneWidget);

    // Verify that our giant home buttons exist in Telugu
    expect(find.text('కొత్త నంబర్'), findsWidgets);
    expect(find.text('ఫోటో పంపండి'), findsWidgets);
  });
}
