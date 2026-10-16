import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

/// التطبيق الوحيد لمستودع المصادقة — يتصل بالـ API الحقيقي.
/// (لا يوجد تطبيق Mock بعد الآن: كل تسجيل دخول يمرّ عبر الخادم فعلياً.)
class ApiAuthRepository implements AuthRepository {
  final AuthRemoteDataSource _remote;
  final TokenStorage _tokenStorage;

  ApiAuthRepository(this._remote, this._tokenStorage);

  @override
  Future<User> login({required String email, required String password}) async {
    try {
      final result = await _remote.login(email: email, password: password);
      // التوكن يُحفظ قبل إعادة المستخدم ليعمل الدخول التلقائي لاحقاً.
      await _tokenStorage.saveToken(result.token);
      return result.user;
    } catch (e) {
      throw DioClient.mapError(e);
    }
  }

  @override
  Future<User> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
    required String type,
  }) async {
    try {
      final result = await _remote.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
        phone: phone,
        type: type,
      );
      await _tokenStorage.saveToken(result.token);
      return result.user;
    } catch (e) {
      throw DioClient.mapError(e);
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      await _remote.changePassword(
        currentPassword: currentPassword,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
    } catch (e) {
      throw DioClient.mapError(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _remote.logout();
    } catch (_) {
      // حتى لو فشل نداء الخادم نكمل — المهم إزالة الجلسة محلياً.
    } finally {
      await _tokenStorage.deleteToken();
    }
  }

  @override
  Future<User?> getCurrentUser() async {
    try {
      final hasToken = await _tokenStorage.hasToken();
      if (!hasToken) return null;
      return await _remote.getCurrentUser();
    } catch (_) {
      // توكن منتهٍ أو غير صالح — تُعامل كأنه لا توجد جلسة.
      return null;
    }
  }
}
