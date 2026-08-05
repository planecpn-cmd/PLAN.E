// PL-15 / PL-16 My Trips
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../l10n/app_localizations.dart';
import '../../models/booking.dart';
import '../../providers/app_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';

class TripsScreen extends ConsumerStatefulWidget {
  const TripsScreen({super.key});

  @override
  ConsumerState<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends ConsumerState<TripsScreen> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final List<String> tabs = [l10n.completed, l10n.cancelled];
    final String statusQuery = _selectedTabIndex == 0 ? 'completed' : 'cancelled';
    final bookingsAsync = ref.watch(bookingsProvider(statusQuery));

    return Scaffold(
      body: PlanEBackground(
        safeArea: false,
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Text(
                  l10n.myTrips,
                  style: const TextStyle(
                    fontFamily: 'serif',
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.forest,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AppTabs(
                  tabs: tabs,
                  selectedIndex: _selectedTabIndex,
                  onTabSelected: (index) {
                    setState(() {
                      _selectedTabIndex = index;
                    });
                  },
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.forest,
                  onRefresh: () async {
                    ref.invalidate(bookingsProvider(statusQuery));
                  },
                  child: AsyncValueView<List<Booking>>(
                    value: bookingsAsync,
                    isEmpty: (data) => data.isEmpty,
                    emptyView: EmptyStateView(
                      title: _selectedTabIndex == 0 ? 'No Completed Trips' : 'No Cancelled Trips',
                      description: _selectedTabIndex == 0
                          ? 'Trips you complete will be listed here with memories & review options.'
                          : 'Any cancelled trip reservations will be shown here.',
                      actionLabel: l10n.exploreExperiences,
                      onActionPressed: () => context.go('/explore'),
                    ),
                    onRetry: () => ref.invalidate(bookingsProvider(statusQuery)),
                    data: (bookings) {
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                        itemCount: bookings.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final booking = bookings[index];
                          return _selectedTabIndex == 0
                              ? _buildCompletedCard(context, booking, l10n)
                              : _buildCancelledCard(context, booking, l10n);
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedCard(BuildContext context, Booking booking, AppLocalizations l10n) {
    final String formattedDate = AppFormatters.formatTripDate(
      booking.completedAt ?? booking.createdAt,
    );
    final String formattedPrice = AppFormatters.formatNpr(booking.totalPaisa);

    return PlanECard(
      onTap: () => context.push('/itinerary/${booking.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.successContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'COMPLETED',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                'Ref: ${booking.bookingRef}',
                style: const TextStyle(fontSize: 12, color: AppColors.disabledText),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Completed Trip #${booking.bookingRef}',
            style: const TextStyle(
              fontFamily: 'serif',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.forest,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.check_circle_outline, size: 14, color: AppColors.success),
              const SizedBox(width: 4),
              Text(
                'Completed on $formattedDate',
                style: const TextStyle(fontSize: 13, color: AppColors.ink),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Paid: $formattedPrice',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.forest,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'View Guide',
                  variant: AppButtonVariant.secondary,
                  minHeight: 40,
                  onPressed: () => context.push('/itinerary/${booking.id}'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: l10n.leaveReview,
                  minHeight: 40,
                  onPressed: () => context.push('/review/${booking.id}'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCancelledCard(BuildContext context, Booking booking, AppLocalizations l10n) {
    final String formattedDate = AppFormatters.formatTripDate(
      booking.cancelledAt ?? booking.createdAt,
    );
    final String formattedPrice = AppFormatters.formatNpr(booking.totalPaisa);

    return PlanECard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'CANCELLED',
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                'Ref: ${booking.bookingRef}',
                style: const TextStyle(fontSize: 12, color: AppColors.disabledText),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Trip #${booking.bookingRef}',
            style: const TextStyle(
              fontFamily: 'serif',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.forest,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Cancelled on $formattedDate',
            style: const TextStyle(fontSize: 12, color: AppColors.disabledText),
          ),
          const SizedBox(height: 4),
          Text(
            'Amount: $formattedPrice',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.ink),
          ),
          const SizedBox(height: 12),
          AppButton(
            label: l10n.bookAgain,
            variant: AppButtonVariant.secondary,
            isFullWidth: true,
            minHeight: 40,
            onPressed: () => context.push('/booking/${booking.experienceId}'),
          ),
        ],
      ),
    );
  }
}
