import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
export 'trip_tools_providers.dart';
export 'remote_config_providers.dart';

import '../core/supabase_client.dart';
import '../models/booking.dart';
import '../models/category.dart';
import '../models/experience.dart';
import '../models/generated_itinerary.dart';
import '../models/home_rail_rule.dart';
import '../models/host_application.dart';
import '../models/notification.dart';
import '../models/profile.dart';
import '../models/region.dart';
import '../repositories/ai_itinerary_repository.dart';
import '../repositories/booking_repository.dart';
import '../repositories/experience_repository.dart';
import '../repositories/host_repository.dart';
import '../repositories/notification_repository.dart';
import '../repositories/profile_repository.dart';
import '../repositories/recent_searches_repository.dart';
import '../repositories/review_repository.dart';
import '../repositories/saved_repository.dart';
import '../repositories/taxonomy_repository.dart';
import 'remote_config_providers.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return AppSupabaseClient.client;
});

/// Set right before launching the Google/Apple browser flow, cleared once the
/// resulting `signedIn` event is handled. Distinguishes an OAuth return
/// (which has no other code path to navigate home) from a `signedIn` event
/// fired by the OTP verification screen, which navigates itself.
final oauthInFlightProvider = StateProvider<bool>((ref) => false);

/// Home screen's location label — starts as a static default and is
/// overwritten with a reverse-geocoded city once the user taps it to use
/// their real GPS location (see HomeScreen's location row).
final homeLocationLabelProvider = StateProvider<String>(
  (ref) => 'Kathmandu, Nepal',
);
final homeLocationLoadingProvider = StateProvider<bool>((ref) => false);

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
  final railRules = resolveHomeRailRules(
    ref.watch(remoteContentProvider('home_rail_rules')),
  );
  return repo.getHomeRails(railRules: railRules);
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

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.watch(supabaseClientProvider));
});

final notificationsProvider = FutureProvider<List<AppNotification>>((
  ref,
) async {
  final repo = ref.watch(notificationRepositoryProvider);
  return repo.getNotifications();
});

final unreadNotificationCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(notificationRepositoryProvider);
  return repo.getUnreadCount();
});

final aiItineraryRepositoryProvider = Provider<AiItineraryRepository>((ref) {
  return AiItineraryRepository(ref.watch(supabaseClientProvider));
});

class AiItineraryState {
  final bool isLoading;
  final String? errorMessage;
  final GeneratedItinerary? result;

  const AiItineraryState({
    this.isLoading = false,
    this.errorMessage,
    this.result,
  });

  AiItineraryState copyWith({
    bool? isLoading,
    String? errorMessage,
    GeneratedItinerary? result,
  }) {
    return AiItineraryState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      result: result ?? this.result,
    );
  }
}

class AiItineraryNotifier extends StateNotifier<AiItineraryState> {
  final AiItineraryRepository _repository;

  // Replays the last request with confirmed:true once the traveler accepts
  // a suggested substitute — set by generate()/generateFromPrompt().
  Future<GeneratedItinerary> Function(bool confirmed)? _lastRequest;

  AiItineraryNotifier(this._repository) : super(const AiItineraryState());

  Future<void> generate({
    required String tripType,
    required int durationDays,
    String? pace,
    int? budgetNpr,
    String? interests,
    String? groupType,
  }) {
    _lastRequest = (confirmed) => _repository.generate(
          tripType: tripType,
          durationDays: durationDays,
          pace: pace,
          budgetNpr: budgetNpr,
          interests: interests,
          groupType: groupType,
          confirmed: confirmed,
        );
    return _run(_lastRequest!(false));
  }

  Future<void> generateFromPrompt(String prompt) {
    _lastRequest = (confirmed) => _repository.generateFromPrompt(prompt, confirmed: confirmed);
    return _run(_lastRequest!(false));
  }

  Future<void> confirmSubstitute() {
    final request = _lastRequest;
    if (request == null) return Future.value();
    return _run(request(true));
  }

  Future<void> _run(Future<GeneratedItinerary> future) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final result = await future;
      state = state.copyWith(isLoading: false, result: result);
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(isLoading: false, errorMessage: message);
    }
  }

  void reset() {
    _lastRequest = null;
    state = const AiItineraryState();
  }
}

final aiItineraryNotifierProvider =
    StateNotifierProvider<AiItineraryNotifier, AiItineraryState>((ref) {
      return AiItineraryNotifier(ref.watch(aiItineraryRepositoryProvider));
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

/// Returns the safe post-authentication destination for a deferred action.
/// Entity identifiers are not interpreted as authorization claims.
String deferredActionDestination(DeferredAction? action) {
  return switch (action?.screenId) {
    'HOST_APPLICATION' => '/host',
    _ => '/home',
  };
}

class NetworkStateNotifier extends StateNotifier<bool> {
  NetworkStateNotifier() : super(false);

  void setOffline(bool isOffline) {
    state = isOffline;
  }

  void toggle() {
    state = !state;
  }
}

final isOfflineProvider = StateNotifierProvider<NetworkStateNotifier, bool>((
  ref,
) {
  return NetworkStateNotifier();
});
