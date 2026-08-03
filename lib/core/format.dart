import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

class AppFormatters {
  static bool _tzInitialized = false;

  static void ensureInitialized() {
    if (!_tzInitialized) {
      tz_data.initializeTimeZones();
      _tzInitialized = true;
    }
  }

  /// Format integer paisa to NPR currency string with Nepali lakh grouping.
  /// Example: 125000000 paisa (1,250,000 Rs) -> "Rs. 12,50,000"
  static String formatNpr(int paisa) {
    final int rupees = paisa ~/ 100;
    final String numStr = rupees.abs().toString();

    if (numStr.length <= 3) {
      final String prefix = rupees < 0 ? '-Rs. ' : 'Rs. ';
      return '$prefix$numStr';
    }

    final String lastThree = numStr.substring(numStr.length - 3);
    final String remaining = numStr.substring(0, numStr.length - 3);

    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < remaining.length; i++) {
      if (i > 0 && (remaining.length - i) % 2 == 0) {
        buffer.write(',');
      }
      buffer.write(remaining[i]);
    }

    buffer.write(',');
    buffer.write(lastThree);

    final String prefix = rupees < 0 ? '-Rs. ' : 'Rs. ';
    return '$prefix$buffer';
  }

  /// Convert DateTime to Asia/Kathmandu timezone.
  static DateTime toKathmandu(DateTime dateTime) {
    ensureInitialized();
    final tz.Location kathmanduLoc = tz.getLocation('Asia/Kathmandu');
    return tz.TZDateTime.from(dateTime.toUtc(), kathmanduLoc);
  }

  /// Format DateTime in Asia/Kathmandu timezone.
  static String formatTripDate(DateTime dateTime, {String pattern = 'd MMM yyyy, h:mm a'}) {
    final DateTime ktmDateTime = toKathmandu(dateTime);
    return DateFormat(pattern).format(ktmDateTime);
  }

  /// Validate Nepali mobile phone numbers (+97798XXXXXXXX or 98XXXXXXXX).
  static bool isNepaliPhone(String phone) {
    final RegExp regExp = RegExp(r'^(\+977)?9[678]\d{8}$');
    return regExp.hasMatch(phone.trim());
  }

  /// Format duration hours (<24h -> "X hours", >=24h -> "Y days").
  static String formatDuration(int hours) {
    if (hours < 24) {
      return '$hours ${hours == 1 ? "hour" : "hours"}';
    } else {
      final int days = hours ~/ 24;
      final int remainingHours = hours % 24;
      if (remainingHours == 0) {
        return '$days ${days == 1 ? "day" : "days"}';
      }
      return '$days ${days == 1 ? "day" : "days"} $remainingHours ${remainingHours == 1 ? "hr" : "hrs"}';
    }
  }
}
