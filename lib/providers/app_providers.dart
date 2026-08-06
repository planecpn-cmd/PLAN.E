import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
export 'trip_tools_providers.dart';

import '../core/supabase_client.dart';
import '../models/booking.dart';
import '../models/category.dart';
import '../models/experience.dart';
import '../models/host_application.dart';
import '../models/profile.dart';
import '../models/region.dart';
import '../repositories/booking_repository.dart';
import '../repositories/experience_repository.dart';
import '../repositories/host_repository.dart';
import '../repositories/profile_repository.dart';
import '../repositories/recent_searches_repository.dart';
import '../repositories/review_repository.dart';
import '../repositories/saved_repository.dart';
import '../repositories/taxonomy_repository.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return AppSupabaseClient.client;
});

final experienceRepositoryProvider = Provider<ExperienceRepository>((ref) {
  return ExperienceRepository(ref.watch(supabaseClientProvider));
});

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository(ref.watch(supabaseClientProvider));
});

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepository(ref.watch(supabaseClientProvider));
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(supabaseClientProvider));
});

final hostRepositoryProvider = Provider<HostRepository>((ref) {
  return HostRepository(ref.watch(supabaseClientProvider));
});

final savedRepositoryProvider = Provider<SavedRepository>((ref) {
  return SavedRepository(ref.watch(supabaseClientProvider));
});

final taxonomyRepositoryProvider = Provider<TaxonomyRepository>((ref) {
  return TaxonomyRepository(ref.watch(supabaseClientProvider));
});

final recentSearchesRepositoryProvider = Provider<RecentSearchesRepository>((
  ref,
) {
  return RecentSearchesRepository();
});

final recentSearchesProvider = FutureProvider<List<String>>((ref) async {
  final repo = ref.watch(recentSearchesRepositoryProvider);
  return repo.getRecentSearches();
});

// Async Providers
final experiencesProvider =
    FutureProvider.family<List<Experience>, Map<String, String?>>((
      ref,
      filters,
    ) async {
      final repo = ref.watch(experienceRepositoryProvider);
      int? minPricePaisa;
      int? maxPricePaisa;
      final minStr = filters['min_price'] ?? filters['min_price_paisa'];
      final maxStr = filters['max_price'] ?? filters['max_price_paisa'];
      if (minStr != null && minStr.isNotEmpty) {
        minPricePaisa = int.tryParse(minStr);
      }
      if (maxStr != null && maxStr.isNotEmpty) {
        maxPricePaisa = int.tryParse(maxStr);
      }

      return repo.getExperiences(
        categoryId: filters['category_id'],
        regionId: filters['region_id'],
        difficulty: filters['difficulty'],
        searchQuery: filters['search_query'],
        minPricePaisa: minPricePaisa,
        maxPricePaisa: maxPricePaisa,
        sortBy: filters['sort_by'],
      );
    });

final experienceDetailProvider = FutureProvider.family<Experience?, String>((
  ref,
  id,
) async {
  final repo = ref.watch(experienceRepositoryProvider);
  return repo.getExperienceById(id);
});

final homeRailsProvider = FutureProvider<Map<String, List<Experience>>>((
  ref,
) async {
  final repo = ref.watch(experienceRepositoryProvider);
  return repo.getHomeRails();
});

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final repo = ref.watch(taxonomyRepositoryProvider);
  return repo.getCategories();
});

final regionsProvider = FutureProvider<List<Region>>((ref) async {
  final repo = ref.watch(taxonomyRepositoryProvider);
  return repo.getRegions();
});

final savedExperiencesProvider = FutureProvider<List<Experience>>((ref) async {
  final repo = ref.watch(savedRepositoryProvider);
  return repo.getSavedExperiences();
});

final bookingsProvider = FutureProvider.family<List<Booking>, String>((
  ref,
  status,
) async {
  final repo = ref.watch(bookingRepositoryProvider);
  return repo.getBookingsByStatus(status);
});

final profileProvider = FutureProvider<Profile?>((ref) async {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getCurrentProfile();
});

final myHostApplicationProvider = FutureProvider<HostApplication?>((ref) async {
  final repo = ref.watch(hostRepositoryProvider);
  return repo.getHostApplication();
});

// Guest & Deferred Action State
class GuestState {
  final List<String> selectedInterests;
  const GuestState({this.selectedInterests = const []});

  GuestState copyWith({List<String>? selectedInterests}) {
    return GuestState(
      selectedInterests: selectedInterests ?? this.selectedInterests,
    );
  }
}

class GuestNotifier extends StateNotifier<GuestState> {
  GuestNotifier() : super(const GuestState());

  void toggleInterest(String interestId) {
    final list = List<String>.from(state.selectedInterests);
    if (list.contains(interestId)) {
      list.remove(interestId);
    } else {
      list.add(interestId);
    }
    state = state.copyWith(selectedInterests: list);
  }
}

final guestProvider = StateNotifierProvider<GuestNotifier, GuestState>((ref) {
  return GuestNotifier();
});

class DeferredAction {
  final String screenId;
  final String? entityId;
  final String action;

  const DeferredAction({
    required this.screenId,
    this.entityId,
    required this.action,
  });
}

class DeferredActionNotifier extends StateNotifier<DeferredAction?> {
  DeferredActionNotifier() : super(null);

  void setPending(DeferredAction action) {
    state = action;
  }

  void clear() {
    state = null;
  }
}

final deferredActionProvider =
    StateNotifierProvider<DeferredActionNotifier, DeferredAction?>((ref) {
      return DeferredActionNotifier();
    });

class NetworkStateNotifier extends StateNotifier<bool> {
  NetworkStateNotifier() : super(false);

  void setOffline(bool isOffline) {
    state = isOffline;
  }

  void toggle() {
    state = !state;
  }
}

final isOfflineProvider =
    StateNotifierProvider<NetworkStateNotifier, bool>((ref) {
      return NetworkStateNotifier();
    });

