// Checks that deleting the final invoice line disables Next and still allows adding a replacement.
// Tests follow setup → action → expected result. expect(...) checks the result.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lancebox/app/store.dart';
import 'package:lancebox/features/invoices/editor.dart';

void main() {
  testWidgets('last invoice item can be deleted and a new item added', (
    tester,
  ) async {
    // Use in-memory preferences so this test cannot change real device data.
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    // Build the screen inside the test environment.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [preferencesProvider.overrideWithValue(prefs)],
        child: const MaterialApp(home: InvoiceEditor()),
      ),
    );
    // Scroll until the target control is built and visible before interacting with it.
    await tester.scrollUntilVisible(
      find.byWidgetPredicate(
        (widget) => widget is IconButton && widget.tooltip == 'Remove item 1',
      ),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    // Finish pending frames and finite animations before checking the screen.
    await tester.pumpAndSettle();
    await tester.tap(
      find.byWidgetPredicate(
        (widget) => widget is IconButton && widget.tooltip == 'Remove item 1',
      ),
    );
    // Finish pending frames and finite animations before checking the screen.
    await tester.pumpAndSettle();
    // The deleted line must no longer have a remove button.
    expect(
      find.byWidgetPredicate(
        (widget) => widget is IconButton && widget.tooltip == 'Remove item 1',
      ),
      findsNothing,
    );
    // Scroll until the target control is built and visible before interacting with it.
    await tester.scrollUntilVisible(
      find.text('Next'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    // Check the expected UI result; a null onPressed callback means Next is disabled.
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Next'))
          .onPressed,
      isNull,
    );
    await tester.ensureVisible(find.text('Add New Item'));
    // Finish pending frames and finite animations before checking the screen.
    await tester.pumpAndSettle();
    // Add a fresh line after deleting the last one to confirm the form remains usable.
    await tester.tap(find.text('Add New Item'));
    // Finish pending frames and finite animations before checking the screen.
    await tester.pumpAndSettle();
    // Scroll until the target control is built and visible before interacting with it.
    await tester.scrollUntilVisible(
      find.byWidgetPredicate(
        (widget) => widget is IconButton && widget.tooltip == 'Remove item 1',
      ),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    // Check the expected UI result; a null onPressed callback means Next is disabled.
    expect(
      find.byWidgetPredicate(
        (widget) => widget is IconButton && widget.tooltip == 'Remove item 1',
      ),
      findsOneWidget,
    );
    // Check the expected UI result; a null onPressed callback means Next is disabled.
    expect(tester.takeException(), isNull);
  });
}
