import 'package:flutter_test/flutter_test.dart';
import 'package:plan_e/core/app_version.dart';
import 'package:plan_e/models/remote_config.dart';

AppVersionGate _gate({
  String min = '1.0.0',
  String latest = '1.0.0',
  bool maintenance = false,
}) {
  return AppVersionGate(
    platform: 'android',
    minSupportedVersion: min,
    latestVersion: latest,
    maintenanceMode: maintenance,
  );
}

void main() {
  group('compareVersionStrings', () {
    test('equal versions compare as 0', () {
      expect(compareVersionStrings('1.0.0', '1.0.0'), 0);
    });

    test('patch difference', () {
      expect(compareVersionStrings('1.0.0', '1.0.1'), lessThan(0));
    });

    test('minor beats patch', () {
      expect(compareVersionStrings('1.2.0', '1.1.9'), greaterThan(0));
    });

    test('major beats everything', () {
      expect(compareVersionStrings('2.0.0', '1.9.9'), greaterThan(0));
    });

    test('missing segments treated as 0', () {
      expect(compareVersionStrings('1.0', '1.0.0'), 0);
      expect(compareVersionStrings('1.0', '1.0.1'), lessThan(0));
    });
  });

  group('decideVersionGateAction', () {
    test('no gate configured for this platform → none', () {
      expect(decideVersionGateAction(null, '1.0.0'), VersionGateAction.none);
    });

    test('maintenance mode wins over everything else', () {
      final gate = _gate(min: '5.0.0', latest: '5.0.0', maintenance: true);
      expect(
        decideVersionGateAction(gate, '1.0.0'),
        VersionGateAction.maintenance,
      );
    });

    test('below min_supported_version → forceUpdate', () {
      final gate = _gate(min: '2.0.0', latest: '2.1.0');
      expect(
        decideVersionGateAction(gate, '1.9.0'),
        VersionGateAction.forceUpdate,
      );
    });

    test('at min but below latest → softUpdate', () {
      final gate = _gate(min: '1.0.0', latest: '1.2.0');
      expect(
        decideVersionGateAction(gate, '1.0.0'),
        VersionGateAction.softUpdate,
      );
    });

    test('at latest → none', () {
      final gate = _gate(min: '1.0.0', latest: '1.2.0');
      expect(decideVersionGateAction(gate, '1.2.0'), VersionGateAction.none);
    });

    test('ahead of latest (e.g. a Shorebird patch bumped it) → none', () {
      final gate = _gate(min: '1.0.0', latest: '1.2.0');
      expect(decideVersionGateAction(gate, '1.3.0'), VersionGateAction.none);
    });
  });
}
