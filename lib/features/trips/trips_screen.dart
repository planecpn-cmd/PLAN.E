// PL-15 / PL-16 My Trips
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../l10n/app_localizations.dart';
import '../../models/booking.dart';
import '../../providers/app_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_tabs.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/empty_state_view.dart';

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
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        title: Text(
          l10n.myTrips,
          style: AppTypography.headingLarge.copyWith(color: AppColors.ink),
        ),
        backgroundColor: AppColors.ivory,
        elevation: 0,
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: AppSpacing.screenPadding,
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
                    actionLabel: 'Explore Experiences',
                    onActionPressed: () => context.go('/explore'),
                  ),
                  onRetry: () => ref.invalidate(bookingsProvider(statusQuery)),
                  data: (bookings) {
                    return ListView.separated(
                      padding: AppSpacing.screenPadding,
                      itemCount: bookings.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: AppSpacing.md12),
                      itemBuilder: (context, index) {
                        final booking = bookings[index];
                        return _selectedTabIndex == 0
                            ? _buildCompletedCard(context, booking)
                            : _buildCancelledCard(context, booking);
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedCard(BuildContext context, Booking booking) {
    final String formattedDate = AppFormatters.formatTripDate(
      booking.completedAt ?? booking.createdAt,
    );
    final String formattedPrice = AppFormatters.formatNpr(booking.totalPaisa);

    return AppCard(
      onTap: () => context.push('/itinerary/${booking.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm8,
                  vertical: AppSpacing.xs4,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.successContainer,
                  borderRadius: AppRadii.borderSm8,
                ),
                child: Text(
                  'COMPLETED',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                'Ref: ${booking.bookingRef}',
                style: AppTypography.caption.copyWith(color: AppColors.disabledText),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm8),
          Text(
            'Completed Trip #${booking.bookingRef}',
            style: AppTypography.headingMedium.copyWith(color: AppColors.ink),
          ),
          const SizedBox(height: AppSpacing.xs4),
          Row(
            children: [
              const Icon(Icons.check_circle_outline, size: 14, color: AppColors.success),
              const SizedBox(width: AppSpacing.xs4),
              Text(
                'Completed on $formattedDate',
                style: AppTypography.caption.copyWith(color: AppColors.ink),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm8),
          Text(
            'Paid: $formattedPrice',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.forest,
            ),
          ),
          const SizedBox(height: AppSpacing.md12),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'View Guide',
                  variant: AppButtonVariant.secondary,
                  onPressed: () => context.push('/itinerary/${booking.id}'),
                ),
              ),
              const SizedBox(width: AppSpacing.md12),
              Expanded(
                child: AppButton(
                  label: 'Leave Review',
                  variant: AppButtonVariant.primary,
                  onPressed: () => context.push('/review/${booking.id}'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCancelledCard(BuildContext context, Booking booking) {
    final String formattedDate = AppFormatters.formatTripDate(
      booking.cancelledAt ?? booking.createdAt,
    );
    final String formattedPrice = AppFormatters.formatNpr(booking.totalPaisa);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm8,
                  vertical: AppSpacing.xs4,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.errorContainer,
                  borderRadius: AppRadii.borderSm8,
                ),
                child: Text(
                  'CANCELLED',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                'Ref: ${booking.bookingRef}',
                style: AppTypography.caption.copyWith(color: AppColors.disabledText),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm8),
          Text(
            'Trip #${booking.bookingRef}',
            style: AppTypography.headingMedium.copyWith(color: AppColors.ink),
          ),
          const SizedBox(height: AppSpacing.xs4),
          Text(
            'Cancelled on $formattedDate',
            style: AppTypography.caption.copyWith(color: AppColors.disabledText),
          ),
          const SizedBox(height: AppSpacing.xs4),
          Text(
            'Amount: $formattedPrice',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md12),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              label: 'Book Again',
              variant: AppButtonVariant.secondary,
              onPressed: () => context.push('/booking/${booking.experienceId}'),
            ),
          ),
        ],
      ),
    );
  }
}


