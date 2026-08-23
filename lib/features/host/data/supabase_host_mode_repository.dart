import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/chat_ordering.dart';
import '../domain/host_mode_models.dart';
import 'unavailable_host_mode_repository.dart';

/// Supabase-backed production Host Mode boundary.
///
/// Identity always comes from the authenticated Supabase session. Every read
/// is additionally gated by [current_host_access], while row ownership remains
/// enforced by database RLS. Methods that do not yet have an authoritative
/// backend workflow continue to inherit the fail-closed implementation.
class SupabaseHostModeRepository extends UnavailableHostModeRepository {
  SupabaseHostModeRepository(this._client);

  final SupabaseClient _client;

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  static const _fallbackImage = 'assets/images/welcome_hero.jpg';

  @override
  Future<HostAccess> getHostAccess() async {
    if (_client.auth.currentUser == null) {
      return const HostAccess(
        isApproved: false,
        isActive: false,
        label: 'Authentication required',
      );
    }

    final response = await _client.rpc('current_host_access');
    final rows = response is List ? response : const [];
    final row = rows.isNotEmpty && rows.first is Map
        ? Map<String, dynamic>.from(rows.first as Map)
        : const <String, dynamic>{};
    final approved = row['is_approved'] == true;
    final active = row['is_active'] == true;
    final status = row['application_status']?.toString() ?? 'not_applied';

    return HostAccess(
      isApproved: approved,
      isActive: active,
      label: approved && active
          ? 'Approved active host'
          : 'Host application: $status',
    );
  }

