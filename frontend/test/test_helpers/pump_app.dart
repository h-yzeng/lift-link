import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Helper function to pump a widget wrapped with MaterialApp and providers
Future<void> pumpApp(
  WidgetTester tester,
  Widget widget, {
  List<Object> overrides = const [],
  ThemeMode themeMode = ThemeMode.light,
}) async {
  final container = ProviderContainer(overrides: overrides.cast());

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        themeMode: themeMode,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        home: widget,
      ),
    ),
  );
}

/// Helper function to pump a widget with navigation support
Future<void> pumpAppWithNavigator(
  WidgetTester tester,
  Widget widget, {
  List<Object> overrides = const [],
  ThemeMode themeMode = ThemeMode.light,
  List<NavigatorObserver>? observers,
}) async {
  final container = ProviderContainer(overrides: overrides.cast());

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        themeMode: themeMode,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        home: widget,
        navigatorObservers: observers ?? [],
      ),
    ),
  );
}
