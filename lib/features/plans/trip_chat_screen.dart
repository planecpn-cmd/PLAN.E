// RM-11 Trip Chat
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/format.dart';
import '../../core/supabase_client.dart';
import '../../core/trip_attachment_picker.dart';
import '../../core/trip_presence_controller.dart';
import '../../models/trip_message.dart';
import '../../providers/trip_tools_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/private_trip_attachment.dart';
import '../../widgets/trip_presence_indicator.dart';
import 'trip_tools_strings.dart';

class TripChatScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const TripChatScreen({super.key, required this.bookingId});

  @override
  ConsumerState<TripChatScreen> createState() => _TripChatScreenState();
}

class _TripChatScreenState extends ConsumerState<TripChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _lastNewestMessageId;
  bool _didInitialScroll = false;
  bool _forceScrollToBottom = false;
  TripPresenceController? _presence;

  @override
  void initState() {
    super.initState();
    if (!AppSupabaseClient.isInitialized ||
        !TripPresenceController.isValidBookingId(widget.bookingId)) {
      return;
    }
    final client = AppSupabaseClient.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;
    _presence = TripPresenceController(
      client: client,
      bookingId: widget.bookingId,
      userId: userId,
      role: 'traveler',
    );
    unawaited(_presence!.start());
  }

  @override
  void dispose() {
    final presence = _presence;
    _presence = null;
    if (presence != null) unawaited(presence.close());
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text;
    if (text.trim().isEmpty) return;

    _messageController.clear();
    unawaited(_presence?.stopTyping() ?? Future<void>.value());
    _forceScrollToBottom = true;
    ref.read(tripChatProvider(widget.bookingId).notifier).sendMessage(text);
  }

  void _positionForMessages(List<TripMessage> messages) {
    if (messages.isEmpty) return;
    final newestId = messages.last.id;
    if (_didInitialScroll && newestId == _lastNewestMessageId) return;

    final wasNearBottom =
        !_scrollController.hasClients ||
        _scrollController.position.maxScrollExtent -
                _scrollController.position.pixels <=
            96;
    final shouldScroll =
        !_didInitialScroll || _forceScrollToBottom || wasNearBottom;
    _lastNewestMessageId = newestId;
    _didInitialScroll = true;
    _forceScrollToBottom = false;
    if (!shouldScroll) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final bottom = _scrollController.position.maxScrollExtent;
      if (_scrollController.position.pixels == bottom) return;
      if (_scrollController.position.pixels == 0 &&
          _lastNewestMessageId == messages.last.id) {
        _scrollController.jumpTo(bottom);
      } else {
        _scrollController.animateTo(
          bottom,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(tripChatProvider(widget.bookingId));
    final chatRepo = ref.watch(tripChatRepositoryProvider);
    final String? currentUserId = chatRepo.currentUserId;

    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        title: Text(
          TripToolsStrings.tripChatTitle,
          style: AppTypography.headingMedium.copyWith(color: AppColors.ink),
        ),
        backgroundColor: AppColors.ivory,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_presence != null)
              ValueListenableBuilder<TripPresenceSnapshot>(
                valueListenable: _presence!,
                builder: (context, snapshot, _) => TripPresenceIndicator(
                  snapshot: snapshot,
                  viewerRole: 'traveler',
                ),
              ),
            Expanded(
              child: AsyncValueView<List<TripMessage>>(
                value: messagesAsync,
                isEmpty: (messages) => messages.isEmpty,
                emptyView: const EmptyStateView(
                  title: TripToolsStrings.chatEmptyTitle,
                  description: TripToolsStrings.chatEmptyDesc,
                  actionLabel: null,
                ),
                onRetry: () =>
                    ref.invalidate(tripChatProvider(widget.bookingId)),
                data: (messages) {
                  _positionForMessages(messages);
                  return ListView.builder(
                    controller: _scrollController,
                    padding: AppSpacing.screenPadding,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final bool isMe =
                          message.senderId == currentUserId ||
                          message.senderName ==
                              TripToolsStrings.meSenderLabel ||
                          message.isPending ||
                          message.isFailed;

                      return _buildMessageBubble(
                        context,
                        key: ValueKey('trip-message-${message.id}'),
                        message: message,
                        isMe: isMe,
                      );
                    },
                  );
                },
              ),
            ),
            _buildInputBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
    BuildContext context, {
    required Key key,
    required TripMessage message,
    required bool isMe,
  }) {
    final String timeFormatted = AppFormatters.formatTripDate(
      message.createdAt,
      pattern: 'h:mm a',
    );

    return Align(
      key: key,
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => _showMessageActions(message, isMe),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs4),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md12,
            vertical: AppSpacing.sm8,
          ),
          decoration: BoxDecoration(
            color: isMe ? AppColors.forest : AppColors.cardBackground,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(AppRadii.md16),
              topRight: const Radius.circular(AppRadii.md16),
              bottomLeft: Radius.circular(isMe ? AppRadii.md16 : AppRadii.sm8),
              bottomRight: Radius.circular(isMe ? AppRadii.sm8 : AppRadii.md16),
            ),
            border: isMe ? null : Border.all(color: AppColors.borderSubtle),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (!isMe && message.senderName != null) ...[
                Text(
                  message.senderName!,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.gold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs4),
              ],
              if (message.attachmentUrl != null) ...[
                PrivateTripAttachment(storagePath: message.attachmentUrl!),
                const SizedBox(height: AppSpacing.xs4),
              ],
              Text(
                message.body,
                style: AppTypography.bodyMedium.copyWith(
                  color: isMe ? AppColors.ivory : AppColors.ink,
                ),
              ),
              const SizedBox(height: AppSpacing.xs4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    timeFormatted,
                    style: AppTypography.caption.copyWith(
                      color: isMe
                          ? AppColors.ivory.withValues(alpha: 0.7)
                          : AppColors.disabledText,
                      fontSize: 10,
                    ),
                  ),
                  if (message.isEdited && !message.isDeleted) ...[
                    const SizedBox(width: AppSpacing.xs4),
                    Text(
                      'edited',
                      style: AppTypography.caption.copyWith(
                        color: isMe
                            ? AppColors.ivory.withValues(alpha: 0.7)
                            : AppColors.disabledText,
                        fontSize: 9,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  if (message.isPending) ...[
                    const SizedBox(width: AppSpacing.xs4),
                    const SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.ivory,
                        ),
                      ),
                    ),
                  ],
                  if (message.isFailed) ...[
                    const SizedBox(width: AppSpacing.xs4),
                    GestureDetector(
                      onTap: () {
                        ref
                            .read(tripChatProvider(widget.bookingId).notifier)
                            .retryMessage(message);
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 12,
                            color: AppColors.errorContainer,
                          ),
                          const SizedBox(width: AppSpacing.xs4),
                          Text(
                            TripToolsStrings.retryAction,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.errorContainer,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (isMe &&
                      !message.isPending &&
                      !message.isFailed &&
                      message.isDelivered) ...[
                    const SizedBox(width: AppSpacing.xs4),
                    Icon(
                      message.isSeen ? Icons.done_all : Icons.done,
                      size: 13,
                      color: message.isSeen
                          ? AppColors.gold
                          : AppColors.ivory.withValues(alpha: 0.75),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showMessageActions(TripMessage message, bool isMe) async {
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
            if (isMe && !message.isDeleted) ...[
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit message'),
                onTap: () => Navigator.pop(context, 'edit'),
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: AppColors.error,
                ),
                title: const Text('Delete message'),
                onTap: () => Navigator.pop(context, 'delete'),
              ),
            ] else if (!isMe) ...[
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: const Text('Report message'),
                onTap: () => Navigator.pop(context, 'report'),
              ),
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
    if (action == 'block') {
      await _blockParticipant(message.senderId);
    }
  }

  Future<void> _reportMessage(TripMessage message) async {
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
      await ref
          .read(tripChatRepositoryProvider)
          .reportMessage(messageId: message.id, reason: reason);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report submitted for review.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Report failed: $error')));
      }
    }
  }

  Future<void> _blockParticipant(String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block participant?'),
        content: const Text(
          'Neither participant will be able to send messages until you unblock them.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Block'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref
        .read(tripChatRepositoryProvider)
        .blockParticipant(conversationId: widget.bookingId, userId: userId);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Participant blocked.')));
    }
  }

  Future<void> _editMessage(TripMessage message) async {
    final controller = TextEditingController(text: message.body);
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
      await ref
          .read(tripChatProvider(widget.bookingId).notifier)
          .editMessage(message, body);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Edit failed: $error')));
      }
    }
  }

  Future<void> _deleteMessage(TripMessage message) async {
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
      await ref
          .read(tripChatProvider(widget.bookingId).notifier)
          .deleteMessage(message);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Delete failed: $error')));
      }
    }
  }

  Widget _buildInputBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg16,
        vertical: AppSpacing.sm8,
      ),
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(top: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              onPressed: _showAttachmentPicker,
              icon: const Icon(Icons.attach_file),
              tooltip: 'Add attachment',
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                style: AppTypography.bodyMedium.copyWith(color: AppColors.ink),
                decoration: InputDecoration(
                  hintText: TripToolsStrings.typeMessageHint,
                  hintStyle: AppTypography.bodyMedium.copyWith(
                    color: AppColors.disabledText,
                  ),
                  filled: true,
                  fillColor: AppColors.sage,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg16,
                    vertical: AppSpacing.sm8,
                  ),
                  border: const OutlineInputBorder(
                    borderRadius: AppRadii.borderPill,
                    borderSide: BorderSide.none,
                  ),
                ),
                textInputAction: TextInputAction.send,
                onChanged: (value) =>
                    _presence?.updateTyping(value.trim().isNotEmpty),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: AppSpacing.sm8),
            Container(
              decoration: const BoxDecoration(
                color: AppColors.forest,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.send_rounded,
                  color: AppColors.ivory,
                  size: 20,
                ),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAttachmentPicker() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_outlined),
              title: const Text('Photo'),
              onTap: () async {
                Navigator.pop(context);
                await _pickAndSend(
                  () => TripAttachmentPicker.pickPhoto(ImageSource.gallery),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Camera'),
              onTap: () async {
                Navigator.pop(context);
                await _pickAndSend(
                  () => TripAttachmentPicker.pickPhoto(ImageSource.camera),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file_outlined),
              title: const Text('Document'),
              onTap: () async {
                Navigator.pop(context);
                await _pickAndSend(TripAttachmentPicker.pickDocument);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndSend(
    Future<SelectedTripAttachment?> Function() pick,
  ) async {
    try {
      final selected = await pick();
      if (selected == null || !mounted) return;
      final caption = _messageController.text.trim();
      _messageController.clear();
      unawaited(_presence?.stopTyping() ?? Future<void>.value());
      _forceScrollToBottom = true;
      await ref
          .read(tripChatProvider(widget.bookingId).notifier)
          .sendAttachment(
            bytes: selected.bytes,
            fileName: selected.fileName,
            mimeType: selected.mimeType,
            caption: caption.isEmpty ? 'Attachment' : caption,
          );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Attachment failed: $error')));
    }
  }
}
