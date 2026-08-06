// PL-13 / PL-14 My Plans
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../l10n/app_localizations.dart';
import '../../models/booking.dart';
import '../../providers/app_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
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
                  l10n.myPlans,
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
                      title: _selectedTabIndex == 0
                          ? 'No Upcoming Plans'
                          : 'No Draft Plans',
                      description: _selectedTabIndex == 0
                          ? 'Your confirmed trips and upcoming adventures will appear here.'
                          : 'Any incomplete bookings or saved drafts will appear here.',
                      actionLabel: 'Explore Experiences',
                      onActionPressed: () => context.go('/explore'),
                    ),
                    onRetry: () =>
                        ref.invalidate(bookingsProvider(statusQuery)),
                    data: (bookings) {
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                        itemCount: bookings.length + 1,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          if (index == bookings.length) {
                            return _buildToolsSection(
                              context,
                              bookings.first.id,
                            );
                          }
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
      ),
    );
  }

  Widget _buildToolsSection(BuildContext context, String bookingId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Text(
          'Trip Planning Tools',
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.forest,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => context.push('/gear/$bookingId'),
                child: const _ToolCard(
                  icon: Icons.backpack_outlined,
                  label: 'Gear Checklist',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => context.push('/budget/$bookingId'),
                child: const _ToolCard(
                  icon: Icons.calculate_outlined,
                  label: 'Budget Tracker',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildUpcomingCard(BuildContext context, Booking booking) {
    final String formattedDate = AppFormatters.formatTripDate(
      booking.createdAt,
    );
    final String formattedPrice = AppFormatters.formatNpr(booking.totalPaisa);

    return PlanECard(
      onTap: () => context.push('/itinerary/${booking.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PlanEPhoto(
            imageUrl: booking.experienceCoverImageUrl,
            height: 150,
            width: double.infinity,
            radius: 14,
            overlay: Container(
              alignment: Alignment.bottomLeft,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.transparent,
                    AppColors.black.withValues(alpha: .62),
                  ],
                ),
              ),
              child: Text(
                booking.experienceTitle ?? 'Upcoming Experience',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.white,
                  fontFamily: 'serif',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.successContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'CONFIRMED',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '#${booking.bookingRef}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.disabledText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Booking #${booking.bookingRef}',
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
              const Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: AppColors.ink,
              ),
              const SizedBox(width: 4),
              Text(
                formattedDate,
                style: const TextStyle(fontSize: 13, color: AppColors.ink),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.people_outline, size: 14, color: AppColors.ink),
              const SizedBox(width: 4),
              Text(
                '${booking.adults} Adults${booking.children > 0 ? ', ${booking.children} Children' : ''}',
                style: const TextStyle(fontSize: 13, color: AppColors.ink),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Paid',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.disabledText,
                    ),
                  ),
                  Text(
                    formattedPrice,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.forest,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.map_outlined,
                      color: AppColors.forest,
                      size: 20,
                    ),
                    onPressed: () => context.push('/itinerary/${booking.id}'),
                    tooltip: 'Itinerary',
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.chat_bubble_outline,
                      color: AppColors.forest,
                      size: 20,
                    ),
                    onPressed: () => context.push('/chat/${booking.id}'),
                    tooltip: 'Trip Chat',
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
    final String formattedDate = AppFormatters.formatTripDate(
      booking.createdAt,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warningContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'DRAFT',
                  style: TextStyle(
                    color: AppColors.warning,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                formattedDate,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.disabledText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Draft #${booking.bookingRef}',
            style: const TextStyle(
              fontFamily: 'serif',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.forest,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Estimated Total: $formattedPrice',
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
                  label: l10n.delete,
                  variant: AppButtonVariant.secondary,
                  minHeight: 40,
                  onPressed: () async {
                    final confirm = await DeleteDraftDialog.show(
                      context,
                      planTitle: 'Draft #${booking.bookingRef}',
                    );
                    if (confirm == true && context.mounted) {
                      AppToast.show(
                        context,
                        message: 'Draft deleted successfully',
                      );
                      ref.invalidate(bookingsProvider('pending'));
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: l10n.continueText,
                  minHeight: 40,
                  onPressed: () {
                    context.push('/booking/${booking.experienceId}');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ToolCard({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return PlanECard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.sage,
            child: Icon(icon, color: AppColors.forest, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
