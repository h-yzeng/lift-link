import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liftlink/features/social/presentation/pages/friends_list_page.dart';

void main() {
  group('FriendsListPage', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FriendsListPage(),
          ),
        ),
      );

      expect(find.byType(FriendsListPage), findsOneWidget);
    });

    testWidgets('displays Friends title', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FriendsListPage(),
          ),
        ),
      );

      expect(find.text('Friends'), findsOneWidget);
    });

    testWidgets('has scaffold structure', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FriendsListPage(),
          ),
        ),
      );

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });
  });
}
