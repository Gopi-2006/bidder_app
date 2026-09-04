import 'package:flutter_test/flutter_test.dart';
import 'package:bidder_app/main.dart';

void main() {
  testWidgets('Bidder app smoke test launches splash and advances', (WidgetTester tester) async {
    await tester.pumpWidget(const GemBidderApp());
    expect(find.text('GeM'), findsWidgets);
    // Advance timers so no pending timer remains
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });
}
