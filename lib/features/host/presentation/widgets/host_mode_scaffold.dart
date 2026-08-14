import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../theme/theme.dart';
import '../host_mode_providers.dart';

class HostModeScaffold extends ConsumerWidget {
  const HostModeScaffold({
    super.key,
    required this.currentIndex,
    required this.body,
    this.title,
    this.actions,
    this.floatingActionButton,
  });

  final int currentIndex;
  final Widget body;
  final String? title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  static const _paths = [
    '/host/dashboard',
    '/host/experiences',
    '/host/bookings',
    '/host/messages',
    '/host/profile',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread =
        ref.watch(hostDashboardProvider).asData?.value.summary.unreadMessages ??
        0;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F5),
      appBar: title == null
          ? null
          : AppBar(
              title: Text(title!),
              actions: actions,
              backgroundColor: const Color(0xFFF7F8F5),
            ),
      body: body,
      floatingActionButton: floatingActionButton,
      extendBody: true,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Container(
            key: const ValueKey('host-navigation-bar'),
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppColors.borderSubtle),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x18000000),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BottomNavigationBar(
                currentIndex: currentIndex,
                onTap: (index) => context.go(_paths[index]),
                backgroundColor: AppColors.white,
                selectedItemColor: AppColors.forest,
                unselectedItemColor: AppColors.ink.withValues(alpha: .45),
                type: BottomNavigationBarType.fixed,
                elevation: 0,
                showSelectedLabels: false,
                showUnselectedLabels: false,
                iconSize: 26,
                items: [
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.dashboard_outlined),
                    activeIcon: Icon(Icons.dashboard_rounded),
                    label: '',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.landscape_outlined),
                    activeIcon: Icon(Icons.landscape_rounded),
                    label: '',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.event_note_outlined),
                    activeIcon: Icon(Icons.event_note_rounded),
                    label: '',
                  ),
                  BottomNavigationBarItem(
                    icon: _MessageIcon(unread: unread),
                    activeIcon: _MessageIcon(selected: true, unread: unread),
                    label: '',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.person_outline),
                    activeIcon: Icon(Icons.person),
                    label: '',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageIcon extends StatelessWidget {
  const _MessageIcon({this.selected = false, required this.unread});
  final bool selected;
  final int unread;

  @override
  Widget build(BuildContext context) {
    return Badge(
      isLabelVisible: unread > 0,
      label: Text('$unread'),
      backgroundColor: AppColors.gold,
      child: Icon(selected ? Icons.chat_bubble : Icons.chat_bubble_outline),
    );
  }
}

class HostSectionHeader extends StatelessWidget {
  const HostSectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onAction,
  });
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTypography.headingMedium.copyWith(color: AppColors.deep),
          ),
        ),
        if (action != null)
          TextButton(onPressed: onAction, child: Text(action!)),
      ],
    );
  }
}

void showUnavailableNotice(BuildContext context, String action) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          '$action is currently unavailable. No changes were saved.',
        ),
      ),
    );
}
