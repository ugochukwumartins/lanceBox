// Compares four screens with saved images to detect unintended visual changes.
// Tests follow setup → action → expected result. expect(...) checks the result.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lancebox/app/app.dart';
import 'package:lancebox/app/store.dart';
import 'package:lancebox/features/invoices/editor.dart';
import 'package:lancebox/features/invoices/preview.dart';
import 'package:lancebox/features/invoices/invoice.dart';

void main() {
  // Run the same visual comparison for each supported baseline screen.
  for (final screen in ['signup', 'dashboard', 'editor', 'preview']) {
    testWidgets('$screen design stays unchanged', (tester) async {
      // Set a predictable phone size for layout and scrolling checks.
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      // Restore the test display settings afterwards so other tests remain independent.
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      // Use in-memory preferences so this test cannot change real device data.
      SharedPreferences.setMockInitialValues({'onboarded': screen != 'signup'});
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
      // Identify the exact painted area to compare with the saved image.
      const captureKey = Key('screen-capture');
      // Build the screen inside the test environment.
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const RepaintBoundary(key: captureKey, child: LanceBoxApp()),
        ),
      );
      // Finish pending frames and finite animations before checking the screen.
      await tester.pumpAndSettle();
      // Use fixed data and dates so screenshots do not change from one day to the next.
      final invoice = Invoice(
        id: 'visual',
        number: '0001',
        client: 'Peter Abu',
        sender: 'Jane Doe',
        title: 'Website Design',
        currency: 'NGN',
        date: DateTime(2026, 9, 12),
        items: const [
          InvoiceItem(
            description: 'Design work',
            quantity: 2,
            unitPrice: 300000,
          ),
        ],
        vat: 7.5,
        shipping: 50000,
        bankNumber: '0123456789',
        bankName: 'Lance Bank',
        accountName: 'Jane Doe',
        terms: 'Due on receipt',
      );
      // Open the requested invoice screen directly after the app has initialized.
      if (screen == 'editor' || screen == 'preview') {
        final navigator = tester.state<NavigatorState>(find.byType(Navigator));
        navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => screen == 'editor'
                ? InvoiceEditor(invoice: invoice)
                : InvoicePreview(invoice: invoice),
          ),
        );
        // Finish pending frames and finite animations before checking the screen.
        await tester.pumpAndSettle();
      }
      // Compare pixels with the approved baseline; do not update it to hide a regression.
      await expectLater(
        find.byKey(captureKey),
        matchesGoldenFile('goldens/$screen.png'),
      );
    });
  }
}
