import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../errors/failures.dart';
import '../errors/server_message_ar.dart';
import '../storage/token_storage.dart';

/// عميل الشبكة الموحّد المبني على Dio.
///
/// مسؤولياته:
///  1. قراءة عنوان الخادم والمهلات من [AppConfig] (مكان واحد).
///  2. إرفاق توكن Sanctum تلقائياً بكل طلب.
///  3. إضافة هيدر ngrok لتجاوز صفحة التحذير.
///  4. تحويل أي خطأ إلى [Failure] برسالة عربية مفهومة للمستخدم.
class DioClient {
  final Dio dio;
  final TokenStorage _tokenStorage;

  DioClient(this._tokenStorage) : dio = Dio() {
    dio.options
      ..baseUrl = AppConfig.apiBaseUrl
      ..connectTimeout = AppConfig.connectTimeout
      ..receiveTimeout = AppConfig.receiveTimeout
      ..sendTimeout = AppConfig.sendTimeout
      ..headers = {
        'Accept': 'application/json',
        // بدون هذا الهيدر تعترض ngrok الطلب بصفحة HTML بدل JSON.
        if (AppConfig.isNgrokTunnel) 'ngrok-skip-browser-warning': 'true',
      }
      // نستقبل كل أكواد الحالة ونعالجها بأنفسنا في onResponse أدناه،
      // ليكون تحويل الأخطاء إلى Failure في مكان واحد.
      ..validateStatus = (status) => status != null && status < 500;

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.readToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          _log('→ ${options.method} ${options.uri}');
          handler.next(options);
        },

        onResponse: (response, handler) async {
          _log('← ${response.statusCode} ${response.requestOptions.uri}');

          final status = response.statusCode ?? 0;
          if (status >= 400) {
            // نحوّله إلى خطأ ليمرّ عبر onError ثم mapError.
            return handler.reject(
              DioException(
                requestOptions: response.requestOptions,
                response: response,
                type: DioExceptionType.badResponse,
              ),
            );
          }
          handler.next(response);
        },

