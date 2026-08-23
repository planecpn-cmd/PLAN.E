import '../models/experience.dart';
import '../models/experience_family.dart';
import 'format.dart';

bool familySupportsDifficulty(String? familySlug) =>
    familySlug == 'adventure-together';

class ExperiencePresentation {
  final String? familySlug;
  final String? familyLabel;
  final String? typeLabel;
  final String detailText;

  const ExperiencePresentation({
    this.familySlug,
    this.familyLabel,
    this.typeLabel,
    required this.detailText,
  });

  factory ExperiencePresentation.from(
    Experience experience,
    ExperienceTaxonomy? taxonomy,
  ) {
    final category = taxonomy?.categoryFor(experience.categoryId);
    final family = taxonomy?.familyFor(experience.categoryId);
    final details = <String>[
      AppFormatters.formatDuration(experience.durationHours),
      if (familySupportsDifficulty(family?.slug))
        _titleCase(experience.difficulty.name),
    ];
    return ExperiencePresentation(
      familySlug: family?.slug,
      familyLabel: family?.nameEn,
      typeLabel: category?.nameEn,
      detailText: details.join(' • '),
    );
  }

  static String _titleCase(String value) =>
      value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';
}
