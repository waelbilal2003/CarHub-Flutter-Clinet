import '../entities/user.dart';

/// عقد المصادقة. طبقة العرض تعتمد على هذا العقد فقط.
/// المسارات المقابلة في الـ Backend: /auth/register، /auth/login،
/// /auth/me، /auth/change-password، /auth/logout.
abstract interface class AuthRepository {
  /// تسجيل الدخول — يحفظ التوكن داخلياً ويعيد المستخدم.
  Future<User> login({required String email, required String password});

  /// إنشاء حساب. الـ Backend يتطلب [passwordConfirmation] و[type]
  /// بقيمة 'contractor' أو 'merchant'، ويعيد التوكن مباشرة
  /// (لا توجد خطوة OTP في الـ API).
  Future<User> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
    required String type,
  });

  /// تغيير كلمة المرور (يتطلب جلسة مفتوحة).
  Future<void> changePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  });

  /// تسجيل الخروج — يمسح التوكن محلياً حتى لو فشل نداء الخادم.
  Future<void> logout();

  /// جلب المستخدم الحالي عبر التوكن المحفوظ (تسجيل الدخول التلقائي).
  /// يعيد null إذا لم توجد جلسة صالحة.
  Future<User?> getCurrentUser();
}
