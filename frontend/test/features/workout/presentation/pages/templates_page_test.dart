import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liftlink/features/workout/presentation/pages/templates_page.dart';

void main() {
  group('TemplatesPage', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TemplatesPage(),
          ),
        ),
      );

      expect(find.byType(TemplatesPage), findsOneWidget);
    });

    testWidgets('displays Workout Templates title', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TemplatesPage(),
          ),
        ),
      );

      expect(find.text('Workout Templates'), findsOneWidget);
    });

    testWidgets('has scaffold structure', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TemplatesPage(),
          ),
        ),
      );

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });
  });
}
