import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'test_main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('E2E Test: Core Loop, Validation, Stability', (tester) async {
    // Set screen size
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Start app with mocks
    app.main();
    await tester.pumpAndSettle();

    // 1. UI Stability: Switch Tabs
    print('Testing UI Stability...');
    expect(find.text('Dashboard'), findsOneWidget); // Home tab default

    await tester.tap(find.byIcon(Icons.bar_chart));
    await tester.pumpAndSettle();
    expect(find.text('Share Stats'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.home));
    await tester.pumpAndSettle();
    expect(find.text('Dashboard'), findsOneWidget);

    // 2. Validation: Add Expense
    print('Testing Validation: Add Expense...');
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Tap "Log Expense" in BottomSheet
    await tester.tap(find.text('Log Expense'));
    await tester.pumpAndSettle();

    expect(find.text('Add Expense'), findsOneWidget);

    // Check Save button is disabled initially
    final saveBtnFinder = find.widgetWithText(ElevatedButton, 'Save Expense');
    final ElevatedButton saveBtn = tester.widget(saveBtnFinder);
    expect(saveBtn.onPressed, isNull);

    // Enter Cost (First TextFormField)
    await tester.enterText(find.byType(TextFormField).first, '50.0');
    await tester.pump();

    // Check Save button enabled
    final ElevatedButton saveBtnEnabled = tester.widget(saveBtnFinder);
    expect(saveBtnEnabled.onPressed, isNotNull);

    // Enter Invalid Cost? (Empty)
    await tester.enterText(find.byType(TextFormField).first, '');
    await tester.pump();
    final ElevatedButton saveBtnDisabled = tester.widget(saveBtnFinder);
    expect(saveBtnDisabled.onPressed, isNull);

    // Cancel
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // 3. Validation: Manual Fuel Log
    print('Testing Validation: Manual Fuel Log...');
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Log Fuel (Scan)'));
    // QuickLogPage has infinite animation. pumpAndSettle will timeout.
    await tester.pump(const Duration(seconds: 1));

    // Tap "Enter Manually"
    await tester.tap(find.text('Enter Manually'));
    // Sheet opens over infinite animation background.
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Manual Entry'), findsOneWidget);

    final saveEntryBtnFinder = find.widgetWithText(ElevatedButton, 'Save Entry');
    final ElevatedButton saveEntryBtn = tester.widget(saveEntryBtnFinder);
    expect(saveEntryBtn.onPressed, isNull);

    // Enter partial data
    // Odometer is likely first, Liters second, Cost third in the sheet
    // But QuickLogPage might have other inputs? No, camera preview is distinct.
    // The Sheet is on top.
    // We can find by label but _buildField label is separate Text widget.
    // We'll use index.

    // Odometer
    await tester.enterText(find.byType(TextFormField).at(0), '10000');
    await tester.pump();
    expect((tester.widget(saveEntryBtnFinder) as ElevatedButton).onPressed, isNull);

    // Volume
    await tester.enterText(find.byType(TextFormField).at(1), '50');
    await tester.pump();
    expect((tester.widget(saveEntryBtnFinder) as ElevatedButton).onPressed, isNull);

    // Cost
    await tester.enterText(find.byType(TextFormField).at(2), '100');
    await tester.pump();

    // Now should be enabled
    expect((tester.widget(saveEntryBtnFinder) as ElevatedButton).onPressed, isNotNull);

    // 4. Core Loop: Save and Verify
    print('Testing Core Loop: Save and Verify...');
    // Note: Offline Sync is implicitly tested here as we expect optimistic UI update
    // independent of network status (which relies on Firestore offline persistence).

    await tester.tap(saveEntryBtnFinder);
    await tester.pumpAndSettle(); // Wait for sync/save and navigation

    // Should return to Dashboard
    expect(find.text('Dashboard'), findsOneWidget);

    // Verify log in list
    expect(find.textContaining('50.0L @ \$100.00'), findsOneWidget);
    expect(find.text('10000 km'), findsOneWidget);

    print('E2E Test Passed!');
  });
}
