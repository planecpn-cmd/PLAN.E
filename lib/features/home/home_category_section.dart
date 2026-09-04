import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/experience.dart';
import '../../models/experience_family.dart';
import '../../theme/theme.dart';
import '../../widgets/section_header.dart';
import 'home_discovery.dart';

/// One interaction for every Home family: overview → filter → overview.
class HomeCategorySection extends StatefulWidget {
  final HomeSectionSpec spec;
  final List<Experience> experiences;
  final ExperienceTaxonomy? taxonomy;
  final Widget Function(Experience, double) cardBuilder;

  const HomeCategorySection({
    super.key,
    required this.spec,
    required this.experiences,
    required this.taxonomy,
    required this.cardBuilder,
  });

  @override
  State<HomeCategorySection> createState() => _HomeCategorySectionState();
}

class _HomeCategorySectionState extends State<HomeCategorySection> {
  HomeFilter? _selected;

  void _seeAll() {
    final filter = _selected;
    final categories = widget.taxonomy?.categoriesById.values
        .where(
          (category) => filter?.categories.contains(category.slug) ?? false,
        )
        .toList();
    // Only pass an exact category when it represents the entire filter.
    if (filter != null &&
        filter.categories.length == 1 &&
        filter.terms.isEmpty &&
        categories?.length == 1) {
      context.push(
        Uri(
          path: '/search',
          queryParameters: {'category_id': categories!.single.id},
        ).toString(),
      );
    } else {
      context.push('/collection/${widget.spec.slug}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final groups = {
      for (final filter in widget.spec.filters)
        filter: widget.experiences
            .where((experience) => filter.matches(experience, widget.taxonomy))
            .toList(growable: false),
    };
    final selected = (groups[_selected]?.isNotEmpty ?? false)
        ? _selected
        : null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: widget.spec.title,
            actionLabel: 'See All',
            onActionTap: _seeAll,
          ),
          Text(
            widget.spec.description,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.ink),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final filter in widget.spec.filters)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(filter.label),
                      selected: selected == filter,
                      selectedColor: AppColors.sage,
                      checkmarkColor: AppColors.forest,
                      labelStyle: AppTypography.bodyMedium.copyWith(
                        color: AppColors.forest,
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.padded,
                      onSelected: groups[filter]!.isEmpty
                          ? null
                          : (_) => setState(
                              () => _selected = selected == filter
                                  ? null
                                  : filter,
                            ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (selected != null) ...[
            SectionHeader(
              title: 'Most Popular',
              actionLabel: 'Overview',
              onActionTap: () => setState(() => _selected = null),
            ),
            const SizedBox(height: 8),
          ],
          LayoutBuilder(
            builder: (context, constraints) {
              final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
              final cardWidth = (200 * scale).clamp(200.0, 340.0);
              final entries = selected == null
                  ? [
                      for (final filter in widget.spec.filters)
                        if (groups[filter]!.isNotEmpty)
                          (filter.label, groups[filter]!.first),
                    ]
                  : [
                      for (final experience in groups[selected]!)
                        (selected.label, experience),
                    ];
              if (entries.isEmpty) {
                return const SizedBox.shrink();
              }
              return SizedBox(
                height: cardWidth * 1.5,
                child: GridView.builder(
                  key: ValueKey(
                    '${widget.spec.slug}-${selected?.label ?? 'overview'}',
                  ),
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.zero,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 1,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        widget.cardBuilder(entry.$2, cardWidth),
                        if (selected == null)
                          Positioned(
                            top: 8,
                            left: 8,
                            child: IgnorePointer(
                              child: Container(
                                constraints: BoxConstraints(
                                  maxWidth: cardWidth - 68,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: const BoxDecoration(
                                  color: AppColors.forest,
                                  borderRadius: AppRadii.borderSm8,
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    entry.$1,
                                    maxLines: 1,
                                    softWrap: false,
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
