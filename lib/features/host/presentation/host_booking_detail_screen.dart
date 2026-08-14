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

class HostBookingDetailScreen extends ConsumerWidget {
  const HostBookingDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booking Details')),
      backgroundColor: const Color(0xFFF7F8F5),
      body: AsyncValueView<HostBookingRequest?>(
        value: ref.watch(hostBookingProvider(id)),
        data: (item) {
          if (item == null) {
            return const EmptyStateView(title: 'Booking not found');
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: AppColors.sage,
                          child: Text(
                            item.travelerName.characters.first,
                            style: AppTypography.headingMedium.copyWith(
                              color: AppColors.forest,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.travelerName,
                                style: AppTypography.headingMedium,
                              ),
                              Text(
                                '${item.travelerCount} travelers',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.disabledText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 28),
                    _Detail(label: 'Experience', value: item.experienceTitle),
                    _Detail(
                      label: 'Dates',
                      value:
                          '${DateFormat('d MMM').format(item.tripStartDate)} – ${DateFormat('d MMM y').format(item.tripEndDate)}',
                    ),
                    _Detail(
                      label: 'Request total',
                      value:
                          'NPR ${NumberFormat('#,###').format(item.totalNpr)}',
                    ),
                    _Detail(label: 'Status', value: _status(item.status)),
                    _Detail(
                      label: 'Submitted',
                      value: DateFormat(
                        'd MMM y · h:mm a',
                      ).format(item.submittedAt),
                    ),
                  ],
                ),
              ),
              if (item.note != null) ...[
                const SizedBox(height: 12),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Traveler note',
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(item.note!, style: AppTypography.bodyMedium),
                    ],
                  ),
                ),
              ],
              if (item.applicationAnswers.isNotEmpty) ...[
                const SizedBox(height: 12),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Application answers',
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...item.applicationAnswers.entries.map(
                        (answer) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                answer.key,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.disabledText,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                answer.value,
                                style: AppTypography.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              AppButton.secondary(
                label: 'Message traveler',
                icon: Icons.chat_bubble_outline,
                isFullWidth: true,
                onPressed: () => item.conversationId == null
                    ? context.go('/host/messages')
                    : context.push('/host/messages/${item.conversationId}'),
              ),
              if (item.status == HostBookingStatus.confirmed) ...[
                const SizedBox(height: 10),
                AppButton(
                  label: 'View departure details',
                  icon: Icons.groups_2_outlined,
                  isFullWidth: true,
                  onPressed: () =>
                      context.push('/host/departures/${item.experienceId}'),
                ),
                const SizedBox(height: 10),
                AppButton.secondary(
                  label: 'Message departure group',
                  icon: Icons.forum_outlined,
                  isFullWidth: true,
                  onPressed: () => openHostDepartureConversation(
                    context,
                    ref,
                    item.experienceId,
                    item.experienceTitle,
                  ),
                ),
              ],
              if (item.status == HostBookingStatus.requested) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: AppButton.secondary(
                        label: 'Decline',
                        onPressed: () => _decide(context, ref, item, false),
                        isFullWidth: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AppButton(
                        label: 'Accept request',
                        onPressed: () => _decide(context, ref, item, true),
                        isFullWidth: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Accepting or declining requires backend authorization, capacity checks and an atomic booking update.',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.disabledText,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  String _status(HostBookingStatus status) => switch (status) {
    HostBookingStatus.requested => 'Pending review',
    HostBookingStatus.confirmed => 'Confirmed',
    HostBookingStatus.completed => 'Completed',
    HostBookingStatus.cancelled => 'Cancelled',
    HostBookingStatus.declined => 'Declined',
  };

  Future<void> _decide(
    BuildContext context,
    WidgetRef ref,
    HostBookingRequest item,
    bool accept,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${accept ? 'Accept' : 'Decline'} request?'),
        content: Text(
          accept
              ? 'This will confirm the booking request.'
              : 'This will decline the booking request.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(accept ? 'Accept' : 'Decline'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref
        .read(hostModeRepositoryProvider)
        .updateBookingStatus(
          item.id,
          accept ? HostBookingStatus.confirmed : HostBookingStatus.declined,
        );
    ref.invalidate(hostBookingProvider(item.id));
    ref.invalidate(hostBookingsProvider);
    ref.invalidate(hostDashboardProvider);
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          accept ? Icons.check_circle_outline : Icons.cancel_outlined,
          color: accept ? AppColors.success : AppColors.gold,
          size: 42,
        ),
        title: Text(accept ? 'Booking confirmed' : 'Request declined'),
        content: Text(
          '${item.travelerName} was updated in temporary frontend state. This change resets when the app restarts.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
    if (context.mounted) {
      context.go(
        accept
            ? '/host/bookings?status=confirmed'
            : '/host/bookings?status=cancelled',
      );
    }
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 105,
          child: Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.disabledText,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}
