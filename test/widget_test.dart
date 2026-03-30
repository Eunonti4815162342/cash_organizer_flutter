import 'package:flutter_test/flutter_test.dart';
import 'package:cash_organizer_flutter/main.dart';

void main() {
  testWidgets('App starts smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CashOrganizerApp());

    // Verify that the title Resumen exists in our navigation
    expect(find.text('Resumen'), findsWidgets);
  });
}
