// PL-13 / PL-14 My Plans
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/experience_presentation.dart';
import '../../l10n/app_localizations.dart';
import '../../models/booking.dart';
import '../../providers/app_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import 'delete_draft_dialog.dart';

const planStatuses = ['confirmed', 'pending', 'completed', 'cancelled'];

int planTabFromQuery(String? tab) => switch (tab) {
  'drafts' => 1,
  'past' => 2,
  'cancelled' => 3,
  _ => 0,
};

class PlansScreen extends ConsumerStatefulWidget {
  final int initialTab;

  const PlansScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends ConsumerState<PlansScreen> {
  late int _selectedTabIndex;

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialTab.clamp(0, planStatuses.length - 1);
  }

  @override
  void didUpdateWidget(covariant PlansScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      _selectedTabIndex = widget.initialTab.clamp(0, planStatuses.length - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final List<String> tabs = [
      l10n.upcoming,
      l10n.drafts,
      'History',
      l10n.cancelled,
    ];
    final String statusQuery = planStatuses[_selectedTabIndex];
    final bookingsAsync = ref.watch(bookingsProvider(statusQuery));
    final taxonomy = ref.watch(experienceTaxonomyProvider).valueOrNull;

    return Scaffold(
      body: PlanEBackground(
        safeArea: false,
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const OfflineBanner(),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Text(
                  'Plans',
                  style: TextStyle(
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
                  isScrollable: true,
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
                      title: _emptyTitle,
                      description: _emptyDescription,
                      actionLabel: 'Explore Experiences',
                      onActionPressed: () => context.go('/explore'),
                    ),
                    onRetry: () =>
                        ref.invalidate(bookingsProvider(statusQuery)),
                    data: (bookings) {
                      final showTools = _selectedTabIndex == 0;
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                        itemCount: bookings.length + (showTools ? 1 : 0),
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          if (showTools && index == bookings.length) {
                            final experience = bookings.first.experience;
                            final familySlug = experience == null
                                ? null
                                : ExperiencePresentation.from(
                                    experience,
                                    taxonomy,
                                  ).familySlug;
                            return _buildToolsSection(
                              context,
                              bookings.first.id,
                              familySlug,
                            );
                          }
                          final booking = bookings[index];
                          return switch (_selectedTabIndex) {
                            0 => _buildUpcomingCard(context, booking),
                            1 => _buildDraftCard(context, booking),
                            2 => _buildCompletedCard(context, booking, l10n),
                            _ => _buildCancelledCard(context, booking, l10n),
                          };
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

  String get _emptyTitle => switch (_selectedTabIndex) {
    0 => 'No Upcoming Plans',
    1 => 'No Draft Plans',
    2 => 'No Experience History',
    _ => 'No Cancelled Plans',
  };

  String get _emptyDescription => switch (_selectedTabIndex) {
    0 => 'Your confirmed and upcoming experiences will appear here.',
    1 => 'Incomplete bookings and saved drafts will appear here.',
    2 => 'Experiences you complete will appear here with review options.',
    _ => 'Cancelled experience reservations will appear here.',
  };

  Widget _buildToolsSection(
    BuildContext context,
    String bookingId,
    String? familySlug,
  ) {
    final isAdventure = familySupportsDifficulty(familySlug);
    final tools = <_ToolAction>[
      _ToolAction(
        Icons.event_note_outlined,
        'Schedule',
        '/itinerary/$bookingId',
      ),
      _ToolAction(Icons.chat_bubble_outline, 'Messages', '/chat/$bookingId'),
      if (isAdventure)
        _ToolAction(
          Icons.backpack_outlined,
          'Gear Checklist',
          '/gear/$bookingId',
        ),
      if (isAdventure || familySlug == 'trips-tours')
        _ToolAction(Icons.calculate_outlined, 'Budget', '/budget/$bookingId'),
      if (!isAdventure)
        const _ToolAction(Icons.map_outlined, 'Directions', '/map'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Text(
          'Experience Tools',
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.forest,
          ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) => Wrap(
            spacing: 12,
            runSpacing: 12,
            children: tools
                .map(
                  (tool) => SizedBox(
                    width: (constraints.maxWidth - 12) / 2,
                    child: _ToolCard(
                      icon: tool.icon,
                      label: tool.label,
                      onTap: () => context.push(tool.route),
                    ),
                  ),
                )
                .toList(),
          ),
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
            imageUrl: booking.experience?.coverImageUrl,
            height: 150,
            width: double.infinity,
            imageRequestWidth: 800,
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
                booking.experience?.title ?? 'Upcoming Experience',
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
                    tooltip: 'Experience chat',
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

  Widget _buildCompletedCard(
    BuildContext context,
    Booking booking,
    AppLocalizations l10n,
  ) {
    final completedDate = AppFormatters.formatTripDate(
      booking.completedAt ?? booking.createdAt,
    );
    return PlanECard(
      onTap: () => context.push('/itinerary/${booking.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BookingStatusRow(
            status: 'COMPLETED',
            reference: booking.bookingRef,
            backgroundColor: AppColors.successContainer,
            foregroundColor: AppColors.success,
          ),
          const SizedBox(height: 8),
          Text(
            booking.experience?.title ??
                'Completed experience #${booking.bookingRef}',
            style: const TextStyle(
              fontFamily: 'serif',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.forest,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Completed on $completedDate',
            style: const TextStyle(fontSize: 13, color: AppColors.ink),
          ),
          const SizedBox(height: 6),
          Text(
            'Paid: ${AppFormatters.formatNpr(booking.totalPaisa)}',
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
                  label: 'View Details',
                  variant: AppButtonVariant.secondary,
                  minHeight: 40,
                  onPressed: () => context.push('/itinerary/${booking.id}'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: booking.hasReview
                    ? const AppButton(
                        label: 'Reviewed',
                        variant: AppButtonVariant.disabled,
                        minHeight: 40,
                        onPressed: null,
                      )
                    : AppButton(
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

  Widget _buildCancelledCard(
    BuildContext context,
    Booking booking,
    AppLocalizations l10n,
  ) {
    final cancelledDate = AppFormatters.formatTripDate(
      booking.cancelledAt ?? booking.createdAt,
    );
    return PlanECard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BookingStatusRow(
            status: 'CANCELLED',
            reference: booking.bookingRef,
            backgroundColor: AppColors.errorContainer,
            foregroundColor: AppColors.error,
          ),
          const SizedBox(height: 8),
          Text(
            booking.experience?.title ?? 'Experience #${booking.bookingRef}',
            style: const TextStyle(
              fontFamily: 'serif',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.forest,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Cancelled on $cancelledDate',
            style: const TextStyle(fontSize: 12, color: AppColors.disabledText),
          ),
          const SizedBox(height: 4),
          Text(
            'Amount: ${AppFormatters.formatNpr(booking.totalPaisa)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
            ),
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

class _ToolCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ToolCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: PlanECard(
        onTap: onTap,
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
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolAction {
  const _ToolAction(this.icon, this.label, this.route);

  final IconData icon;
  final String label;
  final String route;
}

class _BookingStatusRow extends StatelessWidget {
  const _BookingStatusRow({
    required this.status,
    required this.reference,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String status;
  final String reference;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: foregroundColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            'Ref: $reference',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: AppColors.disabledText),
          ),
        ),
      ],
    );
  }
}
