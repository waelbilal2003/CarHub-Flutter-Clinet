import '../../../../core/network/dio_client.dart';
import '../../../auth/domain/entities/user.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';

/// التطبيق الوحيد لمستودع الملف الشخصي (API حقيقي).
class ApiProfileRepository implements ProfileRepository {
  final ProfileRemoteDataSource _remote;
  ApiProfileRepository(this._remote);

  @override
  Future<User> getProfile() async {
    try {
      return await _remote.getProfile();
    } catch (e) {
      throw DioClient.mapError(e);
    }
  }

  @override
  Future<User> updateProfile({
    required String name,
    String? email,
    String? phone,
    String? avatarPath,
  }) async {
    try {
      return await _remote.updateProfile(
        name: name,
        email: email,
        phone: phone,
        avatarPath: avatarPath,
      );
    } catch (e) {
      throw DioClient.mapError(e);
    }
  }
}
