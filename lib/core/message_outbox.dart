import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

enum MessageSenderMode { traveler, host }

class OutboxMessage {
  const OutboxMessage({
    required this.clientMessageId,
    required this.conversationId,
    required this.userId,
    required this.senderMode,
    required this.body,
    required this.createdAt,
    this.attachmentUrl,
    this.attachmentMimeType,
    this.attachmentSizeBytes,
    this.isFailed = false,
  });

  final String clientMessageId;
  final String conversationId;
  final String userId;
  final MessageSenderMode senderMode;
  final String body;
  final String? attachmentUrl;
  final String? attachmentMimeType;
  final int? attachmentSizeBytes;
  final DateTime createdAt;
  final bool isFailed;

  OutboxMessage copyWith({bool? isFailed}) => OutboxMessage(
    clientMessageId: clientMessageId,
    conversationId: conversationId,
    userId: userId,
    senderMode: senderMode,
    body: body,
    attachmentUrl: attachmentUrl,
    attachmentMimeType: attachmentMimeType,
    attachmentSizeBytes: attachmentSizeBytes,
    createdAt: createdAt,
    isFailed: isFailed ?? this.isFailed,
  );

  Map<String, dynamic> toJson() => {
    'client_message_id': clientMessageId,
    'conversation_id': conversationId,
    'user_id': userId,
    'sender_mode': senderMode.name,
    'body': body,
    if (attachmentUrl != null) 'attachment_url': attachmentUrl,
    if (attachmentMimeType != null) 'attachment_mime_type': attachmentMimeType,
    if (attachmentSizeBytes != null)
      'attachment_size_bytes': attachmentSizeBytes,
    'created_at': createdAt.toUtc().toIso8601String(),
    'is_failed': isFailed,
  };

  factory OutboxMessage.fromJson(Map<String, dynamic> json) => OutboxMessage(
    clientMessageId: json['client_message_id'] as String,
    conversationId: json['conversation_id'] as String,
    userId: json['user_id'] as String,
    senderMode: MessageSenderMode.values.byName(json['sender_mode'] as String),
    body: json['body'] as String,
    attachmentUrl: json['attachment_url'] as String?,
    attachmentMimeType: json['attachment_mime_type'] as String?,
    attachmentSizeBytes: json['attachment_size_bytes'] as int?,
    createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
    isFailed: json['is_failed'] as bool? ?? false,
  );
}

/// Durable, user-scoped queue backed by SharedPreferences (native persistent
/// storage on mobile and IndexedDB/local storage through the web plugin).
class MessageOutboxStore {
  const MessageOutboxStore._();

  static const _prefix = 'message_outbox:';
  static Future<void> _writeQueue = Future.value();

  static Future<List<OutboxMessage>> loadConversation({
    required String userId,
    required String conversationId,
    required MessageSenderMode senderMode,
  }) async {
    await _writeQueue;
    final all = await _loadUser(userId);
    return all
        .where(
          (item) =>
              item.conversationId == conversationId &&
              item.senderMode == senderMode,
        )
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  static Future<void> upsert(OutboxMessage message) => _serialize(() async {
    final all = await _loadUser(message.userId);
    final index = all.indexWhere(
      (item) => item.clientMessageId == message.clientMessageId,
    );
    if (index == -1) {
      all.add(message);
    } else {
      all[index] = message;
    }
    await _writeUser(message.userId, all);
  });

  static Future<void> remove({
    required String userId,
    required String clientMessageId,
  }) => _serialize(() async {
    final all = await _loadUser(userId);
    all.removeWhere((item) => item.clientMessageId == clientMessageId);
    await _writeUser(userId, all);
  });

  static Future<void> clearUser(String userId) => _serialize(() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$userId');
  });

  static Future<void> _serialize(Future<void> Function() operation) {
    final result = _writeQueue.then((_) async {
      try {
        await operation();
      } catch (_) {
        // A full/unavailable local store must not prevent an online message
        // from being sent. Durability degrades safely for this one write.
      }
    });
    _writeQueue = result;
    return result;
  }

  static Future<List<OutboxMessage>> _loadUser(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_prefix$userId');
      if (raw == null) return [];
      return (jsonDecode(raw) as List)
          .map(
            (item) =>
                OutboxMessage.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _writeUser(
    String userId,
    List<OutboxMessage> messages,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_prefix$userId',
      jsonEncode(messages.map((message) => message.toJson()).toList()),
    );
  }
}
