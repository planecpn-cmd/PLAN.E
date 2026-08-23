import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../core/chat_ordering.dart';
import '../core/message_outbox.dart';
import '../models/budget_entry.dart';
import '../models/gear_checklist_item.dart';
import '../models/trip_message.dart';
import '../repositories/budget_repository.dart';
import '../repositories/gear_checklist_repository.dart';
import '../repositories/trip_chat_repository.dart';
import 'app_providers.dart';

// Repository Providers
final tripChatRepositoryProvider = Provider<TripChatRepository>((ref) {
  return TripChatRepository(ref.watch(supabaseClientProvider));
});

final gearChecklistRepositoryProvider = Provider<GearChecklistRepository>((
  ref,
) {
  return GearChecklistRepository(ref.watch(supabaseClientProvider));
});

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepository(ref.watch(supabaseClientProvider));
});

// Realtime Trip Chat Provider & StateNotifier
class TripChatNotifier extends StateNotifier<AsyncValue<List<TripMessage>>> {
  final TripChatRepository _repository;
  final String bookingId;
  StreamSubscription<List<TripMessage>>? _realtimeSubscription;
  StreamSubscription<List<TripMessageReceiptSnapshot>>? _receiptSubscription;
  StreamSubscription<List<TripMessageMutationSnapshot>>? _mutationSubscription;
  final List<TripMessage> _outboxMessages = [];
  List<TripMessage> _remoteMessages = [];
  static const _uuid = Uuid();

  TripChatNotifier(this._repository, this.bookingId)
    : super(const AsyncValue.loading()) {
    _initChat();
  }

  void _initChat() async {
    final userId = _repository.currentUserId;
    var persisted = <OutboxMessage>[];
    if (userId != null) {
      persisted = await MessageOutboxStore.loadConversation(
        userId: userId,
        conversationId: bookingId,
        senderMode: MessageSenderMode.traveler,
      );
      _outboxMessages
        ..clear()
        ..addAll(persisted.map(_tripMessageFromOutbox));
      _updateMergedState();
    }
    try {
      final initialMessages = await _repository.getMessages(bookingId);
      _remoteMessages = mergeTripMessagesChronologically(initialMessages);
      _updateMergedState();
      unawaited(_markRead());
    } catch (err, stack) {
      if (mounted) {
        state = AsyncValue.error(err, stack);
      }
    }

    _realtimeSubscription = _repository
        .streamMessages(bookingId)
        .listen(
          (realtimeList) {
            _remoteMessages = mergeTripMessagesChronologically([
              ..._remoteMessages,
              ...realtimeList,
            ]);
            _updateMergedState();
            unawaited(_markRead());
          },
          onError: (err, stack) {
            // Keep existing merged state if stream emits error
          },
        );

    _receiptSubscription = _repository.streamReceipts(bookingId).listen(
      (rows) {
        final delivered = <String>{};
        final seen = <String>{};
        for (final row in rows) {
          if (row.isDelivered) delivered.add(row.messageId);
          if (row.isSeen) seen.add(row.messageId);
        }
        _remoteMessages = _remoteMessages
            .map(
              (message) => message.copyWith(
                isDelivered: delivered.contains(message.id),
                isSeen: seen.contains(message.id),
              ),
            )
            .toList();
        _updateMergedState();
      },
      onError: (_, __) {},
    );

    _mutationSubscription = _repository.streamMutations(bookingId).listen(
      (rows) {
        final byMessage = {for (final row in rows) row.messageId: row};
        _remoteMessages = _remoteMessages.map((message) {
          final mutation = byMessage[message.id];
          return mutation == null
              ? message
              : message.withMutation(
                  effectiveBody: mutation.effectiveBody,
                  editedAt: mutation.editedAt,
                  deletedAt: mutation.deletedAt,
                );
        }).toList();
        _updateMergedState();
      },
      onError: (_, __) {},
    );

    for (final item in persisted) {
      await _sendPersisted(item.copyWith(isFailed: false));
    }
  }

  Future<void> _markRead() async {
    try {
      await _repository.markConversationRead(bookingId);
    } catch (_) {
      // Read state is best-effort and must never make an otherwise available
      // conversation fail to render.
    }
  }

  void _updateMergedState() {
    if (!mounted) return;
    state = AsyncValue.data(
      mergeTripMessagesChronologically([
        ..._outboxMessages,
        ..._remoteMessages,
      ]),
    );
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // The optimistic row and Postgres insert share an ID, so a realtime echo
    // replaces it instead of briefly rendering a duplicate.
    final String tempId = _uuid.v4();
    final String currentUserId = _repository.currentUserId ?? 'local-user';

    final pendingMsg = TripMessage(
      id: tempId,
      bookingId: bookingId,
      senderId: currentUserId,
      senderName: 'You',
      body: text.trim(),
      createdAt: DateTime.now().toUtc(),
      isPending: true,
      isFailed: false,
    );

    _outboxMessages.add(pendingMsg);
    _updateMergedState();
    final item = OutboxMessage(
      clientMessageId: tempId,
      conversationId: bookingId,
      userId: currentUserId,
      senderMode: MessageSenderMode.traveler,
      body: text.trim(),
      createdAt: pendingMsg.createdAt,
    );
    await MessageOutboxStore.upsert(item);
    await _sendPersisted(item);
  }

