import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../theme/theme.dart';
import '../../../widgets/widgets.dart';
import '../domain/host_mode_models.dart';
import 'host_mode_providers.dart';
import 'widgets/host_mode_scaffold.dart';

class HostListingPreviewScreen extends ConsumerWidget {
  const HostListingPreviewScreen({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Traveler Listing Preview')),
    body: AsyncValueView<HostExperience?>(
      value: ref.watch(hostExperienceProvider(id)),
      data: (item) {
        if (item == null) {
          return const EmptyStateView(title: 'Experience not found');
        }
        return ListView(
          children: [
            Stack(
              children: [
                Image.asset(
                  item.imageAsset,
                  height: 280,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                const Positioned(
                  left: 16,
                  bottom: 14,
                  child: Chip(
                    avatar: Icon(Icons.visibility_outlined, size: 16),
                    label: Text('HOST PREVIEW'),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: AppTypography.displayMedium.copyWith(
                      fontFamily: 'serif',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 18),
                      const SizedBox(width: 5),
                      Text(item.location),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(item.summary, style: AppTypography.bodyLarge),
                  const Divider(height: 32),
                  const Text(
                    'Upcoming departure',
                    style: AppTypography.headingMedium,
                  ),
                  const SizedBox(height: 10),
                  AppCard(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_month_outlined,
                          color: AppColors.forest,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${DateFormat('d MMM').format(item.startDate)} – ${DateFormat('d MMM y').format(item.endDate)}',
                          ),
                        ),
                        Text(
                          '${item.capacity - item.bookedSpots} spots left',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.forest,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  AppButton(
                    label: 'Booking disabled in host preview',
                    isFullWidth: true,
                    onPressed: () => showUnavailableNotice(
                      context,
                      'Traveler booking from host preview',
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );
}
