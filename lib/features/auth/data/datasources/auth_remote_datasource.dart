import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../models/user_model.dart';

/// مصدر بيانات المصادقة — يتحدّث مع الـ API مباشرة.
///
/// أشكال الاستجابة (من ملف Postman حرفياً):
///   POST /auth/register → data.user + data.token
///   POST /auth/login    → data.user + data.token
///   GET  /auth/me       → data.user
///   POST /auth/change-password → data = null
///   POST /auth/logout          → data = null
class AuthRemoteDataSource {
  final DioClient _client;
  AuthRemoteDataSource(this._client);

  Future<({UserModel user, String token})> login({
    required String email,
    required String password,
  }) async {
    final res = await _client.dio.post(ApiEndpoints.login, data: {
      'email': email,
      'password': password,
    });
    return _parseAuth(res.data);
  }

  Future<({UserModel user, String token})> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
    required String type,
  }) async {
    final res = await _client.dio.post(ApiEndpoints.register, data: {
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      'type': type,
    });
    return _parseAuth(res.data);
  }

  Future<UserModel> getCurrentUser() async {
    final res = await _client.dio.get(ApiEndpoints.me);
    final envelope = ApiEnvelope.from(res.data);
    return UserModel.fromJson(envelope.objectAt('user'));
  }

  Future<void> changePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    final res = await _client.dio.post(ApiEndpoints.changePassword, data: {
      'current_password': currentPassword,
      'password': password,
      'password_confirmation': passwordConfirmation,
    });
    // يتحقق من success ويرمي Failure عند الفشل المنطقي.
    ApiEnvelope.from(res.data);
  }

  Future<void> logout() async {
    final res = await _client.dio.post(ApiEndpoints.logout);
    ApiEnvelope.from(res.data);
  }

  /// يفكّ الاستجابة التي تحوي data.user و data.token.
  ({UserModel user, String token}) _parseAuth(dynamic body) {
    final envelope = ApiEnvelope.from(body);
    return (
      user: UserModel.fromJson(envelope.objectAt('user')),
      token: envelope.valueAt<String>('token'),
    );
  }
}
