import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';

/// مصدر بيانات المحادثات.
///
/// من ملف Postman:
///   GET  /messages      → data.data[] محادثات + meta
///   GET  /messages/{id} → data.data[] رسائل + meta
///   POST /messages      → الكائن (رسالة) مباشرة داخل data (multipart)
class MessageRemoteDataSource {
  final DioClient _client;
  MessageRemoteDataSource(this._client);

  Future<PaginatedList<Conversation>> conversations({int page = 1}) async {
    final res = await _client.dio.get(
      ApiEndpoints.messages,
      queryParameters: {'page': page},
    );
    final envelope = ApiEnvelope.from(res.data);
    return envelope.paginated(Conversation.fromJson);
  }

  Future<PaginatedList<Message>> chat(int id, {int page = 1}) async {
    final res = await _client.dio.get(
      ApiEndpoints.chat(id),
      queryParameters: {'page': page},
    );
    final envelope = ApiEnvelope.from(res.data);
    return envelope.paginated(Message.fromJson);
  }

  Future<Message> send({
    required int receiverId,
    required String content,
    int? tenderId,
  }) async {
    final formData = FormData.fromMap({
      'receiver_id': receiverId.toString(),
      'content': content,
      if (tenderId != null) 'tender_id': tenderId.toString(),
    });

    final res = await _client.dio.post(ApiEndpoints.messages, data: formData);
    final envelope = ApiEnvelope.from(res.data);
    return Message.fromJson(envelope.object);
  }
}
