/// دوال تحقّق من المدخلات تُستخدم في الحقول عبر التطبيق.
/// كل دالة تعيد null عند الصحّة، أو رسالة خطأ عربية عند الخطأ.
class Validators {
  Validators._();

  static String? required(String? value, [String field = 'هذا الحقل']) {
    if (value == null || value.trim().isEmpty) {
      return '$field مطلوب.';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'البريد الإلكتروني مطلوب.';
    }
    final regex = RegExp(r'^[\w.\-]+@([\w\-]+\.)+[\w\-]{2,}$');
    if (!regex.hasMatch(value.trim())) {
      return 'صيغة البريد الإلكتروني غير صحيحة.';
    }
    return null;
  }

  /// الحد الأدنى 8 محارف — مطابق لـ `Password::defaults()` في الـ Backend.
  /// لا تُخفّضه وإلا رفض الخادم الطلب بـ 422 بعد أن يجيزه التطبيق.
  static const int minPasswordLength = 8;

  /// تحقّق كلمة المرور عند **إنشاء** حساب أو تغييرها: يفرض الحد الأدنى.
  static String? newPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'كلمة المرور مطلوبة.';
    }
    if (value.length < minPasswordLength) {
      return 'كلمة المرور يجب ألّا تقلّ عن $minPasswordLength محارف.';
    }
    return null;
  }

  /// تحقّق كلمة المرور عند **تسجيل الدخول**: الحضور فقط.
  ///
  /// لا نفرض الحد الأدنى هنا عمداً: المستخدم يُدخل كلمة مرور قائمة لا
  /// ينشئ واحدة. لو فرضناه لظهرت له رسالة «يجب ألّا تقلّ عن 8 محارف»
  /// وهي مضلّلة — المشكلة الحقيقية أن الكلمة خاطئة، وهذا يقرّره الخادم.
  static String? loginPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'كلمة المرور مطلوبة.';
    }
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value != original) {
      return 'كلمتا المرور غير متطابقتين.';
    }
    return null;
  }

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'الاسم مطلوب.';
    }
    if (value.trim().length < 3) {
      return 'الاسم قصير جداً.';
    }
    return null;
  }
}
