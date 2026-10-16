/// تمثيل موحّد للأخطاء في كل التطبيق. بدل رمي DioException الخام،
/// نحوّل كل خطأ إلى Failure برسالة عربية واضحة تُعرض للمستخدم.
sealed class Failure implements Exception {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;
}

/// خطأ في الشبكة (لا يوجد اتصال / انتهت المهلة).
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'تعذّر الاتصال بالخادم. تحقّق من الإنترنت وحاول مجدداً.']);
}

/// بيانات الدخول غير صحيحة أو الجلسة منتهية (401).
class AuthFailure extends Failure {
  const AuthFailure([super.message = 'بيانات الدخول غير صحيحة.']);
}

/// خطأ من الخادم (500 وما شابه).
class ServerFailure extends Failure {
  const ServerFailure([super.message = 'حدث خطأ في الخادم. حاول لاحقاً.']);
}

/// خطأ في المدخلات أو الطلب (422 / 400) — عادة رسالة من الـ Backend.
///
/// [fieldErrors] يحمل أخطاء Laravel لكل حقل على حدة، مأخوذة من:
/// `{ "message": "...", "errors": { "email": ["..."], "password": ["..."] } }`
/// فتستطيع الشاشات عرض كل خطأ تحت حقله بدل رسالة عامة واحدة.
class ValidationFailure extends Failure {
  final Map<String, String> fieldErrors;

  const ValidationFailure(super.message, {this.fieldErrors = const {}});
}

/// العنصر المطلوب غير موجود (404).
class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'العنصر المطلوب غير موجود.']);
}

/// خطأ غير متوقّع.
class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'حدث خطأ غير متوقّع.']);
}
