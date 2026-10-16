import '../../../../core/network/api_response.dart';
import '../entities/conversation.dart';
import '../entities/message.dart';

abstract interface class MessageRepository {
  Future<PaginatedList<Conversation>> conversations({int page});

  /// رسائل محادثة محددة.
  /// ⚠️ يحتاج تأكيد إسراء: هل [id] معرّف المحادثة أم معرّف الطرف الآخر؟
  Future<PaginatedList<Message>> chat(int id, {int page});

  Future<Message> send({
    required int receiverId,
    required String content,
    int? tenderId,
  });
}
