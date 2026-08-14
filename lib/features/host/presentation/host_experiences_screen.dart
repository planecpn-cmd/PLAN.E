import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../theme/theme.dart';
import '../../../widgets/widgets.dart';
import '../domain/host_mode_models.dart';
import 'host_mode_providers.dart';
import 'widgets/host_mode_scaffold.dart';

class HostExperiencesScreen extends ConsumerStatefulWidget {
  const HostExperiencesScreen({
    super.key,
    this.initialFilter,
    this.hasInitialFilter = false,
  });
  final HostExperienceStatus? initialFilter;
  final bool hasInitialFilter;
  @override
  ConsumerState<HostExperiencesScreen> createState() =>
      _HostExperiencesScreenState();
}

class _HostExperiencesScreenState extends ConsumerState<HostExperiencesScreen> {
  late HostExperienceStatus? filter;

  @override
  void initState() {
    super.initState();
    filter = widget.hasInitialFilter
        ? widget.initialFilter
        : ref.read(hostExperienceFilterProvider);
    if (widget.hasInitialFilter) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(hostExperienceFilterProvider.notifier).state = filter;
        }
      });
    }
  }

  void _setFilter(HostExperienceStatus? value) {
    ref.read(hostExperienceFilterProvider.notifier).state = value;
    setState(() => filter = value);
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(hostExperiencesProvider);
    return HostModeScaffold(
      currentIndex: 1,
      title: 'Experiences',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ref.read(hostCreateExperienceProvider.notifier).reset();
          context.push('/host/experiences/create');
        },
        icon: const Icon(Icons.add),
        label: const Text('Create'),
      ),
      body: AsyncValueView<List<HostExperience>>(
        value: value,
        onRetry: () => ref.invalidate(hostExperiencesProvider),
        data: (items) {
          final visible = filter == null
              ? items
              : items.where((item) => item.status == filter).toList();
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 144),
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChipPill(
                      label: 'All (${items.length})',
                      isSelected: filter == null,
                      onSelected: (_) => _setFilter(null),
                    ),
                    const SizedBox(width: 8),
                    ...HostExperienceStatus.values.map(
                      (status) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChipPill(
                          label: _label(status),
                          isSelected: filter == status,
                          onSelected: (_) => _setFilter(status),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (visible.isEmpty)
                const EmptyStateView(title: 'No experiences here')
              else
                ...visible.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ExperienceListCard(item: item),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _label(HostExperienceStatus status) => switch (status) {
    HostExperienceStatus.active => 'Published',
    HostExperienceStatus.draft => 'Drafts',
    HostExperienceStatus.pendingReview => 'Pending Review',
    HostExperienceStatus.paused => 'Paused',
  };
}

class _ExperienceListCard extends StatelessWidget {
  const _ExperienceListCard({required this.item});
  final HostExperience item;
  @override
  Widget build(BuildContext context) => AppCard(
    onTap: () => context.push('/host/experiences/${item.id}'),
    padding: const EdgeInsets.all(12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: AppRadii.borderSm8,
          child: Image.asset(
            item.imageAsset,
            width: 92,
            height: 92,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _StatusChip(status: item.status),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                item.location,
                style: AppTypography.caption.copyWith(
                  color: AppColors.disabledText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${DateFormat('d MMM').format(item.startDate)} · ${item.bookedSpots}/${item.capacity} booked',
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.forest,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'NPR ${NumberFormat('#,###').format(item.priceNpr)} per guest',
                style: AppTypography.caption.copyWith(
                  color: AppColors.disabledText,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final HostExperienceStatus status;
  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      HostExperienceStatus.active => ('Published', AppColors.success),
      HostExperienceStatus.draft => ('Draft', AppColors.gold),
      HostExperienceStatus.pendingReview => (
        'Pending Review',
        AppColors.warning,
      ),
      HostExperienceStatus.paused => ('Paused', AppColors.disabledText),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: AppRadii.borderPill,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
