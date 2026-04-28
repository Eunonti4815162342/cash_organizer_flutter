import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:natave_flutter/main.dart';

void main() {
  testWidgets('App basic smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // Note: Since NataveApp expects a locale, we provide one
    await tester.pumpWidget(const NataveApp(locale: Locale('en')));

    // Basic check to see if the app title is present (or at least starts loading)
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
