import 'package:flutter_test/flutter_test.dart';
import 'package:plan_e/core/feature_flag_evaluation.dart';
import 'package:plan_e/models/remote_config.dart';

RemoteFeatureFlag _flag({
  String key = 'test_flag',
  bool enabled = true,
  int rolloutPercent = 100,
  List<String> platforms = const [],
  String? minAppVersion,
  String? maxAppVersion,
}) {
  return RemoteFeatureFlag(
    key: key,
    enabled: enabled,
    rolloutPercent: rolloutPercent,
    platforms: platforms,
    minAppVersion: minAppVersion,
    maxAppVersion: maxAppVersion,
  );
}

bool _eval(
  RemoteFeatureFlag flag, {
  String identifier = 'user-1',
  String platform = 'android',
  String appVersion = '1.0.0',
}) {
  return evaluateFeatureFlag(
    flag,
    identifier: identifier,
    platform: platform,
    appVersion: appVersion,
  );
}

void main() {
  group('stableBucket', () {
    test('deterministic — same inputs always give the same bucket', () {
      final a = stableBucket('user-42', 'my_flag');
      final b = stableBucket('user-42', 'my_flag');
      expect(a, b);
    });

    test('always within 0..99', () {
      for (final id in ['a', 'user-1', 'guest-abc123', '']) {
        final bucket = stableBucket(id, 'flag');
        expect(bucket, inInclusiveRange(0, 99));
      }
    });

    test('different flag keys are not correlated for the same identifier', () {
      // Not a statistical guarantee, just confirms the flag key is actually
      // mixed into the hash rather than ignored.
      final a = stableBucket('user-1', 'flag_a');
      final b = stableBucket('user-1', 'flag_b');
      expect(a == b, isFalse);
    });

    test('spreads across many identifiers (not everyone in the same bucket)', () {
      final buckets = List.generate(200, (i) => stableBucket('user-$i', 'flag'))
          .toSet();
      expect(buckets.length, greaterThan(20));
    });
  });

  group('isInRollout', () {
    test('0% is always excluded', () {
      for (var i = 0; i < 20; i++) {
        expect(isInRollout('user-$i', 'flag', 0), isFalse);
      }
    });

    test('100% is always included', () {
      for (var i = 0; i < 20; i++) {
        expect(isInRollout('user-$i', 'flag', 100), isTrue);
      }
    });

    test('same identifier+flag always lands on the same side, repeatedly', () {
      final first = isInRollout('stable-user', 'flag', 50);
      for (var i = 0; i < 10; i++) {
        expect(isInRollout('stable-user', 'flag', 50), first);
      }
    });
  });

  group('evaluateFeatureFlag', () {
    test('kill switch wins over everything else', () {
      final flag = _flag(
        enabled: false,
        rolloutPercent: 100,
        platforms: const ['android'],
      );
      expect(_eval(flag, platform: 'android'), isFalse);
    });

    test('no platforms configured → unrestricted', () {
      final flag = _flag(platforms: const []);
      expect(_eval(flag, platform: 'android'), isTrue);
      expect(_eval(flag, platform: 'ios'), isTrue);
    });

    test('platform not in the list → excluded', () {
      final flag = _flag(platforms: const ['ios']);
      expect(_eval(flag, platform: 'android'), isFalse);
    });

    test('platform in the list → passes that check', () {
      final flag = _flag(platforms: const ['ios', 'android']);
      expect(_eval(flag, platform: 'android'), isTrue);
    });

    test('below min_app_version → excluded', () {
      final flag = _flag(minAppVersion: '2.0.0');
      expect(_eval(flag, appVersion: '1.5.0'), isFalse);
    });

    test('at or above min_app_version → passes', () {
      final flag = _flag(minAppVersion: '2.0.0');
      expect(_eval(flag, appVersion: '2.0.0'), isTrue);
      expect(_eval(flag, appVersion: '2.1.0'), isTrue);
    });

    test('above max_app_version → excluded', () {
      final flag = _flag(maxAppVersion: '1.5.0');
      expect(_eval(flag, appVersion: '1.6.0'), isFalse);
    });

    test('at or below max_app_version → passes', () {
      final flag = _flag(maxAppVersion: '1.5.0');
      expect(_eval(flag, appVersion: '1.5.0'), isTrue);
      expect(_eval(flag, appVersion: '1.0.0'), isTrue);
    });

    test('null/unset version bounds impose no restriction', () {
      final flag = _flag();
      expect(_eval(flag, appVersion: '0.0.1'), isTrue);
      expect(_eval(flag, appVersion: '99.0.0'), isTrue);
    });

    test('rollout 0% excludes even an otherwise fully-eligible user', () {
      final flag = _flag(rolloutPercent: 0);
      expect(_eval(flag), isFalse);
    });

    test('rollout 100% includes regardless of identifier', () {
      final flag = _flag(rolloutPercent: 100);
      expect(_eval(flag, identifier: 'anyone'), isTrue);
    });

    test('platform mismatch short-circuits before rollout is even consulted', () {
      // rolloutPercent: 100 would include everyone — platform must still win.
      final flag = _flag(platforms: const ['ios'], rolloutPercent: 100);
      expect(_eval(flag, platform: 'android'), isFalse);
    });
  });
}
