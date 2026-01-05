import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liftlink/features/workout/presentation/pages/exercise_list_page.dart';

void main() {
  group('ExerciseListPage', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ExerciseListPage(),
          ),
        ),
      );

      expect(find.byType(ExerciseListPage), findsOneWidget);
    });

    testWidgets('displays Exercise Library title', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ExerciseListPage(),
          ),
        ),
      );

      expect(find.text('Exercise Library'), findsOneWidget);
    });

    testWidgets('displays search field', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ExerciseListPage(),
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search exercises...'), findsOneWidget);
    });

    testWidgets('displays search icon', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ExerciseListPage(),
          ),
        ),
      );

      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('has scaffold structure', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ExerciseListPage(),
          ),
        ),
      );

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });
  });
}
