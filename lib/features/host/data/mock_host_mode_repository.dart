import '../domain/host_mode_models.dart';
import '../../../core/chat_ordering.dart';
import 'host_mode_repository.dart';

/// DEVELOPMENT ONLY: in-memory state. It is never persisted and resets when
/// the app process restarts. This is not authentication or authorization.
class MockHostModeRepository implements HostModeRepository {
  HostProfileDraft _profile = const HostProfileDraft(
    displayName: 'Siddharth Gurung',
    bio:
        'Local trekking host sharing thoughtful journeys across the Annapurna region.',
    location: 'Pokhara, Nepal',
    languages: 'Nepali, English, Gurung',
  );
  final List<HostExperience> _experiences = [
    HostExperience(
      id: 'mock-exp-mardi',
      title: 'Mardi Himal Trek',
      location: 'Kaski, Nepal',
      imageAsset: 'assets/images/welcome_hero.jpg',
      startDate: DateTime(2026, 9, 18),
      endDate: DateTime(2026, 9, 22),
      capacity: 8,
      bookedSpots: 6,
      priceNpr: 24500,
      status: HostExperienceStatus.active,
      summary:
          'A five-day ridge trek with local guides, teahouse stays and Himalayan sunrise views.',
    ),
    HostExperience(
      id: 'mock-exp-panchase',
      title: 'Panchase Sunrise Hike',
      location: 'Pokhara, Nepal',
      imageAsset: 'assets/images/herosection.jpg',
      startDate: DateTime(2026, 10, 4),
      endDate: DateTime(2026, 10, 5),
      capacity: 10,
      bookedSpots: 7,
      priceNpr: 8500,
      status: HostExperienceStatus.active,
    ),
    HostExperience(
      id: 'mock-exp-village',
      title: 'Ghandruk Village Weekend',
      location: 'Annapurna, Nepal',
      imageAsset: 'assets/images/herosection.jpg',
      startDate: DateTime(2026, 11, 12),
      endDate: DateTime(2026, 11, 14),
      capacity: 8,
      bookedSpots: 0,
      priceNpr: 12000,
      status: HostExperienceStatus.draft,
    ),
    HostExperience(
      id: 'mock-exp-review',
      title: 'Khopra Ridge Discovery',
      location: 'Myagdi, Nepal',
      imageAsset: 'assets/images/welcome_hero.jpg',
      startDate: DateTime(2027, 1, 10),
      endDate: DateTime(2027, 1, 15),
      capacity: 8,
      bookedSpots: 0,
      priceNpr: 29500,
      status: HostExperienceStatus.pendingReview,
    ),
    HostExperience(
      id: 'mock-exp-forest',
      title: 'Dhampus Forest Walk',
      location: 'Kaski, Nepal',
      imageAsset: 'assets/images/explore_header_mountains.png',
      startDate: DateTime(2026, 12, 2),
      endDate: DateTime(2026, 12, 2),
      capacity: 12,
      bookedSpots: 5,
      priceNpr: 4500,
      status: HostExperienceStatus.paused,
    ),
  ];

