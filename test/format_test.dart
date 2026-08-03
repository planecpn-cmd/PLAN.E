import 'package:flutter_test/flutter_test.dart';
import 'package:plan_e/core/format.dart';

void main() {
  group('Nepali Formatters - formatNpr', () {
    test('formats small amounts in Rs.', () {
      expect(AppFormatters.formatNpr(50000), 'Rs. 500');
    });

    test('formats lakhs (1,00,000)', () {
      expect(AppFormatters.formatNpr(10000000), 'Rs. 1,00,000');
    });

    test('formats 12,50,000 NPR (125,000,000 paisa)', () {
      expect(AppFormatters.formatNpr(125000000), 'Rs. 12,50,000');
    });

    test('formats crores (1,00,00,000 NPR)', () {
      expect(AppFormatters.formatNpr(1000000000), 'Rs. 1,00,00,000');
    });
  });

  group('Asia/Kathmandu Timezone', () {
    test('converts UTC to Asia/Kathmandu (+05:45 offset)', () {
      final DateTime utcDate = DateTime.utc(2026, 8, 3, 12, 0); // 12:00 UTC
      final DateTime ktmDate = AppFormatters.toKathmandu(utcDate);
      expect(ktmDate.hour, 17);
      expect(ktmDate.minute, 45);
    });

    test('converts across UTC midnight boundary', () {
      final DateTime utcDate = DateTime.utc(2026, 8, 3, 22, 0); // 22:00 UTC
      final DateTime ktmDate = AppFormatters.toKathmandu(utcDate);
      expect(ktmDate.day, 4);
      expect(ktmDate.hour, 3);
      expect(ktmDate.minute, 45);
    });
  });

  group('Nepali Phone Validation', () {
    test('accepts valid 10-digit Nepali mobile numbers starting with 98, 97, 96', () {
      expect(AppFormatters.isNepaliPhone('9841234567'), isTrue);
      expect(AppFormatters.isNepaliPhone('+9779841234567'), isTrue);
      expect(AppFormatters.isNepaliPhone('+9779712345678'), isTrue);
    });

    test('rejects invalid phone numbers', () {
      expect(AppFormatters.isNepaliPhone('12345'), isFalse);
      expect(AppFormatters.isNepaliPhone('984123456'), isFalse); // 9 digits
      expect(AppFormatters.isNepaliPhone('8841234567'), isFalse); // invalid prefix
    });
  });

  group('Duration Formatters', () {
    test('formats hours under 24', () {
      expect(AppFormatters.formatDuration(5), '5 hours');
      expect(AppFormatters.formatDuration(1), '1 hour');
    });

    test('formats days for 24 hours or more', () {
      expect(AppFormatters.formatDuration(24), '1 day');
      expect(AppFormatters.formatDuration(72), '3 days');
      expect(AppFormatters.formatDuration(30), '1 day 6 hrs');
    });
  });
}
