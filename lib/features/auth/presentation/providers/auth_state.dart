import '../../domain/entities/user.dart';

/// وضع الجلسة الحالي في التطبيق.
enum AuthStatus {
  unknown, // لم نتحقّق بعد (عند الإقلاع)
  authenticated, // مسجّل دخول
  unauthenticated // غير مسجّل
}

/// حالة **الجلسة** فقط — من هو المستخدم وهل هو داخل أم لا.
///
/// مهم: لا تحتوي هذه الحالة أي شيء يخصّ النماذج (تحميل/أخطاء حقول)،
/// لأنها مشتركة بين كل شاشات التطبيق. حالة كل نموذج (تسجيل دخول /
/// إنشاء حساب) مستقلة تماماً في [AuthFormState] الخاصة به، وإلا
/// تسرّب خطأ شاشة إلى الأخرى.
class AuthState {
  final AuthStatus status;
  final User? user;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
  });

  AuthState copyWith({AuthStatus? status, User? user}) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
    );
  }
}

/// حالة نموذج مصادقة واحد (شاشة واحدة بعينها).
class AuthFormState {
  /// هل هذا النموذج تحديداً قيد الإرسال؟
  final bool isSubmitting;

  /// رسالة عامة تُعرض أعلى النموذج.
  final String? error;

  /// أخطاء الخادم لكل حقل: «email» ← «البريد مستخدم مسبقاً».
  final Map<String, String> fieldErrors;

  const AuthFormState({
    this.isSubmitting = false,
    this.error,
    this.fieldErrors = const {},
  });

  AuthFormState copyWith({
    bool? isSubmitting,
    String? error,
    Map<String, String>? fieldErrors,
    bool clearError = false,
  }) {
    return AuthFormState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
      fieldErrors: clearError ? const {} : (fieldErrors ?? this.fieldErrors),
    );
  }
}