  final List<HostBookingRequest> _bookings = [
    HostBookingRequest(
      id: 'mock-booking-1',
      experienceId: 'mock-exp-mardi',
      experienceTitle: 'Mardi Himal Trek',
      travelerName: 'Aarav Shrestha',
      travelerCount: 2,
      tripStartDate: DateTime(2026, 9, 18),
      tripEndDate: DateTime(2026, 9, 22),
      submittedAt: DateTime(2026, 8, 13, 8, 36),
      totalNpr: 49000,
      status: HostBookingStatus.requested,
      note: 'It is our first multi-day trek. Is a sleeping bag included?',
      travelers: const [
        HostTraveler(
          id: 'mock-traveler-aarav',
          name: 'Aarav Shrestha',
          email: 'aarav@example.test',
          phone: '+977 9800000001',
          emergencyContact: 'Nisha · +977 9800000011',
        ),
        HostTraveler(
          id: 'mock-traveler-nisha',
          name: 'Nisha Shrestha',
          email: 'nisha@example.test',
          phone: '+977 9800000002',
          emergencyContact: 'Aarav · +977 9800000001',
          dietaryNotes: 'Vegetarian',
        ),
      ],
      applicationAnswers: const {
        'Trekking experience':
            'Two day hikes; this will be our first multi-day trek.',
        'Medical or dietary needs':
            'One vegetarian guest. No medical conditions disclosed.',
        'What are you hoping for?':
            'A safe local experience and sunrise mountain views.',
      },
      conversationId: 'mock-chat-1',
    ),
    HostBookingRequest(
      id: 'mock-booking-2',
      experienceId: 'mock-exp-panchase',
      experienceTitle: 'Panchase Sunrise Hike',
      travelerName: 'Maya Gurung',
      travelerCount: 3,
      tripStartDate: DateTime(2026, 10, 4),
      tripEndDate: DateTime(2026, 10, 5),
      submittedAt: DateTime(2026, 8, 12, 16, 10),
      totalNpr: 25500,
      status: HostBookingStatus.requested,
      applicationAnswers: const {
        'Trekking experience': 'Regular weekend hiker.',
        'Medical or dietary needs': 'No special requirements.',
        'Pickup requested': 'Yes, from Pokhara Airport.',
      },
      conversationId: 'mock-chat-3',
    ),
    HostBookingRequest(
      id: 'mock-booking-3',
      experienceId: 'mock-exp-mardi',
      experienceTitle: 'Mardi Himal Trek',
      travelerName: 'Daniel Kim',
      travelerCount: 1,
      tripStartDate: DateTime(2026, 9, 18),
      tripEndDate: DateTime(2026, 9, 22),
      submittedAt: DateTime(2026, 8, 11, 9, 5),
      totalNpr: 24500,
      status: HostBookingStatus.confirmed,
      travelers: const [
        HostTraveler(
          id: 'mock-traveler-daniel',
          name: 'Daniel Kim',
          email: 'daniel@example.test',
          phone: '+82 10 0000 0000',
          emergencyContact: 'Min Kim · +82 10 0000 0001',
        ),
      ],
      conversationId: 'mock-chat-daniel',
    ),
    HostBookingRequest(
      id: 'mock-booking-4',
      experienceId: 'mock-exp-mardi',
      experienceTitle: 'Mardi Himal Trek',
      travelerName: 'Sofia Martin',
      travelerCount: 2,
      tripStartDate: DateTime(2026, 9, 18),
      tripEndDate: DateTime(2026, 9, 22),
      submittedAt: DateTime(2026, 8, 10, 12, 45),
      totalNpr: 49000,
      status: HostBookingStatus.confirmed,
      travelers: const [
        HostTraveler(
          id: 'mock-traveler-sofia',
          name: 'Sofia Martin',
          email: 'sofia@example.test',
          phone: '+34 600 000 001',
          emergencyContact: 'Luis · +34 600 000 002',
        ),
      ],
      conversationId: 'mock-chat-sofia',
    ),
    HostBookingRequest(
      id: 'mock-booking-5',
      experienceId: 'mock-exp-panchase',
      experienceTitle: 'Panchase Sunrise Hike',
      travelerName: 'Liam Wilson',
      travelerCount: 2,
      tripStartDate: DateTime(2026, 6, 4),
      tripEndDate: DateTime(2026, 6, 5),
      submittedAt: DateTime(2026, 5, 1),
      totalNpr: 17000,
      status: HostBookingStatus.completed,
    ),
    HostBookingRequest(
      id: 'mock-booking-6',
      experienceId: 'mock-exp-mardi',
      experienceTitle: 'Mardi Himal Trek',
      travelerName: 'Emma Chen',
      travelerCount: 1,
      tripStartDate: DateTime(2026, 7, 18),
      tripEndDate: DateTime(2026, 7, 22),
      submittedAt: DateTime(2026, 6, 1),
      totalNpr: 24500,
      status: HostBookingStatus.cancelled,
    ),
  ];

