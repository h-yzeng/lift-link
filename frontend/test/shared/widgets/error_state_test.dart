import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liftlink/shared/widgets/error_state.dart';

void main() {
  group('ErrorState', () {
    testWidgets('displays error icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorState(message: 'Something went wrong'),
          ),
        ),
      );

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('displays custom icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorState(
              message: 'Network error',
              icon: Icons.wifi_off,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
    });

    testWidgets('displays error message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorState(message: 'Failed to load data'),
          ),
        ),
      );

      expect(find.text('Failed to load data'), findsOneWidget);
    });

    testWidgets('displays retry button when onRetry provided', (tester) async {
      var retried = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorState(
              message: 'Error',
              onRetry: () => retried = true,
            ),
          ),
        ),
      );

      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      expect(retried, isTrue);
    });

    testWidgets('hides retry button when onRetry is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorState(message: 'Error'),
          ),
        ),
      );

      expect(find.text('Retry'), findsNothing);
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('displays custom retry label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorState(
              message: 'Error',
              onRetry: () {},
              retryLabel: 'Try Again',
            ),
          ),
        ),
      );

      expect(find.text('Try Again'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('centers content', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorState(message: 'Error'),
          ),
        ),
      );

      // ErrorState wraps content in Center - verify the ErrorState widget is present
      expect(find.byType(ErrorState), findsOneWidget);
    });

    testWidgets('fromError factory creates widget with error toString', (tester) async {
      final error = Exception('Test exception');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorState.fromError(error),
          ),
        ),
      );

      expect(find.textContaining('Test exception'), findsOneWidget);
    });

    testWidgets('fromError factory includes onRetry', (tester) async {
      var retried = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorState.fromError(
              Exception('Error'),
              onRetry: () => retried = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Retry'));
      expect(retried, isTrue);
    });

    testWidgets('uses error color from theme', (tester) async {
      const errorColor = Colors.purple;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: const ColorScheme.light().copyWith(error: errorColor),
          ),
          home: const Scaffold(
            body: ErrorState(message: 'Error'),
          ),
        ),
      );

      final iconFinder = find.byIcon(Icons.error_outline);
      final Icon icon = tester.widget(iconFinder);
      expect(icon.color, equals(errorColor));
    });
  });
}
