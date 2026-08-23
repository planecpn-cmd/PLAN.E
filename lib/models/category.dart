class Category {
  final String id;
  final String slug;
  final String nameEn;
  final String nameNe;
  final String? icon;
  final String? coverImageUrl;
  final String? familyId;
  final int sortOrder;
  final DateTime createdAt;

  const Category({
    required this.id,
    required this.slug,
    required this.nameEn,
    required this.nameNe,
    this.icon,
    this.coverImageUrl,
    this.familyId,
    this.sortOrder = 0,
    required this.createdAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      slug: json['slug'] as String,
      nameEn: json['name_en'] as String,
      nameNe: json['name_ne'] as String,
      icon: json['icon'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      familyId: json['family_id'] as String?,
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
      'icon': icon,
      'cover_image_url': coverImageUrl,
      'family_id': familyId,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Category copyWith({
    String? id,
    String? slug,
    String? nameEn,
    String? nameNe,
    String? icon,
    String? coverImageUrl,
    String? familyId,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      nameEn: nameEn ?? this.nameEn,
      nameNe: nameNe ?? this.nameNe,
      icon: icon ?? this.icon,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      familyId: familyId ?? this.familyId,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
