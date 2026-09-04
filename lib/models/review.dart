import 'experience.dart';

class Review {
  final String id;
  final String? bookingId;
  final String experienceId;
  final String? userId;
  final int rating;
  final String? title;
  final String? body;
  final List<String> photos;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Experience? experience;

  const Review({
    required this.id,
    this.bookingId,
    required this.experienceId,
    this.userId,
    required this.rating,
    this.title,
    this.body,
    this.photos = const [],
    required this.createdAt,
    required this.updatedAt,
    this.experience,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    Experience? experience;
    if (json['experiences'] != null && json['experiences'] is Map<String, dynamic>) {
      experience = Experience.fromJson(json['experiences'] as Map<String, dynamic>);
    }

    return Review(
      id: json['id'] as String,
      bookingId: json['booking_id'] as String?,
      experienceId: json['experience_id'] as String,
      userId: json['user_id'] as String?,
      rating: (json['rating'] as num).toInt(),
      title: json['title'] as String?,
      body: json['body'] as String?,
      photos: (json['photos'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      experience: experience,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (bookingId != null) 'booking_id': bookingId,
      'experience_id': experienceId,
      if (userId != null) 'user_id': userId,
      'rating': rating,
      'title': title,
      'body': body,
      'photos': photos,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (experience != null) 'experiences': experience!.toJson(),
    };
  }

  Review copyWith({
    String? id,
    String? bookingId,
    String? experienceId,
    String? userId,
    int? rating,
    String? title,
    String? body,
    List<String>? photos,
    DateTime? createdAt,
    DateTime? updatedAt,
    Experience? experience,
  }) {
    return Review(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      experienceId: experienceId ?? this.experienceId,
      userId: userId ?? this.userId,
      rating: rating ?? this.rating,
      title: title ?? this.title,
      body: body ?? this.body,
      photos: photos ?? this.photos,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      experience: experience ?? this.experience,
    );
  }
}
