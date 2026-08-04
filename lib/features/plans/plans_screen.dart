// PL-13 / PL-14 My Plans
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../l10n/app_localizations.dart';
import '../../models/booking.dart';
import '../../providers/app_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_tabs.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/empty_state_view.dart';
import 'delete_draft_dialog.dart';

class PlansScreen extends ConsumerStatefulWidget {
  const PlansScreen({super.key});

  @override
  ConsumerState<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends ConsumerState<PlansScreen> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final List<String> tabs = [l10n.upcoming, l10n.drafts];
    final String statusQuery = _selectedTabIndex == 0 ? 'confirmed' : 'pending';
    final bookingsAsync = ref.watch(bookingsProvider(statusQuery));

    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        title: Text(
          l10n.myPlans,
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
                    title: _selectedTabIndex == 0 ? 'No Upcoming Plans' : 'No Draft Plans',
                    description: _selectedTabIndex == 0
                        ? 'Your confirmed trips and upcoming adventures will appear here.'
                        : 'Any incomplete bookings or saved drafts will appear here.',
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
                            ? _buildUpcomingCard(context, booking)
                            : _buildDraftCard(context, booking);
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

  Widget _buildUpcomingCard(BuildContext context, Booking booking) {
    final String formattedDate = AppFormatters.formatTripDate(booking.createdAt);
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
                  'CONFIRMED',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                'Ref: ${booking.bookingRef}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.disabledText,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm8),
          Text(
            'Booking #${booking.bookingRef}',
            style: AppTypography.headingMedium.copyWith(color: AppColors.ink),
          ),
          const SizedBox(height: AppSpacing.xs4),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.ink),
              const SizedBox(width: AppSpacing.xs4),
              Text(
                formattedDate,
                style: AppTypography.caption.copyWith(color: AppColors.ink),
              ),
              const SizedBox(width: AppSpacing.md12),
              const Icon(Icons.people_outline, size: 14, color: AppColors.ink),
              const SizedBox(width: AppSpacing.xs4),
              Text(
                '${booking.adults} Adults${booking.children > 0 ? ', ${booking.children} Children' : ''}',
                style: AppTypography.caption.copyWith(color: AppColors.ink),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md12),
          const Divider(color: AppColors.borderSubtle, height: 1),
          const SizedBox(height: AppSpacing.sm8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Paid',
                    style: AppTypography.caption.copyWith(color: AppColors.disabledText),
                  ),
                  Text(
                    formattedPrice,
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.forest,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _IconButtonMinTarget(
                    icon: Icons.map_outlined,
                    tooltip: 'Itinerary',
                    onPressed: () => context.push('/itinerary/${booking.id}'),
                  ),
                  _IconButtonMinTarget(
                    icon: Icons.chat_bubble_outline,
                    tooltip: 'Trip Chat',
                    onPressed: () => context.push('/chat/${booking.id}'),
                  ),
                  _IconButtonMinTarget(
                    icon: Icons.checklist_outlined,
                    tooltip: 'Gear List',
                    onPressed: () => context.push('/gear/${booking.id}'),
                  ),
                  _IconButtonMinTarget(
                    icon: Icons.account_balance_wallet_outlined,
                    tooltip: 'Budget',
                    onPressed: () => context.push('/budget/${booking.id}'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDraftCard(BuildContext context, Booking booking) {
    final l10n = AppLocalizations.of(context)!;
    final String formattedDate = AppFormatters.formatTripDate(booking.createdAt);
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
                  color: AppColors.warningContainer,
                  borderRadius: AppRadii.borderSm8,
                ),
                child: Text(
                  'DRAFT',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                formattedDate,
                style: AppTypography.caption.copyWith(
                  color: AppColors.disabledText,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm8),
          Text(
            'Draft #${booking.bookingRef}',
            style: AppTypography.headingMedium.copyWith(color: AppColors.ink),
          ),
          const SizedBox(height: AppSpacing.xs4),
          Text(
            'Estimated Total: $formattedPrice',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.forest,
            ),
          ),
          const SizedBox(height: AppSpacing.md12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: AppTouchTarget.minSize,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      shape: const RoundedRectangleBorder(borderRadius: AppRadii.borderPill),
                    ),
                    onPressed: () async {
                      final confirm = await DeleteDraftDialog.show(
                        context,
                        planTitle: 'Draft #${booking.bookingRef}',
                      );
                      if (confirm == true && context.mounted) {
                        AppToast.show(context, message: 'Draft deleted successfully');
                        ref.invalidate(bookingsProvider('pending'));
                      }
                    },
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: Text(l10n.delete),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md12),
              Expanded(
                child: SizedBox(
                  height: AppTouchTarget.minSize,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.forest,
                      foregroundColor: AppColors.ivory,
                      shape: const RoundedRectangleBorder(borderRadius: AppRadii.borderPill),
                    ),
                    onPressed: () {
                      context.push('/booking/${booking.experienceId}');
                    },
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    label: Text(l10n.continueText),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IconButtonMinTarget extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _IconButtonMinTarget({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: AppTouchTarget.minConstraints,
      child: IconButton(
        icon: Icon(icon, color: AppColors.forest, size: 20),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}


