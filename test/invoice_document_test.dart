// Checks the invoice preview at two phone widths with larger accessibility text.
// Tests follow setup → action → expected result. expect(...) checks the result.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lancebox/features/invoices/invoice.dart';
import 'package:lancebox/features/invoices/invoice_document.dart';

void main() {
  // Repeat the layout check for a narrow phone and a wider phone.
  for (final width in [320.0, 390.0]) {
    testWidgets('preview columns fit a $width phone with enlarged text', (
      tester,
    ) async {
      // Set a predictable phone size for layout and scrolling checks.
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      // Restore the test display settings afterwards so other tests remain independent.
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      // Use long text and large amounts to stress the document layout.
      final invoice = Invoice(
        id: '1',
        number: '0001',
        client: 'Mr Peter Abu',
        sender: 'Miss Olasubomi Akin',
        title: 'Website Design For Lancebox',
        currency: 'NGN',
        date: DateTime(2023, 1, 25),
        items: const [
          InvoiceItem(
            description: 'Website design and development',
            quantity: 2,
            unitPrice: 300000000,
          ),
        ],
        vat: 12,
        shipping: 50000000,
        bankNumber: '0123456789',
        bankName: 'Lance Bank',
        accountName: 'Jane Doe',
        terms: 'Payment will be made in installments',
      );
      // Build the screen inside the test environment.
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(width, 900),
              // Enlarge text to 150% to check accessibility sizing.
              textScaler: const TextScaler.linear(1.5),
            ),
            child: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: InvoiceDocument(invoice: invoice),
              ),
            ),
          ),
        ),
      );
      // Verify key document sections remain present, then check for rendering errors.
      expect(find.text('Unit Price(N)'), findsOneWidget);
      expect(find.text('Amount(N)'), findsOneWidget);
      expect(find.text('Payment Details'), findsOneWidget);
      // Fail if Flutter reported an unexpected error, including a layout overflow.
      expect(tester.takeException(), isNull);
    });
  }
}