  final List<HostConversation> _conversations = [
    HostConversation(
      id: 'mock-chat-1',
      identity: 'Aarav Shrestha',
      experienceId: 'mock-exp-mardi',
      experienceTitle: 'Mardi Himal Trek',
      departureDate: DateTime(2026, 9, 18),
      isGroup: false,
      unreadCount: 2,
      messages: [
        HostMessage(
          id: 'm1',
          text: 'Namaste! We are excited for the trek.',
          sentByHost: false,
          sentAt: DateTime(2026, 8, 13, 8, 50),
        ),
        HostMessage(
          id: 'm2',
          text: 'Is a sleeping bag included in the packing list?',
          sentByHost: false,
          sentAt: DateTime(2026, 8, 13, 9, 5),
        ),
      ],
    ),
    HostConversation(
      id: 'mock-chat-group-mardi',
      identity: 'Mardi Himal · 18 Sep Group',
      experienceId: 'mock-exp-mardi',
      experienceTitle: 'Mardi Himal Trek',
      departureDate: DateTime(2026, 9, 18),
      isGroup: true,
      unreadCount: 0,
      messages: [
        HostMessage(
          id: 'm3',
          text: 'Welcome everyone. I’ll share the final meeting details here.',
          sentByHost: true,
          sentAt: DateTime(2026, 8, 12, 17, 20),
        ),
        HostMessage(
          id: 'm4',
          text: 'Thank you! We will meet you at Lakeside.',
          sentByHost: false,
          sentAt: DateTime(2026, 8, 12, 18, 40),
        ),
      ],
    ),
    HostConversation(
      id: 'mock-chat-daniel',
      identity: 'Daniel Kim',
      experienceId: 'mock-exp-mardi',
      experienceTitle: 'Mardi Himal Trek',
      departureDate: DateTime(2026, 9, 18),
      isGroup: false,
      unreadCount: 0,
      messages: [
        HostMessage(
          id: 'm-daniel',
          text: 'I have completed the guest details. Thank you.',
          sentByHost: false,
          sentAt: DateTime(2026, 8, 11, 12, 15),
        ),
      ],
    ),
    HostConversation(
      id: 'mock-chat-sofia',
      identity: 'Sofia Martin',
      experienceId: 'mock-exp-mardi',
      experienceTitle: 'Mardi Himal Trek',
      departureDate: DateTime(2026, 9, 18),
      isGroup: false,
      unreadCount: 0,
      messages: [
        HostMessage(
          id: 'm-sofia',
          text: 'We will arrive in Pokhara the day before.',
          sentByHost: false,
          sentAt: DateTime(2026, 8, 10, 14, 30),
        ),
      ],
    ),
    HostConversation(
      id: 'mock-chat-3',
      identity: 'Maya Gurung',
      experienceId: 'mock-exp-panchase',
      experienceTitle: 'Panchase Sunrise Hike',
      departureDate: DateTime(2026, 10, 4),
      isGroup: false,
      unreadCount: 0,
      messages: [
        HostMessage(
          id: 'm5',
          text: 'Can you arrange a pickup from the airport?',
          sentByHost: false,
          sentAt: DateTime(2026, 8, 12, 10, 15),
        ),
      ],
    ),
    HostConversation(
      id: 'mock-chat-group-panchase',
      identity: 'Panchase · 4 Oct Group',
      experienceId: 'mock-exp-panchase',
      experienceTitle: 'Panchase Sunrise Hike',
      departureDate: DateTime(2026, 10, 4),
      isGroup: true,
      unreadCount: 0,
      messages: [
        HostMessage(
          id: 'm-panchase-group',
          text: 'Welcome to the confirmed Panchase departure group.',
          sentByHost: true,
          sentAt: DateTime(2026, 8, 12, 9, 30),
        ),
      ],
    ),
  ];

