// Checks Riverpod notifications, profile persistence and protection against accidental data changes.
// Tests follow setup → action → expected result. expect(...) checks the result.

import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lancebox/app/store.dart';

void main() {
  // Initialize Flutter services so tests can load assets and use mocked plugins.
  TestWidgetsFlutterBinding.ensureInitialized();
  test('profile and logout publish immutable state and persist completion', () async {
    // Use in-memory preferences so this test cannot change real device data.
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    // Create isolated Riverpod state with the test’s storage dependency.
    final container = ProviderContainer(
      overrides: [preferencesProvider.overrideWithValue(preferences)],
    );
    // Release this test’s Riverpod state, even if an assertion fails.
    addTearDown(container.dispose);
    // Record completion changes received by subscribers.
    final completionChanges = <bool>[];
    container.listen(
      appStoreProvider.select((state) => state.onboarded),
      (_, next) => completionChanges.add(next),
    );
    // Keep the old snapshot to prove later actions do not mutate it.
    final stateBeforeSignup = container.read(appStoreProvider);
    final logo = Uint8List.fromList([1, 2, 3]);
    await container
        .read(appStoreProvider.notifier)
        .completeProfile('Freelancer', logo);
    final stateAfterSignup = container.read(appStoreProvider);
    // Change the original input bytes; the saved snapshot must retain its own copy.
    logo[0] = 9;
    // Verify completion, immutable logo bytes and the persisted completion flag.
    expect(stateBeforeSignup.onboarded, isFalse);
    expect(stateAfterSignup.onboarded, isTrue);
    expect(stateAfterSignup.logo!.first, 1);
    expect(() => stateAfterSignup.logo![0] = 8, throwsUnsupportedError);
    expect(preferences.getBool('onboarded'), isTrue);
    // Log out and check that subscribers see false while the previous snapshot stays true.
    await container.read(appStoreProvider.notifier).logout();
    expect(container.read(appStoreProvider).onboarded, isFalse);
    expect(stateAfterSignup.onboarded, isTrue);
    expect(completionChanges, [true, false]);
    expect(preferences.getBool('onboarded'), isFalse);
  });
}
