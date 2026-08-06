import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plan_e/features/host/host_provider.dart';
import 'package:plan_e/models/host_application.dart';

void main() {
  group('Phase 10 - Host Application Models & Provider', () {
    test('HostApplication model deserialization and status parsing', () {
      final json = {
        'id': 'ha-100',
        'user_id': 'user-123',
        'status': 'submitted',
        'current_step': 4,
        'category_id': 'cat-1',
        'title': 'High Altitude Mountain Trek Guide',
        'description': 'Guided trekking in Solukhumbu region.',
        'location': 'Solukhumbu',
        'photos': ['https://example.com/photo1.jpg'],
        'verification_doc_path': 'host-documents/user-123/id_doc.png',
        'submitted_at': '2026-08-06T12:00:00.000Z',
        'created_at': '2026-08-06T10:00:00.000Z',
        'updated_at': '2026-08-06T12:00:00.000Z',
      };

      final app = HostApplication.fromJson(json);

      expect(app.id, equals('ha-100'));
      expect(app.userId, equals('user-123'));
      expect(app.status, equals(HostAppStatus.submitted));
      expect(app.currentStep, equals(4));
      expect(app.title, equals('High Altitude Mountain Trek Guide'));
      expect(app.verificationDocPath, equals('host-documents/user-123/id_doc.png'));
      expect(app.submittedAt, isNotNull);

      final map = app.toJson();
      expect(map['status'], equals('submitted'));
      expect(map['title'], equals('High Altitude Mountain Trek Guide'));
    });

    test('HostAppStatus enum handles all values correctly', () {
      expect(HostAppStatus.fromString('draft'), equals(HostAppStatus.draft));
      expect(HostAppStatus.fromString('submitted'), equals(HostAppStatus.submitted));
      expect(HostAppStatus.fromString('under_review'), equals(HostAppStatus.underReview));
      expect(HostAppStatus.fromString('verification'), equals(HostAppStatus.verification));
      expect(HostAppStatus.fromString('approved'), equals(HostAppStatus.approved));
      expect(HostAppStatus.fromString('rejected'), equals(HostAppStatus.rejected));
      expect(HostAppStatus.fromString(null), equals(HostAppStatus.draft));

      expect(HostAppStatus.submitted.toJson(), equals('submitted'));
      expect(HostAppStatus.underReview.toJson(), equals('under_review'));
    });

    test('HostApplicationNotifier updates all steps', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(hostApplicationProvider.notifier);

      notifier.updateStep1(
        fullName: 'Pasang Sherpa',
        phone: '9841987654',
        district: 'Solukhumbu',
        bio: 'Certified trekking guide with 10 years experience.',
      );

      var data = container.read(hostApplicationProvider);
      expect(data.fullName, equals('Pasang Sherpa'));
      expect(data.phone, equals('9841987654'));
      expect(data.district, equals('Solukhumbu'));

      notifier.updateStep2(
        experienceTitle: 'Everest Base Camp Trek',
        category: 'Trekking',
        durationHours: 120,
        maxGroupSize: 8,
        pricePaisa: 15000000,
        description: 'Iconic trek to Everest Base Camp.',
      );

      data = container.read(hostApplicationProvider);
      expect(data.experienceTitle, equals('Everest Base Camp Trek'));
      expect(data.pricePaisa, equals(15000000));

      notifier.updateStep3(
        idType: 'Citizenship Card (Nagarikta)',
        idNumber: '12-34-56-78901',
        idImageUploaded: true,
        verificationDocPath: 'host-documents/user-123/doc.png',
      );

      data = container.read(hostApplicationProvider);
      expect(data.idNumber, equals('12-34-56-78901'));
      expect(data.idImageUploaded, isTrue);
      expect(data.verificationDocPath, equals('host-documents/user-123/doc.png'));

      notifier.updateStep4(
        bankName: 'Nabil Bank Ltd.',
        accountName: 'Pasang Sherpa',
        accountNumber: '0100017500001',
        branch: 'Namche Branch',
      );

      data = container.read(hostApplicationProvider);
      expect(data.bankName, equals('Nabil Bank Ltd.'));
      expect(data.accountNumber, equals('0100017500001'));
    });
  });
}
