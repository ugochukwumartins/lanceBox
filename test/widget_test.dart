// Exercises sign-up errors, completion ticks, loading stages and skipping profile setup.
// Tests follow setup → action → expected result. expect(...) checks the result.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lancebox/app/app.dart';
import 'package:lancebox/app/store.dart';
import 'package:lancebox/features/invoices/dashboard.dart';
import 'package:lancebox/shared/ui.dart';

void main() {
  testWidgets('sign-up validates input and skip opens the empty dashboard', (
    tester,
  ) async {
    // Set a predictable phone size for layout and scrolling checks.
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    // Restore the test display settings afterwards so other tests remain independent.
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    // Use in-memory preferences so this test cannot change real device data.
    SharedPreferences.setMockInitialValues({});
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
    // Scroll until the target control is built and visible before interacting with it.
    await tester.scrollUntilVisible(
      find.text('Sign Up'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();
    // Submitting the empty form must show the email validation error.
    expect(find.text('Enter a valid email address'), findsOneWidget);
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'test@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password123!');
    await tester.pump();
    expect(find.byIcon(Icons.check), findsOneWidget);
    // Use a different confirmation password to exercise the mismatch error.
    await tester.enterText(find.byType(TextFormField).at(2), 'different!');
    await tester.ensureVisible(find.text('Sign Up'));
    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();
    expect(find.text('Passwords do not match'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(2), 'password123!');
    await tester.pump();
    expect(find.byIcon(Icons.check), findsNWidgets(2));
    // Leave the active field so a valid input can display its completion tick.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    expect(find.byIcon(Icons.check), findsNWidgets(3));
    // Changing the password must invalidate the previously matching confirmation.
    await tester.enterText(find.byType(TextFormField).at(1), 'password456!');
    await tester.pump();
    expect(find.byIcon(Icons.check), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(1), 'password123!');
    await tester.pump();
    expect(find.byIcon(Icons.check), findsNWidgets(2));
    // Leave the active field so a valid input can display its completion tick.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    expect(find.byIcon(Icons.check), findsNWidgets(3));
    await tester.ensureVisible(find.text('Sign Up'));
    await tester.tap(find.text('Sign Up'));
    await tester.pump();
    expect(find.text('Signing Up'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    // Advance the test clock without waiting in real time; the button should still spin.
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Signing Up'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(BrandLoading), findsOneWidget);
    expect(find.text('Signing Up'), findsNothing);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.byType(BrandLoading), findsNothing);
    expect(find.text('Signing Up'), findsNothing);
    // Scroll until the target control is built and visible before interacting with it.
    await tester.scrollUntilVisible(
      find.text('Skip for now'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    // Skip optional setup and check both navigation and shared completion state.
    await tester.tap(find.text('Skip for now'));
    await tester.pumpAndSettle();
    expect(find.byType(Dashboard), findsOneWidget);
    expect(container.read(appStoreProvider).onboarded, isTrue);
    // Fail if Flutter reported an unexpected error, including a layout overflow.
    expect(tester.takeException(), isNull);
  });
}
