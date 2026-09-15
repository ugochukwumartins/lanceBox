// Small test actions used by long forms. Each helper performs one visible action.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lancebox/shared/widgets/field.dart';

// A Finder describes which widget the test wants to locate.
Future<void> scrollTo(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(
    target,
    180,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(target);
}

Future<void> tapButton(WidgetTester tester, String label) async {
  final button = find.text(label);
  await scrollTo(tester, button);
  await tester.tap(button);
  // Wait for navigation and other finite animations to finish.
  await tester.pumpAndSettle();
}

Future<void> enterField(WidgetTester tester, String label, String value) async {
  // Find our labeled Field, then its actual Flutter text input.
  final field = find.byWidgetPredicate(
    (widget) => widget is Field && widget.label == label,
  );
  await scrollTo(tester, field);
  final input = find.descendant(
    of: field,
    matching: find.byType(TextFormField),
  );
  await tester.ensureVisible(input);
  await tester.enterText(input, value);
  await tester.pump();
}

// VAT and Shipping use keyed inputs rather than the shared Field widget.
Future<void> enterCharge(
  WidgetTester tester,
  String label,
  String value,
) async {
  final input = find.byKey(ValueKey('summary-$label'));
  await scrollTo(tester, input);
  await tester.enterText(input, value);
  await tester.pump();
}
