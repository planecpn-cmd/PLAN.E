import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/booking.dart';
import '../../models/experience.dart';
import '../../models/experience_departure.dart';
import '../../providers/app_providers.dart';
import 'booking_repository_service.dart';

class BookingFormData {
  final Experience experience;
  final List<ExperienceDeparture> departures;

  BookingFormData({
    required this.experience,
    required this.departures,
  });
}

final bookingFeatureRepositoryProvider = Provider<BookingFeatureRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return BookingFeatureRepository(client);
});

final experienceDeparturesProvider = FutureProvider.family<List<ExperienceDeparture>, String>((ref, experienceId) async {
  final repo = ref.watch(bookingFeatureRepositoryProvider);
  return repo.getDepartures(experienceId);
});

final bookingDetailProvider = FutureProvider.family<Booking?, String>((ref, bookingId) async {
  final repo = ref.watch(bookingFeatureRepositoryProvider);
  return repo.getBookingById(bookingId);
});

final bookingFormDataProvider = FutureProvider.family<BookingFormData, String>((ref, experienceId) async {
  final expRepo = ref.watch(experienceRepositoryProvider);
  final bookingRepo = ref.watch(bookingFeatureRepositoryProvider);

  final experience = await expRepo.getExperienceById(experienceId);
  if (experience == null) {
    throw Exception('Experience not found');
  }

  List<ExperienceDeparture> departures = await bookingRepo.getDepartures(experienceId);

  if (departures.isEmpty) {
    final now = DateTime.now();
    final durationDays = (experience.durationHours / 24).ceil();
    departures = [
      ExperienceDeparture(
        id: 'dep-1',
        experienceId: experienceId,
        startDate: now.add(const Duration(days: 7)),
        endDate: now.add(Duration(days: 7 + durationDays)),
        totalSpots: experience.groupSizeMax,
        spotsLeft: experience.groupSizeMax,
        priceOverridePaisa: null,
        status: 'open',
        createdAt: now,
      ),
      ExperienceDeparture(
        id: 'dep-2',
        experienceId: experienceId,
        startDate: now.add(const Duration(days: 14)),
        endDate: now.add(Duration(days: 14 + durationDays)),
        totalSpots: experience.groupSizeMax,
        spotsLeft: (experience.groupSizeMax * 0.6).round(),
        priceOverridePaisa: null,
        status: 'open',
        createdAt: now,
      ),
      ExperienceDeparture(
        id: 'dep-3',
        experienceId: experienceId,
        startDate: now.add(const Duration(days: 21)),
        endDate: now.add(Duration(days: 21 + durationDays)),
        totalSpots: experience.groupSizeMax,
        spotsLeft: (experience.groupSizeMax * 0.3).round(),
        priceOverridePaisa: null,
        status: 'open',
        createdAt: now,
      ),
    ];
  }

  return BookingFormData(experience: experience, departures: departures);
});
