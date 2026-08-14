import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/theme.dart';
import '../../../widgets/widgets.dart';
import '../domain/host_mode_models.dart';
import 'host_mode_providers.dart';

class HostTravelerDetailScreen extends ConsumerWidget {
  const HostTravelerDetailScreen({
    super.key,
    required this.bookingId,
    required this.travelerId,
  });
  final String bookingId;
  final String travelerId;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Traveler Details')),
    backgroundColor: const Color(0xFFF7F8F5),
    body: AsyncValueView<HostBookingRequest?>(
      value: ref.watch(hostBookingProvider(bookingId)),
      data: (booking) {
        HostTraveler? traveler;
        for (final item in booking?.travelers ?? const <HostTraveler>[]) {
          if (item.id == travelerId) traveler = item;
        }
        if (traveler == null) {
          return const EmptyStateView(title: 'Traveler not found');
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 42,
                    backgroundColor: AppColors.forest,
                    child: Text(
                      traveler.name.characters.first,
                      style: const TextStyle(fontSize: 28, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(traveler.name, style: AppTypography.headingLarge),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AppCard(
              child: Column(
                children: [
                  _Row('Email', traveler.email),
                  const Divider(),
                  _Row('Phone', traveler.phone),
                  const Divider(),
                  _Row('Emergency contact', traveler.emergencyContact),
                  const Divider(),
                  _Row('Dietary notes', traveler.dietaryNotes),
                ],
              ),
            ),
            const SizedBox(height: 14),
            AppButton(
              label: 'Message traveler',
              icon: Icons.chat_bubble_outline,
              isFullWidth: true,
              onPressed: () => booking?.conversationId == null
                  ? context.go('/host/messages')
                  : context.push('/host/messages/${booking!.conversationId}'),
            ),
          ],
        );
      },
    ),
  );
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
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
