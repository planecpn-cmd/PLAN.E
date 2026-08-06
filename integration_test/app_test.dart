// PL-25 Integration Tests
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:plan_e/main.dart';
import 'package:plan_e/models/category.dart';
import 'package:plan_e/models/experience.dart';
import 'package:plan_e/models/experience_departure.dart';
import 'package:plan_e/models/profile.dart';
import 'package:plan_e/providers/app_providers.dart';
import 'package:plan_e/features/experience/experience_detail_providers.dart'
    as exp_detail;
import 'package:plan_e/features/booking/booking_providers.dart' as booking_p;
import 'package:plan_e/router.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final mockCategories = [
    Category(
      id: 'cat-1',
      nameEn: 'Trekking',
      nameNe: 'ट्रेकिङ',
      slug: 'trekking',
      icon: 'hiking',
      sortOrder: 1,
      createdAt: DateTime.utc(2026, 1, 1),
    ),
    Category(
      id: 'cat-2',
      nameEn: 'Culture',
      nameNe: 'संस्कृति',
      slug: 'culture',
      icon: 'museum',
      sortOrder: 2,
      createdAt: DateTime.utc(2026, 1, 1),
    ),
    Category(
      id: 'cat-3',
      nameEn: 'Wildlife',
      nameNe: 'वन्यजन्तु',
      slug: 'wildlife',
      icon: 'pets',
      sortOrder: 3,
      createdAt: DateTime.utc(2026, 1, 1),
    ),
    Category(
      id: 'cat-4',
      nameEn: 'Homestay',
      nameNe: 'होमस्टे',
      slug: 'homestay',
      icon: 'home_work',
      sortOrder: 4,
      createdAt: DateTime.utc(2026, 1, 1),
    ),
  ];

  final mockExperience = Experience(
    id: 'exp-1',
    title: 'Kathmandu Heritage Walk',
    slug: 'ktm-heritage-walk',
    summary: 'Explore ancient Durbar Squares and culture',
    description:
        'Full guided tour through historic Kathmandu Valley streets and temples with local food tasting.',
    coverImageUrl: 'https://example.com/ktm.jpg',
    pricePaisa: 250000,
    meetingPoint: 'Thamel, Kathmandu Gate',
    locationName: 'Kathmandu Valley',
    lat: 27.7172,
    lng: 85.3240,
    ratingAvg: 4.8,
    ratingCount: 24,
    durationHours: 6,
    groupSizeMax: 10,
    difficulty: DifficultyLevel.easy,
    status: ExperienceStatus.published,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  final mockDeparture = ExperienceDeparture(
    id: 'dep-1',
    experienceId: 'exp-1',
    startDate: DateTime.now().add(const Duration(days: 7)),
    endDate: DateTime.now().add(const Duration(days: 8)),
    totalSpots: 10,
    spotsLeft: 8,
    priceOverridePaisa: null,
    status: 'open',
    createdAt: DateTime.now(),
  );

  final mockProfile = Profile(
    id: 'user-1',
    fullName: 'Test Traveler',
    phone: '9849123456',
    role: UserRole.traveler,
    points: 500,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  final List<Override> integrationOverrides = [
    categoriesProvider.overrideWith((ref) async => mockCategories),
    homeRailsProvider.overrideWith(
      (ref) async => {
        'recommended': [mockExperience],
        'trending': [mockExperience],
      },
    ),
    experienceDetailProvider('exp-1').overrideWith(
      (ref) async => mockExperience,
    ),
    exp_detail.experienceDeparturesProvider('exp-1').overrideWith(
      (ref) async => [mockDeparture],
    ),
    booking_p.bookingFormDataProvider('exp-1').overrideWith(
      (ref) async => booking_p.BookingFormData(
        experience: mockExperience,
        departures: [mockDeparture],
      ),
    ),
    profileProvider.overrideWith((ref) async => mockProfile),
    exp_detail.isSavedExperienceProvider('exp-1').overrideWith(
      (ref) async => false,
    ),
    exp_detail.experienceItineraryProvider('exp-1').overrideWith(
      (ref) async => [],
    ),
    exp_detail.experienceReviewsProvider('exp-1').overrideWith(
      (ref) async => [],
    ),
  ];

  group('Phase 12 - Comprehensive End-to-End Integration Test Suite', () {
    testWidgets('1. App launch & splash -> Onboarding slide navigation -> Interest selection', (WidgetTester tester) async {
      router.go('/');
      await tester.pumpWidget(
        ProviderScope(
          overrides: integrationOverrides,
          child: const PlanEApp(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final getStartedBtn = find.text('Get Started');
      expect(getStartedBtn, findsOneWidget);

      // Tap Get Started -> Navigate to Onboarding Slide 1
      await tester.tap(getStartedBtn);
      await tester.pumpAndSettle();
      expect(find.text('Discover Authentic Nepal'), findsOneWidget);

      // Tap Next -> Slide 2
      final nextBtn = find.text('Next');
      expect(nextBtn, findsOneWidget);
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();
      expect(find.text('Transparent & Local Pricing'), findsOneWidget);

      // Tap Next -> Slide 3
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Empower Local Hosts'), findsOneWidget);

      // Tap Select Interests -> Interests Screen
      final selectInterestsBtn = find.text('Select Interests');
      expect(selectInterestsBtn, findsOneWidget);
      await tester.tap(selectInterestsBtn);
      await tester.pumpAndSettle();

      expect(find.text('What are\nyou into?'), findsOneWidget);

      // Select 3 interests
      await tester.tap(find.text('Trekking'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Culture'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Wildlife'));
      await tester.pumpAndSettle();

      expect(find.text('3 / 3 selected'), findsOneWidget);

      // Tap Continue -> Navigates to Home screen
      final continueBtn = find.text('Continue');
      expect(continueBtn, findsOneWidget);
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      expect(find.text('Kathmandu, Nepal'), findsOneWidget);
    });

    testWidgets('2. Home screen rails -> Experience detail view -> Booking form', (WidgetTester tester) async {
      router.go('/home');
      await tester.pumpWidget(
        ProviderScope(
          overrides: integrationOverrides,
          child: const PlanEApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Home Screen renders experience cards
      final expCard = find.text('Kathmandu Heritage Walk');
      expect(expCard, findsWidgets);

      // Tap experience card to view detail
      await tester.tap(expCard.first);
      await tester.pumpAndSettle();

      // Detail Screen renders title and Join button
      expect(find.text('Kathmandu Heritage Walk'), findsWidgets);
      final joinBtn = find.text('JOIN EXPERIENCE');
      expect(joinBtn, findsOneWidget);

      // Tap Join button -> Navigates to Booking form
      await tester.tap(joinBtn);
      await tester.pumpAndSettle();

      // Booking Screen renders departure selection & contact form
      expect(find.text('Booking Details'), findsOneWidget);
      expect(find.text('Contact & Traveller Details'), findsOneWidget);

      // Select departure card
      final departureCard = find.textContaining('spots left').first;
      await tester.tap(departureCard);
      await tester.pumpAndSettle();

      // Fill name & phone number
      final textFields = find.byType(TextFormField);
      expect(textFields, findsWidgets);
      await tester.enterText(textFields.at(0), 'Test Traveler');
      await tester.enterText(textFields.at(1), '9849123456');
      await tester.pumpAndSettle();

      expect(find.text('PROCEED TO PAYMENT'), findsOneWidget);
    });

    testWidgets('3. Host application wizard navigation', (WidgetTester tester) async {
      router.go('/host');
      await tester.pumpWidget(
        ProviderScope(
          overrides: integrationOverrides,
          child: const PlanEApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Become Host Screen renders
      expect(find.text('Become a Host'), findsOneWidget);
      final startAppBtn = find.text('START YOUR APPLICATION');
      expect(startAppBtn, findsOneWidget);

      // Tap Start Application -> Host Step 1
      await tester.ensureVisible(startAppBtn);
      await tester.tap(startAppBtn);
      await tester.pumpAndSettle();
      expect(find.text('Host Basic Details'), findsOneWidget);

      final step1NextBtn = find.text('CONTINUE TO STEP 2');
      expect(step1NextBtn, findsOneWidget);
      await tester.ensureVisible(step1NextBtn);
      await tester.tap(step1NextBtn);
      await tester.pumpAndSettle();

      // Host Step 2
      expect(find.text('Experience Details'), findsOneWidget);
      final step2NextBtn = find.text('CONTINUE TO STEP 3');
      expect(step2NextBtn, findsOneWidget);
      await tester.ensureVisible(step2NextBtn);
      await tester.tap(step2NextBtn);
      await tester.pumpAndSettle();

      // Host Step 3
      expect(find.text('Host Verification & ID'), findsOneWidget);

      // Tap document upload container
      final uploadBox = find.textContaining('Tap to upload citizenship photo');
      expect(uploadBox, findsOneWidget);
      await tester.ensureVisible(uploadBox);
      await tester.tap(uploadBox);
      await tester.pumpAndSettle();

      // Verify document attached feedback
      expect(find.textContaining('Document Attached'), findsOneWidget);

      final step3NextBtn = find.text('CONTINUE TO STEP 4');
      expect(step3NextBtn, findsOneWidget);
      await tester.ensureVisible(step3NextBtn);
      await tester.tap(step3NextBtn);
      await tester.pumpAndSettle();

      // Host Step 4
      expect(find.text('Payout & Bank Details'), findsOneWidget);
      final submitBtn = find.text('SUBMIT APPLICATION');
      expect(submitBtn, findsOneWidget);
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Application Submitted Screen
      expect(find.text('Application Submitted!'), findsOneWidget);
      expect(find.text('UNDER REVIEW'), findsOneWidget);
    });
  });
}