  Future<void> sendAttachment({
    required Uint8List bytes,
    required String fileName,
    String? mimeType,
    String caption = 'Photo attachment',
  }) async {
    final userId = _repository.currentUserId;
    if (userId == null) return;
    final clientMessageId = _uuid.v4();
    final uploaded = await _repository.uploadAttachment(
      bookingId: bookingId,
      clientMessageId: clientMessageId,
      bytes: bytes,
      fileName: fileName,
      reportedMimeType: mimeType,
    );
    final item = OutboxMessage(
      clientMessageId: clientMessageId,
      conversationId: bookingId,
      userId: userId,
      senderMode: MessageSenderMode.traveler,
      body: caption.trim().isEmpty ? 'Photo attachment' : caption.trim(),
      attachmentUrl: uploaded.storagePath,
      attachmentMimeType: uploaded.mimeType,
      attachmentSizeBytes: uploaded.sizeBytes,
      createdAt: DateTime.now().toUtc(),
    );
    await MessageOutboxStore.upsert(item);
    _outboxMessages.add(_tripMessageFromOutbox(item));
    _updateMergedState();
    await _sendPersisted(item);
  }

  Future<void> retryMessage(TripMessage msg) async {
    final userId = _repository.currentUserId;
    if (userId == null) return;
    await _sendPersisted(
      OutboxMessage(
        clientMessageId: msg.id,
        conversationId: bookingId,
        userId: userId,
        senderMode: MessageSenderMode.traveler,
        body: msg.body,
        attachmentUrl: msg.attachmentUrl,
        attachmentMimeType: msg.attachmentMimeType,
        attachmentSizeBytes: msg.attachmentSizeBytes,
        createdAt: msg.createdAt,
      ),
    );
  }

  Future<void> editMessage(TripMessage message, String body) async {
    final normalized = body.trim();
    if (normalized.isEmpty || normalized.length > 2000) return;
    await _repository.editMessage(message.id, normalized);
    _remoteMessages = _remoteMessages
        .map(
          (item) => item.id == message.id
              ? item.withMutation(
                  effectiveBody: normalized,
                  editedAt: DateTime.now().toUtc(),
                )
              : item,
        )
        .toList();
    _updateMergedState();
  }

  Future<void> deleteMessage(TripMessage message) async {
    await _repository.deleteMessage(message.id);
    _remoteMessages = _remoteMessages
        .map(
          (item) => item.id == message.id
              ? item.withMutation(deletedAt: DateTime.now().toUtc())
              : item,
        )
        .toList();
    _updateMergedState();
  }

  TripMessage _tripMessageFromOutbox(OutboxMessage item) => TripMessage(
    id: item.clientMessageId,
    bookingId: item.conversationId,
    senderId: item.userId,
    senderName: 'You',
    body: item.body,
    attachmentUrl: item.attachmentUrl,
    attachmentMimeType: item.attachmentMimeType,
    attachmentSizeBytes: item.attachmentSizeBytes,
    createdAt: item.createdAt,
    isPending: !item.isFailed,
    isFailed: item.isFailed,
  );

  Future<void> _sendPersisted(OutboxMessage item) async {
    final pending = item.copyWith(isFailed: false);
    await MessageOutboxStore.upsert(pending);
    final index = _outboxMessages.indexWhere(
      (message) => message.id == item.clientMessageId,
    );
    if (index == -1) {
      _outboxMessages.add(_tripMessageFromOutbox(pending));
    } else {
      _outboxMessages[index] = _tripMessageFromOutbox(pending);
    }
    _updateMergedState();
    try {
      final sentMsg = await _repository.sendMessage(
        bookingId: item.conversationId,
        body: item.body,
        messageId: item.clientMessageId,
        attachmentUrl: item.attachmentUrl,
      );
      if (item.attachmentUrl != null &&
          item.attachmentMimeType != null &&
          item.attachmentSizeBytes != null) {
        await _repository.registerAttachment(
          messageId: sentMsg.id,
          storagePath: item.attachmentUrl!,
          mimeType: item.attachmentMimeType!,
          sizeBytes: item.attachmentSizeBytes!,
        );
      }
      _outboxMessages.removeWhere(
        (message) => message.id == item.clientMessageId,
      );
      await MessageOutboxStore.remove(
        userId: item.userId,
        clientMessageId: item.clientMessageId,
      );
      _remoteMessages = mergeTripMessagesChronologically([
        ..._remoteMessages,
        sentMsg,
      ]);
    } catch (_) {
      final failed = item.copyWith(isFailed: true);
      await MessageOutboxStore.upsert(failed);
      final failedIndex = _outboxMessages.indexWhere(
        (message) => message.id == item.clientMessageId,
      );
      if (failedIndex != -1) {
        _outboxMessages[failedIndex] = _tripMessageFromOutbox(failed);
      }
    }
    _updateMergedState();
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    _receiptSubscription?.cancel();
    _mutationSubscription?.cancel();
    super.dispose();
  }
}

