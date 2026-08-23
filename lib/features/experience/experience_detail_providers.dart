import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/experience_departure.dart';
import '../../models/itinerary_item.dart';
import '../../models/review.dart';
import '../../models/profile.dart';
import '../../providers/app_providers.dart';

final experienceDeparturesProvider =
    FutureProvider.family<List<ExperienceDeparture>, String>((
      ref,
      experienceId,
    ) async {
      final repo = ref.watch(experienceRepositoryProvider);
      return repo.getDepartures(experienceId);
    });

final experienceItineraryProvider =
    FutureProvider.family<List<ItineraryItem>, String>((
      ref,
      experienceId,
    ) async {
      final repo = ref.watch(experienceRepositoryProvider);
      return repo.getItinerary(experienceId);
    });

final experienceReviewsProvider = FutureProvider.family<List<Review>, String>((
  ref,
  experienceId,
) async {
  final repo = ref.watch(experienceRepositoryProvider);
  return repo.getReviews(experienceId);
});

final hostProfileProvider = FutureProvider.family<Profile?, String>((
  ref,
  hostId,
) async {
  final repo = ref.watch(experienceRepositoryProvider);
  return repo.getHostProfile(hostId);
});

final isSavedExperienceProvider = FutureProvider.family<bool, String>((
  ref,
  experienceId,
) async {
  final repo = ref.watch(savedRepositoryProvider);
  return repo.isSaved(experienceId);
});