  @override
  Future<HostAccess> getHostAccess() async => const HostAccess(
    isApproved: true,
    isActive: true,
    label: 'Development approved-host preview',
  );

  @override
  Future<HostDashboardData> getDashboard() async {
    final pending = _bookings
        .where((b) => b.status == HostBookingStatus.requested)
        .toList();
    final active = _experiences
        .where((e) => e.status == HostExperienceStatus.active)
        .toList();
    final unread = _conversations.fold<int>(
      0,
      (sum, item) => sum + item.unreadCount,
    );
    return HostDashboardData(
      summary: HostSummary(
        displayName: _profile.displayName,
        isVerified: true,
        activeExperiences: active.length,
        upcomingGuests: _bookings
            .where((b) => b.status == HostBookingStatus.confirmed)
            .fold(0, (sum, b) => sum + b.travelerCount),
        pendingRequests: pending.length,
        upcomingEarningsNpr: 48500,
        unreadMessages: unread,
      ),
      needsAttention: pending.take(1).toList(),
      upcomingExperience: active.isEmpty ? null : active.first,
      unreadConversation: _conversations
          .where((c) => c.unreadCount > 0)
          .firstOrNull,
    );
  }

  @override
  Future<List<HostExperience>> getExperiences() async =>
      List.unmodifiable(_experiences);
  @override
  Future<HostExperience?> getExperience(String id) async =>
      _experiences.where((e) => e.id == id).firstOrNull;
  @override
  Future<List<HostBookingRequest>> getBookings() async =>
      List.unmodifiable(_bookings);
  @override
  Future<HostBookingRequest?> getBooking(String id) async =>
      _bookings.where((b) => b.id == id).firstOrNull;
  @override
  Future<List<HostConversation>> getConversations() async =>
      sortHostConversationsByLatestActivity(_conversations);
  @override
  Stream<List<HostConversation>> watchConversations() async* {
    yield await getConversations();
  }

  @override
  Future<HostConversation?> getConversation(String id) async =>
      _conversations.where((c) => c.id == id).firstOrNull;

  @override
  Future<HostConversation?> getDepartureConversation(
    String experienceId,
  ) async => _conversations
      .where((c) => c.experienceId == experienceId && c.isGroup)
      .firstOrNull;

  @override
  Future<HostExperience> saveDraft(HostExperienceDraft draft) async =>
      _upsertDraft(draft, HostExperienceStatus.draft);
  @override
  Future<HostExperience> submitForReview(HostExperienceDraft draft) async =>
      _upsertDraft(draft, HostExperienceStatus.pendingReview);

  HostExperience _upsertDraft(
    HostExperienceDraft draft,
    HostExperienceStatus status,
  ) {
    final id =
        draft.id ?? 'mock-exp-local-${DateTime.now().microsecondsSinceEpoch}';
    final item = HostExperience(
      id: id,
      title: draft.title.trim().isEmpty
          ? 'Untitled experience'
          : draft.title.trim(),
      location: draft.location.trim().isEmpty
          ? 'Location not set'
          : draft.location.trim(),
      imageAsset:
          draft.photoAssets.firstOrNull ?? 'assets/images/welcome_hero.jpg',
      startDate: draft.startDate ?? DateTime(2027, 1, 1),
      endDate: draft.endDate ?? draft.startDate ?? DateTime(2027, 1, 1),
      capacity: draft.capacity ?? 1,
      bookedSpots: 0,
      priceNpr: draft.priceNpr ?? 0,
      status: status,
      summary: draft.description.trim(),
    );
    final index = _experiences.indexWhere((e) => e.id == id);
    if (index < 0) {
      _experiences.add(item);
    } else {
      _experiences[index] = item;
    }
    return item;
  }

