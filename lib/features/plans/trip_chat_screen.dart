// RM-11 Trip Chat
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../models/trip_message.dart';
import '../../providers/trip_tools_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/empty_state_view.dart';
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

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text;
    if (text.trim().isEmpty) return;

    _messageController.clear();
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
              ],
            ),
          ],
        ),
      ),
    );
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
}
