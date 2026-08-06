class TripMessage {
  final String id;
  final String bookingId;
  final String senderId;
  final String? senderName;
  final String body;
  final String? attachmentUrl;
  final DateTime createdAt;
  final bool isPending;
  final bool isFailed;

  const TripMessage({
    required this.id,
    required this.bookingId,
    required this.senderId,
    this.senderName,
    required this.body,
    this.attachmentUrl,
    required this.createdAt,
    this.isPending = false,
    this.isFailed = false,
  });

  factory TripMessage.fromJson(Map<String, dynamic> json) {
    String? senderDisplayName;
    if (json['profiles'] != null && json['profiles'] is Map<String, dynamic>) {
      senderDisplayName = json['profiles']['full_name'] as String?;
    }

    return TripMessage(
      id: json['id'] as String,
      bookingId: json['booking_id'] as String,
      senderId: json['sender_id'] as String,
      senderName: senderDisplayName ?? json['sender_name'] as String?,
      body: json['body'] as String? ?? '',
      attachmentUrl: json['attachment_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now().toUtc(),
      isPending: json['is_pending'] as bool? ?? false,
      isFailed: json['is_failed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_id': bookingId,
      'sender_id': senderId,
      'body': body,
      if (attachmentUrl != null) 'attachment_url': attachmentUrl,
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
    DateTime? createdAt,
    bool? isPending,
    bool? isFailed,
  }) {
    return TripMessage(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      body: body ?? this.body,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      createdAt: createdAt ?? this.createdAt,
      isPending: isPending ?? this.isPending,
      isFailed: isFailed ?? this.isFailed,
    );
  }
}
