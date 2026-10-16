import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/data/models/user_model.dart';

/// مصدر بيانات الملف الشخصي.
///
/// من ملف Postman:
///   GET  /auth/me      → data.user
///   POST /auth/profile → multipart (name, email, phone, avatar) → data.user
class ProfileRemoteDataSource {
  final DioClient _client;
  ProfileRemoteDataSource(this._client);

  Future<UserModel> getProfile() async {
    final res = await _client.dio.get(ApiEndpoints.me);
    final envelope = ApiEnvelope.from(res.data);
    return UserModel.fromJson(envelope.objectAt('user'));
  }

  Future<UserModel> updateProfile({
    required String name,
    String? email,
    String? phone,
    String? avatarPath,
  }) async {
    final formData = FormData.fromMap({
      'name': name,
      if (email != null && email.isNotEmpty) 'email': email,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (avatarPath != null && avatarPath.isNotEmpty)
        'avatar': await MultipartFile.fromFile(avatarPath),
    });

    final res = await _client.dio.post(
      ApiEndpoints.updateProfile,
      data: formData,
    );
    final envelope = ApiEnvelope.from(res.data);
    return UserModel.fromJson(envelope.objectAt('user'));
  }
}
