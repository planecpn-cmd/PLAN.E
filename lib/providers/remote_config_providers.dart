import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_version.dart';
import '../core/current_platform.dart';
import '../core/device_identity.dart';
import '../core/feature_flag_evaluation.dart';
import '../core/remote_config_service.dart';
import '../models/remote_config.dart';
import 'app_providers.dart';

/// Overridden in main() with the snapshot loaded from disk before `runApp` —
/// see ProviderScope(overrides: [...]) in main.dart. Defaults to empty (not
/// a throw) when unoverridden, e.g. in widget tests that pump PlanEApp
/// directly — same fail-open rule as everywhere else in this system: no
/// cached config behaves exactly like no remote config at all.
final cachedRemoteConfigSnapshotProvider = Provider<RemoteConfigSnapshot>((
  ref,
) {
  return RemoteConfigSnapshot.empty();
});

class RemoteConfigNotifier extends StateNotifier<RemoteConfigSnapshot> {
  final SupabaseClient _client;

  RemoteConfigNotifier(this._client, RemoteConfigSnapshot initial)
      : super(initial);

  /// Fetches fresh config from Supabase. Fire-and-forget from call sites
  /// (boot, foreground resume) — on failure this silently keeps whatever
  /// state is already loaded (cache or the last successful fetch).
  Future<void> refresh() async {
    try {
      final snapshot = await RemoteConfigService.fetchAndCache(_client);
      if (mounted) state = snapshot;
    } catch (_) {
      // Fail open — network hiccup, RLS misconfiguration, whatever. The app
      // keeps running on its last-known-good config.
    }
  }
}

final remoteConfigProvider =
    StateNotifierProvider<RemoteConfigNotifier, RemoteConfigSnapshot>((ref) {
  final initial = ref.watch(cachedRemoteConfigSnapshotProvider);
  return RemoteConfigNotifier(ref.watch(supabaseClientProvider), initial);
});

/// Bucketing identifier for rollout percentages: the signed-in user's id,
/// or a persisted per-install id for guests (nobody has a session before
/// signing in). Switches when a guest logs in — same user can land in a
/// different bucket before vs. after signing in; documented, not a bug.
final rolloutIdentifierProvider = Provider<String>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.currentUser?.id ?? DeviceIdentity.id;
});

/// Returns null when the flag doesn't exist remotely — call sites decide
/// their own fallback with `?? defaultValue`, same pattern as
/// `profileAsync.value?.points ?? 0` elsewhere in this app. When the flag
/// *does* exist, the return value is the full evaluation — kill switch,
/// platform, version bounds, and rollout percentage all applied — not just
/// the raw `enabled` column.
final featureFlagProvider = Provider.family<bool?, String>((ref, key) {
  final flag = ref.watch(remoteConfigProvider).flags[key];
  if (flag == null) return null;

  return evaluateFeatureFlag(
    flag,
    identifier: ref.watch(rolloutIdentifierProvider),
    platform: currentPlatformKey,
    appVersion: AppVersionInfo.version,
  );
});

final remoteContentProvider = Provider.family<dynamic, String>((ref, slot) {
  return ref.watch(remoteConfigProvider).content[slot];
});

final appConfigProvider = Provider.family<dynamic, String>((ref, key) {
  return ref.watch(remoteConfigProvider).config[key];
});

final appVersionGateProvider = Provider.family<AppVersionGate?, String>((
  ref,
  platform,
) {
  return ref.watch(remoteConfigProvider).versions[platform];
});
