// PL-17 Profile Screen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../models/profile.dart';
import '../../providers/app_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import 'logout_dialog.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(profileProvider);
    final savedAsync = ref.watch(savedExperiencesProvider);
    final bookingsAsync = ref.watch(bookingsProvider('all'));

    return Scaffold(
      body: PlanEBackground(
        safeArea: false,
        child: SafeArea(
          bottom: false,
          child: AsyncValueView<Profile?>(
            value: profileAsync,
            onRetry: () => ref.refresh(profileProvider),
            data: (profile) {
              final String name = profile?.fullName ?? 'Traveler';
              final String location = profile?.location ?? 'Kathmandu, Nepal';
              final String initial = name.isNotEmpty
                  ? name[0].toUpperCase()
                  : 'T';
              final int savedCount = savedAsync.asData?.value.length ?? 0;
              final int tripsCount = bookingsAsync.asData?.value.length ?? 0;
              final UserRole role = profile?.role ?? UserRole.traveler;

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.profile,
                      style: const TextStyle(
                        fontFamily: 'serif',
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.forest,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.border,
                                width: 2,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 54,
                              backgroundColor: AppColors.forest,
                              backgroundImage: profile?.avatarUrl != null
                                  ? NetworkImage(profile!.avatarUrl!)
                                  : null,
                              child: profile?.avatarUrl == null
                                  ? Text(
                                      initial,
                                      style: const TextStyle(
                                        fontSize: 40,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.ivory,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            name,
                            style: const TextStyle(
                              fontFamily: 'serif',
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.forest,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: AppColors.disabledText,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                location,
                                style: const TextStyle(
                                  color: AppColors.disabledText,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () => context.push('/profile/edit'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.forest),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.edit_outlined,
                                    size: 16,
                                    color: AppColors.forest,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    l10n.editProfile.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.forest,
                                      letterSpacing: .5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Stats Card
                    PlanECard(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => context.go('/trips'),
                              child: _StatTile(
                                number: '$tripsCount',
                                label: 'Trips',
                              ),
                            ),
                          ),
                          const SizedBox(height: 40, child: VerticalDivider()),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => context.push('/saved'),
                              child: _StatTile(
                                number: '$savedCount',
                                label: 'Saved',
                              ),
                            ),
                          ),
                          const SizedBox(height: 40, child: VerticalDivider()),
                          Expanded(
                            child: _StatTile(
                              number: '${profile?.points ?? 0}',
                              label: 'Points',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Settings List Card
                    PlanECard(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Column(
                        children: [
                          _ProfileRow(
                            icon: Icons.work_outline,
                            label: l10n.myTrips,
                            onTap: () => context.go('/trips'),
                          ),
                          const Divider(height: 1),
                          _ProfileRow(
                            icon: Icons.rate_review_outlined,
                            label: l10n.myReviews,
                            onTap: () => context.push('/profile/my-reviews'),
                          ),
                          const Divider(height: 1),
                          _ProfileRow(
                            icon: Icons.credit_card,
                            label: l10n.paymentMethods,
                            onTap: () =>
                                context.push('/profile/payment-methods'),
                          ),
                          const Divider(height: 1),
                          _ProfileRow(
                            icon: Icons.notifications_none,
                            label: l10n.notifications,
                            onTap: () => context.push('/profile/notifications'),
                          ),
                          const Divider(height: 1),
                          _ProfileRow(
                            icon: Icons.language,
                            label: l10n.languageAndRegion,
                            onTap: () => context.push('/profile/language'),
                          ),
                          const Divider(height: 1),
                          _ProfileRow(
                            icon: Icons.help_outline,
                            label: l10n.helpAndSupport,
                            onTap: () => context.push('/profile/help'),
                          ),
                          const Divider(height: 1),
                          _ProfileRow(
                            icon: Icons.settings_outlined,
                            label: l10n.settings,
                            onTap: () => context.push('/profile/settings'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Host Action
                    _buildHostButton(context, role, l10n),
                    const SizedBox(height: 16),

                    // Logout Button
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => const LogoutDialog(),
                          );
                        },
                        child: Text(
                          l10n.logout.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const OrnamentDivider(),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHostButton(
    BuildContext context,
    UserRole role,
    AppLocalizations l10n,
  ) {
    if (role == UserRole.hostApplicant) {
      return GestureDetector(
        onTap: () => context.push('/host/submitted'),
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.warningContainer,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: AppColors.warning),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.hourglass_top, color: AppColors.warning),
              const SizedBox(width: 10),
              Text(
                l10n.hostUnderReviewTitle.toUpperCase(),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (role == UserRole.host) {
      return Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.successContainer,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: AppColors.success),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified, color: AppColors.success),
            const SizedBox(width: 10),
            Text(
              l10n.hostVerifiedTitle.toUpperCase(),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.success,
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => context.push('/host'),
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.sage.withValues(alpha: .7),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.group_outlined, color: AppColors.forest),
            const SizedBox(width: 10),
            Text(
              l10n.becomeLocalHostTitle.toUpperCase(),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.forest,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String number;
  final String label;

  const _StatTile({required this.number, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          number,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.forest,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: AppColors.disabledText, fontSize: 12),
        ),
      ],
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.forest),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: AppColors.disabledText,
            ),
          ],
        ),
      ),
    );
  }
}
