import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:plan_e/features/host/data/mock_host_mode_repository.dart';
import 'package:plan_e/features/host/domain/host_experience_validator.dart';
import 'package:plan_e/features/host/domain/host_mode_models.dart';
import 'package:plan_e/features/host/presentation/host_mode_providers.dart';
import 'package:plan_e/providers/app_providers.dart';

void main() {
  group('Host Mode frontend architecture', () {
    test('production dependency defaults to fail-closed host access', () async {
      final client = SupabaseClient('https://example.supabase.co', 'test-key');
      final container = ProviderContainer(
        overrides: [supabaseClientProvider.overrideWithValue(client)],
      );
      addTearDown(container.dispose);

      final access = await container.read(hostAccessProvider.future);

      expect(access.canEnterHostMode, isFalse);
      expect(access.isApproved, isFalse);
      expect(access.isActive, isFalse);
    });

    test(
      'development repository provides deterministic in-memory data',
      () async {
        final repository = MockHostModeRepository();
        final dashboard = await repository.getDashboard();
        final experiences = await repository.getExperiences();
        final bookings = await repository.getBookings();

        expect(dashboard.summary.pendingRequests, 2);
        expect(dashboard.upcomingExperience?.title, 'Mardi Himal Trek');
        expect(experiences, hasLength(5));
        expect(bookings, isNotEmpty);
      },
    );

    test('validates normalized experience draft input', () {
      final validDraft = HostExperienceDraft(
        title: '  Mardi Himal Trek  ',
        location: '  Kaski, Nepal  ',
        description:
            'A carefully guided multi-day trek with local meals and lodging.',
        startDate: DateTime(2026, 9, 18),
        endDate: DateTime(2026, 9, 22),
        capacity: 8,
        priceNpr: 24500,
      );
      expect(HostExperienceValidator.validateDraft(validDraft), isEmpty);
    });

    test('rejects invalid dates, capacity and price', () {
      final invalidDraft = HostExperienceDraft(
        title: 'Trip',
        location: '',
        description: 'Too short',
        startDate: DateTime(2026, 9, 22),
        endDate: DateTime(2026, 9, 18),
        capacity: 0,
        priceNpr: -1,
      );
      final errors = HostExperienceValidator.validateDraft(invalidDraft);
      expect(
        errors.keys,
        containsAll([
          'title',
          'location',
          'description',
          'endDate',
          'capacity',
          'price',
        ]),
      );
    });

    test('documents both future host access requirements', () {
      expect(HostModeAccessRequirements.requiresAuthenticatedSession, isTrue);
      expect(HostModeAccessRequirements.requiresApprovedActiveHost, isTrue);
    });

    test('host registration resumes after login or signup', () {
      expect(
        deferredActionDestination(
          const DeferredAction(
            screenId: 'HOST_APPLICATION',
            action: 'register as a PLAN E host',
          ),
        ),
        '/host',
      );
      expect(deferredActionDestination(null), '/home');
    });

    test('development access is explicitly approved and active', () async {
      final access = await MockHostModeRepository().getHostAccess();
      expect(access.canEnterHostMode, isTrue);
      expect(access.label, contains('Development'));
    });

    test('booking decisions update local state only', () async {
      final repository = MockHostModeRepository();
      await repository.updateBookingStatus(
        'mock-booking-1',
        HostBookingStatus.confirmed,
      );
      expect(
        (await repository.getBooking('mock-booking-1'))?.status,
        HostBookingStatus.confirmed,
      );
      expect(
        (await MockHostModeRepository().getBooking('mock-booking-1'))?.status,
        HostBookingStatus.requested,
      );
    });

    test('submit creates a pending review experience locally', () async {
      final repository = MockHostModeRepository();
      final draft = HostExperienceDraft(
        title: 'Helambu Local Trail',
        location: 'Sindhupalchok, Nepal',
        description:
            'A locally guided trail experience with village stays and meals.',
        photoAssets: const ['assets/images/welcome_hero.jpg'],
        startDate: DateTime(2027, 2, 1),
        endDate: DateTime(2027, 2, 4),
        capacity: 8,
        priceNpr: 18000,
      );
      final submitted = await repository.submitForReview(draft);
      expect(submitted.status, HostExperienceStatus.pendingReview);
      expect(await repository.getExperiences(), contains(submitted));
    });

    test('messages normalize input and clear unread state locally', () async {
      final repository = MockHostModeRepository();
      final before = await repository.getConversation('mock-chat-1');
      await repository.markConversationRead('mock-chat-1');
      await repository.sendMessage('mock-chat-1', '  See you at Lakeside.  ');
      final after = await repository.getConversation('mock-chat-1');
      expect(before?.unreadCount, 2);
      expect(after?.unreadCount, 0);
      expect(after?.messages.last.text, 'See you at Lakeside.');
      expect(after?.messages.last.sentByHost, isTrue);
    });

    test(
      'booking requests expose application answers and conversation links',
      () async {
        final booking = await MockHostModeRepository().getBooking(
          'mock-booking-1',
        );
        expect(booking, isNotNull);
        expect(booking!.applicationAnswers, isNotEmpty);
        expect(booking.conversationId, 'mock-chat-1');
      },
    );

    test('confirmed departures resolve their own group conversation', () async {
      final repository = MockHostModeRepository();
      final mardi = await repository.getDepartureConversation('mock-exp-mardi');
      final panchase = await repository.getDepartureConversation(
        'mock-exp-panchase',
      );
      expect(mardi?.isGroup, isTrue);
      expect(mardi?.experienceId, 'mock-exp-mardi');
      expect(panchase?.isGroup, isTrue);
      expect(panchase?.experienceId, 'mock-exp-panchase');
    });

    test(
      'profile edits are normalized locally and reset with repository',
      () async {
        final repository = MockHostModeRepository();
        await repository.updateHostProfile(
          const HostProfileDraft(
            displayName: '  Nima Sherpa  ',
            bio: '  A local mountain host with extensive trail experience.  ',
            location: '  Solukhumbu, Nepal  ',
            languages: '  Nepali, English  ',
          ),
        );
        final updated = await repository.getHostProfile();
        expect(updated.displayName, 'Nima Sherpa');
        expect(
          (await repository.getDashboard()).summary.displayName,
          'Nima Sherpa',
        );
        expect(
          (await MockHostModeRepository().getHostProfile()).displayName,
          isNot('Nima Sherpa'),
        );
      },
    );

    test('experience management changes remain local', () async {
      final repository = MockHostModeRepository();
      await repository.setExperiencePaused('mock-exp-mardi', true);
      expect(
        (await repository.getExperience('mock-exp-mardi'))?.status,
        HostExperienceStatus.paused,
      );
      await repository.updateAvailability(
        'mock-exp-mardi',
        DateTime(2027, 3, 2),
        DateTime(2027, 3, 6),
        10,
      );
      final updated = await repository.getExperience('mock-exp-mardi');
      expect(updated?.capacity, 10);
      expect(updated?.startDate, DateTime(2027, 3, 2));
      expect(
        (await MockHostModeRepository().getExperience(
          'mock-exp-mardi',
        ))?.status,
        HostExperienceStatus.active,
      );
    });

    test(
      'all future-backend business sections have development data',
      () async {
        final repository = MockHostModeRepository();
        for (final page in HostBusinessPage.values) {
          final data = await repository.getBusinessPage(page);
          expect(data.title, isNotEmpty, reason: '$page needs a title');
          expect(data.items, isNotEmpty, reason: '$page needs content');
        }
      },
    );

    test('complete ten-step draft passes submission validation', () {
      final draft = HostExperienceDraft(
        title: 'Helambu Local Trail',
        location: 'Sindhupalchok, Nepal',
        description:
            'A locally guided trail experience with village stays and meals.',
        photoAssets: const ['assets/images/welcome_hero.jpg'],
        tripDetails:
            'A moderate four-day trek with lodge accommodation and transport.',
        itinerary: const ['Day 1 · Travel and village orientation'],
        included: const ['Guide and lodge accommodation'],
        bring: const ['Walking shoes and warm layers'],
        startDate: DateTime(2027, 2, 1),
        endDate: DateTime(2027, 2, 4),
        capacity: 8,
        priceNpr: 18000,
        meetingPoint: 'Boudha Gate, Kathmandu',
      );
      expect(HostExperienceValidator.validateForSubmission(draft), isEmpty);
    });
  });
}
