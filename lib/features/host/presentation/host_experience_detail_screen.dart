import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../theme/theme.dart';
import '../../../widgets/widgets.dart';
import '../domain/host_mode_models.dart';
import 'host_conversation_navigation.dart';
import 'host_mode_providers.dart';
import 'widgets/host_mode_scaffold.dart';

class HostExperienceDetailScreen extends ConsumerWidget {
  const HostExperienceDetailScreen({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Manage Experience')),
    backgroundColor: const Color(0xFFF7F8F5),
    body: AsyncValueView<HostExperience?>(
      value: ref.watch(hostExperienceProvider(id)),
      data: (item) {
        if (item == null) {
          return const EmptyStateView(title: 'Experience not found');
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
          children: [
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: Image.asset(
                      item.imageAsset,
                      height: 190,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Padding(
                    padding: AppSpacing.paddingLg16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                style: AppTypography.headingLarge.copyWith(
                                  fontFamily: 'serif',
                                ),
                              ),
                            ),
                            _Status(status: item.status),
                          ],
                        ),
                        Text(
                          item.location,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.disabledText,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _Info(
                          Icons.calendar_month_outlined,
                          'Departure',
                          '${DateFormat('d MMM').format(item.startDate)} – ${DateFormat('d MMM y').format(item.endDate)}',
                        ),
                        _Info(
                          Icons.groups_outlined,
                          'Occupancy',
                          '${item.bookedSpots} of ${item.capacity} spots',
                        ),
                        _Info(
                          Icons.payments_outlined,
                          'Guest price',
                          'NPR ${NumberFormat('#,###').format(item.priceNpr)}',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            AppCard(
              child: Column(
                children: [
                  _Control(
                    icon: Icons.visibility_outlined,
                    label: 'Preview traveler listing',
                    onTap: () => context.push('/host/experiences/$id/preview'),
                  ),
                  const Divider(),
                  _Control(
                    icon: Icons.edit_outlined,
                    label: 'Edit experience',
                    onTap: () {
                      ref
                          .read(hostCreateExperienceProvider.notifier)
                          .seed(item);
                      context.push('/host/experiences/$id/edit');
                    },
                  ),
                  const Divider(),
                  _Control(
                    icon: Icons.calendar_month_outlined,
                    label: 'Manage dates & availability',
                    onTap: () =>
                        context.push('/host/experiences/$id/availability'),
                  ),
                  const Divider(),
                  _Control(
                    icon: Icons.groups_2_outlined,
                    label: 'View booking occupancy',
                    onTap: () => context.push('/host/departures/${item.id}'),
                  ),
                  const Divider(),
                  _Control(
                    icon: Icons.event_note_outlined,
                    label: 'View related bookings',
                    onTap: () => context.go(
                      '/host/bookings?experience=${item.id}&status=all',
                    ),
                  ),
                  const Divider(),
                  _Control(
                    icon: Icons.forum_outlined,
                    label: 'Message confirmed guests',
                    onTap: () => openHostDepartureConversation(
                      context,
                      ref,
                      item.id,
                      item.title,
                    ),
                  ),
                  const Divider(),
                  _Control(
                    icon: item.status == HostExperienceStatus.paused
                        ? Icons.play_circle_outline
                        : Icons.pause_circle_outline,
                    label: item.status == HostExperienceStatus.paused
                        ? 'Resume listing'
                        : 'Pause listing',
                    onTap: () => _toggle(context, ref, item),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );

  Future<void> _toggle(
    BuildContext context,
    WidgetRef ref,
    HostExperience item,
  ) async {
    final pause = item.status != HostExperienceStatus.paused;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${pause ? 'Pause' : 'Resume'} listing?'),
        content: Text(
          pause
              ? 'This will pause the listing for travelers.'
              : 'This will make the listing active again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(pause ? 'Pause' : 'Resume'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref
        .read(hostModeRepositoryProvider)
        .setExperiencePaused(item.id, pause);
    ref.invalidate(hostExperienceProvider(item.id));
    ref.invalidate(hostExperiencesProvider);
    ref.invalidate(hostDashboardProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${pause ? 'Paused' : 'Reactivated'} in temporary frontend state.',
          ),
        ),
      );
    }
  }
}

class _Control extends StatelessWidget {
  const _Control({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.forest),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.disabledText),
        ],
      ),
    ),
  );
}

class _Info extends StatelessWidget {
  const _Info(this.icon, this.label, this.value);
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Icon(icon, size: 18, color: AppColors.forest),
        const SizedBox(width: 9),
        Expanded(child: Text(label)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

class _Status extends StatelessWidget {
  const _Status({required this.status});
  final HostExperienceStatus status;
  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      HostExperienceStatus.active => 'Published',
      HostExperienceStatus.draft => 'Draft',
      HostExperienceStatus.pendingReview => 'Pending Review',
      HostExperienceStatus.paused => 'Paused',
    };
    return Chip(label: Text(label), visualDensity: VisualDensity.compact);
  }
}