  @override
  Future<void> setExperiencePaused(String id, bool paused) async {
    final index = _experiences.indexWhere((e) => e.id == id);
    if (index >= 0) {
      _experiences[index] = _experiences[index].copyWith(
        status: paused
            ? HostExperienceStatus.paused
            : HostExperienceStatus.active,
      );
    }
  }

  @override
  Future<void> updateAvailability(
    String id,
    DateTime start,
    DateTime end,
    int capacity,
  ) async {
    final index = _experiences.indexWhere((e) => e.id == id);
    if (index >= 0) {
      _experiences[index] = _experiences[index].copyWith(
        startDate: start,
        endDate: end,
        capacity: capacity,
      );
    }
  }

  @override
  Future<void> updateBookingStatus(String id, HostBookingStatus status) async {
    final index = _bookings.indexWhere((b) => b.id == id);
    if (index >= 0) {
      _bookings[index] = _bookings[index].copyWith(status: status);
    }
  }

  @override
  Future<void> markConversationRead(String id) async {
    final index = _conversations.indexWhere((c) => c.id == id);
    if (index >= 0) {
      _conversations[index] = _conversations[index].copyWith(unreadCount: 0);
    }
  }

  @override
  Future<HostMessage> sendMessage(String id, String normalizedText) async {
    final text = normalizedText.trim();
    if (text.isEmpty || text.length > 2000) {
      throw ArgumentError('Message must contain 1 to 2000 characters.');
    }
    final message = HostMessage(
      id: 'mock-message-${DateTime.now().microsecondsSinceEpoch}',
      text: text,
      sentByHost: true,
      sentAt: DateTime.now().toUtc(),
    );
    final index = _conversations.indexWhere((c) => c.id == id);
    if (index >= 0) {
      _conversations[index] = _conversations[index].copyWith(
        messages: sortHostMessagesChronologically([
          ..._conversations[index].messages,
          message,
        ]),
      );
    }
    return message;
  }

  @override
  Future<HostProfileDraft> getHostProfile() async => _profile;

  @override
  Future<void> updateHostProfile(HostProfileDraft normalizedProfile) async {
    _profile = HostProfileDraft(
      displayName: normalizedProfile.displayName.trim(),
      bio: normalizedProfile.bio.trim(),
      location: normalizedProfile.location.trim(),
      languages: normalizedProfile.languages.trim(),
    );
  }

