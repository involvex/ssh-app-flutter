// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ssh_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ssh_app/services/config_service.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Initialize ConfigService with in-memory SharedPreferences for tests.
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await ConfigService.init();

    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify the app builds and shows the main title.
    expect(find.text('SSH App'), findsOneWidget);
  });
}
