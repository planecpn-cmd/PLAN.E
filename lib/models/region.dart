class Region {
  final String id;
  final String slug;
  final String nameEn;
  final String nameNe;
  final String? coverImageUrl;
  final String? description;
  final int sortOrder;
  final DateTime createdAt;

  const Region({
    required this.id,
    required this.slug,
    required this.nameEn,
    required this.nameNe,
    this.coverImageUrl,
    this.description,
    this.sortOrder = 0,
    required this.createdAt,
  });

  factory Region.fromJson(Map<String, dynamic> json) {
    return Region(
      id: json['id'] as String,
      slug: json['slug'] as String,
      nameEn: json['name_en'] as String,
      nameNe: json['name_ne'] as String,
      coverImageUrl: json['cover_image_url'] as String?,
      description: json['description'] as String?,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'slug': slug,
      'name_en': nameEn,
      'name_ne': nameNe,
      'cover_image_url': coverImageUrl,
      'description': description,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Region copyWith({
    String? id,
    String? slug,
    String? nameEn,
    String? nameNe,
    String? coverImageUrl,
    String? description,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return Region(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      nameEn: nameEn ?? this.nameEn,
      nameNe: nameNe ?? this.nameNe,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      description: description ?? this.description,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
