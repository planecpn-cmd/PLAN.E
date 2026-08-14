import '../domain/host_mode_models.dart';

abstract interface class HostModeRepository {
  Future<HostAccess> getHostAccess();
  Future<HostDashboardData> getDashboard();
  Future<List<HostExperience>> getExperiences();
  Future<HostExperience?> getExperience(String id);
  Future<HostExperience> saveDraft(HostExperienceDraft draft);
  Future<HostExperience> submitForReview(HostExperienceDraft draft);
  Future<void> setExperiencePaused(String id, bool paused);
  Future<void> updateAvailability(
    String id,
    DateTime start,
    DateTime end,
    int capacity,
  );
  Future<List<HostBookingRequest>> getBookings();
  Future<HostBookingRequest?> getBooking(String id);
  Future<void> updateBookingStatus(String id, HostBookingStatus status);
  Future<List<HostConversation>> getConversations();
  Stream<List<HostConversation>> watchConversations();
  Future<HostConversation?> getConversation(String id);
  Future<HostConversation?> getDepartureConversation(String experienceId);
  Future<void> markConversationRead(String id);
  Future<HostMessage> sendMessage(String id, String normalizedText);
  Future<HostProfileDraft> getHostProfile();
  Future<void> updateHostProfile(HostProfileDraft normalizedProfile);
  Future<HostBusinessData> getBusinessPage(HostBusinessPage page);
}