        onError: (DioException e, handler) async {
          _log('✖ ${e.response?.statusCode ?? e.type} ${e.requestOptions.uri}');

          // جلسة منتهية: نمسح التوكن، وطبقة الحالة تعيد التوجيه لتسجيل الدخول.
          if (e.response?.statusCode == 401) {
            await _tokenStorage.deleteToken();
          }
          handler.next(e);
        },
      ),
    );
  }

  static void _log(String message) {
    if (AppConfig.enableNetworkLogs && kDebugMode) {
      developer.log(message, name: 'CarHub/API');
    }
  }

  /// يحوّل أي خطأ إلى [Failure] برسالة عربية.
  /// تستدعيه الـ repositories داخل كتلة catch.
  static Failure mapError(Object error) {
    // أخطاء منطقية رميناها نحن (مثل success = false) تمرّ كما هي.
    if (error is Failure) return error;

    if (error is! DioException) return const UnknownFailure();

    // انقطاع الشبكة أو انتهاء المهلة
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError) {
      return const NetworkFailure();
    }

    final status = error.response?.statusCode;
    final data = error.response?.data;

    // حالة خاصة مهمة أثناء التطوير: نفق ngrok متوقف.
    // ngrok يردّ بصفحة نصية تحوي ERR_NGROK_3200 بدل استجابة JSON.
    if (_looksLikeNgrokOffline(data)) {
      return const ServerFailure(
        'خادم التطوير غير متصل حالياً (نفق ngrok متوقّف). '
        'تأكّد من تشغيل الخادم ثم أعد المحاولة.',
      );
    }

    if (status == 401) {
      // 401 على مسار الدخول = بيانات خاطئة، وعلى غيره = جلسة منتهية.
      final isLoginAttempt =
          error.requestOptions.path.contains('/auth/login');
      return AuthFailure(
        _extractMessage(data) ??
            (isLoginAttempt
                ? 'البريد الإلكتروني أو كلمة المرور غير صحيحة.'
                : 'انتهت جلستك. سجّل الدخول من جديد للمتابعة.'),
      );
    }
    if (status == 403) {
      return AuthFailure(
        _extractMessage(data) ?? 'لا تملك صلاحية تنفيذ هذا الإجراء.',
      );
    }
    if (status == 404) {
      return NotFoundFailure(
        _extractMessage(data) ?? 'العنصر المطلوب غير موجود.',
      );
    }
    if (status == 419) {
      return const AuthFailure(
        'انتهت صلاحية الجلسة. سجّل الدخول من جديد للمتابعة.',
      );
    }
    if (status == 429) {
      return const ValidationFailure(
        'حاولت كثيراً في وقت قصير. انتظر قليلاً ثم أعد المحاولة.',
      );
    }
    if (status == 422 || status == 400) {
      return ValidationFailure(
        _extractMessage(data) ?? 'تأكّد من البيانات المُدخلة ثم أعد المحاولة.',
        fieldErrors: _extractFieldErrors(data),
      );
    }
    if (status != null && status >= 500) {
      // لا نعرض نصّ استثناء Laravel للمستخدم مهما كان: هو إنجليزي
      // وتقني، ويكشف تفاصيل داخلية عن الخادم. يبقى في سجلّ التطوير فقط.
      _log('خطأ خادم ($status): ${_rawMessage(data) ?? '—'}');
      return const ServerFailure(
        'حدث خلل مؤقّت في الخادم. حاول مرة أخرى بعد قليل.',
      );
    }

    return UnknownFailure(
      _extractMessage(data) ?? 'تعذّر إتمام العملية. حاول مرة أخرى.',
    );
  }

  static bool _looksLikeNgrokOffline(dynamic data) {
    if (data is String) {
      return data.contains('ERR_NGROK') || data.contains('is offline');
    }
    return false;
  }

  /// يحوّل `errors` في استجابة Laravel إلى خريطة «اسم الحقل ← أول رسالة».
  ///
  /// كل رسالة تمرّ عبر [translateServerMessage]، لأن Laravel هنا يعمل
  /// بـ APP_LOCALE=en فتصل رسائل التحقق إنجليزية. هذه الخريطة هي ما
  /// يُعرض تحت كل حقل في النماذج، فلا يجوز أن يظهر فيها نص إنجليزي.
  static Map<String, String> _extractFieldErrors(dynamic data) {
    if (data is! Map) return const {};
    final errors = data['errors'];
    if (errors is! Map) return const {};

    final result = <String, String>{};
    errors.forEach((key, value) {
      final String? raw;
      if (value is List && value.isNotEmpty) {
        raw = value.first.toString();
      } else if (value is String) {
        raw = value;
      } else {
        raw = null;
      }
      if (raw != null) {
        result[key.toString()] = translateServerMessage(raw);
      }
    });
    return result;
  }

  /// يقرأ رسالة الخطأ من استجابة Laravel **مُعرَّبة**.
  /// يدعم الشكلين:
  ///   { "message": "..." }
  ///   { "message": "...", "errors": { "email": ["..."] } }
  static String? _extractMessage(dynamic data) {
    final raw = _rawMessage(data);
    if (raw == null) return null;
    return translateServerMessage(raw);
  }

  /// النص الخام كما ورد من الخادم — للسجلّات فقط، لا يُعرض للمستخدم.
  static String? _rawMessage(dynamic data) {
    if (data is! Map) return null;

    // أخطاء التحقق أدقّ من الرسالة العامة، فنفضّلها.
    final errors = data['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final first = errors.values.first;
      if (first is List && first.isNotEmpty) return first.first.toString();
      if (first is String) return first;
    }

    final message = data['message'];
    if (message is String && message.isNotEmpty) return message;

    return null;
  }
}
