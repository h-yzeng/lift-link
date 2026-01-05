import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liftlink/features/workout/presentation/pages/create_exercise_page.dart';

void main() {
  group('CreateExercisePage', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CreateExercisePage(),
          ),
        ),
      );

      expect(find.byType(CreateExercisePage), findsOneWidget);
    });

    testWidgets('displays Create Exercise title', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CreateExercisePage(),
          ),
        ),
      );

      expect(find.text('Create Exercise'), findsOneWidget);
    });

    testWidgets('displays exercise name field', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CreateExercisePage(),
          ),
        ),
      );

      expect(find.text('Exercise Name'), findsOneWidget);
    });

    testWidgets('has form structure', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CreateExercisePage(),
          ),
        ),
      );

      expect(find.byType(Form), findsOneWidget);
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('has scaffold and appbar', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CreateExercisePage(),
          ),
        ),
      );

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });
  });
}
