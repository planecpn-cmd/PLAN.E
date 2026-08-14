import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plan_e/core/chat_ordering.dart';
import 'package:plan_e/features/host/data/mock_host_mode_repository.dart';
import 'package:plan_e/features/host/domain/host_mode_models.dart';
import 'package:plan_e/features/host/presentation/host_conversation_screen.dart';
import 'package:plan_e/features/host/presentation/host_mode_providers.dart';
import 'package:plan_e/models/trip_message.dart';
import 'package:plan_e/providers/trip_tools_providers.dart';
import 'package:plan_e/repositories/trip_chat_repository.dart';
import 'package:plan_e/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _baseTime = DateTime.utc(2026, 8, 14, 5, 49);

TripMessage _tripMessage(String id, int minutes, {String? body}) => TripMessage(
  id: id,
  bookingId: 'booking-1',
  senderId: 'user-1',
  body: body ?? id,
  createdAt: _baseTime.add(Duration(minutes: minutes)),
);

HostMessage _hostMessage(String id, int minutes) => HostMessage(
  id: id,
  text: id,
  sentByHost: true,
  sentAt: _baseTime.add(Duration(minutes: minutes)),
);

HostConversation _conversation(String id, List<HostMessage> messages) =>
    HostConversation(
      id: id,
      identity: id,
      experienceId: 'experience-$id',
      experienceTitle: 'Experience $id',
      departureDate: DateTime.utc(2026, 9, 18),
      isGroup: true,
      unreadCount: 0,
      messages: messages,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('canonical message ordering', () {
    test('messages render oldest to newest using timestamps', () {
      final ordered = mergeTripMessagesChronologically([
        _tripMessage('latest', 30),
        _tripMessage('oldest', 0),
        _tripMessage('middle', 10),
      ]);

      expect(ordered.map((message) => message.id), [
        'oldest',
        'middle',
        'latest',
      ]);
    });

    test('new sent and realtime messages take chronological positions', () {
      final ordered = mergeTripMessagesChronologically([
        _tripMessage('first', 0),
        _tripMessage('sent', 30),
        _tripMessage('received', 20),
      ]);

      expect(ordered.map((message) => message.id), [
        'first',
        'received',
        'sent',
      ]);
      expect(ordered.last.id, 'sent');
    });

    test('optimistic and realtime copies with one ID are not duplicated', () {
      final optimistic = _tripMessage('stable-id', 0).copyWith(isPending: true);
      final backend = _tripMessage('stable-id', 1);

      final merged = mergeTripMessagesChronologically([optimistic, backend]);

      expect(merged, hasLength(1));
      expect(merged.single.isPending, isFalse);
      expect(merged.single.createdAt, backend.createdAt);
    });
  });

  group('inbox activity ordering', () {
    test('conversations sort by last_message_at descending', () {
      final conversations = sortHostConversationsByLatestActivity([
        _conversation('older', [_hostMessage('old', 0)]),
        _conversation('newer', [_hostMessage('new', 30)]),
        _conversation('middle', [_hostMessage('mid', 10)]),
      ]);

      expect(conversations.map((item) => item.id), [
        'newer',
        'middle',
        'older',
      ]);
    });

    test('sending or receiving promotes that conversation to the top', () {
      final active = _conversation('active', [_hostMessage('active-old', 20)]);
      final updated = _conversation('updated', [
        _hostMessage('updated-old', 0),
        _hostMessage('updated-new', 40),
      ]);

      final conversations = sortHostConversationsByLatestActivity([
        active,
        updated,
      ]);

      expect(conversations.first.id, 'updated');
      expect(conversations.first.lastMessage, 'updated-new');
    });
  });

  test(
    'realtime echo replaces optimistic message in TripChatNotifier',
    () async {
      final repository = _TripChatTestRepository([_tripMessage('initial', 0)]);
      final notifier = TripChatNotifier(repository, 'booking-1');
      addTearDown(notifier.dispose);
      await _flushAsync();

      final send = notifier.sendMessage('Hello');
      await _flushAsync();
      final stableId = repository.lastSentId!;
      repository.emit([
        _tripMessage('initial', 0),
        _tripMessage(stableId, 10, body: 'Hello'),
      ]);
      await _flushAsync();

      final duringRealtime = notifier.state.requireValue;
      expect(
        duringRealtime.where((message) => message.id == stableId),
        hasLength(1),
      );
      expect(duringRealtime.last.id, stableId);

      repository.completeSend(_tripMessage(stableId, 10, body: 'Hello'));
      await send;
      final afterBackend = notifier.state.requireValue;
      expect(
        afterBackend.where((message) => message.id == stableId),
        hasLength(1),
      );
      expect(afterBackend.last.id, stableId);
    },
  );

  testWidgets('opening a host conversation starts at the newest messages', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final messages = List.generate(
      35,
      (index) => _hostMessage('message-$index', index),
    );
    final repository = _HostChatTestRepository(
      _conversation('conversation-1', messages.reversed.toList()),
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [hostModeRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const HostConversationScreen(id: 'conversation-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final listView = tester.widget<ListView>(find.byType(ListView));
    final position = listView.controller!.position;
    expect(position.pixels, position.maxScrollExtent);
    expect(find.text('message-34'), findsOneWidget);
  });
}

Future<void> _flushAsync() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

class _TripChatTestRepository extends TripChatRepository {
  _TripChatTestRepository(this.initial)
    : super(SupabaseClient('http://localhost', 'test-key'));

  final List<TripMessage> initial;
  final _stream = StreamController<List<TripMessage>>.broadcast();
  Completer<TripMessage>? _sendCompleter;
  String? lastSentId;

  @override
  Future<List<TripMessage>> getMessages(String bookingId) async => initial;

  @override
  Stream<List<TripMessage>> streamMessages(String bookingId) => _stream.stream;

  @override
  String? get currentUserId => 'user-1';

  @override
  Future<TripMessage> sendMessage({
    required String bookingId,
    required String body,
    required String messageId,
    String? attachmentUrl,
  }) {
    lastSentId = messageId;
    _sendCompleter = Completer<TripMessage>();
    return _sendCompleter!.future;
  }

  void emit(List<TripMessage> messages) => _stream.add(messages);

  void completeSend(TripMessage message) => _sendCompleter!.complete(message);
}

class _HostChatTestRepository extends MockHostModeRepository {
  _HostChatTestRepository(this.conversation);

  HostConversation conversation;
  final _changes = StreamController<List<HostConversation>>.broadcast();

  @override
  Future<List<HostConversation>> getConversations() async => [conversation];

  @override
  Stream<List<HostConversation>> watchConversations() async* {
    yield [conversation];
    yield* _changes.stream;
  }

  @override
  Future<void> markConversationRead(String id) async {}

  void dispose() => _changes.close();
}
