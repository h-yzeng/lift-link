import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liftlink/features/workout/presentation/pages/workout_history_page.dart';

void main() {
  group('WorkoutHistoryPage', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: WorkoutHistoryPage(),
          ),
        ),
      );

      expect(find.byType(WorkoutHistoryPage), findsOneWidget);
    });

    testWidgets('displays Workout History title', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: WorkoutHistoryPage(),
          ),
        ),
      );

      expect(find.text('Workout History'), findsOneWidget);
    });

    testWidgets('has scaffold structure', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: WorkoutHistoryPage(),
          ),
        ),
      );

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });
  });
}
