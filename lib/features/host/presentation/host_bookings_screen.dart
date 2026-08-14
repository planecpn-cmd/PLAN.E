import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../theme/theme.dart';
import '../../../widgets/widgets.dart';
import '../domain/host_mode_models.dart';
import 'host_mode_providers.dart';
import 'widgets/host_mode_scaffold.dart';

class HostBookingsScreen extends ConsumerStatefulWidget {
  const HostBookingsScreen({
    super.key,
    this.initialFilter,
    this.hasInitialFilter = false,
    this.experienceId,
  });
  final HostBookingStatus? initialFilter;
  final bool hasInitialFilter;
  final String? experienceId;
  @override
  ConsumerState<HostBookingsScreen> createState() => _HostBookingsScreenState();
}

class _HostBookingsScreenState extends ConsumerState<HostBookingsScreen> {
  late HostBookingStatus? filter;
  @override
  void initState() {
    super.initState();
    filter = widget.hasInitialFilter
        ? widget.initialFilter
        : ref.read(hostBookingFilterProvider);
    if (widget.hasInitialFilter) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(hostBookingFilterProvider.notifier).state = filter;
        }
      });
    }
  }

  void _setFilter(HostBookingStatus? value) {
    ref.read(hostBookingFilterProvider.notifier).state = value;
    setState(() => filter = value);
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(hostBookingsProvider);
    return HostModeScaffold(
      currentIndex: 2,
      title: 'Bookings',
      body: AsyncValueView<List<HostBookingRequest>>(
        value: value,
        onRetry: () => ref.invalidate(hostBookingsProvider),
        data: (items) {
          final forExperience = widget.experienceId == null
              ? items
              : items
                    .where((item) => item.experienceId == widget.experienceId)
                    .toList();
          final visible = filter == null
              ? forExperience
              : forExperience
                    .where(
                      (item) => filter == HostBookingStatus.cancelled
                          ? item.status == HostBookingStatus.cancelled ||
                                item.status == HostBookingStatus.declined
                          : item.status == filter,
                    )
                    .toList();
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 144),
            children: [
              if (widget.experienceId != null) ...[
                const SizedBox(height: 10),
                AppCard(
                  backgroundColor: AppColors.sage,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.filter_alt_outlined,
                        color: AppColors.forest,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('Showing bookings for this experience'),
                      ),
                      TextButton(
                        onPressed: () => context.go('/host/bookings'),
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChipPill(
                      label: 'All',
                      isSelected: filter == null,
                      onSelected: (_) => _setFilter(null),
                    ),
                    const SizedBox(width: 8),
                    ...const [
                      HostBookingStatus.requested,
                      HostBookingStatus.confirmed,
                      HostBookingStatus.completed,
                      HostBookingStatus.cancelled,
                    ].map(
                      (status) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChipPill(
                          label: _statusLabel(status),
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
                const EmptyStateView(title: 'No bookings in this view')
              else
                ...visible.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _BookingCard(item: item),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

String _statusLabel(HostBookingStatus status) => switch (status) {
  HostBookingStatus.requested => 'Requests',
  HostBookingStatus.confirmed => 'Confirmed',
  HostBookingStatus.completed => 'Completed',
  HostBookingStatus.cancelled => 'Cancelled',
  HostBookingStatus.declined => 'Declined',
};

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.item});
  final HostBookingRequest item;
  @override
  Widget build(BuildContext context) => AppCard(
    onTap: () => context.push('/host/bookings/${item.id}'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.sage,
              child: Text(
                item.travelerName.characters.first,
                style: const TextStyle(
                  color: AppColors.forest,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.travelerName,
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${item.travelerCount} ${item.travelerCount == 1 ? 'traveler' : 'travelers'}',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.disabledText,
                    ),
                  ),
                ],
              ),
            ),
            _BookingStatus(status: item.status),
          ],
        ),
        const Divider(height: 24),
        Text(
          item.experienceTitle,
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(
              Icons.calendar_month_outlined,
              size: 16,
              color: AppColors.forest,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '${DateFormat('d MMM').format(item.tripStartDate)} – ${DateFormat('d MMM y').format(item.tripEndDate)}',
                style: AppTypography.caption,
              ),
            ),
            Text(
              'NPR ${NumberFormat('#,###').format(item.totalNpr)}',
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _BookingStatus extends StatelessWidget {
  const _BookingStatus({required this.status});
  final HostBookingStatus status;
  @override
  Widget build(BuildContext context) {
    final color = status == HostBookingStatus.requested
        ? AppColors.gold
        : status == HostBookingStatus.confirmed
        ? AppColors.success
        : AppColors.disabledText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: AppRadii.borderPill,
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
