import 'package:flutter_test/flutter_test.dart';
import 'package:plan_e/models/remote_config.dart';

void main() {
  group('RemoteFeatureFlag', () {
    test('defaults enabled to false when missing', () {
      final flag = RemoteFeatureFlag.fromJson({'key': 'x'});
      expect(flag.enabled, isFalse);
    });
  });

  group('RemoteConfigSnapshot', () {
    test('round-trips through JSON (the cache read/write path)', () {
      final original = RemoteConfigSnapshot(
        flags: const {
          'ai_itinerary': RemoteFeatureFlag(key: 'ai_itinerary', enabled: true),
        },
        content: const {
          'promo_banner': {'headline': 'Autumn treks now open'},
        },
        config: const {'support_phone': '+97714000000'},
        versions: const {
          'android': AppVersionGate(
            platform: 'android',
            minSupportedVersion: '1.0.0',
            latestVersion: '1.2.0',
            maintenanceMode: false,
          ),
        },
        fetchedAt: DateTime.utc(2026, 8, 10, 5, 47, 56),
      );

      final roundTripped = RemoteConfigSnapshot.fromJson(original.toJson());

      expect(roundTripped.flags['ai_itinerary']?.enabled, isTrue);
      expect(
        roundTripped.content['promo_banner']['headline'],
        'Autumn treks now open',
      );
      expect(roundTripped.config['support_phone'], '+97714000000');
      expect(
        roundTripped.versions['android']?.minSupportedVersion,
        '1.0.0',
      );
      expect(roundTripped.fetchedAt, original.fetchedAt);
    });

    test('empty snapshot fails open — every lookup returns null', () {
      final snapshot = RemoteConfigSnapshot.empty();
      expect(snapshot.flags['anything'], isNull);
      expect(snapshot.content['anything'], isNull);
      expect(snapshot.versions['android'], isNull);
    });

    test('malformed cache JSON does not throw when read via fromJson', () {
      // What RemoteConfigService.loadCached() feeds this after jsonDecode —
      // a schema-changed or truncated cache should degrade to empty, not crash.
      expect(
        () => RemoteConfigSnapshot.fromJson(const {}),
        returnsNormally,
      );
      final snapshot = RemoteConfigSnapshot.fromJson(const {});
      expect(snapshot.flags, isEmpty);
    });
  });
}
