import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/host_mode_repository.dart';
import '../data/supabase_host_mode_repository.dart';
import '../domain/host_mode_models.dart';
import '../../../providers/app_providers.dart';

final hostModeRepositoryProvider = Provider<HostModeRepository>((ref) {
  return SupabaseHostModeRepository(ref.watch(supabaseClientProvider));
});

final hostAccessProvider = FutureProvider<HostAccess>(
  (ref) => ref.watch(hostModeRepositoryProvider).getHostAccess(),
);
final hostDashboardProvider = FutureProvider<HostDashboardData>(
  (ref) => ref.watch(hostModeRepositoryProvider).getDashboard(),
);
final hostExperiencesProvider = FutureProvider<List<HostExperience>>(
  (ref) => ref.watch(hostModeRepositoryProvider).getExperiences(),
);
final hostExperienceProvider = FutureProvider.family<HostExperience?, String>(
  (ref, id) => ref.watch(hostModeRepositoryProvider).getExperience(id),
);
final hostBookingsProvider = FutureProvider<List<HostBookingRequest>>(
  (ref) => ref.watch(hostModeRepositoryProvider).getBookings(),
);
final hostConversationsProvider = StreamProvider<List<HostConversation>>(
  (ref) => ref.watch(hostModeRepositoryProvider).watchConversations(),
);
final hostBookingProvider = FutureProvider.family<HostBookingRequest?, String>(
  (ref, id) => ref.watch(hostModeRepositoryProvider).getBooking(id),
);
final hostConversationProvider =
    StreamProvider.family<HostConversation?, String>(
      (ref, id) => ref
          .watch(hostModeRepositoryProvider)
          .watchConversations()
          .map(
            (conversations) => conversations
                .where((conversation) => conversation.id == id)
                .firstOrNull,
          ),
    );
final hostDepartureConversationProvider =
    FutureProvider.family<HostConversation?, String>(
      (ref, experienceId) => ref
          .watch(hostModeRepositoryProvider)
          .getDepartureConversation(experienceId),
    );
final hostProfileDraftProvider = FutureProvider<HostProfileDraft>(
  (ref) => ref.watch(hostModeRepositoryProvider).getHostProfile(),
);
final hostBusinessPageProvider =
    FutureProvider.family<HostBusinessData, HostBusinessPage>(
      (ref, page) =>
          ref.watch(hostModeRepositoryProvider).getBusinessPage(page),
    );

/// Presentation-only state retained while the Host Mode ProviderScope lives.
/// Route query parameters can override these values for dashboard deep links.
final hostExperienceFilterProvider = StateProvider<HostExperienceStatus?>(
  (ref) => null,
);
final hostBookingFilterProvider = StateProvider<HostBookingStatus?>(
  (ref) => HostBookingStatus.requested,
);
final hostMessageSearchProvider = StateProvider<String>((ref) => '');

class HostCreateExperienceNotifier extends StateNotifier<HostExperienceDraft> {
  HostCreateExperienceNotifier() : super(const HostExperienceDraft());
  void update(HostExperienceDraft draft) => state = draft;
  void reset() => state = const HostExperienceDraft();
  void seed(HostExperience experience) {
    state = HostExperienceDraft(
      id: experience.id,
      title: experience.title,
      location: experience.location,
      description: experience.summary,
      photoAssets: [experience.imageAsset],
      startDate: experience.startDate,
      endDate: experience.endDate,
      capacity: experience.capacity,
      priceNpr: experience.priceNpr,
    );
  }
}

final hostCreateExperienceProvider =
    StateNotifierProvider<HostCreateExperienceNotifier, HostExperienceDraft>(
      (ref) => HostCreateExperienceNotifier(),
    );
