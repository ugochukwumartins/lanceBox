// Exercises creating, previewing and editing an invoice on a narrow phone.
// Tests follow setup → action → expected result. expect(...) checks the result.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lancebox/app/app.dart';
import 'package:lancebox/app/store.dart';
import 'helpers/form_actions.dart';

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
    await tester.pumpAndSettle();
    // ACT: Complete the invoice details.
    await enterField(tester, 'Client’s Name', 'Peter Abu');
    await enterField(tester, 'Your Name', 'Jane Doe');
    await enterField(tester, 'Invoice Title', 'Website design');
    await enterField(tester, 'Item Description', 'Design work');
    await enterField(tester, 'Quantity', '2');
    await enterField(tester, 'Price', '3000');
    await enterCharge(tester, 'VAT', '');
    await enterCharge(tester, 'Shipping', '');
    await tester.ensureVisible(find.text('Next'));
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Next'))
          .onPressed,
      isNotNull,
    );
    // CHECK: Optional charges may be blank, but VAT above 100 blocks Next.
    await enterCharge(tester, 'VAT', '101');
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
    await enterCharge(tester, 'VAT', '7.5');
    await enterCharge(tester, 'Shipping', '500');
    await tapButton(tester, 'Next');
    // Try more than ten digits to check that the input formatter limits the value.
    await enterField(tester, 'Bank Number', '012345678901');
    expect(find.text('0123456789'), findsOneWidget);
    // Check the error shown when a bank name contains numbers.
    await enterField(tester, 'Name of Bank', 'Lance123');
    expect(
      find.text('Bank name cannot contain numbers or special symbols'),
      findsOneWidget,
    );
    await enterField(tester, 'Bank Number', '0123456789');
    await enterField(tester, 'Name of Bank', 'Lance Bank');
    await enterField(tester, 'Name of Account', 'Jane Doe');
    await enterField(tester, 'Terms of Payment', 'Due on receipt');
    await tapButton(tester, 'Preview Invoice');
    expect(find.text('Preview'), findsOneWidget);
    // Return from preview and verify that customer and bank values are retained.
    await tester.tap(find.text('Edit Invoice'));
    await tester.pumpAndSettle();
    expect(find.text('Peter Abu'), findsOneWidget);
    // Scroll until the target control is built and visible before interacting with it.
    await tester.scrollUntilVisible(
      find.text('Next'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Lance Bank'), findsOneWidget);
    await tapButton(tester, 'Preview Invoice');
    expect(find.text('Preview'), findsOneWidget);
    // Fail if Flutter reported an unexpected error, including a layout overflow.
    expect(tester.takeException(), isNull);
  });
}
