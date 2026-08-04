// PL-17 Profile Screen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../models/profile.dart';
import '../../providers/app_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/async_value_view.dart';
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
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        title: Text(
          l10n.profile,
          style: AppTypography.headingMedium.copyWith(color: AppColors.ink),
        ),
        backgroundColor: AppColors.ivory,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.ink),
            tooltip: 'Settings',
            constraints: AppTouchTarget.minConstraints,
            onPressed: () => context.push('/profile/settings'),
          ),
        ],
      ),
      body: AsyncValueView<Profile?>(
        value: profileAsync,
        onRetry: () => ref.refresh(profileProvider),
        data: (profile) {
          final String name = profile?.fullName ?? 'Traveler';
          final String phone = profile?.phone ?? '+977 9800000000';
          final String location = profile?.location ?? 'Kathmandu, Nepal';
          final String initial = name.isNotEmpty ? name[0].toUpperCase() : 'T';
          final int points = profile?.points ?? 350;
          final int savedCount = savedAsync.asData?.value.length ?? 4;
          final int tripsCount = bookingsAsync.asData?.value.length ?? 2;
          final UserRole role = profile?.role ?? UserRole.traveler;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg16,
              vertical: AppSpacing.md12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Header Card
                AppCard(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: AppColors.forest,
                        backgroundImage: profile?.avatarUrl != null
                            ? NetworkImage(profile!.avatarUrl!)
                            : null,
                        child: profile?.avatarUrl == null
                            ? Text(
                                initial,
                                style: AppTypography.displayMedium.copyWith(
                                  color: AppColors.ivory,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: AppSpacing.lg16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    name,
                                    style: AppTypography.headingMedium,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (role == UserRole.host)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm8,
                                      vertical: AppSpacing.xs4,
                                    ),
                                    decoration: const BoxDecoration(
                                      color: AppColors.forest,
                                      borderRadius: AppRadii.borderPill,
                                    ),
                                    child: Text(
                                      'HOST',
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.ivory,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xs4),
                            Text(
                              phone,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.disabledText,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 14,
                                  color: AppColors.gold,
                                ),
                                const SizedBox(width: AppSpacing.xs4),
                                Text(
                                  location,
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.ink,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg16),

                // DB Counters Row (Saved, Trips, Points)
                Row(
                  children: [
                    Expanded(
                      child: _CounterTile(
                        label: 'Saved',
                        value: '$savedCount',
                        icon: Icons.bookmark_outline,
                        onTap: () => context.push('/saved'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md12),
                    Expanded(
                      child: _CounterTile(
                        label: 'Trips',
                        value: '$tripsCount',
                        icon: Icons.card_travel_outlined,
                        onTap: () => context.go('/trips'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md12),
                    Expanded(
                      child: _CounterTile(
                        label: 'Points',
                        value: '$points',
                        icon: Icons.stars_outlined,
                        onTap: () {},
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl20),

                // Become a Host CTA Card
                _BecomeHostCtaCard(role: role),
                const SizedBox(height: AppSpacing.xl20),

                // Settings & Links Section
                Text(
                  'Account Settings',
                  style: AppTypography.headingMedium.copyWith(fontSize: 18.0),
                ),
                const SizedBox(height: AppSpacing.md12),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _SettingsTile(
                        icon: Icons.person_outline,
                        title: l10n.editProfile,
                        subtitle: 'Name, phone, bio & photo',
                        onTap: () => context.push('/profile/edit'),
                      ),
                      const Divider(height: 1, color: AppColors.borderSubtle),
                      _SettingsTile(
                        icon: Icons.account_balance_wallet_outlined,
                        title: l10n.paymentMethods,
                        subtitle: 'Khalti, eSewa & cards',
                        onTap: () => context.push('/profile/payment-methods'),
                      ),
                      const Divider(height: 1, color: AppColors.borderSubtle),
                      _SettingsTile(
                        icon: Icons.notifications_none_outlined,
                        title: l10n.notifications,
                        subtitle: 'Trip alerts & recommendations',
                        onTap: () => context.push('/profile/notifications'),
                      ),
                      const Divider(height: 1, color: AppColors.borderSubtle),
                      _SettingsTile(
                        icon: Icons.language_outlined,
                        title: l10n.languageAndRegion,
                        subtitle: 'English (NPR - Rs)',
                        onTap: () => context.push('/profile/language'),
                      ),
                      const Divider(height: 1, color: AppColors.borderSubtle),
                      _SettingsTile(
                        icon: Icons.rate_review_outlined,
                        title: l10n.myReviews,
                        subtitle: 'Past ratings & feedback',
                        onTap: () => context.push('/profile/my-reviews'),
                      ),
                      const Divider(height: 1, color: AppColors.borderSubtle),
                      _SettingsTile(
                        icon: Icons.help_outline,
                        title: l10n.helpAndSupport,
                        subtitle: 'FAQs, contact & policies',
                        onTap: () => context.push('/profile/help'),
                      ),
                      const Divider(height: 1, color: AppColors.borderSubtle),
                      _SettingsTile(
                        icon: Icons.tune_outlined,
                        title: l10n.settings,
                        subtitle: 'Cache, privacy & app info',
                        onTap: () => context.push('/profile/settings'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl20),

                // Logout Action Button
                AppButton.secondary(
                  label: l10n.logout,
                  icon: Icons.logout,
                  isFullWidth: true,
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const LogoutDialog(),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.xxl24),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CounterTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const _CounterTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.borderMd16,
      child: AppCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md12,
          vertical: AppSpacing.lg16,
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.forest, size: 22),
            const SizedBox(height: AppSpacing.xs4),
            Text(
              value,
              style: AppTypography.headingMedium.copyWith(
                color: AppColors.forest,
              ),
            ),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: AppColors.disabledText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BecomeHostCtaCard extends StatelessWidget {
  final UserRole role;

  const _BecomeHostCtaCard({required this.role});

  @override
  Widget build(BuildContext context) {
    if (role == UserRole.hostApplicant) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg16),
        decoration: const BoxDecoration(
          color: AppColors.warningContainer,
          borderRadius: AppRadii.borderMd16,
        ),
        child: Row(
          children: [
            const Icon(Icons.hourglass_top, color: AppColors.warning, size: 32),
            const SizedBox(width: AppSpacing.md12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Host Application Under Review',
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs4),
                  Text(
                    'Check your status or update application details.',
                    style: AppTypography.caption.copyWith(color: AppColors.ink),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.warning),
              constraints: AppTouchTarget.minConstraints,
              onPressed: () => context.push('/host/submitted'),
            ),
          ],
        ),
      );
    }

    if (role == UserRole.host) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg16),
        decoration: const BoxDecoration(
          color: AppColors.successContainer,
          borderRadius: AppRadii.borderMd16,
        ),
        child: Row(
          children: [
            const Icon(Icons.verified, color: AppColors.success, size: 32),
            const SizedBox(width: AppSpacing.md12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Verified PLAN E Host',
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs4),
                  Text(
                    'Manage your local homestays & experience listings.',
                    style: AppTypography.caption.copyWith(color: AppColors.ink),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg16),
      decoration: BoxDecoration(
        color: AppColors.forest,
        borderRadius: AppRadii.borderMd16,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cabin, color: AppColors.gold, size: 28),
              const SizedBox(width: AppSpacing.sm8),
              Text(
                'Become a Local Host',
                style: AppTypography.headingMedium.copyWith(
                  color: AppColors.ivory,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm8),
          Text(
            'Share authentic Nepali culture, homestays, or adventure tours with travelers worldwide.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.sage,
            ),
          ),
          const SizedBox(height: AppSpacing.md12),
          AppButton(
            label: 'Start Host Application',
            icon: Icons.arrow_forward,
            onPressed: () => context.push('/host'),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg16,
          vertical: AppSpacing.md12,
        ),
        child: Row(
          children: [
            Container(
              width: AppTouchTarget.minSize,
              height: AppTouchTarget.minSize,
              alignment: Alignment.center,
              child: Icon(icon, color: AppColors.forest, size: 22),
            ),
            const SizedBox(width: AppSpacing.sm8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.disabledText,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.disabledText),
          ],
        ),
      ),
    );
  }
}
