import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/api_auth_repository.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

/// مستودع المصادقة — تطبيق واحد فقط يتصل بالـ API الحقيقي.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  final dioClient = ref.watch(dioClientProvider);
  final remote = AuthRemoteDataSource(dioClient);
  return ApiAuthRepository(remote, tokenStorage);
});

/// حالة الجلسة على مستوى التطبيق (يقرأها الراوتر وكل الشاشات).
///
/// لا تحمل أي حالة نموذج — راجع [loginFormProvider] و[registerFormProvider].
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthNotifier(repo);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthState()) {
    _checkAuthStatus();
  }

  /// الدخول التلقائي عند الإقلاع: إن وُجد توكن محفوظ نتحقق منه
  /// عبر GET /auth/me، فإن صحّ دخل المستخدم مباشرة.
  Future<void> _checkAuthStatus() async {
    try {
      final user = await _repository.getCurrentUser();
      state = AuthState(
        status: user != null
            ? AuthStatus.authenticated
            : AuthStatus.unauthenticated,
        user: user,
      );
    } catch (_) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  /// تفتح الجلسة بعد نجاح تسجيل دخول أو إنشاء حساب.
  /// تستدعيها نماذج المصادقة، والراوتر ينقل للرئيسية تلقائياً.
  void setSession(User user) {
    state = AuthState(status: AuthStatus.authenticated, user: user);
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// مزامنة بيانات المستخدم بعد تحديث الملف الشخصي.
  void updateUser(User user) {
    state = state.copyWith(user: user);
  }
}
