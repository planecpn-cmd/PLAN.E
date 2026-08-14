import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../theme/theme.dart';
import '../../../widgets/widgets.dart';
import '../../../core/chat_ordering.dart';
import '../domain/host_mode_models.dart';
import 'host_mode_providers.dart';
import 'widgets/host_mode_scaffold.dart';

class HostMessagesScreen extends ConsumerStatefulWidget {
  const HostMessagesScreen({super.key, this.initialQuery = ''});
  final String initialQuery;
  @override
  ConsumerState<HostMessagesScreen> createState() => _HostMessagesScreenState();
}

class _HostMessagesScreenState extends ConsumerState<HostMessagesScreen> {
  late final TextEditingController search;
  late String query;

  @override
  void initState() {
    super.initState();
    final routeQuery = widget.initialQuery.trim();
    query = routeQuery.isEmpty
        ? ref.read(hostMessageSearchProvider)
        : routeQuery;
    if (routeQuery.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(hostMessageSearchProvider.notifier).state = routeQuery;
        }
      });
    }
    search = TextEditingController(text: query);
  }

  void _setQuery(String value) {
    ref.read(hostMessageSearchProvider.notifier).state = value;
    setState(() => query = value);
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HostModeScaffold(
      currentIndex: 3,
      title: 'Messages',
      body: AsyncValueView<List<HostConversation>>(
        value: ref.watch(hostConversationsProvider),
        onRetry: () => ref.invalidate(hostConversationsProvider),
        data: (items) {
          final normalized = query.trim().toLowerCase();
          final ordered = sortHostConversationsByLatestActivity(items);
          final visible = normalized.isEmpty
              ? ordered
              : ordered
                    .where(
                      (item) =>
                          '${item.identity} ${item.experienceTitle} ${item.lastMessage}'
                              .toLowerCase()
                              .contains(normalized),
                    )
                    .toList();
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 144),
            children: [
              AppTextField(
                controller: search,
                hint: 'Search people, groups or experiences',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          search.clear();
                          _setQuery('');
                        },
                        icon: const Icon(Icons.close),
                      ),
                onChanged: _setQuery,
              ),
              const SizedBox(height: 14),
              if (visible.isEmpty)
                EmptyStateView(
                  icon: Icons.search_off,
                  title: 'No conversations found',
                  description: 'Try a traveler, group or experience name.',
                  actionLabel: 'Clear search',
                  onActionPressed: () {
                    search.clear();
                    _setQuery('');
                  },
                )
              else
                ...visible.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppCard(
                      onTap: () => context.push('/host/messages/${item.id}'),
                      child: Row(
                        children: [
                          Badge(
                            isLabelVisible: item.unreadCount > 0,
                            label: Text('${item.unreadCount}'),
                            backgroundColor: AppColors.gold,
                            child: CircleAvatar(
                              radius: 23,
                              backgroundColor: AppColors.sage,
                              child: Icon(
                                item.isGroup
                                    ? Icons.groups_outlined
                                    : Icons.person_outline,
                                color: AppColors.forest,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.identity,
                                        style: AppTypography.bodyMedium
                                            .copyWith(
                                              fontWeight: item.unreadCount > 0
                                                  ? FontWeight.w800
                                                  : FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                    Text(
                                      DateFormat(
                                        'h:mm a',
                                      ).format(item.lastMessageAt),
                                      style: AppTypography.caption.copyWith(
                                        fontSize: 10.5,
                                        color: AppColors.disabledText,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(
                                      item.isGroup
                                          ? Icons.groups_2_outlined
                                          : Icons.landscape_outlined,
                                      size: 13,
                                      color: AppColors.forest,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        '${item.experienceTitle} · ${DateFormat('d MMM y').format(item.departureDate)}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.caption.copyWith(
                                          color: AppColors.forest,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  item.lastMessage,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.caption.copyWith(
                                    fontWeight: item.unreadCount > 0
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: AppColors.disabledText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
