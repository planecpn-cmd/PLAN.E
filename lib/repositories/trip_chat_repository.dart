import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/chat_ordering.dart';
import '../core/offline_cache.dart';
import '../models/trip_message.dart';

class TripChatRepository {
  final SupabaseClient _client;

  TripChatRepository(this._client);

  /// Fetch historic messages for a trip booking from Supabase. Read-only
  /// cache — offline, this returns whatever was last synced; sending a new
  /// message still requires connectivity (see
  /// docs/OFFLINE_CACHE_PLAN.md §5), the outbox in
  /// TripChatNotifier.sendMessage handles that failure separately, not here.
  Future<List<TripMessage>> getMessages(String bookingId) async {
    final cacheKey = 'trip_messages:$bookingId';
    try {
      final response = await _client
          .from('trip_messages')
          .select(
            '*, profiles(full_name), trip_message_receipts(delivered_at,seen_at), trip_message_mutations(effective_body,edited_at,deleted_at)',
          )
          .eq('booking_id', bookingId)
          .order('created_at', ascending: true);

      final List<dynamic> data = response as List<dynamic>;
      // Cache the raw response, not TripMessage.toJson() — that method is
      // shaped for outbound inserts and deliberately drops the joined
      // `profiles.full_name` (there's no sender to re-send on insert).
      // Round-tripping through it would silently blank out every cached
      // message's sender name. The raw data is already exactly the shape
      // fromJson expects.
      await OfflineCache.write(cacheKey, data);
      return mergeTripMessagesChronologically(
        data.map((json) => TripMessage.fromJson(json as Map<String, dynamic>)),
      );
    } catch (_) {
      final cached = await OfflineCache.read<List<TripMessage>>(
        cacheKey,
        (json) => (json as List)
            .map((e) => TripMessage.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
      if (cached != null) return mergeTripMessagesChronologically(cached);
      rethrow;
    }
  }

  /// Subscribe to Realtime channel for `trip_messages` table updates
  Stream<List<TripMessage>> streamMessages(String bookingId) {
    return _client
        .from('trip_messages')
        .stream(primaryKey: ['id'])
        .eq('booking_id', bookingId)
        .order('created_at', ascending: true)
        .map(
          (data) => mergeTripMessagesChronologically(
            data.map((json) => TripMessage.fromJson(json)),
          ),
        );
  }

  Stream<List<TripMessageReceiptSnapshot>> streamReceipts(String bookingId) {
    return _client
        .from('trip_message_receipts')
        .stream(primaryKey: ['message_id', 'recipient_id'])
        .eq('conversation_id', bookingId)
        .map(
          (rows) => rows
              .map(
                (row) => TripMessageReceiptSnapshot(
                  messageId: row['message_id'] as String,
                  isDelivered: row['delivered_at'] != null,
                  isSeen: row['seen_at'] != null,
                ),
              )
              .toList(),
        );
  }

  Stream<List<TripMessageMutationSnapshot>> streamMutations(String bookingId) {
    return _client
        .from('trip_message_mutations')
        .stream(primaryKey: ['message_id'])
        .eq('conversation_id', bookingId)
        .map(
          (rows) => rows
              .map(
                (row) => TripMessageMutationSnapshot(
                  messageId: row['message_id'] as String,
                  effectiveBody: row['effective_body'] as String?,
                  editedAt: _date(row['edited_at']),
                  deletedAt: _date(row['deleted_at']),
                ),
              )
              .toList(),
        );
  }

  Future<void> editMessage(String messageId, String body) async {
    await _client.rpc(
      'edit_trip_message',
      params: {'p_message_id': messageId, 'p_new_body': body},
    );
  }

  Future<void> deleteMessage(String messageId) async {
    await _client.rpc(
      'delete_trip_message',
      params: {'p_message_id': messageId},
    );
  }

  Future<String> reportMessage({
    required String messageId,
    required String reason,
    String? details,
  }) async {
    final result = await _client.rpc(
      'report_trip_message',
      params: {
        'p_message_id': messageId,
        'p_reason': reason,
        'p_details': details,
      },
    );
    return result.toString();
  }

  Future<void> blockParticipant({
    required String conversationId,
    required String userId,
  }) => _client.rpc(
    'block_trip_participant',
    params: {
      'p_conversation_id': conversationId,
      'p_blocked_user_id': userId,
    },
  );

  Future<void> unblockParticipant(String userId) => _client.rpc(
    'unblock_trip_participant',
    params: {'p_blocked_user_id': userId},
  );

  Future<TripConversationSafety> getConversationSafety(
    String conversationId,
  ) async {
    final response = await _client.rpc(
      'get_trip_conversation_safety',
      params: {'p_conversation_id': conversationId},
    );
    final rows = response as List;
    if (rows.isEmpty) throw StateError('Conversation safety state missing.');
    return TripConversationSafety.fromJson(
      Map<String, dynamic>.from(rows.first as Map),
    );
  }

  Future<List<TripModerationReport>> getModerationQueue() async {
    final response = await _client.rpc('get_trip_moderation_queue');
    return (response as List)
        .map(
          (row) => TripModerationReport.fromJson(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList();
  }

  Future<void> reviewReport({
    required String reportId,
    required String status,
    String? notes,
  }) => _client.rpc(
    'review_trip_message_report',
    params: {
      'p_report_id': reportId,
      'p_status': status,
      'p_resolution_notes': notes,
    },
  );

  /// Insert message into Supabase database
  Future<TripMessage> sendMessage({
    required String bookingId,
    required String body,
    required String messageId,
    String? attachmentUrl,
  }) async {
    final response = await _client.rpc(
      'send_trip_message',
      params: {
        'p_booking_id': bookingId,
        'p_client_message_id': messageId,
        'p_body': body,
        'p_attachment_url': attachmentUrl,
      },
    );
    final rows = response as List;
    if (rows.isEmpty) {
      throw StateError('Message could not be reconciled after retry.');
    }
    return TripMessage.fromJson(Map<String, dynamic>.from(rows.first as Map));
  }

  /// Idempotently advances this user's compact read cursor to the latest
  /// server-authoritative message in the booking conversation.
  Future<void> markConversationRead(String bookingId) async {
    await _client.rpc(
      'mark_trip_conversation_read',
      params: {'p_conversation_id': bookingId},
    );
  }

  /// Get current user ID
  String? get currentUserId => _client.auth.currentUser?.id;

  Future<UploadedTripAttachment> uploadAttachment({
    required String bookingId,
    required String clientMessageId,
    required Uint8List bytes,
    required String fileName,
    String? reportedMimeType,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw StateError('Authentication is required.');
    if (bytes.isEmpty || bytes.length > 10 * 1024 * 1024) {
      throw ArgumentError('Attachment must be between 1 byte and 10 MB.');
    }
    final extension = _attachmentExtension(fileName, reportedMimeType);
    final mimeType = _attachmentMimeType(extension);
    final path = '$bookingId/$userId/$clientMessageId.$extension';
    await _client.storage
        .from('trip-attachments')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            upsert: false,
            contentType: mimeType,
            cacheControl: '3600',
          ),
        );
    return UploadedTripAttachment(
      storagePath: path,
      mimeType: mimeType,
      sizeBytes: bytes.length,
    );
  }

  Future<void> registerAttachment({
    required String messageId,
    required String storagePath,
    required String mimeType,
    required int sizeBytes,
  }) async {
    await _client.rpc(
      'register_trip_message_attachment',
      params: {
        'p_message_id': messageId,
        'p_storage_path': storagePath,
        'p_mime_type': mimeType,
        'p_size_bytes': sizeBytes,
      },
    );
  }

  Future<String> createAttachmentSignedUrl(String storagePath) => _client
      .storage
      .from('trip-attachments')
      .createSignedUrl(storagePath, 300);

  static String _attachmentExtension(String fileName, String? mimeType) {
    final extension = fileName.split('.').last.toLowerCase();
    if (extension == 'jpg' || extension == 'jpeg') return 'jpg';
    if (extension == 'png' || extension == 'webp' || extension == 'pdf') {
      return extension;
    }
    return switch (mimeType?.toLowerCase()) {
      'image/png' => 'png',
      'image/webp' => 'webp',
      'application/pdf' => 'pdf',
      'image/jpeg' => 'jpg',
      _ => throw ArgumentError('Unsupported attachment type.'),
    };
  }

  static String _attachmentMimeType(String extension) => switch (extension) {
    'png' => 'image/png',
    'webp' => 'image/webp',
    'pdf' => 'application/pdf',
    _ => 'image/jpeg',
  };

  static DateTime? _date(Object? value) =>
      value == null ? null : DateTime.tryParse(value.toString())?.toUtc();
}

class TripMessageReceiptSnapshot {
  const TripMessageReceiptSnapshot({
    required this.messageId,
    required this.isDelivered,
    required this.isSeen,
  });

  final String messageId;
  final bool isDelivered;
  final bool isSeen;
}

class TripMessageMutationSnapshot {
  const TripMessageMutationSnapshot({
    required this.messageId,
    this.effectiveBody,
    this.editedAt,
    this.deletedAt,
  });

  final String messageId;
  final String? effectiveBody;
  final DateTime? editedAt;
  final DateTime? deletedAt;
}

class UploadedTripAttachment {
  const UploadedTripAttachment({
    required this.storagePath,
    required this.mimeType,
    required this.sizeBytes,
  });

  final String storagePath;
  final String mimeType;
  final int sizeBytes;
}

class TripConversationSafety {
  const TripConversationSafety({
    required this.blockedByMe,
    required this.blockedMe,
    required this.canMessage,
  });

  factory TripConversationSafety.fromJson(Map<String, dynamic> json) =>
      TripConversationSafety(
        blockedByMe: json['blocked_by_me'] == true,
        blockedMe: json['blocked_me'] == true,
        canMessage: json['can_message'] == true,
      );

  final bool blockedByMe;
  final bool blockedMe;
  final bool canMessage;
}

class TripModerationReport {
  const TripModerationReport({
    required this.id,
    required this.status,
    required this.reason,
    required this.messageBody,
    required this.createdAt,
    this.details,
  });

  factory TripModerationReport.fromJson(Map<String, dynamic> json) =>
      TripModerationReport(
        id: json['report_id'].toString(),
        status: json['report_status'].toString(),
        reason: json['reason'].toString(),
        details: json['details']?.toString(),
        messageBody: json['effective_body']?.toString() ?? 'Message deleted',
        createdAt: DateTime.parse(json['created_at'].toString()).toUtc(),
      );

  final String id;
  final String status;
  final String reason;
  final String? details;
  final String messageBody;
  final DateTime createdAt;
}
