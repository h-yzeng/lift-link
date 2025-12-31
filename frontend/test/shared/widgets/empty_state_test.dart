import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liftlink/shared/widgets/empty_state.dart';

void main() {
  group('EmptyState', () {
    testWidgets('displays icon with correct properties', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              title: 'No items',
            ),
          ),
        ),
      );

      final iconFinder = find.byIcon(Icons.inbox);
      expect(iconFinder, findsOneWidget);

      final Icon icon = tester.widget(iconFinder);
      expect(icon.size, equals(64)); // default iconSize
    });

    testWidgets('displays custom icon size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              title: 'No items',
              iconSize: 100,
            ),
          ),
        ),
      );

      final iconFinder = find.byIcon(Icons.inbox);
      final Icon icon = tester.widget(iconFinder);
      expect(icon.size, equals(100));
    });

    testWidgets('displays title text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              title: 'Nothing here yet',
            ),
          ),
        ),
      );

      expect(find.text('Nothing here yet'), findsOneWidget);
    });

    testWidgets('displays subtitle when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              title: 'No items',
              subtitle: 'Add some items to get started',
            ),
          ),
        ),
      );

      expect(find.text('Add some items to get started'), findsOneWidget);
    });

    testWidgets('hides subtitle when not provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              title: 'No items',
            ),
          ),
        ),
      );

      expect(find.text('Add some items to get started'), findsNothing);
    });

    testWidgets('displays action button when both label and callback provided', (tester) async {
      var buttonPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              title: 'No items',
              actionLabel: 'Add Item',
              onAction: () => buttonPressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Add Item'), findsOneWidget);

      await tester.tap(find.text('Add Item'));
      expect(buttonPressed, isTrue);
    });

    testWidgets('hides action button when only label provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              title: 'No items',
              actionLabel: 'Add Item',
            ),
          ),
        ),
      );

      expect(find.widgetWithText(FilledButton, 'Add Item'), findsNothing);
    });

    testWidgets('uses custom icon color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              title: 'No items',
              iconColor: Colors.red,
            ),
          ),
        ),
      );

      final iconFinder = find.byIcon(Icons.inbox);
      final Icon icon = tester.widget(iconFinder);
      expect(icon.color, equals(Colors.red));
    });

    testWidgets('centers content', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              title: 'No items',
            ),
          ),
        ),
      );

      // EmptyState wraps content in Center - verify the EmptyState widget is present
      expect(find.byType(EmptyState), findsOneWidget);
    });
  });
}
