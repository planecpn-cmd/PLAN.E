// RM-18 Notifications Screen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_toast.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _tripAlerts = true;
  bool _hostMessages = true;
  bool _promoOffers = false;
  bool _weatherAlerts = true;
  bool _soundEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: AppTypography.headingMedium.copyWith(color: AppColors.ink),
        ),
        backgroundColor: AppColors.ivory,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          constraints: AppTouchTarget.minConstraints,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Preferences',
              style: AppTypography.headingMedium.copyWith(fontSize: 18),
            ),
            const SizedBox(height: AppSpacing.xs4),
            Text(
              'Customize which notifications you receive from PLAN E.',
              style: AppTypography.caption.copyWith(color: AppColors.disabledText),
            ),
            const SizedBox(height: AppSpacing.lg16),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _NotificationSwitchTile(
                    title: 'Trip Updates & Reminders',
                    subtitle: 'Itinerary changes, upcoming booking alerts & check-in times',
                    icon: Icons.calendar_today_outlined,
                    value: _tripAlerts,
                    onChanged: (val) {
                      setState(() => _tripAlerts = val);
                      AppToast.show(context, message: 'Trip updates preference saved');
                    },
                  ),
                  const Divider(height: 1, color: AppColors.borderSubtle),
                  _NotificationSwitchTile(
                    title: 'Host & Direct Messages',
                    subtitle: 'Instant chat messages and instructions from local hosts',
                    icon: Icons.chat_bubble_outline,
                    value: _hostMessages,
                    onChanged: (val) {
                      setState(() => _hostMessages = val);
                      AppToast.show(context, message: 'Host messages preference saved');
                    },
                  ),
                  const Divider(height: 1, color: AppColors.borderSubtle),
                  _NotificationSwitchTile(
                    title: 'Mountain Weather Alerts',
                    subtitle: 'Real-time weather & trail safety warnings for booked region',
                    icon: Icons.thunderstorm_outlined,
                    value: _weatherAlerts,
                    onChanged: (val) {
                      setState(() => _weatherAlerts = val);
                      AppToast.show(context, message: 'Weather alerts preference saved');
                    },
                  ),
                  const Divider(height: 1, color: AppColors.borderSubtle),
                  _NotificationSwitchTile(
                    title: 'Promotions & Special Deals',
                    subtitle: 'Seasonal discounts on homestays and featured treks',
                    icon: Icons.local_offer_outlined,
                    value: _promoOffers,
                    onChanged: (val) {
                      setState(() => _promoOffers = val);
                      AppToast.show(context, message: 'Promotional offers preference saved');
                    },
                  ),
                  const Divider(height: 1, color: AppColors.borderSubtle),
                  _NotificationSwitchTile(
                    title: 'App Sound & Vibration',
                    subtitle: 'Play sound for incoming push notifications',
                    icon: Icons.volume_up_outlined,
                    value: _soundEnabled,
                    onChanged: (val) {
                      setState(() => _soundEnabled = val);
                      AppToast.show(context, message: 'Sound preference saved');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationSwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotificationSwitchTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.disabledText,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeTrackColor: AppColors.forest,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
