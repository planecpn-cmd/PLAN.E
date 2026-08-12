import '../models/remote_config.dart';
import 'app_version.dart';

/// FNV-1a, 32-bit. Not Dart's built-in `String.hashCode` — that's explicitly
/// documented as unstable across isolates/runs, which would silently flip
/// users in and out of a rollout bucket on every app restart. This is a
/// few lines of well-known, purely arithmetic hashing instead of adding a
/// dependency (`crypto` is only a transitive package here, not a direct
/// one) for something this small.
int _fnv1a32(String input) {
  const int fnvPrime = 0x01000193;
  int hash = 0x811c9dc5;
  for (final codeUnit in input.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * fnvPrime) & 0xFFFFFFFF;
  }
  return hash;
}

/// Deterministic 0–99 bucket for (identifier, flagKey) — same two inputs
/// always produce the same bucket, so a given user/device always lands on
/// the same side of a rollout percentage for a given flag, but a different
/// bucket for a *different* flag (no correlation between unrelated rollouts).
int stableBucket(String identifier, String flagKey) {
  return _fnv1a32('$identifier:$flagKey') % 100;
}

/// Whether (identifier, flagKey) falls inside a [rolloutPercent]% rollout.
bool isInRollout(String identifier, String flagKey, int rolloutPercent) {
  if (rolloutPercent >= 100) return true;
  if (rolloutPercent <= 0) return false;
  return stableBucket(identifier, flagKey) < rolloutPercent;
}

/// Full evaluation of a feature flag: kill switch, then platform, then
/// version bounds, then rollout percentage — in that order, each one able
/// to turn the flag off but none able to turn it back on. `enabled: false`
/// always wins regardless of everything else below it.
bool evaluateFeatureFlag(
  RemoteFeatureFlag flag, {
  required String identifier,
  required String platform,
  required String appVersion,
}) {
  if (!flag.enabled) return false;

  if (flag.platforms.isNotEmpty && !flag.platforms.contains(platform)) {
    return false;
  }

  final minVersion = flag.minAppVersion;
  if (minVersion != null &&
      minVersion.isNotEmpty &&
      compareVersionStrings(appVersion, minVersion) < 0) {
    return false;
  }

  final maxVersion = flag.maxAppVersion;
  if (maxVersion != null &&
      maxVersion.isNotEmpty &&
      compareVersionStrings(appVersion, maxVersion) > 0) {
    return false;
  }

  return isInRollout(identifier, flag.key, flag.rolloutPercent);
}
