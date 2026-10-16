import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/datasources/message_remote_datasource.dart';
import '../../data/repositories/api_message_repository.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/message_repository.dart';

final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ApiMessageRepository(MessageRemoteDataSource(dioClient));
});

/// قائمة المحادثات — GET /messages
final conversationsProvider = FutureProvider<List<Conversation>>((ref) async {
  final result = await ref.watch(messageRepositoryProvider).conversations();
  return result.items;
});

/// رسائل محادثة محددة — GET /messages/{id}
final chatProvider = FutureProvider.family<List<Message>, int>((ref, id) async {
  final result = await ref.watch(messageRepositoryProvider).chat(id);
  return result.items;
});

class SendMessageState {
  final bool isSending;
  final String? error;
  const SendMessageState({this.isSending = false, this.error});
}

final sendMessageProvider =
    StateNotifierProvider<SendMessageController, SendMessageState>((ref) {
  return SendMessageController(ref);
});

class SendMessageController extends StateNotifier<SendMessageState> {
  final Ref _ref;
  SendMessageController(this._ref) : super(const SendMessageState());

  Future<bool> send({
    required int receiverId,
    required String content,
    int? tenderId,
    int? refreshChatId,
  }) async {
    state = const SendMessageState(isSending: true);
    try {
      await _ref.read(messageRepositoryProvider).send(
            receiverId: receiverId,
            content: content,
            tenderId: tenderId,
          );
      state = const SendMessageState(isSending: false);
      if (refreshChatId != null) _ref.invalidate(chatProvider(refreshChatId));
      _ref.invalidate(conversationsProvider);
      return true;
    } catch (e) {
      state = SendMessageState(isSending: false, error: e.toString());
      return false;
    }
  }
}
