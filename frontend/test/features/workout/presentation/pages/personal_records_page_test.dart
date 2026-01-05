import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liftlink/features/workout/presentation/pages/personal_records_page.dart';

void main() {
  group('PersonalRecordsPage', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PersonalRecordsPage(),
          ),
        ),
      );

      expect(find.byType(PersonalRecordsPage), findsOneWidget);
    });

    testWidgets('displays Personal Records title', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PersonalRecordsPage(),
          ),
        ),
      );

      expect(find.text('Personal Records'), findsOneWidget);
    });

    testWidgets('has scaffold structure', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PersonalRecordsPage(),
          ),
        ),
      );

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });
  });
}
