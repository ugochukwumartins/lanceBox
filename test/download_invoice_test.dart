// Verify successful downloads enter history; cancelled downloads do not.
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
// The file_picker dependency exposes this platform interface for test doubles.
// ignore: depend_on_referenced_packages
import 'package:file_picker_platform_interface/file_picker_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lancebox/app/store.dart';
import 'package:lancebox/features/invoices/editor.dart';
import 'package:lancebox/features/invoices/dashboard.dart';
import 'helpers/sample_invoice.dart';

class TestFilePicker extends FilePickerPlatform {
  // null simulates Cancel; a file URI simulates a successful save.
  Uri? result;
  @override
  Future<Uri?> saveFile({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
    String? dialogTitle,
    String? initialDirectory,
    Function(FilePickerStatus)? onFileSaving,
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async => result;
}

void main() {
  testWidgets('download saves history once and cancellation leaves it empty', (
    tester,
  ) async {
    // SETUP: Isolate app storage and replace the real file-save dialog.
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [preferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    final originalPicker = FilePickerPlatform.instance;
    final picker = TestFilePicker();
    FilePickerPlatform.instance = picker;
    addTearDown(() => FilePickerPlatform.instance = originalPicker);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Dashboard()),
      ),
    );
    Future<void> openPreview() async {
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => InvoiceEditor(invoice: sampleInvoice()),
        ),
      );
      await tester.pumpAndSettle();
      for (final label in ['Next', 'Preview Invoice']) {
        await tester.scrollUntilVisible(
          find.text(label),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
      }
    }

    await openPreview();
    Future<void> download() async {
      await tester.scrollUntilVisible(
        find.text('Download Pdf'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Download Pdf'));
      // PDF font loading performs real asynchronous asset work.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 1)),
      );
      // The download spinner stays active behind the open success modal.
      await tester.pump(const Duration(milliseconds: 300));
    }

    // CHECK: Cancelling the save dialog must leave history empty.
    await download();
    expect(container.read(appStoreProvider).invoices, isEmpty);
    picker.result = Uri.file('/tmp/invoice.pdf');
    // ACT + CHECK: Download twice; each time return home with only one record.
    for (var attempt = 0; attempt < 2; attempt++) {
      await download();
      expect(find.text('Download Successful'), findsOneWidget);
      expect(container.read(appStoreProvider).invoices.length, 1);
      expect(prefs.getString('invoices'), contains('Design'));
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.byType(Dashboard), findsOneWidget);
      expect(find.byType(InvoiceEditor), findsNothing);
      expect(find.text('Design'), findsOneWidget);
      if (attempt == 0) await openPreview();
    }
  });
}
