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

class HostGuestListScreen extends ConsumerWidget {
  const HostGuestListScreen({super.key, required this.experienceId});
  final String experienceId;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Departure Guest List')),
    backgroundColor: const Color(0xFFF7F8F5),
    body: AsyncValueView<List<HostBookingRequest>>(
      value: ref.watch(hostBookingsProvider),
      data: (all) {
        final bookings = all
            .where(
              (b) =>
                  b.experienceId == experienceId &&
                  b.status == HostBookingStatus.confirmed,
            )
            .toList();
        final first = bookings.firstOrNull;
        final travelers = bookings
            .expand(
              (b) => b.travelers.map(
                (traveler) => (booking: b, traveler: traveler),
              ),
            )
            .toList();
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (first != null)
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      first.experienceTitle,
                      style: AppTypography.headingMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('d MMMM y').format(first.tripStartDate),
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.disabledText,
                      ),
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: travelers.length / 8,
                      minHeight: 7,
                      backgroundColor: AppColors.sage,
                      color: AppColors.forest,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${travelers.length} confirmed guests',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 14),
            HostSectionHeader(
              title: 'Confirmed travelers',
              action: 'Message group',
              onAction: () => openHostDepartureConversation(
                context,
                ref,
                experienceId,
                first?.experienceTitle ?? 'Departure',
              ),
            ),
            const SizedBox(height: 8),
            if (travelers.isEmpty)
              const EmptyStateView(title: 'No confirmed travelers')
            else
              ...travelers.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    onTap: () => context.push(
                      '/host/bookings/${entry.booking.id}/travelers/${entry.traveler.id}',
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.sage,
                          child: Text(
                            entry.traveler.name.characters.first,
                            style: const TextStyle(
                              color: AppColors.forest,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.traveler.name,
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                entry.traveler.dietaryNotes,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.disabledText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: AppColors.disabledText,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
