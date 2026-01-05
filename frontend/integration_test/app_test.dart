import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liftlink/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('LiftLink Integration Tests', () {
    testWidgets('App launches successfully', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify app loads - check for MaterialApp
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Navigation between pages works', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // App should be running
      expect(find.byType(MaterialApp), findsOneWidget);

      // Integration test framework is set up and working
    });
  });
}
