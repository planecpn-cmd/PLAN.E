enum UserRole {
  traveler,
  hostApplicant,
  host,
  admin;

  static UserRole fromString(String? value) {
    switch (value) {
      case 'host_applicant':
        return UserRole.hostApplicant;
      case 'host':
        return UserRole.host;
      case 'admin':
        return UserRole.admin;
      case 'traveler':
      default:
        return UserRole.traveler;
    }
  }

  String toJson() {
    switch (this) {
      case UserRole.hostApplicant:
        return 'host_applicant';
      case UserRole.host:
        return 'host';
      case UserRole.admin:
        return 'admin';
      case UserRole.traveler:
        return 'traveler';
    }
  }
}

class Profile {
  final String id;
  final String? fullName;
  final String? phone;
  final String? avatarUrl;
  final String? location;
  final String? bio;
  final UserRole role;
  final String language;
  final int points;
  final bool onboardingComplete;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Profile({
    required this.id,
    this.fullName,
    this.phone,
    this.avatarUrl,
    this.location,
    this.bio,
    this.role = UserRole.traveler,
    this.language = 'en',
    this.points = 0,
    this.onboardingComplete = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      fullName: json['full_name'] as String?,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      location: json['location'] as String?,
      bio: json['bio'] as String?,
      role: UserRole.fromString(json['role'] as String?),
      language: (json['language'] as String?) ?? 'en',
      points: (json['points'] as num?)?.toInt() ?? 0,
      onboardingComplete: (json['onboarding_complete'] as bool?) ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'phone': phone,
      'avatar_url': avatarUrl,
      'location': location,
      'bio': bio,
      'role': role.toJson(),
      'language': language,
      'points': points,
      'onboarding_complete': onboardingComplete,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Profile copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? avatarUrl,
    String? location,
    String? bio,
    UserRole? role,
    String? language,
    int? points,
    bool? onboardingComplete,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Profile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      location: location ?? this.location,
      bio: bio ?? this.bio,
      role: role ?? this.role,
      language: language ?? this.language,
      points: points ?? this.points,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
