import 'package:dio/dio.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/ai_reply.dart';

/// مصدر بيانات المساعد الذكي — `POST /ai/ask` (CONTRACTS.md §1).
///
/// التطبيق لا يتصل بخدمة الذكاء مباشرة أبداً؛ Laravel هو البوابة.
class AiRemoteDataSource {
  final DioClient _client;
  AiRemoteDataSource(this._client);

  /// رسالة 503 من الـ Backend (AI_UNAVAILABLE) — نعرض نصّاً لطيفاً ثابتاً.
  static const unavailableMessage =
      'المساعد غير متاح حالياً. جرّب بعد قليل، أو تصفّح السوق مباشرة.';
  static const timeoutMessage =
      'المساعد تأخّر في الرد أكثر من المعتاد. أعد المحاولة بعد قليل.';

  Future<AiReply> ask({
    required String message,
    String? conversationId,
    String? city,
  }) async {
    try {
      final res = await _client.dio.post(
        ApiEndpoints.aiAsk,
        data: {
          'message': message,
          'conversation_id': conversationId,
          'context': {'city': city},
        },
        // ردّ النموذج قد يستغرق عشرات الثواني: مهلة خاصة بهذا الطلب وحده.
        options: Options(receiveTimeout: AppConfig.aiReceiveTimeout),
      );
      final envelope = ApiEnvelope.from(res.data);
      return AiReply.fromJson(envelope.object);
    } on DioException catch (e) {
      throw _mapAiError(e);
    }
  }

  /// حالات خاصة بالمساعد؛ الباقي (401/403/422/429/الشبكة) عبر [DioClient.mapError].
  static Failure _mapAiError(DioException e) {
    if (e.type == DioExceptionType.receiveTimeout) {
      return const NetworkFailure(timeoutMessage);
    }
    if (e.response?.statusCode == 503) {
      return const ServerFailure(unavailableMessage);
    }
    return DioClient.mapError(e);
  }
}
