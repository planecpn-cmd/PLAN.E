import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../theme/theme.dart';
import '../../../widgets/widgets.dart';
import '../domain/host_mode_models.dart';
import 'host_conversation_navigation.dart';
import 'host_mode_providers.dart';

class HostDepartureDetailScreen extends ConsumerWidget {
  const HostDepartureDetailScreen({super.key, required this.experienceId});
  final String experienceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final experience = ref.watch(hostExperienceProvider(experienceId));
    final bookings = ref.watch(hostBookingsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Departure Details')),
      backgroundColor: const Color(0xFFF7F8F5),
      body: experience.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorStateView(message: error.toString()),
        data: (item) {
          if (item == null) {
            return const EmptyStateView(title: 'Departure not found');
          }
          final confirmed =
              bookings.asData?.value
                  .where(
                    (booking) =>
                        booking.experienceId == experienceId &&
                        booking.status == HostBookingStatus.confirmed,
                  )
                  .toList() ??
              const <HostBookingRequest>[];
          final guestCount = confirmed.fold<int>(
            0,
            (sum, booking) => sum + booking.travelerCount,
          );
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: AppTypography.headingMedium),
                    const SizedBox(height: 7),
                    _Row(
                      Icons.calendar_month_outlined,
                      '${DateFormat('d MMM').format(item.startDate)} – ${DateFormat('d MMM y').format(item.endDate)}',
                    ),
                    _Row(Icons.location_on_outlined, item.location),
                    _Row(
                      Icons.groups_outlined,
                      '$guestCount of ${item.capacity} guests confirmed',
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: item.capacity == 0
                          ? 0
                          : guestCount / item.capacity,
                      minHeight: 7,
                      backgroundColor: AppColors.sage,
                      color: AppColors.forest,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              AppButton(
                label: 'View participant list',
                icon: Icons.groups_2_outlined,
                isFullWidth: true,
                onPressed: () =>
                    context.push('/host/departures/$experienceId/guests'),
              ),
              const SizedBox(height: 10),
              AppButton.secondary(
                label: 'Message departure group',
                icon: Icons.forum_outlined,
                isFullWidth: true,
                onPressed: () => openHostDepartureConversation(
                  context,
                  ref,
                  item.id,
                  item.title,
                ),
              ),
              const SizedBox(height: 10),
              AppButton.secondary(
                label: 'Update departure availability',
                icon: Icons.edit_calendar_outlined,
                isFullWidth: true,
                onPressed: () => context.push(
                  '/host/experiences/$experienceId/availability',
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.icon, this.text);
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Icon(icon, size: 18, color: AppColors.forest),
        const SizedBox(width: 9),
        Expanded(child: Text(text)),
      ],
    ),
  );
}
