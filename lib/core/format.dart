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

  /// Month names in English and Nepali for Bikram Sambat.
  static const List<String> _bsMonthsEn = [
    'Baisakh', 'Jestha', 'Ashadh', 'Shrawan', 'Bhadra', 'Ashwin',
    'Kartik', 'Mangsir', 'Poush', 'Magh', 'Falgun', 'Chaitra'
  ];

  static const List<String> _bsMonthsNe = [
    'वैशाख', 'जेठ', 'असार', 'साउन', 'भदौ', 'असोज',
    'कात्तिक', 'मंसिर', 'पुष', 'माघ', 'फागुन', 'चैत'
  ];

  /// Lookup map for BS Year starting Gregorian dates (Baisakh 1) and days in each month.
  static const Map<int, Map<String, dynamic>> _bsData = {
    2075: {'start': '2018-04-14', 'days': [31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30]},
    2076: {'start': '2019-04-14', 'days': [31, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 30]},
    2077: {'start': '2020-04-13', 'days': [31, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31]},
    2078: {'start': '2021-04-14', 'days': [31, 31, 31, 32, 31, 31, 30, 29, 30, 29, 30, 30]},
    2079: {'start': '2022-04-14', 'days': [31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30]},
    2080: {'start': '2023-04-14', 'days': [31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30]},
    2081: {'start': '2024-04-13', 'days': [31, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31]},
    2082: {'start': '2025-04-14', 'days': [31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30]},
    2083: {'start': '2026-04-14', 'days': [31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30]},
    2084: {'start': '2027-04-14', 'days': [31, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 30]},
    2085: {'start': '2028-04-13', 'days': [31, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31]},
    2086: {'start': '2029-04-14', 'days': [31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30]},
    2087: {'start': '2030-04-14', 'days': [31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30]},
    2088: {'start': '2031-04-14', 'days': [31, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 30]},
    2089: {'start': '2032-04-13', 'days': [31, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31]},
    2090: {'start': '2033-04-14', 'days': [31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30]},
  };

  /// Convert standard digits to Nepali digits (0-9 -> ०-९).
  static String toNepaliDigits(String input) {
    const map = {
      '0': '०', '1': '१', '2': '२', '3': '३', '4': '४',
      '5': '५', '6': '६', '7': '७', '8': '८', '9': '९'
    };
    return input.split('').map((c) => map[c] ?? c).join('');
  }

  /// Convert DateTime to Bikram Sambat (BS) date display string.
  /// Example: DateTime(2026, 8, 6) -> "21 Shrawan 2083 BS"
  /// If nepaliScript is true -> "२१ साउन २०८३ बि.सं."
  static String toBikramSambat(DateTime dateTime, {bool nepaliScript = false}) {
    final DateTime ktm = toKathmandu(dateTime);
    final DateTime ktmDateOnly = DateTime.utc(ktm.year, ktm.month, ktm.day);

    int bsYear = ktm.year + 57;
    if (!_bsData.containsKey(bsYear)) {
      // Find matching BS year in table or fallback
      for (final y in _bsData.keys.toList()..sort()) {
        final start = DateTime.parse(_bsData[y]!['start'] as String);
        if (ktmDateOnly.isBefore(start)) {
          bsYear = y - 1;
          break;
        } else {
          bsYear = y;
        }
      }
    }

    // Refine BS year by checking Baisakh 1
    if (_bsData.containsKey(bsYear)) {
      final baisakh1 = DateTime.parse(_bsData[bsYear]!['start'] as String);
      if (ktmDateOnly.isBefore(baisakh1)) {
        bsYear--;
      }
    }

    if (_bsData.containsKey(bsYear)) {
      final baisakh1 = DateTime.parse(_bsData[bsYear]!['start'] as String);
      final daysList = List<int>.from(_bsData[bsYear]!['days'] as List);
      int diffDays = ktmDateOnly.difference(baisakh1).inDays;

      int bsMonthIdx = 0;
      while (bsMonthIdx < 12 && diffDays >= daysList[bsMonthIdx]) {
        diffDays -= daysList[bsMonthIdx];
        bsMonthIdx++;
      }

      final int bsDay = diffDays + 1;
      final String monthName = nepaliScript ? _bsMonthsNe[bsMonthIdx] : _bsMonthsEn[bsMonthIdx];

      if (nepaliScript) {
        return '${toNepaliDigits(bsDay.toString())} $monthName ${toNepaliDigits(bsYear.toString())} बि.सं.';
      } else {
        return '$bsDay $monthName $bsYear BS';
      }
    }

    // Mathematical fallback for dates outside table
    final int fallbackYear = ktm.month >= 4 && ktm.day >= 14 ? ktm.year + 57 : ktm.year + 56;
    final int approxMonthIdx = ((ktm.month + 8) % 12);
    final String monthName = nepaliScript ? _bsMonthsNe[approxMonthIdx] : _bsMonthsEn[approxMonthIdx];
    if (nepaliScript) {
      return '${toNepaliDigits(ktm.day.toString())} $monthName ${toNepaliDigits(fallbackYear.toString())} बि.सं.';
    }
    return '${ktm.day} $monthName $fallbackYear BS';
  }
}
