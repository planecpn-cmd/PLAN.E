enum HostExperienceStatus { active, draft, pendingReview, paused }

enum HostBookingStatus { requested, confirmed, completed, cancelled, declined }

class HostAccess {
  final bool isApproved;
  final bool isActive;
  final String label;
  const HostAccess({
    required this.isApproved,
    required this.isActive,
    required this.label,
  });
  bool get canEnterHostMode => isApproved && isActive;
}

enum HostBusinessPage {
  publicProfile,
  verification,
  earnings,
  reviews,
  history,
  notifications,
  help,
  guidelines,
  terms,
}

class HostBusinessItem {
  final String title;
  final String detail;
  final String? value;
  final bool unread;
  const HostBusinessItem({
    required this.title,
    required this.detail,
    this.value,
    this.unread = false,
  });
}

class HostBusinessData {
  final String title;
  final String introduction;
  final List<HostBusinessItem> items;
  const HostBusinessData({
    required this.title,
    required this.introduction,
    required this.items,
  });
}

class HostProfileDraft {
  final String displayName;
  final String bio;
  final String location;
  final String languages;
  const HostProfileDraft({
    required this.displayName,
    required this.bio,
    required this.location,
    required this.languages,
  });
  HostProfileDraft copyWith({
    String? displayName,
    String? bio,
    String? location,
    String? languages,
  }) => HostProfileDraft(
    displayName: displayName ?? this.displayName,
    bio: bio ?? this.bio,
    location: location ?? this.location,
    languages: languages ?? this.languages,
  );
}

class HostSummary {
  final String displayName;
  final bool isVerified;
  final int activeExperiences;
  final int upcomingGuests;
  final int pendingRequests;
  final int upcomingEarningsNpr;
  final int unreadMessages;
  const HostSummary({
    required this.displayName,
    required this.isVerified,
    required this.activeExperiences,
    required this.upcomingGuests,
    required this.pendingRequests,
    required this.upcomingEarningsNpr,
    required this.unreadMessages,
  });
}

class HostExperience {
  final String id;
  final String title;
  final String location;
  final String imageAsset;
  final DateTime startDate;
  final DateTime endDate;
  final int capacity;
  final int bookedSpots;
  final int priceNpr;
  final HostExperienceStatus status;
  final String summary;
  const HostExperience({
    required this.id,
    required this.title,
    required this.location,
    required this.imageAsset,
    required this.startDate,
    required this.endDate,
    required this.capacity,
    required this.bookedSpots,
    required this.priceNpr,
    required this.status,
    this.summary = 'A locally hosted PLAN E experience in Nepal.',
  });
  double get occupancy => capacity == 0 ? 0 : bookedSpots / capacity;
  HostExperience copyWith({
    String? title,
    String? location,
    DateTime? startDate,
    DateTime? endDate,
    int? capacity,
    int? bookedSpots,
    int? priceNpr,
    HostExperienceStatus? status,
    String? summary,
  }) => HostExperience(
    id: id,
    title: title ?? this.title,
    location: location ?? this.location,
    imageAsset: imageAsset,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    capacity: capacity ?? this.capacity,
    bookedSpots: bookedSpots ?? this.bookedSpots,
    priceNpr: priceNpr ?? this.priceNpr,
    status: status ?? this.status,
    summary: summary ?? this.summary,
  );
}

class HostTraveler {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String emergencyContact;
  final String dietaryNotes;
  const HostTraveler({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.emergencyContact,
    this.dietaryNotes = 'None provided',
  });
}

class HostBookingRequest {
  final String id;
  final String experienceId;
  final String experienceTitle;
  final String travelerName;
  final int travelerCount;
  final DateTime tripStartDate;
  final DateTime tripEndDate;
  final DateTime submittedAt;
  final int totalNpr;
  final HostBookingStatus status;
  final String? note;
  final List<HostTraveler> travelers;
  final Map<String, String> applicationAnswers;
  final String? conversationId;
  const HostBookingRequest({
    required this.id,
    required this.experienceId,
    required this.experienceTitle,
    required this.travelerName,
    required this.travelerCount,
    required this.tripStartDate,
    required this.tripEndDate,
    required this.submittedAt,
    required this.totalNpr,
    required this.status,
    this.note,
    this.travelers = const [],
    this.applicationAnswers = const {},
    this.conversationId,
  });
  HostBookingRequest copyWith({HostBookingStatus? status}) =>
      HostBookingRequest(
        id: id,
        experienceId: experienceId,
        experienceTitle: experienceTitle,
        travelerName: travelerName,
        travelerCount: travelerCount,
        tripStartDate: tripStartDate,
        tripEndDate: tripEndDate,
        submittedAt: submittedAt,
        totalNpr: totalNpr,
        status: status ?? this.status,
        note: note,
        travelers: travelers,
        applicationAnswers: applicationAnswers,
        conversationId: conversationId,
      );
}

