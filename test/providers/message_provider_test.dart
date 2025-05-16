import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:sifter/models/message.dart';
import 'package:sifter/providers/riverpod/message_provider.dart';
import 'package:sifter/services/message_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

@GenerateMocks([MessageService])
import 'message_provider_test.mocks.dart';

void main() {
  late MockMessageService mockMessageService;
  late MessageNotifier messageNotifier;

  setUp(() {
    mockMessageService = MockMessageService();
    messageNotifier = MessageNotifier();
  });

  group('MessageNotifier', () {
    test('initial state is initial', () {
      expect(messageNotifier.state.value, const AppState.initial());
    });

    test('loadMessages success', () async {
      final messages = [
        Message(
          id: '1',
          roomId: 'room1',
          senderId: 'user1',
          text: 'Hello',
          timestamp: DateTime.now(),
        ),
      ];

      when(mockMessageService.getMessages('room1'))
          .thenAnswer((_) => Stream.value(
              QuerySnapshot.withConverter(
                docs: messages.map((m) => MockDocumentSnapshot(m)).toList(),
                converter: (_, __) => m,
              ),
            ));

      await messageNotifier.loadMessages('room1');

      expect(messageNotifier.state.value?.isSuccess, true);
      expect(messageNotifier.state.value?.data, messages);
    });

    test('loadMessages error', () async {
      when(mockMessageService.getMessages('room1'))
          .thenThrow(Exception('Failed to load messages'));

      await messageNotifier.loadMessages('room1');

      expect(messageNotifier.state.value?.isError, true);
      expect(messageNotifier.state.value?.errorMessage, 'Exception: Failed to load messages');
    });

    test('sendMessage success', () async {
      when(mockMessageService.sendTextMessage(
        roomId: 'room1',
        senderId: 'user1',
        text: 'Hello',
      )).thenAnswer((_) async => null);

      await messageNotifier.sendMessage(
        roomId: 'room1',
        senderId: 'user1',
        text: 'Hello',
      );

      verify(mockMessageService.sendTextMessage(
        roomId: 'room1',
        senderId: 'user1',
        text: 'Hello',
      )).called(1);
    });
  });
} 