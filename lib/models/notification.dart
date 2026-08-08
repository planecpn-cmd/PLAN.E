enum NotificationType {
  booking,
  chat,
  hostApplication,
  system,
  promo;

  static NotificationType fromString(String? value) {
    switch (value) {
      case 'booking':
        return NotificationType.booking;
      case 'chat':
        return NotificationType.chat;
      case 'host_application':
        return NotificationType.hostApplication;
      case 'promo':
        return NotificationType.promo;
      case 'system':
      default:
        return NotificationType.system;
    }
  }
}

class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final String? entityId;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.entityId,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      type: NotificationType.fromString(json['type'] as String?),
      title: json['title'] as String,
      body: json['body'] as String,
      entityId: json['entity_id'] as String?,
      isRead: (json['is_read'] as bool?) ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
