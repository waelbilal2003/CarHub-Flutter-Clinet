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
  static const clientsOnlyMessage =
      'المساعد الذكي متاح لحسابات العملاء فقط.';
  static const tooManyMessage =
      'أرسلت رسائل كثيرة في وقت قصير. انتظر قليلاً ثم أعد المحاولة.';
  static const tooFastMessage = 'انتظر لحظة قبل سؤالك التالي.';
  static const dailyLimitMessage =
      'وصلت للحد اليومي للمساعد. يتجدد رصيدك غداً.';
  static const monthlyLimitMessage =
      'وصلت للحد الشهري للمساعد. يتجدد رصيدك أول الشهر القادم.';
  static const invalidMessageText =
      'الرسالة يجب أن تكون بين 1 و300 حرف.';
  static const conversationGoneMessage =
      'تعذّر متابعة هذه المحادثة. ابدأ محادثة جديدة.';
  static const invalidRequestMessage =
      'تعذّر إرسال الرسالة. راجعها ثم أعد المحاولة.';

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
      throw limitReached(e) ?? mapAiError(e);
    }
  }

  /// 429 AI_LIMIT_REACHED -> [AiLimitReached] مع خيار الإعلان، وإلا null.
  static AiLimitReached? limitReached(DioException e) {
    if (e.response?.statusCode != 429 || _code(e) != 'AI_LIMIT_REACHED') return null;
    final raw = e.response?.data;
    final data = raw is Map && raw['data'] is Map
        ? Map<String, dynamic>.from(raw['data'] as Map)
        : const <String, dynamic>{};
    final limit = data['limit'] == 'monthly' ? 'monthly' : 'daily';
    final ads = data['ads_remaining_today'];
    return AiLimitReached(
      limit == 'monthly' ? monthlyLimitMessage : dailyLimitMessage,
      limit: limit,
      canWatchAd: data['can_watch_ad'] == true,
      adsRemainingToday: ads is int ? ads : 0,
    );
  }

  static String? _code(DioException e) {
    final data = e.response?.data;
    final errors = data is Map ? data['errors'] : null;
    final codes = errors is Map ? errors['code'] : null;
    return codes is List && codes.isNotEmpty ? codes.first?.toString() : null;
  }

  /// حالات خاصة بالمساعد، برسائل ثابتة من التطبيق لا من نص الخادم: رسائل
  /// التحقق تصل من Laravel مفاتيحَ غير مترجمة (validation.required)، و429 من
  /// throttle لا يأتي بشكل المشروع. الباقي (401/الشبكة/5xx) عبر [DioClient.mapError].
  static Failure mapAiError(DioException e) {
    if (e.type == DioExceptionType.receiveTimeout) {
      return const NetworkFailure(timeoutMessage);
    }
    switch (e.response?.statusCode) {
      case 503:
        return const ServerFailure(unavailableMessage);
      case 403:
        return const AuthFailure(clientsOnlyMessage);
      case 429:
        // AI_TOO_FAST (ثانيتان بين سؤالين) أو throttle:api العام. AI_LIMIT_REACHED في [limitReached].
        return _code(e) == 'AI_TOO_FAST'
            ? const ValidationFailure(tooFastMessage)
            : const ValidationFailure(tooManyMessage);
      case 422:
        final data = e.response?.data;
        final errors = data is Map ? data['errors'] : null;
        if (errors is Map && errors.containsKey('conversation_id')) {
          return const ValidationFailure(conversationGoneMessage);
        }
        if (errors is Map && errors.containsKey('message')) {
          return const ValidationFailure(invalidMessageText);
        }
        return const ValidationFailure(invalidRequestMessage);
    }
    return DioClient.mapError(e);
  }
}
