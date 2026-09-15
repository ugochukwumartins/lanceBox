# Reading the tests

Start with `delete_item_test.dart`, then read `invoice_flow_test.dart`.

Each test prepares an example, performs an action and checks the result:

```dart
await enterField(tester, 'Quantity', '2');
await tapButton(tester, 'Next');
expect(find.text('Bank Details'), findsOneWidget);
```

This means: enter a quantity, tap Next, then check that the bank-details heading appears.

- `test` checks calculations or data without displaying a screen.
- `testWidgets` builds Flutter widgets and simulates user actions.
- `find` locates a control; it does not tap it.
- `expect` compares the actual result with the expected result.
- `isNull` means there is no value. For a button callback, this means disabled.
- `pump` refreshes the test screen. `pumpAndSettle` waits for finite animations to finish; avoid it while an endless spinner remains visible.
- Mock preferences keep test data separate from real device storage.
- `addTearDown` releases resources and restores settings after a test.

`helpers/form_actions.dart` contains short scrolling and typing helpers. They perform visible actions and leave assertions in each test. `helpers/sample_invoice.dart` supplies repeatable invoice data. The fake picker in the download test simulates cancellation or successful file saving without opening a real device dialog.

Run everything with `flutter test`, or one file with `flutter test test/invoice_flow_test.dart`. Golden tests compare screens with saved images; do not regenerate them unless a design change is intentional.
