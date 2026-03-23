// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutterapp/main.dart' as app;

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    // Start the real app and trigger frames.
    app.main();
    await tester.pumpAndSettle();

    // Verify that the app root is present.
    expect(find.byType(WidgetsApp), findsOneWidget);
  });
}
