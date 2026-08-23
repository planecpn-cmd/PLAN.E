import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/booking.dart';
import '../../models/experience.dart';
import '../../models/experience_departure.dart';
import '../../providers/app_providers.dart';

class BookingFormData {
  final Experience experience;
  final List<ExperienceDeparture> departures;

  BookingFormData({required this.experience, required this.departures});
}

final experienceDeparturesProvider =
    FutureProvider.family<List<ExperienceDeparture>, String>((
      ref,
      experienceId,
    ) async {
      final repo = ref.watch(bookingRepositoryProvider);
      return repo.getDepartures(experienceId);
    });

final bookingDetailProvider = FutureProvider.family<Booking?, String>((
  ref,
  bookingId,
) async {
  final repo = ref.watch(bookingRepositoryProvider);
  return repo.getBookingById(bookingId);
});

final bookingFormDataProvider = FutureProvider.family<BookingFormData, String>((
  ref,
  experienceId,
) async {
  final expRepo = ref.watch(experienceRepositoryProvider);
  final bookingRepo = ref.watch(bookingRepositoryProvider);

  final experience = await expRepo.getExperienceById(experienceId);
  if (experience == null) {
    throw Exception('Experience not found');
  }

  final departures = await bookingRepo.getDepartures(experienceId);

  if (departures.isEmpty) {
    throw StateError(
      'No bookable departures are available for this experience.',
    );
  }

  return BookingFormData(experience: experience, departures: departures);
});
