import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import 'domain/host_mode_models.dart';
import 'presentation/host_conversation_navigation.dart';
import 'presentation/host_mode_providers.dart';
import 'presentation/widgets/host_mode_scaffold.dart';

class HostDashboardScreen extends ConsumerWidget {
  const HostDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(hostDashboardProvider);
    return HostModeScaffold(
      currentIndex: 0,
      body: SafeArea(
        bottom: false,
        child: AsyncValueView<HostDashboardData>(
          value: dashboard,
          onRetry: () => ref.invalidate(hostDashboardProvider),
          data: (data) => RefreshIndicator(
            onRefresh: () async => ref.invalidate(hostDashboardProvider),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 144),
              children: [
                _Header(summary: data.summary),
                const SizedBox(height: 16),
                _StatsGrid(summary: data.summary),
                const SizedBox(height: 24),
                HostSectionHeader(
                  title: 'Needs Attention',
                  action: 'View all',
                  onAction: () => context.go('/host/bookings?status=requested'),
                ),
                const SizedBox(height: 8),
                if (data.needsAttention.isEmpty)
                  const AppCard(child: Text('You’re all caught up.'))
                else
                  _RequestCard(
                    request: data.needsAttention.first,
                    unreadConversation: data.unreadConversation,
                  ),
                const SizedBox(height: 24),
                const HostSectionHeader(title: 'Upcoming Experience'),
                const SizedBox(height: 8),
                if (data.upcomingExperience != null)
                  _ExperienceCard(experience: data.upcomingExperience!),
                const SizedBox(height: 24),
                const HostSectionHeader(title: 'Quick Actions'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Create Experience',
                        icon: Icons.add_circle_outline,
                        onPressed: () {
                          ref
                              .read(hostCreateExperienceProvider.notifier)
                              .reset();
                          context.push('/host/experiences/create');
                        },
                        isFullWidth: true,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AppButton.secondary(
                        label: 'Manage Bookings',
                        icon: Icons.event_note_outlined,
                        onPressed: () => context.go('/host/bookings'),
                        isFullWidth: true,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.summary});
  final HostSummary summary;

  String get firstName {
    final name = summary.displayName.trim();
    return name.isEmpty ? 'Host' : name.split(RegExp(r'\s+')).first;
  }

  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'HOST DASHBOARD',
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: AppColors.forest,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$greeting, $firstName',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.headingMedium.copyWith(
                fontFamily: 'serif',
                fontWeight: FontWeight.w700,
                color: AppColors.deep,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              "Here’s what’s happening today.",
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.disabledText,
              ),
            ),
          ],
        ),
      ),
      IconButton.filledTonal(
        onPressed: () => context.push('/host/profile/notifications'),
        icon: const Badge(
          smallSize: 8,
          backgroundColor: AppColors.gold,
          child: Icon(Icons.notifications_none_rounded),
        ),
        style: IconButton.styleFrom(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.forest,
        ),
      ),
    ],
  );
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.summary});
  final HostSummary summary;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          Expanded(
            child: _Stat(
              icon: Icons.hiking_outlined,
              value: '${summary.activeExperiences}',
              label: 'Active Experiences',
              onTap: () => context.go('/host/experiences?status=active'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _Stat(
              icon: Icons.groups_2_outlined,
              value: '${summary.upcomingGuests}',
              label: 'Upcoming Guests',
              onTap: () => context.go('/host/bookings?status=confirmed'),
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: _Stat(
              icon: Icons.pending_actions_outlined,
              value: '${summary.pendingRequests}',
              label: 'Pending Requests',
              attention: true,
              onTap: () => context.go('/host/bookings?status=requested'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _Stat(
              icon: Icons.account_balance_wallet_outlined,
              value:
                  'NPR ${NumberFormat('#,###').format(summary.upcomingEarningsNpr)}',
              label: 'Upcoming Earnings',
              compact: true,
              onTap: () => context.push('/host/profile/earnings'),
            ),
          ),
        ],
      ),
    ],
  );
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.value,
    required this.label,
    this.attention = false,
    this.compact = false,
    this.onTap,
  });
  final IconData icon;
  final String value;
  final String label;
  final bool attention;
  final bool compact;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => AppCard(
    onTap: onTap,
    backgroundColor: attention
        ? AppColors.warningContainer.withValues(alpha: .35)
        : AppColors.white,
    borderColor: attention
        ? AppColors.gold.withValues(alpha: .55)
        : AppColors.borderSubtle,
    child: SizedBox(
      height: 67,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(
            icon,
            size: 19,
            color: attention ? AppColors.gold : AppColors.forest,
          ),
          Text(
            value,
            maxLines: 1,
            style: TextStyle(
              fontSize: compact ? 17 : 22,
              fontWeight: FontWeight.w800,
              color: AppColors.deep,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              fontSize: 11,
              color: AppColors.disabledText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, required this.unreadConversation});
  final HostBookingRequest request;
  final HostConversation? unreadConversation;
  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PENDING BOOKING REQUEST',
          style: AppTypography.caption.copyWith(
            fontSize: 10,
            letterSpacing: .7,
            fontWeight: FontWeight.w800,
            color: AppColors.gold,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          request.experienceTitle,
          style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.sage,
              child: Text(
                request.travelerName.characters.first,
                style: const TextStyle(
                  color: AppColors.forest,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${request.travelerName} · ${request.travelerCount} travelers',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${DateFormat('d–').format(request.tripStartDate)}${DateFormat('d MMM').format(request.tripEndDate)} · recently submitted',
                    style: AppTypography.caption.copyWith(
                      fontSize: 11,
                      color: AppColors.disabledText,
                    ),
                  ),
                ],
              ),
            ),
            AppButton(
              label: 'Review',
              onPressed: () => context.push('/host/bookings/${request.id}'),
              minHeight: 40,
              fontSize: 12,
            ),
          ],
        ),
        const Divider(height: 25),
        InkWell(
          onTap: () => unreadConversation == null
              ? context.go('/host/messages')
              : context.push('/host/messages/${unreadConversation!.id}'),
          child: Row(
            children: [
              const Icon(
                Icons.mark_unread_chat_alt_outlined,
                size: 18,
                color: AppColors.forest,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  unreadConversation == null
                      ? 'View messages'
                      : '${unreadConversation!.unreadCount} unread messages',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.disabledText),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ExperienceCard extends ConsumerWidget {
  const _ExperienceCard({required this.experience});
  final HostExperience experience;
  @override
  Widget build(BuildContext context, WidgetRef ref) => AppCard(
    padding: EdgeInsets.zero,
    elevation: 1,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadii.md16),
          ),
          child: Image.asset(
            experience.imageAsset,
            height: 155,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        Padding(
          padding: AppSpacing.paddingLg16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                experience.title,
                style: AppTypography.headingMedium.copyWith(
                  fontFamily: 'serif',
                  color: AppColors.deep,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${DateFormat('d').format(experience.startDate)}–${DateFormat('d MMMM y').format(experience.endDate)}  ·  ${experience.location}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.disabledText,
                ),
              ),
              const SizedBox(height: 13),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${experience.bookedSpots} of ${experience.capacity} spots filled',
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${(experience.occupancy * 100).round()}%',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.forest,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: AppRadii.borderPill,
                child: LinearProgressIndicator(
                  value: experience.occupancy,
                  minHeight: 7,
                  backgroundColor: AppColors.sage,
                  color: AppColors.forest,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: AppButton.secondary(
                      label: 'Manage',
                      icon: Icons.tune_outlined,
                      onPressed: () =>
                          context.push('/host/experiences/${experience.id}'),
                      minHeight: 42,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppButton(
                      label: 'Message Guests',
                      icon: Icons.chat_bubble_outline,
                      onPressed: () => openHostDepartureConversation(
                        context,
                        ref,
                        experience.id,
                        experience.title,
                      ),
                      minHeight: 42,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
