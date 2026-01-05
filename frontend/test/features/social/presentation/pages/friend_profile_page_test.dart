import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liftlink/features/social/presentation/pages/friend_profile_page.dart';

void main() {
  group('FriendProfilePage', () {
    const testFriendId = 'friend-123';

    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FriendProfilePage(friendId: testFriendId),
          ),
        ),
      );

      expect(find.byType(FriendProfilePage), findsOneWidget);
    });
  });
}