final tripChatProvider =
    StateNotifierProvider.family<
      TripChatNotifier,
      AsyncValue<List<TripMessage>>,
      String
    >((ref, bookingId) {
      final repo = ref.watch(tripChatRepositoryProvider);
      return TripChatNotifier(repo, bookingId);
    });

// Interactive Gear Checklist Provider & StateNotifier
class GearChecklistNotifier
    extends StateNotifier<AsyncValue<List<GearChecklistItem>>> {
  final GearChecklistRepository _repository;
  final String bookingId;

  GearChecklistNotifier(this._repository, this.bookingId)
    : super(const AsyncValue.loading()) {
    loadItems();
  }

  Future<void> loadItems() async {
    state = const AsyncValue.loading();
    try {
      final items = await _repository.getItems(bookingId);
      state = AsyncValue.data(items);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  Future<void> toggleItem(String itemId) async {
    final currentData = state.valueOrNull;
    if (currentData == null) return;

    final index = currentData.indexWhere((item) => item.id == itemId);
    if (index == -1) return;

    final targetItem = currentData[index];
    final updatedItem = targetItem.copyWith(isChecked: !targetItem.isChecked);

    final updatedList = List<GearChecklistItem>.from(currentData);
    updatedList[index] = updatedItem;
    state = AsyncValue.data(updatedList);

    try {
      await _repository.toggleItem(itemId, updatedItem.isChecked);
    } catch (e) {
      // Revert on remote error
      state = AsyncValue.data(currentData);
    }
  }

  Future<void> addItem(String label) async {
    if (label.trim().isEmpty) return;

    try {
      final newItem = await _repository.addItem(bookingId, label.trim());
      final currentList = state.valueOrNull ?? [];
      state = AsyncValue.data([...currentList, newItem]);
    } catch (e) {
      // Re-throw or let state stay unchanged
    }
  }

  Future<void> deleteItem(String itemId) async {
    final currentList = state.valueOrNull ?? [];
    final updatedList = currentList.where((item) => item.id != itemId).toList();
    state = AsyncValue.data(updatedList);

    try {
      await _repository.deleteItem(itemId);
    } catch (e) {
      state = AsyncValue.data(currentList);
    }
  }
}

final gearChecklistProvider =
    StateNotifierProvider.family<
      GearChecklistNotifier,
      AsyncValue<List<GearChecklistItem>>,
      String
    >((ref, bookingId) {
      final repo = ref.watch(gearChecklistRepositoryProvider);
      return GearChecklistNotifier(repo, bookingId);
    });

// Interactive Budget Tracker Provider & StateNotifier
class BudgetTrackerNotifier
    extends StateNotifier<AsyncValue<List<BudgetEntry>>> {
  final BudgetRepository _repository;
  final String bookingId;

  BudgetTrackerNotifier(this._repository, this.bookingId)
    : super(const AsyncValue.loading()) {
    loadEntries();
  }

  Future<void> loadEntries() async {
    state = const AsyncValue.loading();
    try {
      final entries = await _repository.getBudgetEntries(bookingId);
      state = AsyncValue.data(entries);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  Future<void> addExpense({
    required String label,
    required int amountPaisa,
    required String category,
    DateTime? spentOn,
  }) async {
    if (label.trim().isEmpty || amountPaisa <= 0) return;

    try {
      final newEntry = await _repository.addBudgetEntry(
        bookingId: bookingId,
        label: label.trim(),
        amountPaisa: amountPaisa,
        category: category,
        spentOn: spentOn ?? DateTime.now().toUtc(),
      );

      final currentList = state.valueOrNull ?? [];
      state = AsyncValue.data([newEntry, ...currentList]);
    } catch (e) {
      // Handle error
    }
  }

  Future<void> deleteExpense(String entryId) async {
    final currentList = state.valueOrNull ?? [];
    final updatedList = currentList
        .where((entry) => entry.id != entryId)
        .toList();
    state = AsyncValue.data(updatedList);

    try {
      await _repository.deleteBudgetEntry(entryId);
    } catch (e) {
      state = AsyncValue.data(currentList);
    }
  }
}

final budgetTrackerProvider =
    StateNotifierProvider.family<
      BudgetTrackerNotifier,
      AsyncValue<List<BudgetEntry>>,
      String
    >((ref, bookingId) {
      final repo = ref.watch(budgetRepositoryProvider);
      return BudgetTrackerNotifier(repo, bookingId);
    });
