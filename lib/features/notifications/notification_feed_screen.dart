// Notification inbox — distinct from /profile/notifications, which is the
// notification *preferences* (what types to receive) screen.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/notification.dart';
import '../../providers/app_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';

class NotificationFeedScreen extends ConsumerWidget {
  const NotificationFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

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
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: AppColors.ink),
            tooltip: 'Notification preferences',
            onPressed: () => context.push('/profile/notifications'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(notificationRepositoryProvider).markAllAsRead();
              ref.invalidate(notificationsProvider);
              ref.invalidate(unreadNotificationCountProvider);
            },
            child: Text(
              'Mark all read',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.forest),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.forest,
        onRefresh: () async => ref.invalidate(notificationsProvider),
        child: AsyncValueView<List<AppNotification>>(
          value: notificationsAsync,
          onRetry: () => ref.refresh(notificationsProvider),
          isEmpty: (data) => data.isEmpty,
          emptyView: const EmptyStateView(
            title: 'No Notifications Yet',
            description: "We'll let you know when there's something new.",
            icon: Icons.notifications_none_outlined,
          ),
          data: (notifications) {
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.lg16),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm8),
              itemBuilder: (context, index) {
                final n = notifications[index];
                return _NotificationTile(
                  notification: n,
                  onTap: () async {
                    if (!n.isRead) {
                      await ref.read(notificationRepositoryProvider).markAsRead(n.id);
                      ref.invalidate(notificationsProvider);
                      ref.invalidate(unreadNotificationCountProvider);
                    }
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationTile({required this.notification, required this.onTap});

  IconData get _icon {
    switch (notification.type) {
      case NotificationType.booking:
        return Icons.event_available_outlined;
      case NotificationType.chat:
        return Icons.chat_bubble_outline;
      case NotificationType.hostApplication:
        return Icons.badge_outlined;
      case NotificationType.promo:
        return Icons.local_offer_outlined;
      case NotificationType.system:
        return Icons.info_outline;
    }
  }

  String get _relativeTime {
    final diff = DateTime.now().difference(notification.createdAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${notification.createdAt.day}/${notification.createdAt.month}/${notification.createdAt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: notification.isRead
                  ? AppColors.sage
                  : AppColors.forest.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(_icon, size: 20, color: AppColors.forest),
          ),
          const SizedBox(width: AppSpacing.md12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  notification.body,
                  style: AppTypography.caption.copyWith(color: AppColors.disabledText),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _relativeTime,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.disabledText,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (!notification.isRead)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 4),
              decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
            ),
        ],
      ),
    );
  }
}
