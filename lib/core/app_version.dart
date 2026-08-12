import 'package:package_info_plus/package_info_plus.dart';

import '../models/remote_config.dart';

/// Real build identity, read once at boot from the platform bundle. Replaces
/// hand-typed version strings, which drift from pubspec.yaml the moment
/// either one changes without the other — the whole point of a remote
/// force-update gate is comparing against a version that's actually true.
class AppVersionInfo {
  static PackageInfo? _info;

  static Future<void> initialize() async {
    if (_info != null) return;
    _info = await PackageInfo.fromPlatform();
  }

  static String get version => _info?.version ?? '0.0.0';
  static String get buildNumber => _info?.buildNumber ?? '0';
  static String get packageName => _info?.packageName ?? '';
  static String get displayVersion => 'Version $version (Build $buildNumber)';

  /// True if the running app's version is older than [other].
  static bool isOlderThan(String other) => compareVersionStrings(version, other) < 0;
}

/// Compares two dotted version strings ("1.2.3") segment by segment,
/// numerically. Not a full semver parser (no pre-release/build metadata) —
/// deliberately minimal for the plain major.minor.patch strings this app and
/// `app_versions`/`feature_flags` (min_app_version/max_app_version) use.
/// Missing or non-numeric segments compare as 0.
int compareVersionStrings(String a, String b) {
  final partsA = a.split('.').map((s) => int.tryParse(s) ?? 0).toList();
  final partsB = b.split('.').map((s) => int.tryParse(s) ?? 0).toList();
  final length = partsA.length > partsB.length ? partsA.length : partsB.length;
  for (var i = 0; i < length; i++) {
    final va = i < partsA.length ? partsA[i] : 0;
    final vb = i < partsB.length ? partsB[i] : 0;
    if (va != vb) return va.compareTo(vb);
  }
  return 0;
}

/// What VersionGate should do, in priority order: maintenance beats a
/// force-update, which beats a soft nudge. Pulled out of the widget so the
/// branching is testable without pumping a widget tree.
enum VersionGateAction { none, maintenance, forceUpdate, softUpdate }

VersionGateAction decideVersionGateAction(
  AppVersionGate? gate,
  String currentVersion,
) {
  if (gate == null) return VersionGateAction.none;
  if (gate.maintenanceMode) return VersionGateAction.maintenance;
  if (compareVersionStrings(currentVersion, gate.minSupportedVersion) < 0) {
    return VersionGateAction.forceUpdate;
  }
  if (compareVersionStrings(currentVersion, gate.latestVersion) < 0) {
    return VersionGateAction.softUpdate;
  }
  return VersionGateAction.none;
}
