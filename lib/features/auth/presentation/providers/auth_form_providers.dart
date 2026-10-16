import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_provider.dart';
import 'auth_state.dart';

/// حالة نموذج تسجيل الدخول — **مستقلة تماماً** عن نموذج إنشاء الحساب.
///
/// `autoDispose` تعني أن الحالة تُمسح عند مغادرة الشاشة، فلا يعود
/// خطأ قديم للظهور عند فتحها من جديد.
final loginFormProvider =
    StateNotifierProvider.autoDispose<LoginFormNotifier, AuthFormState>((ref) {
  return LoginFormNotifier(ref);
});

/// حالة نموذج إنشاء الحساب — مستقلة تماماً عن نموذج الدخول.
final registerFormProvider =
    StateNotifierProvider.autoDispose<RegisterFormNotifier, AuthFormState>(
        (ref) {
  return RegisterFormNotifier(ref);
});

/// أساس مشترك للسلوك المتكرّر (بدء الإرسال، تحويل الخطأ، مسح أخطاء الحقول).
/// الاشتراك هنا في **الكود** فقط — أما الحالة فمنفصلة لكل نموذج.
abstract class _AuthFormNotifier extends StateNotifier<AuthFormState> {
  final Ref ref;
  _AuthFormNotifier(this.ref) : super(const AuthFormState());

  AuthRepository get repo => ref.read(authRepositoryProvider);

  void beginSubmit() {
    state = const AuthFormState(isSubmitting: true);
  }

  /// يحوّل [Failure] إلى حالة نموذج: رسالة عامة + أخطاء حقول إن وُجدت.
  void failWith(Failure f) {
    state = AuthFormState(
      isSubmitting: false,
      error: f.message,
      fieldErrors:
          f is ValidationFailure ? f.fieldErrors : const <String, String>{},
    );
  }

  /// يمسح خطأ حقل واحد بمجرّد أن يعدّله المستخدم.
  ///
  /// هذا ما يمنع «المربع الأحمر الدائم»: خطأ الخادم يختفي فور
  /// تصحيح المستخدم للحقل، بدل أن يبقى عالقاً حتى إعادة الإرسال.
  void clearFieldError(String field) {
    if (!state.fieldErrors.containsKey(field)) return;
    final next = Map<String, String>.from(state.fieldErrors)..remove(field);
    state = state.copyWith(fieldErrors: next);
  }

  /// يمسح كل الأخطاء (يُستدعى عند مغادرة الشاشة أو البدء من جديد).
  void reset() => state = const AuthFormState();
}

class LoginFormNotifier extends _AuthFormNotifier {
  LoginFormNotifier(super.ref);

  Future<bool> submit({
    required String email,
    required String password,
  }) async {
    beginSubmit();
    try {
      final user = await repo.login(email: email, password: password);
      state = const AuthFormState();
      ref.read(authProvider.notifier).setSession(user);
      return true;
    } on Failure catch (f) {
      failWith(f);
      return false;
    }
  }
}

class RegisterFormNotifier extends _AuthFormNotifier {
  RegisterFormNotifier(super.ref);

  Future<bool> submit({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
    // تطبيق CarHub هذا خاص بالعميل وحده. الأدوار الأخرى
    // (contractor / merchant / admin) تُنشأ من تطبيق الأعمال أو لوحة
    // الإدارة، لا من هنا. القيمة مطابقة لـ App\Enums\UserType::CLIENT.
    String type = 'client',
  }) async {
    beginSubmit();
    try {
      final user = await repo.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
        phone: phone,
        type: type,
      );
      state = const AuthFormState();
      // لا توجد خطوة OTP — التوكن يعود مع الاستجابة فتُفتح الجلسة فوراً.
      ref.read(authProvider.notifier).setSession(user);
      return true;
    } on Failure catch (f) {
      failWith(f);
      return false;
    }
  }
}
