// Exercises creating, previewing and editing an invoice on a narrow phone.
// Tests follow setup → action → expected result. expect(...) checks the result.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lancebox/app/app.dart';
import 'package:lancebox/app/store.dart';

void main() {
  testWidgets('create, preview and edit an invoice at narrow phone width', (
    tester,
  ) async {
    // Set a predictable phone size for layout and scrolling checks.
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    // Restore the test display settings afterwards so other tests remain independent.
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    // Use in-memory preferences so this test cannot change real device data.
    SharedPreferences.setMockInitialValues({'onboarded': true});
    // Create isolated Riverpod state with the test’s storage dependency.
    final container = ProviderContainer(
      overrides: [
        preferencesProvider.overrideWithValue(
          await SharedPreferences.getInstance(),
        ),
      ],
    );
    // Release this test’s Riverpod state, even if an assertion fails.
    addTearDown(container.dispose);
    // Build the screen inside the test environment.
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const LanceBoxApp(),
      ),
    );
    await tester.tap(find.text('Create New Invoice'));
    // Finish pending frames and finite animations before checking the screen.
    await tester.pumpAndSettle();
    // Locate a field by label, scroll to it and enter the supplied test value.
    Future<void> fill(String label, String value) async {
      if (label == 'VAT (%)' || label == 'Shipping') {
        final target = find.byKey(
          ValueKey('summary-${label == 'VAT (%)' ? 'VAT' : label}'),
        );
        // Scroll until the target control is built and visible before interacting with it.
        await tester.scrollUntilVisible(
          target,
          180,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.enterText(target, value);
        await tester.pump();
        return;
      }
      final field = find.byWidgetPredicate(
        (w) => w is TextFormField && w.controller != null,
      );
      final labelFinder = find.text(label).first;
      // Scroll until the target control is built and visible before interacting with it.
      await tester.scrollUntilVisible(
        labelFinder,
        180,
        scrollable: find.byType(Scrollable).first,
      );
      final column = find
          .ancestor(of: labelFinder, matching: find.byType(Column))
          .first;
      final target = find.descendant(of: column, matching: field).first;
      await tester.ensureVisible(target);
      await tester.enterText(target, value);
      await tester.pump();
    }

    await fill('Client’s Name', 'Peter Abu');
    await fill('Your Name', 'Jane Doe');
    await fill('Invoice Title', 'Website design');
    await fill('Item Description', 'Design work');
    await fill('Quantity', '2');
    await fill('Price', '3000');
    await fill('VAT (%)', '');
    await fill('Shipping', '');
    await tester.ensureVisible(find.text('Next'));
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Next'))
          .onPressed,
      isNotNull,
    );
    await fill('VAT (%)', '101');
    // Scroll until the target control is built and visible before interacting with it.
    await tester.scrollUntilVisible(
      find.text('Next'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Next'))
          .onPressed,
      isNull,
    );
    await fill('VAT (%)', '7.5');
    await fill('Shipping', '500');
    await tester.ensureVisible(find.text('Next'));
    await tester.tap(find.text('Next'));
    // Finish pending frames and finite animations before checking the screen.
    await tester.pumpAndSettle();
    // Try more than ten digits to check that the input formatter limits the value.
    await fill('Bank Number', '012345678901');
    expect(find.text('0123456789'), findsOneWidget);
    // Check the error shown when a bank name contains numbers.
    await fill('Name of Bank', 'Lance123');
    expect(
      find.text('Bank name cannot contain numbers or special symbols'),
      findsOneWidget,
    );
    await fill('Bank Number', '0123456789');
    await fill('Name of Bank', 'Lance Bank');
    await fill('Name of Account', 'Jane Doe');
    await fill('Terms of Payment', 'Due on receipt');
    await tester.ensureVisible(find.text('Preview Invoice'));
    await tester.tap(find.text('Preview Invoice'));
    // Finish pending frames and finite animations before checking the screen.
    await tester.pumpAndSettle();
    expect(find.text('Preview'), findsOneWidget);
    // Return from preview and verify that customer and bank values are retained.
    await tester.tap(find.text('Edit Invoice'));
    // Finish pending frames and finite animations before checking the screen.
    await tester.pumpAndSettle();
    expect(find.text('Peter Abu'), findsOneWidget);
    // Scroll until the target control is built and visible before interacting with it.
    await tester.scrollUntilVisible(
      find.text('Next'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Next'));
    // Finish pending frames and finite animations before checking the screen.
    await tester.pumpAndSettle();
    expect(find.text('Lance Bank'), findsOneWidget);
    await tester.ensureVisible(find.text('Preview Invoice'));
    await tester.tap(find.text('Preview Invoice'));
    // Finish pending frames and finite animations before checking the screen.
    await tester.pumpAndSettle();
    expect(find.text('Preview'), findsOneWidget);
    // Fail if Flutter reported an unexpected error, including a layout overflow.
    expect(tester.takeException(), isNull);
  });
}
