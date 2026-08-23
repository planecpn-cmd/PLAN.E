import 'package:flutter/material.dart';

import '../theme/theme.dart';

class ExperienceMood {
  final String label;
  final String subtitle;
  final IconData icon;
  final String familySlug;

  const ExperienceMood({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.familySlug,
  });
}

const experienceMoods = [
  ExperienceMood(
    label: 'Relax',
    subtitle: 'Slow down and recharge',
    icon: Icons.spa_outlined,
    familySlug: 'mind-soul',
  ),
  ExperienceMood(
    label: 'Explore',
    subtitle: 'See somewhere new',
    icon: Icons.route_outlined,
    familySlug: 'trips-tours',
  ),
  ExperienceMood(
    label: 'Learn',
    subtitle: 'Culture, crafts and skills',
    icon: Icons.lightbulb_outline,
    familySlug: 'live-like-a-local',
  ),
  ExperienceMood(
    label: 'Connect',
    subtitle: 'Meet people and communities',
    icon: Icons.people_outline,
    familySlug: 'meet-people',
  ),
  ExperienceMood(
    label: 'Taste',
    subtitle: 'Discover local food',
    icon: Icons.restaurant_outlined,
    familySlug: 'live-like-a-local',
  ),
  ExperienceMood(
    label: 'Help',
    subtitle: 'Make a local impact',
    icon: Icons.volunteer_activism_outlined,
    familySlug: 'give-back',
  ),
];

class ExperienceMoodGrid extends StatelessWidget {
  final ValueChanged<ExperienceMood> onSelected;

  const ExperienceMoodGrid({super.key, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - AppSpacing.sm8) / 2;
        return Wrap(
          spacing: AppSpacing.sm8,
          runSpacing: AppSpacing.sm8,
          children: experienceMoods
              .map(
                (mood) => SizedBox(
                  width: itemWidth,
                  child: Semantics(
                    button: true,
                    label: '${mood.label}. ${mood.subtitle}',
                    child: Material(
                      color: AppColors.white,
                      borderRadius: AppRadii.borderMd16,
                      child: InkWell(
                        onTap: () => onSelected(mood),
                        borderRadius: AppRadii.borderMd16,
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 68),
                          padding: const EdgeInsets.all(AppSpacing.md12),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.borderSubtle),
                            borderRadius: AppRadii.borderMd16,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  color: AppColors.sage,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  mood.icon,
                                  size: 21,
                                  color: AppColors.forest,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm8),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      mood.label,
                                      style: AppTypography.bodyMedium.copyWith(
                                        color: AppColors.ink,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      mood.subtitle,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.disabledText,
                                        height: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}
