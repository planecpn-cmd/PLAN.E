// Locks down the exact fallback policy booking_screen.dart uses for the
// eSewa kill switch: `ref.read(featureFlagProvider('payment_esewa')) ?? true`.
// The `?? true` matters — a flag row that doesn't exist yet (nothing has
// configured it in Supabase) must mean "eSewa stays available, same as
// before this system existed", not "eSewa is off". Getting this backwards
// (`?? false`) would silently kill a working payment gateway for every user
// the moment this feature shipped, with no flag ever having been touched.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plan_e/models/remote_config.dart';
import 'package:plan_e/providers/app_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  ProviderContainer containerWith(RemoteConfigSnapshot snapshot) {
    return ProviderContainer(
      overrides: [
        cachedRemoteConfigSnapshotProvider.overrideWithValue(snapshot),
        // remoteConfigProvider's constructor reads this even though refresh()
        // is never called in these tests — just needs a non-throwing value.
        supabaseClientProvider.overrideWithValue(
          SupabaseClient('https://example.invalid', 'test-anon-key'),
        ),
      ],
    );
  }

  test('flag never configured → fails open to enabled', () {
    final container = containerWith(RemoteConfigSnapshot.empty());
    addTearDown(container.dispose);

    final enabled =
        container.read(featureFlagProvider('payment_esewa')) ?? true;
    expect(enabled, isTrue);
  });

  test('flag explicitly disabled → stays disabled', () {
    final container = containerWith(
      const RemoteConfigSnapshot(
        flags: {
          'payment_esewa': RemoteFeatureFlag(key: 'payment_esewa', enabled: false),
        },
      ),
    );
    addTearDown(container.dispose);

    final enabled =
        container.read(featureFlagProvider('payment_esewa')) ?? true;
    expect(enabled, isFalse);
  });

  test('flag explicitly enabled → stays enabled', () {
    final container = containerWith(
      const RemoteConfigSnapshot(
        flags: {
          'payment_esewa': RemoteFeatureFlag(key: 'payment_esewa', enabled: true),
        },
      ),
    );
    addTearDown(container.dispose);

    final enabled =
        container.read(featureFlagProvider('payment_esewa')) ?? true;
    expect(enabled, isTrue);
  });
}
