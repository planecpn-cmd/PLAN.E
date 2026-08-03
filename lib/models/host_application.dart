enum HostAppStatus {
  draft,
  submitted,
  underReview,
  verification,
  approved,
  rejected;

  static HostAppStatus fromString(String? value) {
    switch (value) {
      case 'submitted':
        return HostAppStatus.submitted;
      case 'under_review':
        return HostAppStatus.underReview;
      case 'verification':
        return HostAppStatus.verification;
      case 'approved':
        return HostAppStatus.approved;
      case 'rejected':
        return HostAppStatus.rejected;
      case 'draft':
      default:
        return HostAppStatus.draft;
    }
  }

  String toJson() {
    switch (this) {
      case HostAppStatus.submitted:
        return 'submitted';
      case HostAppStatus.underReview:
        return 'under_review';
      case HostAppStatus.verification:
        return 'verification';
      case HostAppStatus.approved:
        return 'approved';
      case HostAppStatus.rejected:
        return 'rejected';
      case HostAppStatus.draft:
        return 'draft';
    }
  }
}

class HostApplication {
  final String id;
  final String userId;
  final HostAppStatus status;
  final int currentStep;
  final String? categoryId;
  final String? title;
  final String? description;
  final String? location;
  final List<String> photos;
  final String? verificationDocPath;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final String? reviewerNote;
  final DateTime createdAt;
  final DateTime updatedAt;

  const HostApplication({
    required this.id,
    required this.userId,
    this.status = HostAppStatus.draft,
    this.currentStep = 1,
    this.categoryId,
    this.title,
    this.description,
    this.location,
    this.photos = const [],
    this.verificationDocPath,
    this.submittedAt,
    this.reviewedAt,
    this.reviewerNote,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HostApplication.fromJson(Map<String, dynamic> json) {
    return HostApplication(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      status: HostAppStatus.fromString(json['status'] as String?),
      currentStep: (json['current_step'] as num?)?.toInt() ?? 1,
      categoryId: json['category_id'] as String?,
      title: json['title'] as String?,
      description: json['description'] as String?,
      location: json['location'] as String?,
      photos: (json['photos'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      verificationDocPath: json['verification_doc_path'] as String?,
      submittedAt: json['submitted_at'] != null
          ? DateTime.parse(json['submitted_at'] as String)
          : null,
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'] as String)
          : null,
      reviewerNote: json['reviewer_note'] as String?,
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
      'user_id': userId,
      'status': status.toJson(),
      'current_step': currentStep,
      'category_id': categoryId,
      'title': title,
      'description': description,
      'location': location,
      'photos': photos,
      'verification_doc_path': verificationDocPath,
      'submitted_at': submittedAt?.toIso8601String(),
      'reviewed_at': reviewedAt?.toIso8601String(),
      'reviewer_note': reviewerNote,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  HostApplication copyWith({
    String? id,
    String? userId,
    HostAppStatus? status,
    int? currentStep,
    String? categoryId,
    String? title,
    String? description,
    String? location,
    List<String>? photos,
    String? verificationDocPath,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    String? reviewerNote,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HostApplication(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      currentStep: currentStep ?? this.currentStep,
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      photos: photos ?? this.photos,
      verificationDocPath: verificationDocPath ?? this.verificationDocPath,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewerNote: reviewerNote ?? this.reviewerNote,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
