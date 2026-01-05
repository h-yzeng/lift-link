import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liftlink/features/social/presentation/pages/activity_feed_page.dart';

void main() {
  group('ActivityFeedPage', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ActivityFeedPage(),
          ),
        ),
      );

      expect(find.byType(ActivityFeedPage), findsOneWidget);
    });
  });
}