class HostMessage {
  final String id;
  final String text;
  final bool sentByHost;
  final DateTime sentAt;
  const HostMessage({
    required this.id,
    required this.text,
    required this.sentByHost,
    required this.sentAt,
  });
}

class HostConversation {
  final String id;
  final String identity;
  final String experienceId;
  final String experienceTitle;
  final DateTime departureDate;
  final bool isGroup;
  final int unreadCount;
  final List<HostMessage> messages;
  const HostConversation({
    required this.id,
    required this.identity,
    required this.experienceId,
    required this.experienceTitle,
    required this.departureDate,
    required this.isGroup,
    required this.unreadCount,
    required this.messages,
  });
  HostMessage? get latestMessage {
    if (messages.isEmpty) return null;
    return messages.reduce(
      (latest, message) =>
          message.sentAt.isAfter(latest.sentAt) ? message : latest,
    );
  }

  String get lastMessage => latestMessage?.text ?? '';
  DateTime get lastMessageAt => latestMessage?.sentAt ?? departureDate;
  HostConversation copyWith({int? unreadCount, List<HostMessage>? messages}) =>
      HostConversation(
        id: id,
        identity: identity,
        experienceId: experienceId,
        experienceTitle: experienceTitle,
        departureDate: departureDate,
        isGroup: isGroup,
        unreadCount: unreadCount ?? this.unreadCount,
        messages: messages ?? this.messages,
      );
}

class HostDashboardData {
  final HostSummary summary;
  final List<HostBookingRequest> needsAttention;
  final HostExperience? upcomingExperience;
  final HostConversation? unreadConversation;
  const HostDashboardData({
    required this.summary,
    required this.needsAttention,
    required this.upcomingExperience,
    this.unreadConversation,
  });
}

class HostExperienceDraft {
  final String? id;
  final String title;
  final String location;
  final String description;
  final List<String> photoAssets;
  final String tripDetails;
  final List<String> itinerary;
  final List<String> included;
  final List<String> bring;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? capacity;
  final int? priceNpr;
  final String meetingPoint;
  const HostExperienceDraft({
    this.id,
    this.title = '',
    this.location = '',
    this.description = '',
    this.photoAssets = const [],
    this.tripDetails = '',
    this.itinerary = const [],
    this.included = const [],
    this.bring = const [],
    this.startDate,
    this.endDate,
    this.capacity,
    this.priceNpr,
    this.meetingPoint = '',
  });
  HostExperienceDraft copyWith({
    String? id,
    String? title,
    String? location,
    String? description,
    List<String>? photoAssets,
    String? tripDetails,
    List<String>? itinerary,
    List<String>? included,
    List<String>? bring,
    DateTime? startDate,
    DateTime? endDate,
    int? capacity,
    int? priceNpr,
    String? meetingPoint,
  }) => HostExperienceDraft(
    id: id ?? this.id,
    title: title ?? this.title,
    location: location ?? this.location,
    description: description ?? this.description,
    photoAssets: photoAssets ?? this.photoAssets,
    tripDetails: tripDetails ?? this.tripDetails,
    itinerary: itinerary ?? this.itinerary,
    included: included ?? this.included,
    bring: bring ?? this.bring,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    capacity: capacity ?? this.capacity,
    priceNpr: priceNpr ?? this.priceNpr,
    meetingPoint: meetingPoint ?? this.meetingPoint,
  );
}

abstract final class HostModeAccessRequirements {
  static const bool requiresAuthenticatedSession = true;
  static const bool requiresApprovedActiveHost = true;
}
