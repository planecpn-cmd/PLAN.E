import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../theme/theme.dart';
import '../../../widgets/widgets.dart';
import '../../../core/chat_ordering.dart';
import '../domain/host_mode_models.dart';
import 'host_mode_providers.dart';
import 'widgets/host_mode_scaffold.dart';

class HostConversationScreen extends ConsumerStatefulWidget {
  const HostConversationScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<HostConversationScreen> createState() =>
      _HostConversationScreenState();
}

class _HostConversationScreenState
    extends ConsumerState<HostConversationScreen> {
  final composer = TextEditingController();
  final scrollController = ScrollController();
  String? _lastNewestMessageId;
  bool _didInitialScroll = false;
  bool _forceScrollToBottom = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_markRead);
  }

  Future<void> _markRead() async {
    await ref.read(hostModeRepositoryProvider).markConversationRead(widget.id);
    ref.invalidate(hostConversationProvider(widget.id));
    ref.invalidate(hostConversationsProvider);
    ref.invalidate(hostDashboardProvider);
  }

  @override
  void dispose() {
    composer.dispose();
    scrollController.dispose();
    super.dispose();
  }

  void _positionForMessages(List<HostMessage> messages) {
    if (messages.isEmpty) return;
    final newestId = messages.last.id;
    if (_didInitialScroll && newestId == _lastNewestMessageId) return;

    final wasNearBottom =
        !scrollController.hasClients ||
        scrollController.position.maxScrollExtent -
                scrollController.position.pixels <=
            96;
    final shouldScroll =
        !_didInitialScroll || _forceScrollToBottom || wasNearBottom;
    _lastNewestMessageId = newestId;
    _didInitialScroll = true;
    _forceScrollToBottom = false;
    if (!shouldScroll) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !scrollController.hasClients) return;
      final bottom = scrollController.position.maxScrollExtent;
      if (scrollController.position.pixels == bottom) return;
      if (scrollController.position.pixels == 0) {
        scrollController.jumpTo(bottom);
      } else {
        scrollController.animateTo(
          bottom,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final conversation = ref.watch(hostConversationProvider(widget.id));
    return Scaffold(
      appBar: AppBar(
        title: conversation.maybeWhen(
          data: (item) => Text(item?.identity ?? 'Conversation'),
          orElse: () => const Text('Conversation'),
        ),
      ),
      backgroundColor: const Color(0xFFF7F8F5),
      body: AsyncValueView<HostConversation?>(
        value: conversation,
        data: (item) {
          if (item == null) {
            return const EmptyStateView(title: 'Conversation not found');
          }
          final messages = sortHostMessagesChronologically(item.messages);
          _positionForMessages(messages);
          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                color: AppColors.sage,
                child: Column(
                  children: [
                    Text(
                      item.experienceTitle,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.forest,
                      ),
                    ),
                    Text(
                      '${item.isGroup ? 'Departure group' : 'Traveler'} · ${DateFormat('d MMMM y').format(item.departureDate)}',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: messages
                      .map(
                        (message) => Align(
                          key: ValueKey('host-message-${message.id}'),
                          alignment: message.sentByHost
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.sizeOf(context).width * .76,
                            ),
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.fromLTRB(13, 10, 13, 8),
                            decoration: BoxDecoration(
                              color: message.sentByHost
                                  ? AppColors.forest
                                  : AppColors.white,
                              border: Border.all(
                                color: message.sentByHost
                                    ? AppColors.forest
                                    : AppColors.borderSubtle,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  message.text,
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: message.sentByHost
                                        ? AppColors.white
                                        : AppColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  DateFormat('h:mm a').format(message.sentAt),
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    color: message.sentByHost
                                        ? Colors.white70
                                        : AppColors.disabledText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 8, 10),
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    border: Border(
                      top: BorderSide(color: AppColors.borderSubtle),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _attachments,
                        icon: const Icon(Icons.attach_file),
                        tooltip: 'Add attachment',
                      ),
                      Expanded(
                        child: TextField(
                          controller: composer,
                          textCapitalization: TextCapitalization.sentences,
                          maxLength: 2000,
                          decoration: const InputDecoration(
                            hintText: 'Write a message',
                            counterText: '',
                          ),
                        ),
                      ),
                      IconButton.filled(
                        onPressed: _send,
                        icon: const Icon(Icons.send_rounded),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _send() async {
    final text = composer.text.trim();
    if (text.isEmpty) return;
    _forceScrollToBottom = true;
    await ref.read(hostModeRepositoryProvider).sendMessage(widget.id, text);
    composer.clear();
    ref.invalidate(hostConversationProvider(widget.id));
    ref.invalidate(hostConversationsProvider);
  }

  void _attachments() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Add attachment', style: AppTypography.headingMedium),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.photo_outlined),
                title: const Text('Photo'),
                onTap: () {
                  Navigator.pop(context);
                  showUnavailableNotice(context, 'Photo attachments');
                },
              ),
              ListTile(
                leading: const Icon(Icons.insert_drive_file_outlined),
                title: const Text('Document'),
                onTap: () {
                  Navigator.pop(context);
                  showUnavailableNotice(context, 'Document attachments');
                },
              ),
              const Text(
                'Attachment uploads are currently unavailable.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
