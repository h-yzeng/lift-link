import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liftlink/features/auth/presentation/pages/login_page.dart';

void main() {
  group('LoginPage', () {
    testWidgets('displays email and password fields', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('displays login button', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      expect(find.text('Log In'), findsOneWidget);
    });

    testWidgets('displays create account button', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      expect(find.text('Create Account'), findsOneWidget);
    });

    testWidgets('displays forgot password link', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      expect(find.text('Forgot Password?'), findsOneWidget);
    });

    testWidgets('validates empty email field', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      // Tap login button without entering data
      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();

      // Should show validation errors
      expect(find.text('Please enter your email'), findsOneWidget);
    });

    testWidgets('toggles password visibility', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      // Find the password visibility toggle button (shows visibility icon when obscured)
      final visibilityToggle = find.byIcon(Icons.visibility);
      expect(visibilityToggle, findsOneWidget);

      // Tap to show password
      await tester.tap(visibilityToggle);
      await tester.pumpAndSettle();

      // Icon should change to visibility_off
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });
  });
}
