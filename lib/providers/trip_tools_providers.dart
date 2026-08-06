import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

final gearChecklistRepositoryProvider = Provider<GearChecklistRepository>((ref) {
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
  final List<TripMessage> _outboxMessages = [];
  List<TripMessage> _remoteMessages = [];

  TripChatNotifier(this._repository, this.bookingId)
      : super(const AsyncValue.loading()) {
    _initChat();
  }

  void _initChat() async {
    try {
      final initialMessages = await _repository.getMessages(bookingId);
      _remoteMessages = initialMessages;
      _updateMergedState();
    } catch (err, stack) {
      if (mounted) {
        state = AsyncValue.error(err, stack);
      }
    }

    _realtimeSubscription = _repository.streamMessages(bookingId).listen(
      (realtimeList) {
        _remoteMessages = realtimeList;
        _updateMergedState();
      },
      onError: (err, stack) {
        // Keep existing merged state if stream emits error
      },
    );
  }

  void _updateMergedState() {
    if (!mounted) return;
    final List<TripMessage> combined = List.from(_remoteMessages);

    // Append pending/failed local outbox messages if not already in remote list
    for (final outboxMsg in _outboxMessages) {
      if (!combined.any((m) => m.id == outboxMsg.id)) {
        combined.add(outboxMsg);
      }
    }

    combined.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    state = AsyncValue.data(combined);
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final String tempId = 'outbox_${DateTime.now().millisecondsSinceEpoch}';
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

    try {
      final sentMsg = await _repository.sendMessage(
        bookingId: bookingId,
        body: text.trim(),
      );
      _outboxMessages.removeWhere((m) => m.id == tempId);
      if (!_remoteMessages.any((m) => m.id == sentMsg.id)) {
        _remoteMessages.add(sentMsg);
      }
      _updateMergedState();
    } catch (e) {
      final index = _outboxMessages.indexWhere((m) => m.id == tempId);
      if (index != -1) {
        _outboxMessages[index] = pendingMsg.copyWith(
          isPending: false,
          isFailed: true,
        );
      }
      _updateMergedState();
    }
  }

  Future<void> retryMessage(TripMessage msg) async {
    final index = _outboxMessages.indexWhere((m) => m.id == msg.id);
    if (index != -1) {
      _outboxMessages[index] = msg.copyWith(
        isPending: true,
        isFailed: false,
      );
      _updateMergedState();
    }

    try {
      final sentMsg = await _repository.sendMessage(
        bookingId: bookingId,
        body: msg.body,
      );
      _outboxMessages.removeWhere((m) => m.id == msg.id);
      if (!_remoteMessages.any((m) => m.id == sentMsg.id)) {
        _remoteMessages.add(sentMsg);
      }
      _updateMergedState();
    } catch (e) {
      final idx = _outboxMessages.indexWhere((m) => m.id == msg.id);
      if (idx != -1) {
        _outboxMessages[idx] = msg.copyWith(
          isPending: false,
          isFailed: true,
        );
      }
      _updateMergedState();
    }
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    super.dispose();
  }
}

final tripChatProvider = StateNotifierProvider.family<
    TripChatNotifier,
    AsyncValue<List<TripMessage>>,
    String>((ref, bookingId) {
  final repo = ref.watch(tripChatRepositoryProvider);
  return TripChatNotifier(repo, bookingId);
});

// Interactive Gear Checklist Provider & StateNotifier
class GearChecklistNotifier extends StateNotifier<AsyncValue<List<GearChecklistItem>>> {
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

final gearChecklistProvider = StateNotifierProvider.family<
    GearChecklistNotifier,
    AsyncValue<List<GearChecklistItem>>,
    String>((ref, bookingId) {
  final repo = ref.watch(gearChecklistRepositoryProvider);
  return GearChecklistNotifier(repo, bookingId);
});

// Interactive Budget Tracker Provider & StateNotifier
class BudgetTrackerNotifier extends StateNotifier<AsyncValue<List<BudgetEntry>>> {
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
    final updatedList = currentList.where((entry) => entry.id != entryId).toList();
    state = AsyncValue.data(updatedList);

    try {
      await _repository.deleteBudgetEntry(entryId);
    } catch (e) {
      state = AsyncValue.data(currentList);
    }
  }
}

final budgetTrackerProvider = StateNotifierProvider.family<
    BudgetTrackerNotifier,
    AsyncValue<List<BudgetEntry>>,
    String>((ref, bookingId) {
  final repo = ref.watch(budgetRepositoryProvider);
  return BudgetTrackerNotifier(repo, bookingId);
});
