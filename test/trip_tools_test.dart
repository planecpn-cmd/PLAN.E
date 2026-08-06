import 'package:flutter_test/flutter_test.dart';

import 'package:plan_e/core/format.dart';
import 'package:plan_e/models/budget_entry.dart';
import 'package:plan_e/models/gear_checklist_item.dart';
import 'package:plan_e/models/trip_message.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Trip Chat Model & Outbox State Tests', () {
    test('TripMessage deserializes json correctly', () {
      final json = {
        'id': 'msg-123',
        'booking_id': 'bkg-456',
        'sender_id': 'user-789',
        'body': 'Hello trek group!',
        'created_at': '2026-08-06T12:00:00.000Z',
        'profiles': {'full_name': 'Tenzing Norgay'},
      };

      final message = TripMessage.fromJson(json);

      expect(message.id, equals('msg-123'));
      expect(message.bookingId, equals('bkg-456'));
      expect(message.senderId, equals('user-789'));
      expect(message.senderName, equals('Tenzing Norgay'));
      expect(message.body, equals('Hello trek group!'));
      expect(message.isPending, isFalse);
      expect(message.isFailed, isFalse);
    });

    test('TripMessage pending outbox state transformation', () {
      final pendingMessage = TripMessage(
        id: 'outbox-1',
        bookingId: 'bkg-456',
        senderId: 'user-789',
        body: 'Pending local message',
        createdAt: DateTime.now().toUtc(),
        isPending: true,
      );

      expect(pendingMessage.isPending, isTrue);
      expect(pendingMessage.isFailed, isFalse);

      final failedMessage = pendingMessage.copyWith(
        isPending: false,
        isFailed: true,
      );

      expect(failedMessage.isPending, isFalse);
      expect(failedMessage.isFailed, isTrue);
    });
  });

  group('Gear Checklist Model & State Tests', () {
    test('GearChecklistItem deserializes and toggles state correctly', () {
      final json = {
        'id': 'item-1',
        'booking_id': 'bkg-456',
        'label': 'Trekking Boots',
        'is_checked': false,
        'is_custom': false,
        'sort_order': 0,
        'created_at': '2026-08-06T12:00:00.000Z',
      };

      final item = GearChecklistItem.fromJson(json);

      expect(item.id, equals('item-1'));
      expect(item.label, equals('Trekking Boots'));
      expect(item.isChecked, isFalse);
      expect(item.isCustom, isFalse);

      final toggled = item.copyWith(isChecked: true);
      expect(toggled.isChecked, isTrue);
    });

    test('Custom gear item creates with isCustom = true', () {
      final customItem = GearChecklistItem(
        id: 'custom-1',
        bookingId: 'bkg-456',
        label: 'Portable Solar Charger',
        isChecked: false,
        isCustom: true,
        createdAt: DateTime.now().toUtc(),
      );

      expect(customItem.isCustom, isTrue);
      expect(customItem.label, equals('Portable Solar Charger'));
    });
  });

  group('Budget Entry Model & Calculations Tests', () {
    test('BudgetEntry handles integer paisa math and serialization', () {
      final json = {
        'id': 'exp-101',
        'booking_id': 'bkg-456',
        'label': 'Tea house dinner & dal bhat',
        'amount_paisa': 125000, // Rs. 1,250
        'category': 'Food & Drinks',
        'spent_on': '2026-08-06',
        'created_at': '2026-08-06T12:00:00.000Z',
      };

      final entry = BudgetEntry.fromJson(json);

      expect(entry.id, equals('exp-101'));
      expect(entry.amountPaisa, equals(125000));
      expect(entry.category, equals('Food & Drinks'));
      expect(AppFormatters.formatNpr(entry.amountPaisa), equals('Rs. 1,250'));
    });

    test('Budget total and category breakdown calculations', () {
      final entries = [
        BudgetEntry(
          id: '1',
          bookingId: 'bkg-1',
          label: 'Lunch',
          amountPaisa: 50000, // Rs. 500
          category: 'Food & Drinks',
          spentOn: DateTime.now(),
          createdAt: DateTime.now(),
        ),
        BudgetEntry(
          id: '2',
          bookingId: 'bkg-1',
          label: 'Jeep to Besisahar',
          amountPaisa: 250000, // Rs. 2,500
          category: 'Transport',
          spentOn: DateTime.now(),
          createdAt: DateTime.now(),
        ),
        BudgetEntry(
          id: '3',
          bookingId: 'bkg-1',
          label: 'Dinner',
          amountPaisa: 80000, // Rs. 800
          category: 'Food & Drinks',
          spentOn: DateTime.now(),
          createdAt: DateTime.now(),
        ),
      ];

      final totalPaisa = entries.fold<int>(0, (sum, e) => sum + e.amountPaisa);
      expect(totalPaisa, equals(380000)); // Rs. 3,800 total
      expect(AppFormatters.formatNpr(totalPaisa), equals('Rs. 3,800'));

      final Map<String, int> categories = {};
      for (final e in entries) {
        categories[e.category] = (categories[e.category] ?? 0) + e.amountPaisa;
      }

      expect(categories['Food & Drinks'], equals(130000)); // Rs. 1,300
      expect(categories['Transport'], equals(250000)); // Rs. 2,500
    });
  });
}
