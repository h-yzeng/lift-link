import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:liftlink/app.dart';

void main() {
  testWidgets('App initializes without error', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: LiftLinkApp()));

    // Verify that the app initializes (shows loading indicator during auth check)
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('App uses Material 3', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: LiftLinkApp()));

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.theme?.useMaterial3, isTrue);
  });

  testWidgets('App has correct title', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: LiftLinkApp()));

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.title, equals('LiftLink'));
  });
}