  @override
  Future<HostBusinessData> getBusinessPage(HostBusinessPage page) async {
    return switch (page) {
      HostBusinessPage.publicProfile => HostBusinessData(
        title: _profile.displayName,
        introduction: _profile.bio,
        items: [
          HostBusinessItem(title: 'Based in', detail: _profile.location),
          HostBusinessItem(title: 'Languages', detail: _profile.languages),
          const HostBusinessItem(title: 'Hosting since', detail: '2024'),
          const HostBusinessItem(
            title: 'Response rate',
            detail: '98% within one hour',
          ),
        ],
      ),
      HostBusinessPage.verification => const HostBusinessData(
        title: 'Verification & Documents',
        introduction:
            'Development-only status display. Document actions require a secure backend.',
        items: [
          HostBusinessItem(
            title: 'Identity verification',
            detail: 'Citizenship document reviewed',
            value: 'Verified',
          ),
          HostBusinessItem(
            title: 'Host application',
            detail: 'Approved for local experience hosting',
            value: 'Approved',
          ),
          HostBusinessItem(
            title: 'Emergency contact',
            detail: 'Contact details provided',
            value: 'Complete',
          ),
        ],
      ),
      HostBusinessPage.earnings => const HostBusinessData(
        title: 'Earnings & Payouts',
        introduction:
            'Display-only development figures. No payout or payment operation is available.',
        items: [
          HostBusinessItem(
            title: 'Upcoming earnings',
            detail: 'Confirmed future departures',
            value: 'NPR 48,500',
          ),
          HostBusinessItem(
            title: 'Paid this year',
            detail: 'Development preview total',
            value: 'NPR 186,000',
          ),
          HostBusinessItem(
            title: 'Payout method',
            detail: 'Not connected',
            value: 'Unavailable',
          ),
        ],
      ),
      HostBusinessPage.reviews => const HostBusinessData(
        title: 'Guest Reviews',
        introduction:
            'Recent development-only feedback for the public host profile.',
        items: [
          HostBusinessItem(
            title: 'Sofia · 5.0',
            detail:
                'A calm, knowledgeable host who made the trail feel welcoming.',
          ),
          HostBusinessItem(
            title: 'Daniel · 4.8',
            detail:
                'Clear communication and excellent local food recommendations.',
          ),
        ],
      ),
      HostBusinessPage.history => const HostBusinessData(
        title: 'Hosting History',
        introduction: 'Completed departures and hosting activity.',
        items: [
          HostBusinessItem(
            title: 'Panchase Sunrise Hike',
            detail: '4 June 2026 · 8 guests',
            value: 'Completed',
          ),
          HostBusinessItem(
            title: 'Mardi Himal Trek',
            detail: '18 April 2026 · 6 guests',
            value: 'Completed',
          ),
          HostBusinessItem(
            title: 'Ghandruk Village Weekend',
            detail: '12 March 2026 · 5 guests',
            value: 'Completed',
          ),
        ],
      ),
      HostBusinessPage.notifications => const HostBusinessData(
        title: 'Host Notifications',
        introduction: 'Operational updates for Host Mode.',
        items: [
          HostBusinessItem(
            title: 'New booking request',
            detail: 'Aarav requested Mardi Himal Trek.',
            unread: true,
          ),
          HostBusinessItem(
            title: 'Unread message',
            detail: 'Aarav asked about the packing list.',
            unread: true,
          ),
          HostBusinessItem(
            title: 'Departure reminder',
            detail: 'Mardi Himal Trek begins in 36 days.',
          ),
        ],
      ),
      HostBusinessPage.help => const HostBusinessData(
        title: 'Host Help & Support',
        introduction:
            'Guidance for running safe and welcoming PLAN E experiences.',
        items: [
          HostBusinessItem(
            title: 'Booking support',
            detail: 'Review common request and cancellation questions.',
          ),
          HostBusinessItem(
            title: 'Safety support',
            detail: 'Emergency preparation and incident guidance.',
          ),
          HostBusinessItem(
            title: 'Contact support',
            detail: 'Support messaging will require backend integration.',
            value: 'Preview only',
          ),
        ],
      ),
      HostBusinessPage.guidelines => const HostBusinessData(
        title: 'Hosting Guidelines',
        introduction: 'Core expectations for PLAN E hosts.',
        items: [
          HostBusinessItem(
            title: 'Be accurate',
            detail:
                'Keep itinerary, pricing, difficulty and inclusions current.',
          ),
          HostBusinessItem(
            title: 'Put safety first',
            detail: 'Assess conditions and communicate risks before departure.',
          ),
          HostBusinessItem(
            title: 'Respect communities',
            detail: 'Host responsibly and follow local customs.',
          ),
          HostBusinessItem(
            title: 'Communicate promptly',
            detail: 'Respond to requests and changes clearly.',
          ),
        ],
      ),
      HostBusinessPage.terms => const HostBusinessData(
        title: 'Terms & Policies',
        introduction:
            'Development preview of policy categories; legally binding content will be provided later.',
        items: [
          HostBusinessItem(
            title: 'Host terms',
            detail: 'Responsibilities, eligibility and platform conduct.',
          ),
          HostBusinessItem(
            title: 'Cancellation policy',
            detail: 'Traveler and host cancellation principles.',
          ),
          HostBusinessItem(
            title: 'Privacy',
            detail: 'Handling traveler information and sensitive documents.',
          ),
          HostBusinessItem(
            title: 'Payout policy',
            detail: 'Future secure payout processing requirements.',
          ),
        ],
      ),
    };
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
