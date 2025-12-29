import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:liftlink/app.dart';

void main() {
  testWidgets('App shows coming soon message', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: LiftLinkApp()));

    // Verify that the coming soon message is displayed.
    expect(find.text('LiftLink - Coming Soon'), findsOneWidget);
  });
}
