import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/message_repository.dart';
import '../datasources/message_remote_datasource.dart';

class ApiMessageRepository implements MessageRepository {
  final MessageRemoteDataSource _remote;
  ApiMessageRepository(this._remote);

  @override
  Future<PaginatedList<Conversation>> conversations({int page = 1}) async {
    try {
      return await _remote.conversations(page: page);
    } catch (e) {
      throw DioClient.mapError(e);
    }
  }

  @override
  Future<PaginatedList<Message>> chat(int id, {int page = 1}) async {
    try {
      return await _remote.chat(id, page: page);
    } catch (e) {
      throw DioClient.mapError(e);
    }
  }

  @override
  Future<Message> send({
    required int receiverId,
    required String content,
    int? tenderId,
  }) async {
    try {
      return await _remote.send(
        receiverId: receiverId,
        content: content,
        tenderId: tenderId,
      );
    } catch (e) {
      throw DioClient.mapError(e);
    }
  }
}
