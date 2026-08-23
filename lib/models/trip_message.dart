class TripMessage {
  final String id;
  final String bookingId;
  final String senderId;
  final String? senderName;
  final String body;
  final String? attachmentUrl;
  final String? attachmentMimeType;
  final int? attachmentSizeBytes;
  final DateTime createdAt;
  final bool isPending;
  final bool isFailed;
  final bool isDelivered;
  final bool isSeen;
  final DateTime? editedAt;
  final DateTime? deletedAt;

  const TripMessage({
    required this.id,
    required this.bookingId,
    required this.senderId,
    this.senderName,
    required this.body,
    this.attachmentUrl,
    this.attachmentMimeType,
    this.attachmentSizeBytes,
    required this.createdAt,
    this.isPending = false,
    this.isFailed = false,
    this.isDelivered = false,
    this.isSeen = false,
    this.editedAt,
    this.deletedAt,
  });

  factory TripMessage.fromJson(Map<String, dynamic> json) {
    String? senderDisplayName;
    if (json['profiles'] != null && json['profiles'] is Map<String, dynamic>) {
      senderDisplayName = json['profiles']['full_name'] as String?;
    }

    final receipts = json['trip_message_receipts'];
    final receiptRows = receipts is List
        ? receipts
              .whereType<Map<String, dynamic>>()
              .map(Map<String, dynamic>.from)
              .toList()
        : const <Map<String, dynamic>>[];
    final mutations = json['trip_message_mutations'];
    final mutationRows = mutations is List
        ? mutations.whereType<Map<String, dynamic>>().toList()
        : const <Map<String, dynamic>>[];
    final mutation = mutationRows.firstOrNull;
    final deletedAt = _date(mutation?['deleted_at']);
    final editedAt = _date(mutation?['edited_at']);
    final effectiveBody = mutation?['effective_body'] as String?;

    return TripMessage(
      id: json['id'] as String,
      bookingId: json['booking_id'] as String,
      senderId: json['sender_id'] as String,
      senderName: senderDisplayName ?? json['sender_name'] as String?,
      body: deletedAt != null
          ? 'Message deleted'
          : effectiveBody ?? json['body'] as String? ?? '',
      attachmentUrl: deletedAt == null
          ? json['attachment_url'] as String?
          : null,
      attachmentMimeType: json['attachment_mime_type'] as String?,
      attachmentSizeBytes: json['attachment_size_bytes'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String).toUtc()
          : DateTime.now().toUtc(),
      isPending: json['is_pending'] as bool? ?? false,
      isFailed: json['is_failed'] as bool? ?? false,
      isDelivered: receiptRows.any((row) => row['delivered_at'] != null),
      isSeen: receiptRows.any((row) => row['seen_at'] != null),
      editedAt: editedAt,
      deletedAt: deletedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_id': bookingId,
      'sender_id': senderId,
      'body': body,
      if (attachmentUrl != null) 'attachment_url': attachmentUrl,
      if (attachmentMimeType != null)
        'attachment_mime_type': attachmentMimeType,
      if (attachmentSizeBytes != null)
        'attachment_size_bytes': attachmentSizeBytes,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }

  TripMessage copyWith({
    String? id,
    String? bookingId,
    String? senderId,
    String? senderName,
    String? body,
    String? attachmentUrl,
    String? attachmentMimeType,
    int? attachmentSizeBytes,
    DateTime? createdAt,
    bool? isPending,
    bool? isFailed,
    bool? isDelivered,
    bool? isSeen,
    DateTime? editedAt,
    DateTime? deletedAt,
  }) {
    return TripMessage(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      body: body ?? this.body,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      attachmentMimeType: attachmentMimeType ?? this.attachmentMimeType,
      attachmentSizeBytes: attachmentSizeBytes ?? this.attachmentSizeBytes,
      createdAt: createdAt ?? this.createdAt,
      isPending: isPending ?? this.isPending,
      isFailed: isFailed ?? this.isFailed,
      isDelivered: isDelivered ?? this.isDelivered,
      isSeen: isSeen ?? this.isSeen,
      editedAt: editedAt ?? this.editedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  TripMessage withMutation({
    String? effectiveBody,
    DateTime? editedAt,
    DateTime? deletedAt,
  }) => TripMessage(
    id: id,
    bookingId: bookingId,
    senderId: senderId,
    senderName: senderName,
    body: deletedAt == null ? effectiveBody ?? body : 'Message deleted',
    attachmentUrl: deletedAt == null ? attachmentUrl : null,
    attachmentMimeType: deletedAt == null ? attachmentMimeType : null,
    attachmentSizeBytes: deletedAt == null ? attachmentSizeBytes : null,
    createdAt: createdAt,
    isPending: isPending,
    isFailed: isFailed,
    isDelivered: isDelivered,
    isSeen: isSeen,
    editedAt: editedAt ?? this.editedAt,
    deletedAt: deletedAt ?? this.deletedAt,
  );

  bool get isEdited => editedAt != null;
  bool get isDeleted => deletedAt != null;

  static DateTime? _date(Object? value) =>
      value == null ? null : DateTime.tryParse(value.toString())?.toUtc();
}
