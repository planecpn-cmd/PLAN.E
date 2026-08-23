import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/message_outbox.dart';
import '../../../core/supabase_client.dart';
import '../../../core/trip_attachment_picker.dart';
import '../../../core/trip_presence_controller.dart';
import '../../../providers/trip_tools_providers.dart';
import '../../../theme/theme.dart';
import '../../../widgets/widgets.dart';
import '../../../widgets/private_trip_attachment.dart';
import '../../../widgets/trip_presence_indicator.dart';
import '../../../core/chat_ordering.dart';
import '../domain/host_mode_models.dart';
import 'host_mode_providers.dart';

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
  String? _lastMarkedReadMessageId;
  final List<HostMessage> _outboxMessages = [];
  bool _didInitialScroll = false;
  bool _forceScrollToBottom = false;
  TripPresenceController? _presence;

  @override
  void initState() {
    super.initState();
    if (AppSupabaseClient.isInitialized &&
        TripPresenceController.isValidBookingId(widget.id)) {
      final client = AppSupabaseClient.client;
      final userId = client.auth.currentUser?.id;
      if (userId != null) {
        _presence = TripPresenceController(
          client: client,
          bookingId: widget.id,
          userId: userId,
          role: 'host',
        );
        unawaited(_presence!.start());
      }
    }
    Future.microtask(_restoreOutbox);
  }

  Future<void> _restoreOutbox() async {
    final userId = ref.read(hostModeRepositoryProvider).currentUserId;
    if (userId == null) return;
    final persisted = await MessageOutboxStore.loadConversation(
      userId: userId,
      conversationId: widget.id,
      senderMode: MessageSenderMode.host,
    );
    if (!mounted) return;
    setState(() {
      _outboxMessages
        ..clear()
        ..addAll(persisted.map(_hostMessageFromOutbox));
    });
    for (final item in persisted) {
      await _deliver(item.copyWith(isFailed: false));
    }
  }

  void _markLatestMessageRead(String messageId) {
    if (_lastMarkedReadMessageId == messageId) return;
    _lastMarkedReadMessageId = messageId;
    Future.microtask(() async {
      try {
        await ref
            .read(hostModeRepositoryProvider)
            .markConversationRead(widget.id);
        ref.invalidate(hostConversationsProvider);
        ref.invalidate(hostDashboardProvider);
      } catch (_) {
        // Read state is best-effort; chat remains usable during a temporary
        // read-cursor write failure.
      }
    });
  }

  @override
  void dispose() {
    final presence = _presence;
    _presence = null;
    if (presence != null) unawaited(presence.close());
    composer.dispose();
    scrollController.dispose();
    super.dispose();
  }

  void _positionForMessages(List<HostMessage> messages) {
    if (messages.isEmpty) return;
    final newestId = messages.last.id;
    _markLatestMessageRead(newestId);
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
          final messages = sortHostMessagesChronologically([
            ...item.messages,
            ..._outboxMessages,
          ]);
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
              if (_presence != null)
                ValueListenableBuilder<TripPresenceSnapshot>(
                  valueListenable: _presence!,
                  builder: (context, snapshot, _) => TripPresenceIndicator(
                    snapshot: snapshot,
                    viewerRole: 'host',
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
                          child: GestureDetector(
                            onLongPress: () => _showMessageActions(message),
                            child: Container(
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.sizeOf(context).width * .76,
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
                                  if (message.attachmentUrl != null) ...[
                                    PrivateTripAttachment(
                                      storagePath: message.attachmentUrl!,
                                    ),
                                    const SizedBox(height: 6),
                                  ],
                                  Text(
                                    message.text,
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: message.sentByHost
                                          ? AppColors.white
                                          : AppColors.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        DateFormat(
                                          'h:mm a',
                                        ).format(message.sentAt),
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          color: message.sentByHost
                                              ? Colors.white70
                                              : AppColors.disabledText,
                                        ),
                                      ),
                                      if (message.isEdited &&
                                          !message.isDeleted) ...[
                                        const SizedBox(width: 5),
                                        Text(
                                          'edited',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontStyle: FontStyle.italic,
                                            color: message.sentByHost
                                                ? Colors.white70
                                                : AppColors.disabledText,
                                          ),
                                        ),
                                      ],
                                      if (message.isPending) ...[
                                        const SizedBox(width: 5),
                                        const SizedBox(
                                          width: 10,
                                          height: 10,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 1.4,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                      if (message.isFailed) ...[
                                        const SizedBox(width: 5),
                                        GestureDetector(
                                          onTap: () => _retry(message.id),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.error_outline,
                                                size: 12,
                                                color: AppColors.errorContainer,
                                              ),
                                              SizedBox(width: 3),
                                              Text(
                                                'Retry',
                                                style: TextStyle(
                                                  fontSize: 9.5,
                                                  color:
                                                      AppColors.errorContainer,
                                                  decoration:
                                                      TextDecoration.underline,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      if (message.sentByHost &&
                                          !message.isPending &&
                                          !message.isFailed &&
                                          message.isDelivered) ...[
                                        const SizedBox(width: 5),
                                        Icon(
                                          message.isSeen
                                              ? Icons.done_all
                                              : Icons.done,
                                          size: 13,
                                          color: message.isSeen
                                              ? AppColors.gold
                                              : Colors.white70,
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
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
                          onChanged: (value) =>
                              _presence?.updateTyping(value.trim().isNotEmpty),
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

  Future<void> _showMessageActions(HostMessage message) async {
    if (message.isPending || message.isFailed) {
      return;
    }
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.sentByHost && !message.isDeleted) ...[
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit message'),
                onTap: () => Navigator.pop(context, 'edit'),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.error),
                title: const Text('Delete message'),
                onTap: () => Navigator.pop(context, 'delete'),
              ),
            ] else if (!message.sentByHost) ...[
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: const Text('Report message'),
                onTap: () => Navigator.pop(context, 'report'),
              ),
              if (message.senderId != null)
                ListTile(
                  leading: const Icon(Icons.block, color: AppColors.error),
                  title: const Text('Block participant'),
                  onTap: () => Navigator.pop(context, 'block'),
                ),
            ],
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (action == 'edit') await _editMessage(message);
    if (action == 'delete') await _deleteMessage(message);
    if (action == 'report') await _reportMessage(message);
    if (action == 'block' && message.senderId != null) {
      await _blockParticipant(message.senderId!);
    }
  }

  Future<void> _reportMessage(HostMessage message) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Why are you reporting this?'),
        children: [
          for (final option in const {
            'harassment': 'Harassment',
            'spam': 'Spam',
            'scam': 'Scam or fraud',
            'unsafe': 'Unsafe behavior',
            'hate': 'Hate speech',
            'other': 'Other',
          }.entries)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, option.key),
              child: Text(option.value),
            ),
        ],
      ),
    );
    if (reason == null || !mounted) return;
    try {
      await ref.read(tripChatRepositoryProvider).reportMessage(
        messageId: message.id,
        reason: reason,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report submitted for review.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Report failed: $error')),
        );
      }
    }
  }

  Future<void> _blockParticipant(String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block participant?'),
        content: const Text('Neither participant will be able to send messages until you unblock them.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Block')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(tripChatRepositoryProvider).blockParticipant(
      conversationId: widget.id,
      userId: userId,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Participant blocked.')),
      );
    }
  }

  Future<void> _editMessage(HostMessage message) async {
    final controller = TextEditingController(text: message.text);
    final body = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit message'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 2000,
          maxLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (body == null || body.trim().isEmpty || !mounted) return;
    try {
      await ref.read(tripChatRepositoryProvider).editMessage(message.id, body);
      ref.invalidate(hostConversationProvider(widget.id));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Edit failed: $error')));
      }
    }
  }

  Future<void> _deleteMessage(HostMessage message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete message?'),
        content: const Text(
          'The message will be hidden for everyone while retained for safety review.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(tripChatRepositoryProvider).deleteMessage(message.id);
      ref.invalidate(hostConversationProvider(widget.id));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Delete failed: $error')));
      }
    }
  }

  Future<void> _send() async {
    final text = composer.text.trim();
    if (text.isEmpty) return;
    _forceScrollToBottom = true;
    composer.clear();
    unawaited(_presence?.stopTyping() ?? Future<void>.value());
    final userId = ref.read(hostModeRepositoryProvider).currentUserId;
    if (userId == null) return;
    final item = OutboxMessage(
      clientMessageId: const Uuid().v4(),
      conversationId: widget.id,
      userId: userId,
      senderMode: MessageSenderMode.host,
      body: text,
      createdAt: DateTime.now().toUtc(),
    );
    await MessageOutboxStore.upsert(item);
    if (mounted) {
      setState(() => _outboxMessages.add(_hostMessageFromOutbox(item)));
    }
    await _deliver(item);
  }

  HostMessage _hostMessageFromOutbox(OutboxMessage item) => HostMessage(
    id: item.clientMessageId,
    text: item.body,
    sentByHost: true,
    sentAt: item.createdAt,
    isPending: !item.isFailed,
    isFailed: item.isFailed,
    attachmentUrl: item.attachmentUrl,
  );

  Future<void> _retry(String clientMessageId) async {
    final userId = ref.read(hostModeRepositoryProvider).currentUserId;
    if (userId == null) return;
    final items = await MessageOutboxStore.loadConversation(
      userId: userId,
      conversationId: widget.id,
      senderMode: MessageSenderMode.host,
    );
    final matches = items.where(
      (item) => item.clientMessageId == clientMessageId,
    );
    if (matches.isNotEmpty) await _deliver(matches.first);
  }

  Future<void> _deliver(OutboxMessage item) async {
    final pending = item.copyWith(isFailed: false);
    await MessageOutboxStore.upsert(pending);
    _replaceOutboxMessage(_hostMessageFromOutbox(pending));
    try {
      await ref
          .read(hostModeRepositoryProvider)
          .sendMessage(
            widget.id,
            item.body,
            clientMessageId: item.clientMessageId,
            attachmentUrl: item.attachmentUrl,
          );
      if (item.attachmentUrl != null &&
          item.attachmentMimeType != null &&
          item.attachmentSizeBytes != null) {
        await ref
            .read(tripChatRepositoryProvider)
            .registerAttachment(
              messageId: item.clientMessageId,
              storagePath: item.attachmentUrl!,
              mimeType: item.attachmentMimeType!,
              sizeBytes: item.attachmentSizeBytes!,
            );
      }
      await MessageOutboxStore.remove(
        userId: item.userId,
        clientMessageId: item.clientMessageId,
      );
      if (mounted) {
        setState(
          () => _outboxMessages.removeWhere(
            (message) => message.id == item.clientMessageId,
          ),
        );
      }
      ref.invalidate(hostConversationProvider(widget.id));
      ref.invalidate(hostConversationsProvider);
    } catch (_) {
      final failed = item.copyWith(isFailed: true);
      await MessageOutboxStore.upsert(failed);
      _replaceOutboxMessage(_hostMessageFromOutbox(failed));
    }
  }

  void _replaceOutboxMessage(HostMessage replacement) {
    if (!mounted) return;
    setState(() {
      final index = _outboxMessages.indexWhere(
        (message) => message.id == replacement.id,
      );
      if (index == -1) {
        _outboxMessages.add(replacement);
      } else {
        _outboxMessages[index] = replacement;
      }
    });
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
                onTap: () async {
                  Navigator.pop(context);
                  await _pickAndSendAttachment(
                    () => TripAttachmentPicker.pickPhoto(ImageSource.gallery),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickAndSendAttachment(
                    () => TripAttachmentPicker.pickPhoto(ImageSource.camera),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.insert_drive_file_outlined),
                title: const Text('Document'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickAndSendAttachment(
                    TripAttachmentPicker.pickDocument,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndSendAttachment(
    Future<SelectedTripAttachment?> Function() pick,
  ) async {
    try {
      final selected = await pick();
      if (selected != null) await _sendAttachment(selected);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Attachment failed: $error')));
    }
  }

  Future<void> _sendAttachment(SelectedTripAttachment selected) async {
    final userId = ref.read(hostModeRepositoryProvider).currentUserId;
    if (userId == null) return;
    final clientMessageId = const Uuid().v4();
    try {
      final uploaded = await ref
          .read(tripChatRepositoryProvider)
          .uploadAttachment(
            bookingId: widget.id,
            clientMessageId: clientMessageId,
            bytes: selected.bytes,
            fileName: selected.fileName,
            reportedMimeType: selected.mimeType,
          );
      final caption = composer.text.trim();
      composer.clear();
      unawaited(_presence?.stopTyping() ?? Future<void>.value());
      final item = OutboxMessage(
        clientMessageId: clientMessageId,
        conversationId: widget.id,
        userId: userId,
        senderMode: MessageSenderMode.host,
        body: caption.isEmpty ? 'Attachment' : caption,
        attachmentUrl: uploaded.storagePath,
        attachmentMimeType: uploaded.mimeType,
        attachmentSizeBytes: uploaded.sizeBytes,
        createdAt: DateTime.now().toUtc(),
      );
      await MessageOutboxStore.upsert(item);
      _replaceOutboxMessage(_hostMessageFromOutbox(item));
      await _deliver(item);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Attachment failed: $error')));
    }
  }
}