  Future<User> _requireApprovedHost() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('An authenticated session is required.');
    }
    final access = await getHostAccess();
    if (!access.canEnterHostMode) {
      throw StateError('An approved and active host account is required.');
    }
    return user;
  }

  @override
  Future<List<HostExperience>> getExperiences() async {
    final user = await _requireApprovedHost();
    final experienceRows = await _client
        .from('experiences')
        .select(
          'id,title,summary,location_name,cover_image_url,price_paisa,status,group_size_max,created_at',
        )
        .eq('host_id', user.id)
        .order('created_at', ascending: true);

    final ids = experienceRows
        .map((row) => row['id']?.toString())
        .whereType<String>()
        .toList();
    final departuresByExperience = <String, List<Map<String, dynamic>>>{};
    if (ids.isNotEmpty) {
      final departureRows = await _client
          .from('experience_departures')
          .select(
            'id,experience_id,start_date,end_date,total_spots,spots_left,status',
          )
          .inFilter('experience_id', ids)
          .order('start_date');
      for (final raw in departureRows) {
        final row = Map<String, dynamic>.from(raw);
        final experienceId = row['experience_id']?.toString();
        if (experienceId != null) {
          departuresByExperience.putIfAbsent(experienceId, () => []).add(row);
        }
      }
    }

    return experienceRows.map((raw) {
      final row = Map<String, dynamic>.from(raw);
      final id = row['id'].toString();
      final departures = departuresByExperience[id] ?? const [];
      final departure = departures.isEmpty ? null : departures.first;
      final now = DateTime.now();
      final start = _date(departure?['start_date']) ?? now;
      final end = _date(departure?['end_date']) ?? start;
      final capacity = _integer(
        departure?['total_spots'] ?? row['group_size_max'],
      );
      final spotsLeft = _integer(departure?['spots_left'] ?? capacity);
      return HostExperience(
        id: id,
        title: row['title']?.toString() ?? 'Untitled experience',
        location: row['location_name']?.toString() ?? 'Nepal',
        imageAsset: _fallbackImage,
        startDate: start,
        endDate: end,
        capacity: capacity,
        bookedSpots: (capacity - spotsLeft).clamp(0, capacity),
        priceNpr: _integer(row['price_paisa']) ~/ 100,
        status: _experienceStatus(row['status']?.toString()),
        summary:
            row['summary']?.toString() ??
            'A locally hosted PLAN E experience in Nepal.',
      );
    }).toList();
  }

  @override
  Future<HostExperience?> getExperience(String id) async {
    final experiences = await getExperiences();
    for (final experience in experiences) {
      if (experience.id == id) return experience;
    }
    return null;
  }

  @override
  Future<List<HostBookingRequest>> getBookings() async {
    await _requireApprovedHost();
    final experiences = await getExperiences();
    if (experiences.isEmpty) return const [];
    final experiencesById = {for (final item in experiences) item.id: item};
    final bookingRows = await _client
        .from('bookings')
        .select(
          'id,user_id,experience_id,departure_id,adults,children,contact_name,contact_phone,total_paisa,status,created_at',
        )
        .inFilter('experience_id', experiencesById.keys.toList())
        .order('created_at', ascending: false);

    final bookingIds = bookingRows
        .map((row) => row['id']?.toString())
        .whereType<String>()
        .toList();
    final participantsByBooking = <String, List<Map<String, dynamic>>>{};
    if (bookingIds.isNotEmpty) {
      final participantRows = await _client
          .from('booking_participants')
          .select('id,booking_id,full_name,age,is_lead')
          .inFilter('booking_id', bookingIds);
      for (final raw in participantRows) {
        final row = Map<String, dynamic>.from(raw);
        final bookingId = row['booking_id']?.toString();
        if (bookingId != null) {
          participantsByBooking.putIfAbsent(bookingId, () => []).add(row);
        }
      }
    }

    return bookingRows.map((raw) {
      final row = Map<String, dynamic>.from(raw);
      final id = row['id'].toString();
      final experience = experiencesById[row['experience_id']?.toString()];
      final contactName = row['contact_name']?.toString() ?? 'Traveler';
      final contactPhone = row['contact_phone']?.toString() ?? 'Not provided';
      final participants = participantsByBooking[id] ?? const [];
      final travelers = participants.map((participant) {
        return HostTraveler(
          id: participant['id']?.toString() ?? id,
          name: participant['full_name']?.toString() ?? contactName,
          email: 'Not provided',
          phone: contactPhone,
          emergencyContact: 'Not provided',
        );
      }).toList();
      final travelerCount = _integer(row['adults']) + _integer(row['children']);
      return HostBookingRequest(
        id: id,
        experienceId: row['experience_id']?.toString() ?? '',
        experienceTitle: experience?.title ?? 'Experience',
        travelerName: contactName,
        travelerCount: travelerCount,
        tripStartDate: experience?.startDate ?? DateTime.now(),
        tripEndDate: experience?.endDate ?? DateTime.now(),
        submittedAt: _date(row['created_at']) ?? DateTime.now(),
        totalNpr: _integer(row['total_paisa']) ~/ 100,
        status: _bookingStatus(row['status']?.toString()),
        note: 'Booking from your host account.',
        travelers: travelers,
        applicationAnswers: const {
          'Application details':
              'No structured application-answer fields are stored yet.',
        },
        conversationId: id,
      );
    }).toList();
  }

  @override
  Future<HostBookingRequest?> getBooking(String id) async {
    final bookings = await getBookings();
    for (final booking in bookings) {
      if (booking.id == id) return booking;
    }
    return null;
  }

  @override
  Future<List<HostConversation>> getConversations() async {
    final user = await _requireApprovedHost();
    final bookings = await getBookings();
    if (bookings.isEmpty) return const [];
    final bookingsById = {for (final booking in bookings) booking.id: booking};
    final messageRows = await _client
        .from('trip_messages')
        .select(
          'id,booking_id,sender_id,body,attachment_url,created_at,trip_message_receipts(delivered_at,seen_at),trip_message_mutations(effective_body,edited_at,deleted_at)',
        )
        .inFilter('booking_id', bookingsById.keys.toList())
        .order('created_at');
    final messagesByBooking = <String, List<HostMessage>>{};
    for (final raw in messageRows) {
      final row = Map<String, dynamic>.from(raw);
      final bookingId = row['booking_id']?.toString();
      if (bookingId == null) continue;
      final receipts = row['trip_message_receipts'];
      final receiptRows = receipts is List
          ? receipts
                .whereType<Map<String, dynamic>>()
                .map(Map<String, dynamic>.from)
                .toList()
          : const <Map<String, dynamic>>[];
      final mutations = row['trip_message_mutations'];
      final mutationRows = mutations is List
          ? mutations.whereType<Map<String, dynamic>>().toList()
          : const <Map<String, dynamic>>[];
      final mutation = mutationRows.firstOrNull;
      final deletedAt = _date(mutation?['deleted_at']);
      messagesByBooking
          .putIfAbsent(bookingId, () => [])
          .add(
            HostMessage(
              id: row['id']?.toString() ?? '',
              senderId: row['sender_id']?.toString(),
              text: deletedAt != null
                  ? 'Message deleted'
                  : mutation?['effective_body']?.toString() ??
                        row['body']?.toString() ??
                        '',
              sentByHost: row['sender_id']?.toString() == user.id,
              sentAt: _date(row['created_at']) ?? DateTime.now(),
              attachmentUrl: deletedAt == null
                  ? row['attachment_url']?.toString()
                  : null,
              isDelivered: receiptRows.any(
                (receipt) => receipt['delivered_at'] != null,
              ),
              isSeen: receiptRows.any((receipt) => receipt['seen_at'] != null),
              editedAt: _date(mutation?['edited_at']),
              deletedAt: deletedAt,
            ),
          );
    }

    final readRows = await _client
        .from('trip_message_reads')
        .select('conversation_id,last_read_at')
        .inFilter('conversation_id', bookingsById.keys.toList());
    final lastReadByBooking = <String, DateTime>{};
    for (final raw in readRows) {
      final row = Map<String, dynamic>.from(raw);
      final bookingId = row['conversation_id']?.toString();
      final lastReadAt = _date(row['last_read_at']);
      if (bookingId != null && lastReadAt != null) {
        lastReadByBooking[bookingId] = lastReadAt;
      }
    }

    final conversations = bookings.map((booking) {
      final messages = sortHostMessagesChronologically(
        messagesByBooking[booking.id] ?? const [],
      );
      final lastReadAt = lastReadByBooking[booking.id];
      final unreadCount = messages.where((message) {
        if (message.sentByHost) return false;
        return lastReadAt == null || message.sentAt.isAfter(lastReadAt);
      }).length;
      return HostConversation(
        id: booking.id,
        identity:
            booking.status == HostBookingStatus.confirmed &&
                booking.travelerCount > 1
            ? '${booking.experienceTitle} · confirmed group'
            : booking.travelerName,
        experienceId: booking.experienceId,
        experienceTitle: booking.experienceTitle,
        departureDate: booking.tripStartDate,
        isGroup:
            booking.status == HostBookingStatus.confirmed &&
            booking.travelerCount > 1,
        unreadCount: unreadCount,
        messages: messages,
      );
    });
    return sortHostConversationsByLatestActivity(conversations);
  }

  @override
  Stream<List<HostConversation>> watchConversations() {
    late final StreamController<List<HostConversation>> controller;
    RealtimeChannel? channel;
    var conversations = <HostConversation>[];
    Future<void> patchQueue = Future.value();

    Future<void> patchInsertedMessage(PostgresChangePayload payload) async {
      final row = payload.newRecord;
      final bookingId = row['booking_id']?.toString();
      final messageId = row['id']?.toString();
      if (bookingId == null || messageId == null) return;

      final index = conversations.indexWhere((item) => item.id == bookingId);
      if (index == -1) {
        // A booking created after this subscription started has no cached
        // inbox row. Refresh only on that rare cache miss; ordinary inserts
        // patch one conversation locally in O(1) database work.
        conversations = await getConversations();
        if (!controller.isClosed) {
          controller.add(sortHostConversationsByLatestActivity(conversations));
        }
        return;
      }

      final existing = conversations[index];
      if (existing.messages.any((message) => message.id == messageId)) return;
      final userId = _client.auth.currentUser?.id;
      final sentByHost = row['sender_id']?.toString() == userId;
      final message = HostMessage(
        id: messageId,
        senderId: row['sender_id']?.toString(),
        text: row['body']?.toString() ?? '',
        sentByHost: sentByHost,
        sentAt: _date(row['created_at'])?.toUtc() ?? DateTime.now().toUtc(),
        attachmentUrl: row['attachment_url']?.toString(),
      );
      conversations[index] = existing.copyWith(
        messages: sortHostMessagesChronologically([
          ...existing.messages,
          message,
        ]),
        unreadCount: existing.unreadCount + (sentByHost ? 0 : 1),
      );
      conversations = sortHostConversationsByLatestActivity(conversations);
      if (!controller.isClosed) controller.add(conversations);
    }

    void patchReceipt(PostgresChangePayload payload) {
      final row = payload.newRecord;
      final bookingId = row['conversation_id']?.toString();
      final messageId = row['message_id']?.toString();
      if (bookingId == null || messageId == null) return;
      final conversationIndex = conversations.indexWhere(
        (item) => item.id == bookingId,
      );
      if (conversationIndex == -1) return;
      final conversation = conversations[conversationIndex];
      final messageIndex = conversation.messages.indexWhere(
        (message) => message.id == messageId,
      );
      if (messageIndex == -1) return;
      final messages = List<HostMessage>.from(conversation.messages);
      messages[messageIndex] = messages[messageIndex].copyWith(
        isDelivered: row['delivered_at'] != null,
        isSeen: row['seen_at'] != null,
      );
      conversations[conversationIndex] = conversation.copyWith(
        messages: messages,
      );
      if (!controller.isClosed) controller.add(conversations);
    }

    void patchMutation(PostgresChangePayload payload) {
      final row = payload.newRecord;
      final bookingId = row['conversation_id']?.toString();
      final messageId = row['message_id']?.toString();
      if (bookingId == null || messageId == null) return;
      final conversationIndex = conversations.indexWhere(
        (item) => item.id == bookingId,
      );
      if (conversationIndex == -1) return;
      final conversation = conversations[conversationIndex];
      final messageIndex = conversation.messages.indexWhere(
        (message) => message.id == messageId,
      );
      if (messageIndex == -1) return;
      final messages = List<HostMessage>.from(conversation.messages);
      messages[messageIndex] = messages[messageIndex].withMutation(
        effectiveBody: row['effective_body']?.toString(),
        editedAt: _date(row['edited_at']),
        deletedAt: _date(row['deleted_at']),
      );
      conversations[conversationIndex] = conversation.copyWith(
        messages: messages,
      );
      if (!controller.isClosed) controller.add(conversations);
    }

    controller = StreamController<List<HostConversation>>(
      onListen: () {
        unawaited(() async {
          try {
            final user = await _requireApprovedHost();
            channel = _client
                .channel(
                  'host-inbox-${user.id}-${DateTime.now().microsecondsSinceEpoch}',
                )
                .onPostgresChanges(
                  event: PostgresChangeEvent.insert,
                  schema: 'public',
                  table: 'trip_messages',
                  callback: (payload) {
                    patchQueue = patchQueue.then(
                      (_) => patchInsertedMessage(payload),
                    );
                  },
                )
                .onPostgresChanges(
                  event: PostgresChangeEvent.all,
                  schema: 'public',
                  table: 'trip_message_receipts',
                  callback: patchReceipt,
                )
                .onPostgresChanges(
                  event: PostgresChangeEvent.all,
                  schema: 'public',
                  table: 'trip_message_mutations',
                  callback: patchMutation,
                )
                .subscribe();
            conversations = await getConversations();
            if (!controller.isClosed) controller.add(conversations);
          } catch (error, stack) {
            if (!controller.isClosed) controller.addError(error, stack);
          }
        }());
      },
      onCancel: () async {
        final activeChannel = channel;
        if (activeChannel != null) {
          await _client.removeChannel(activeChannel);
        }
      },
    );
    return controller.stream;
  }

  @override
  Future<HostConversation?> getConversation(String id) async {
    final conversations = await getConversations();
    for (final conversation in conversations) {
      if (conversation.id == id) return conversation;
    }
    return null;
  }

  @override
  Future<HostConversation?> getDepartureConversation(
    String experienceId,
  ) async {
    final conversations = await getConversations();
    for (final conversation in conversations) {
      if (conversation.experienceId == experienceId && conversation.isGroup) {
        return conversation;
      }
    }
    for (final conversation in conversations) {
      if (conversation.experienceId == experienceId) return conversation;
    }
    return null;
  }

  @override
  Future<void> markConversationRead(String id) async {
    await _requireApprovedHost();
    await _client.rpc(
      'mark_trip_conversation_read',
      params: {'p_conversation_id': id},
    );
  }

  @override
  Future<HostMessage> sendMessage(
    String id,
    String normalizedText, {
    String? clientMessageId,
    String? attachmentUrl,
  }) async {
    final user = await _requireApprovedHost();
    final text = normalizedText.trim();
    if (text.isEmpty || text.length > 2000) {
      throw ArgumentError('Message must contain 1 to 2000 characters.');
    }
    final stableId = clientMessageId ?? const Uuid().v4();
    final response = await _client.rpc(
      'send_trip_message',
      params: {
        'p_booking_id': id,
        'p_client_message_id': stableId,
        'p_body': text,
        'p_attachment_url': attachmentUrl,
      },
    );
    final rows = response as List;
    if (rows.isEmpty) {
      throw StateError('Message could not be reconciled after retry.');
    }
    final row = Map<String, dynamic>.from(rows.first as Map);
    return HostMessage(
      id: row['id']?.toString() ?? '',
      senderId: row['sender_id']?.toString(),
      text: row['body']?.toString() ?? text,
      sentByHost: row['sender_id']?.toString() == user.id,
      sentAt: _date(row['created_at'])?.toUtc() ?? DateTime.now().toUtc(),
      attachmentUrl: row['attachment_url']?.toString(),
    );
  }

  @override
  Future<HostProfileDraft> getHostProfile() async {
    final user = await _requireApprovedHost();
    final row = await _client
        .from('profiles')
        .select('full_name,bio,location,language')
        .eq('id', user.id)
        .single();
    return HostProfileDraft(
      displayName: row['full_name']?.toString() ?? 'Host',
      bio: row['bio']?.toString() ?? '',
      location: row['location']?.toString() ?? 'Nepal',
      languages: row['language'] == 'ne' ? 'Nepali' : 'English',
    );
  }

  @override
  Future<void> updateHostProfile(HostProfileDraft normalizedProfile) async {
    final user = await _requireApprovedHost();
    final name = normalizedProfile.displayName.trim();
    final bio = normalizedProfile.bio.trim();
    final location = normalizedProfile.location.trim();
    if (name.isEmpty || name.length > 100) {
      throw ArgumentError('Display name must contain 1 to 100 characters.');
    }
    if (bio.length > 1000 || location.length > 120) {
      throw ArgumentError('Profile text is too long.');
    }
    await _client
        .from('profiles')
        .update({'full_name': name, 'bio': bio, 'location': location})
        .eq('id', user.id);
  }

  @override
  Future<HostDashboardData> getDashboard() async {
    await _requireApprovedHost();
    final results = await Future.wait<dynamic>([
      getExperiences(),
      getBookings(),
      getConversations(),
      getHostProfile(),
    ]);
    final experiences = results[0] as List<HostExperience>;
    final bookings = results[1] as List<HostBookingRequest>;
    final conversations = results[2] as List<HostConversation>;
    final profile = results[3] as HostProfileDraft;
    final requested = bookings
        .where((booking) => booking.status == HostBookingStatus.requested)
        .toList();
    final confirmed = bookings
        .where((booking) => booking.status == HostBookingStatus.confirmed)
        .toList();
    final active =
        experiences
            .where(
              (experience) => experience.status == HostExperienceStatus.active,
            )
            .toList()
          ..sort((a, b) => a.startDate.compareTo(b.startDate));
    HostConversation? unread;
    for (final conversation in conversations) {
      if (conversation.unreadCount > 0) {
        unread = conversation;
        break;
      }
    }
    return HostDashboardData(
      summary: HostSummary(
        displayName: profile.displayName,
        isVerified: true,
        activeExperiences: active.length,
        upcomingGuests: confirmed.fold(
          0,
          (total, booking) => total + booking.travelerCount,
        ),
        pendingRequests: requested.length,
        upcomingEarningsNpr: confirmed.fold(
          0,
          (total, booking) => total + booking.totalNpr,
        ),
        unreadMessages: conversations.fold(
          0,
          (total, conversation) => total + conversation.unreadCount,
        ),
      ),
      needsAttention: requested,
      upcomingExperience: active.isEmpty ? null : active.first,
      unreadConversation: unread,
    );
  }

  @override
  Future<HostBusinessData> getBusinessPage(HostBusinessPage page) async {
    await _requireApprovedHost();
    final profile = await getHostProfile();
    switch (page) {
      case HostBusinessPage.publicProfile:
        return HostBusinessData(
          title: 'Public Host Profile',
          introduction: 'Traveler-facing host information from your profile.',
          items: [
            HostBusinessItem(title: profile.displayName, detail: profile.bio),
            HostBusinessItem(title: 'Location', detail: profile.location),
          ],
        );
      case HostBusinessPage.verification:
        return const HostBusinessData(
          title: 'Verification & Documents',
          introduction: 'Your host account is approved and active.',
          items: [
            HostBusinessItem(
              title: 'Host status',
              detail: 'Approved',
              value: 'Active',
            ),
          ],
        );
      case HostBusinessPage.earnings:
        final bookings = await getBookings();
        final earnings = bookings
            .where((item) => item.status == HostBookingStatus.confirmed)
            .fold(0, (total, item) => total + item.totalNpr);
        return HostBusinessData(
          title: 'Earnings & Payouts',
          introduction:
              'Display only. Secure payout processing is not connected.',
          items: [
            HostBusinessItem(
              title: 'Upcoming booking value',
              detail: 'Confirmed bookings',
              value: 'NPR $earnings',
            ),
          ],
        );
      case HostBusinessPage.reviews:
        return _displayOnly('Reviews');
      case HostBusinessPage.history:
        return _displayOnly('Hosting History');
      case HostBusinessPage.notifications:
        return _displayOnly('Notifications');
      case HostBusinessPage.help:
        return _displayOnly('Help & Support');
      case HostBusinessPage.guidelines:
        return _displayOnly('Hosting Guidelines');
      case HostBusinessPage.terms:
        return _displayOnly('Terms & Policies');
    }
  }

  static HostBusinessData _displayOnly(String title) => HostBusinessData(
    title: title,
    introduction: 'This section is not available yet.',
    items: const [
      HostBusinessItem(
        title: 'Coming soon',
        detail: 'Account-backed content will appear here when available.',
      ),
    ],
  );

  static int _integer(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _date(Object? value) =>
      value == null ? null : DateTime.tryParse(value.toString())?.toUtc();

  static HostExperienceStatus _experienceStatus(String? status) {
    switch (status) {
      case 'published':
        return HostExperienceStatus.active;
      case 'pending_review':
        return HostExperienceStatus.pendingReview;
      case 'paused':
        return HostExperienceStatus.paused;
      default:
        return HostExperienceStatus.draft;
    }
  }

  static HostBookingStatus _bookingStatus(String? status) {
    switch (status) {
      case 'confirmed':
        return HostBookingStatus.confirmed;
      case 'completed':
        return HostBookingStatus.completed;
      case 'cancelled':
      case 'cancellation_requested':
      case 'expired':
        return HostBookingStatus.cancelled;
      default:
        return HostBookingStatus.requested;
    }
  }
}
