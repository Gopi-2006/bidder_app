import 'package:flutter_test/flutter_test.dart';
import 'package:bidder_app/main.dart';

void main() {
  testWidgets('Bidder app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const GemBidderApp());
    expect(find.text('Government e-Marketplace'), findsOneWidget);
  });
}
