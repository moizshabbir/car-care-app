import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:car_care_app/main.dart';

void main() {
  testWidgets('App initialization test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our app displays the initialized text.
    expect(find.text('Car Care App Initialized'), findsOneWidget);
  });
}
