import '../domain/host_mode_models.dart';
import 'host_mode_repository.dart';

/// Fail-closed base for Host Mode operations without a production workflow.
///
/// A real production implementation must derive identity and host approval
/// from the authenticated backend session. Until that exists, operational
/// Host Mode data and mutations remain unavailable.
class UnavailableHostModeRepository implements HostModeRepository {
  static const _message =
      'Host Mode requires an authenticated, approved and active host account.';

  Future<T> _unavailable<T>() => Future<T>.error(StateError(_message));

  @override
  String? get currentUserId => null;

  @override
  Future<HostAccess> getHostAccess() async => const HostAccess(
    isApproved: false,
    isActive: false,
    label: 'Host access unavailable',
  );

  @override
  Future<HostDashboardData> getDashboard() => _unavailable();

  @override
  Future<List<HostExperience>> getExperiences() => _unavailable();

  @override
  Future<HostExperience?> getExperience(String id) => _unavailable();

  @override
  Future<HostExperience> saveDraft(HostExperienceDraft draft) => _unavailable();

  @override
  Future<HostExperience> submitForReview(HostExperienceDraft draft) =>
      _unavailable();

  @override
  Future<void> setExperiencePaused(String id, bool paused) => _unavailable();

  @override
  Future<void> updateAvailability(
    String id,
    DateTime start,
    DateTime end,
    int capacity,
  ) => _unavailable();

  @override
  Future<List<HostBookingRequest>> getBookings() => _unavailable();

  @override
  Future<HostBookingRequest?> getBooking(String id) => _unavailable();

  @override
  Future<void> updateBookingStatus(String id, HostBookingStatus status) =>
      _unavailable();

  @override
  Future<List<HostConversation>> getConversations() => _unavailable();

  @override
  Stream<List<HostConversation>> watchConversations() =>
      Stream.fromFuture(_unavailable());

  @override
  Future<HostConversation?> getConversation(String id) => _unavailable();

  @override
  Future<HostConversation?> getDepartureConversation(String experienceId) =>
      _unavailable();

  @override
  Future<void> markConversationRead(String id) => _unavailable();

  @override
  Future<HostMessage> sendMessage(
    String id,
    String normalizedText, {
    String? clientMessageId,
    String? attachmentUrl,
  }) => _unavailable();

  @override
  Future<HostProfileDraft> getHostProfile() => _unavailable();

  @override
  Future<void> updateHostProfile(HostProfileDraft normalizedProfile) =>
      _unavailable();

  @override
  Future<HostBusinessData> getBusinessPage(HostBusinessPage page) =>
      _unavailable();
}
