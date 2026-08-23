import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:plan_e/core/message_outbox.dart';
import 'package:plan_e/models/trip_message.dart';
import 'package:plan_e/providers/trip_tools_providers.dart';
import 'package:plan_e/repositories/trip_chat_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('outbox survives a fresh read and preserves failed state', () async {
    final item = OutboxMessage(
      clientMessageId: 'message-1',
      conversationId: 'booking-1',
      userId: 'user-1',
      senderMode: MessageSenderMode.traveler,
      body: 'Namaste',
      attachmentUrl: 'booking-1/user-1/message-1.jpg',
      attachmentMimeType: 'image/jpeg',
      attachmentSizeBytes: 1024,
      createdAt: DateTime.utc(2026, 8, 16),
      isFailed: true,
    );

    await MessageOutboxStore.upsert(item);
    final restored = await MessageOutboxStore.loadConversation(
      userId: 'user-1',
      conversationId: 'booking-1',
      senderMode: MessageSenderMode.traveler,
    );

    expect(restored, hasLength(1));
    expect(restored.single.clientMessageId, 'message-1');
    expect(restored.single.isFailed, isTrue);
    expect(restored.single.attachmentMimeType, 'image/jpeg');
    expect(restored.single.attachmentSizeBytes, 1024);
  });

  test('upsert deduplicates retries by client message id', () async {
    final item = OutboxMessage(
      clientMessageId: 'stable-id',
      conversationId: 'booking-1',
      userId: 'user-1',
      senderMode: MessageSenderMode.host,
      body: 'Hello',
      createdAt: DateTime.utc(2026, 8, 16),
    );

    await MessageOutboxStore.upsert(item);
    await MessageOutboxStore.upsert(item.copyWith(isFailed: true));
    final restored = await MessageOutboxStore.loadConversation(
      userId: 'user-1',
      conversationId: 'booking-1',
      senderMode: MessageSenderMode.host,
    );

    expect(restored, hasLength(1));
    expect(restored.single.isFailed, isTrue);
  });

  test('outbox is isolated by user, conversation and sender mode', () async {
    Future<void> save(
      String id,
      String user,
      String conversation,
      MessageSenderMode mode,
    ) => MessageOutboxStore.upsert(
      OutboxMessage(
        clientMessageId: id,
        conversationId: conversation,
        userId: user,
        senderMode: mode,
        body: id,
        createdAt: DateTime.utc(2026, 8, 16),
      ),
    );

    await save('wanted', 'user-1', 'booking-1', MessageSenderMode.traveler);
    await save('other-user', 'user-2', 'booking-1', MessageSenderMode.traveler);
    await save(
      'other-booking',
      'user-1',
      'booking-2',
      MessageSenderMode.traveler,
    );
    await save('other-mode', 'user-1', 'booking-1', MessageSenderMode.host);

    final restored = await MessageOutboxStore.loadConversation(
      userId: 'user-1',
      conversationId: 'booking-1',
      senderMode: MessageSenderMode.traveler,
    );
    expect(restored.map((item) => item.clientMessageId), ['wanted']);

    await MessageOutboxStore.clearUser('user-1');
    expect(
      await MessageOutboxStore.loadConversation(
        userId: 'user-1',
        conversationId: 'booking-1',
        senderMode: MessageSenderMode.traveler,
      ),
      isEmpty,
    );
    expect(
      await MessageOutboxStore.loadConversation(
        userId: 'user-2',
        conversationId: 'booking-1',
        senderMode: MessageSenderMode.traveler,
      ),
      hasLength(1),
    );
  });

  test('TripChatNotifier replays and removes a persisted message', () async {
    final queued = OutboxMessage(
      clientMessageId: 'replay-id',
      conversationId: 'booking-1',
      userId: 'user-1',
      senderMode: MessageSenderMode.traveler,
      body: 'Replay me',
      createdAt: DateTime.utc(2026, 8, 16),
      isFailed: true,
    );
    await MessageOutboxStore.upsert(queued);
    final repository = _ReplayRepository();
    final notifier = TripChatNotifier(repository, 'booking-1');
    addTearDown(notifier.dispose);

    for (var i = 0; i < 8; i++) {
      await Future<void>.delayed(Duration.zero);
    }

    expect(repository.sentIds, ['replay-id']);
    expect(
      await MessageOutboxStore.loadConversation(
        userId: 'user-1',
        conversationId: 'booking-1',
        senderMode: MessageSenderMode.traveler,
      ),
      isEmpty,
    );
    expect(
      notifier.state.value!.where((message) => message.id == 'replay-id'),
      hasLength(1),
    );
  });
}

class _ReplayRepository extends TripChatRepository {
  _ReplayRepository() : super(SupabaseClient('http://localhost', 'test-key'));

  final List<String> sentIds = [];

  @override
  String get currentUserId => 'user-1';

  @override
  Future<List<TripMessage>> getMessages(String bookingId) async => [];

  @override
  Stream<List<TripMessage>> streamMessages(String bookingId) =>
      const Stream.empty();

  @override
  Future<void> markConversationRead(String bookingId) async {}

  @override
  Future<TripMessage> sendMessage({
    required String bookingId,
    required String body,
    required String messageId,
    String? attachmentUrl,
  }) async {
    sentIds.add(messageId);
    return TripMessage(
      id: messageId,
      bookingId: bookingId,
      senderId: currentUserId,
      body: body,
      createdAt: DateTime.now().toUtc(),
    );
  }
}
