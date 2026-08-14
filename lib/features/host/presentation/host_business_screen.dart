import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../theme/theme.dart';
import '../../../widgets/widgets.dart';
import '../domain/host_mode_models.dart';
import 'host_mode_providers.dart';
import 'widgets/host_mode_scaffold.dart';

class HostBusinessScreen extends ConsumerWidget {
  const HostBusinessScreen({super.key, required this.page});
  final HostBusinessPage page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(_fallbackTitle(page))),
      backgroundColor: const Color(0xFFF7F8F5),
      body: AsyncValueView<HostBusinessData>(
        value: ref.watch(hostBusinessPageProvider(page)),
        onRetry: () => ref.invalidate(hostBusinessPageProvider(page)),
        data: (data) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
          children: [
            if (page == HostBusinessPage.publicProfile)
              _PublicProfileHeader(data: data)
            else ...[
              Text(
                data.title,
                style: AppTypography.headingLarge.copyWith(fontFamily: 'serif'),
              ),
              const SizedBox(height: 7),
              Text(
                data.introduction,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.disabledText,
                ),
              ),
            ],
            const SizedBox(height: 16),
            ...data.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  onTap: () => _openItem(context, item),
                  borderColor: item.unread
                      ? AppColors.gold.withValues(alpha: .55)
                      : AppColors.borderSubtle,
                  backgroundColor: item.unread
                      ? AppColors.warningContainer.withValues(alpha: .25)
                      : AppColors.white,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.unread) ...[
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: CircleAvatar(
                            radius: 4,
                            backgroundColor: AppColors.gold,
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item.detail,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.disabledText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (item.value != null) ...[
                        const SizedBox(width: 10),
                        Text(
                          item.value!,
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.forest,
                          ),
                        ),
                      ] else
                        const Icon(
                          Icons.chevron_right,
                          color: AppColors.disabledText,
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (page == HostBusinessPage.publicProfile)
              AppButton.secondary(
                label: 'Edit host profile',
                icon: Icons.edit_outlined,
                isFullWidth: true,
                onPressed: () => context.push('/host/profile/edit'),
              ),
            if (page == HostBusinessPage.earnings) ...[
              const SizedBox(height: 4),
              AppButton.secondary(
                label: 'Manage payout method',
                icon: Icons.account_balance_outlined,
                isFullWidth: true,
                onPressed: () =>
                    showUnavailableNotice(context, 'Secure payout management'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openItem(BuildContext context, HostBusinessItem item) {
    if (page == HostBusinessPage.notifications) {
      if (item.title == 'New booking request') {
        context.push('/host/bookings/mock-booking-1');
        return;
      }
      if (item.title == 'Unread message') {
        context.push('/host/messages/mock-chat-1');
        return;
      }
      if (item.title == 'Departure reminder') {
        context.push('/host/experiences/mock-exp-mardi');
        return;
      }
    }
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.title, style: AppTypography.headingMedium),
              const SizedBox(height: 8),
              Text(item.detail),
              if (item.value != null) ...[
                const SizedBox(height: 12),
                Chip(label: Text(item.value!)),
              ],
              const SizedBox(height: 16),
              Text(
                page == HostBusinessPage.earnings ||
                        page == HostBusinessPage.verification
                    ? 'Display only. Secure backend verification is required before changes are available.'
                    : 'This section is currently read-only.',
                style: AppTypography.caption.copyWith(
                  color: AppColors.disabledText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fallbackTitle(HostBusinessPage page) => switch (page) {
    HostBusinessPage.publicProfile => 'Public Host Profile',
    HostBusinessPage.verification => 'Verification & Documents',
    HostBusinessPage.earnings => 'Earnings & Payouts',
    HostBusinessPage.reviews => 'Reviews',
    HostBusinessPage.history => 'Hosting History',
    HostBusinessPage.notifications => 'Host Notifications',
    HostBusinessPage.help => 'Help & Support',
    HostBusinessPage.guidelines => 'Hosting Guidelines',
    HostBusinessPage.terms => 'Terms & Policies',
  };
}

class _PublicProfileHeader extends StatelessWidget {
  const _PublicProfileHeader({required this.data});
  final HostBusinessData data;
  @override
  Widget build(BuildContext context) => AppCard(
    backgroundColor: AppColors.sage.withValues(alpha: .45),
    child: Column(
      children: [
        const CircleAvatar(
          radius: 42,
          backgroundColor: AppColors.forest,
          child: Icon(Icons.person, size: 38, color: Colors.white),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                data.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTypography.headingLarge.copyWith(fontFamily: 'serif'),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.verified, size: 18, color: AppColors.success),
          ],
        ),
        const SizedBox(height: 7),
        Text(
          data.introduction,
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium,
        ),
      ],
    ),
  );
}
