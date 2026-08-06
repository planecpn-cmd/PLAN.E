// Phase 11 - Localization, Bikram Sambat, Offline Banner & Accessibility Tests
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plan_e/core/format.dart';
import 'package:plan_e/l10n/app_localizations.dart';
import 'package:plan_e/widgets/offline_banner.dart';

void main() {
  group('Phase 11 - Bikram Sambat (BS) & Nepali Digit Formatting', () {
    test('toBikramSambat formats 2026-08-06 in English BS script', () {
      final date = DateTime.utc(2026, 8, 6);
      final bsString = AppFormatters.toBikramSambat(date);
      expect(bsString, equals('21 Shrawan 2083 BS'));
    });

    test('toBikramSambat formats 2026-08-06 in Nepali script', () {
      final date = DateTime.utc(2026, 8, 6);
      final bsString = AppFormatters.toBikramSambat(date, nepaliScript: true);
      expect(bsString, equals('२१ साउन २०८३ बि.सं.'));
    });

    test('toBikramSambat handles start of BS year 2081 Baisakh 1 (2024-04-13)', () {
      final date = DateTime.utc(2024, 4, 13);
      final bsEn = AppFormatters.toBikramSambat(date);
      final bsNe = AppFormatters.toBikramSambat(date, nepaliScript: true);
      expect(bsEn, equals('1 Baisakh 2081 BS'));
      expect(bsNe, equals('१ वैशाख २०८१ बि.सं.'));
    });

    test('toNepaliDigits converts standard digits to Devanagari numerals', () {
      expect(AppFormatters.toNepaliDigits('0123456789'), equals('०१२३४५६७८९'));
      expect(AppFormatters.toNepaliDigits('2083 BS'), equals('२०८३ BS'));
    });
  });

  group('Phase 11 - Full Localization (Nepali ARB & AppLocalizationsNe)', () {
    test('AppLocalizationsNe provides complete Nepali translations', () {
      final l10nNe = lookupAppLocalizations(const Locale('ne'));
      expect(l10nNe.tagline, equals('प्रामाणिक नेपाल अनुभवहरू'));
      expect(l10nNe.getStarted, equals('सुरु गर्नुहोस्'));
      expect(l10nNe.home, equals('गृह'));
      expect(l10nNe.explore, equals('खोज्नुहोस्'));
      expect(l10nNe.plans, equals('योजनाहरू'));
      expect(l10nNe.trips, equals('यात्राहरू'));
      expect(l10nNe.profile, equals('प्रोफाइल'));
      expect(l10nNe.diffEasy, equals('सजिलो'));
      expect(l10nNe.diffModerate, equals('मध्यम'));
      expect(l10nNe.diffChallenging, equals('चुनौतीपूर्ण'));
      expect(l10nNe.diffStrenuous, equals('अति कठिन'));
    });
  });

  group('Phase 11 - OfflineBanner Widget & Accessibility', () {
    testWidgets('OfflineBanner displays non-intrusive banner when offline is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: OfflineBanner(
                isOfflineOverride: true,
                child: Text('Main Screen Content'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Offline Mode — Displaying cached travel data'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
      expect(find.text('Main Screen Content'), findsOneWidget);
    });

    testWidgets('OfflineBanner is hidden when offline is false', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: OfflineBanner(
                isOfflineOverride: false,
                child: Text('Main Screen Content'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Offline Mode — Displaying cached travel data'), findsNothing);
      expect(find.byIcon(Icons.wifi_off_rounded), findsNothing);
      expect(find.text('Main Screen Content'), findsOneWidget);
    });
  });
}
