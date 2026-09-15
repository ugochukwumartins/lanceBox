// Checks invoice calculations, data storage, editing and PDF generation without navigating screens.
// Tests follow setup → action → expected result. expect(...) checks the result.

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lancebox/app/store.dart';
import 'package:lancebox/features/invoices/invoice.dart';
import 'package:lancebox/features/invoices/export.dart';
import 'helpers/sample_invoice.dart';

void main() {
  test(
    'unit prices accept integers and decimals through JSON and formatting',
    () {
      for (final price in <num>[10000, 10000.5]) {
        final item = InvoiceItem(
          description: 'Service',
          quantity: 2,
          unitPrice: price,
        );
        final restored = InvoiceItem.fromJson(
          jsonDecode(jsonEncode(item.toJson())) as Map<String, dynamic>,
        );
        expect(restored.unitPrice, price);
        expect(restored.total, (price * 2).round());
        expect(money(restored.unitPrice), money(price));
      }
      expect(money(10000.0), 'NGN 100.00');
    },
  );
  // Initialize Flutter services so tests can load assets and use mocked plugins.
  TestWidgetsFlutterBinding.ensureInitialized();
  test('fractional quantities, VAT and shipping use rounded minor units', () {
    final invoice = sampleInvoice();
    // Check line rounding, subtotal, VAT, final total and formatted display separately.
    expect(invoice.items.last.total, 15002);
    expect(invoice.subtotal, 615002);
    expect(invoice.tax, 46125);
    expect(invoice.total, 711127);
    expect(money(invoice.total), 'NGN 7,111.27');
  });
  test('reject invalid numerical inputs', () {
    for (final value in ['NaN', 'Infinity', '-1', 'abc', '']) {
      expect(nonNegativeNumber(value), isNotNull);
    }
    expect(positiveNumber('0'), isNotNull);
    expect(nonNegativeNumber('0'), isNull);
  });
  test('invoice round trip preserves account leading zero and totals', () {
    // Serialize and restore the invoice exactly as local storage does.
    final invoice = Invoice.fromJson(
      jsonDecode(jsonEncode(sampleInvoice().toJson())) as Map<String, dynamic>,
    );
    expect(invoice.bankNumber, '0123456789');
    expect(invoice.total, sampleInvoice().total);
  });
  test('saved invoices survive reload and edits do not duplicate', () async {
    // Use in-memory preferences so this test cannot change real device data.
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    // Create isolated Riverpod state with the test’s storage dependency.
    final container = ProviderContainer(
      overrides: [preferencesProvider.overrideWithValue(prefs)],
    );
    // Release this test’s Riverpod state, even if an assertion fails.
    addTearDown(container.dispose);
    final store = container.read(appStoreProvider.notifier);
    await store.save(sampleInvoice());
    // Save the same ID again: it must update the existing record instead of duplicating it.
    await store.save(sampleInvoice(title: 'Updated'));
    // Create a fresh store using the same preferences to simulate reopening the app.
    final restored = ProviderContainer(
      overrides: [preferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(restored.dispose);
    final reopened = restored.read(appStoreProvider);
    expect(reopened.invoices.length, 1);
    expect(reopened.invoices.single.title, 'Updated');
  });
  test('corrupt saved data is not silently overwritten', () async {
    // Use in-memory preferences so this test cannot change real device data.
    SharedPreferences.setMockInitialValues({'invoices': 'broken'});
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
    final store = container.read(appStoreProvider.notifier);
    expect(container.read(appStoreProvider).loadError, isNotNull);
    // A save must be refused when existing invoice data could not be read safely.
    await expectLater(store.save(sampleInvoice()), throwsStateError);
  });
  test('export produces a PDF document', () async {
    final bytes = await invoicePdf(sampleInvoice(), null);
    // Check the PDF file signature and a basic size threshold, not its visual appearance.
    expect(ascii.decode(bytes.take(5).toList()), '%PDF-');
    expect(bytes.length, greaterThan(1000));
  });
}
