// Confirms the actual Riverpod wiring — not just the pure evaluateFeatureFlag
// function tested in feature_flag_evaluation_test.dart. Exercises
// featureFlagProvider end to end: remoteConfigProvider -> flag lookup ->
// rolloutIdentifierProvider -> evaluateFeatureFlag.
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
        supabaseClientProvider.overrideWithValue(
          SupabaseClient('https://example.invalid', 'test-anon-key'),
        ),
      ],
    );
  }

  test('rollout 0% turns an otherwise-enabled flag off through the provider', () {
    final container = containerWith(
      const RemoteConfigSnapshot(
        flags: {
          'promo': RemoteFeatureFlag(key: 'promo', enabled: true, rolloutPercent: 0),
        },
      ),
    );
    addTearDown(container.dispose);

    expect(container.read(featureFlagProvider('promo')), isFalse);
  });

  test('rollout 100% stays on through the provider', () {
    final container = containerWith(
      const RemoteConfigSnapshot(
        flags: {
          'promo': RemoteFeatureFlag(key: 'promo', enabled: true, rolloutPercent: 100),
        },
      ),
    );
    addTearDown(container.dispose);

    expect(container.read(featureFlagProvider('promo')), isTrue);
  });

  test('kill switch beats a 100% rollout through the provider', () {
    final container = containerWith(
      const RemoteConfigSnapshot(
        flags: {
          'promo': RemoteFeatureFlag(key: 'promo', enabled: false, rolloutPercent: 100),
        },
      ),
    );
    addTearDown(container.dispose);

    expect(container.read(featureFlagProvider('promo')), isFalse);
  });
}
