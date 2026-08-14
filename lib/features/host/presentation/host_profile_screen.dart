import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../theme/theme.dart';
import '../../../widgets/widgets.dart';
import '../../profile/logout_dialog.dart';
import '../domain/host_mode_models.dart';
import 'host_mode_providers.dart';
import 'widgets/host_mode_scaffold.dart';

class HostProfileScreen extends ConsumerWidget {
  const HostProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return HostModeScaffold(
      currentIndex: 4,
      title: 'Host Profile',
      body: AsyncValueView<HostDashboardData>(
        value: ref.watch(hostDashboardProvider),
        data: (data) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 144),
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: AppColors.forest,
                    child: Text(
                      data.summary.displayName.characters.first,
                      style: const TextStyle(
                        fontSize: 30,
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          data.summary.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: AppTypography.headingLarge.copyWith(
                            fontFamily: 'serif',
                          ),
                        ),
                      ),
                      if (data.summary.isVerified) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.verified,
                          size: 18,
                          color: AppColors.success,
                        ),
                      ],
                    ],
                  ),
                  Text(
                    'Host account',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.disabledText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AppCard(
              child: Column(
                children: [
                  _ProfileRow(
                    icon: Icons.storefront_outlined,
                    label: 'View Public Profile',
                    onTap: () => context.push('/host/profile/public'),
                  ),
                  const Divider(),
                  _ProfileRow(
                    icon: Icons.edit_outlined,
                    label: 'Edit Host Profile',
                    onTap: () => context.push('/host/profile/edit'),
                  ),
                  const Divider(),
                  _ProfileRow(
                    icon: Icons.verified_user_outlined,
                    label: 'Verification & Documents',
                    onTap: () => context.push('/host/profile/verification'),
                  ),
                  const Divider(),
                  _ProfileRow(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Earnings & Payouts',
                    onTap: () => context.push('/host/profile/earnings'),
                  ),
                  const Divider(),
                  _ProfileRow(
                    icon: Icons.star_outline,
                    label: 'Reviews',
                    onTap: () => context.push('/host/profile/reviews'),
                  ),
                  const Divider(),
                  _ProfileRow(
                    icon: Icons.history,
                    label: 'Hosting History',
                    onTap: () => context.push('/host/profile/history'),
                  ),
                  const Divider(),
                  _ProfileRow(
                    icon: Icons.notifications_none,
                    label: 'Notifications',
                    onTap: () => context.push('/host/profile/notifications'),
                  ),
                  const Divider(),
                  _ProfileRow(
                    icon: Icons.help_outline,
                    label: 'Help & Support',
                    onTap: () => context.push('/host/profile/help'),
                  ),
                  const Divider(),
                  _ProfileRow(
                    icon: Icons.menu_book_outlined,
                    label: 'Hosting Guidelines',
                    onTap: () => context.push('/host/profile/guidelines'),
                  ),
                  const Divider(),
                  _ProfileRow(
                    icon: Icons.description_outlined,
                    label: 'Terms & Policies',
                    onTap: () => context.push('/host/profile/terms'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            AppCard(
              backgroundColor: AppColors.sage.withValues(alpha: .5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Switch mode',
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Browse experiences, review trip updates, and make bookings in the traveler app.',
                  ),
                  const SizedBox(height: 12),
                  AppButton.secondary(
                    label: 'Go to traveler mode',
                    icon: Icons.swap_horiz,
                    isFullWidth: true,
                    onPressed: () => context.go('/home'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: TextButton.icon(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (context) => const LogoutDialog(),
                ),
                icon: const Icon(Icons.logout, color: AppColors.error),
                label: const Text(
                  'LOGOUT',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.forest),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.disabledText),
        ],
      ),
    ),
  );
}
