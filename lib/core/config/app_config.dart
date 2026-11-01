/// ★ نقطة الإعداد المركزية الوحيدة للاتصال بالـ Backend ★
///
/// لتغيير الخادم (مثلاً من ngrok إلى دومين حقيقي عند النشر) عدّل
/// [apiBaseUrl] هنا فقط — لا يوجد أي رابط مكتوب داخل باقي الكود.
class AppConfig {
  AppConfig._();

  /// عنوان الـ API الأساسي (يشمل /api/v1).
  ///
  /// الحالي: نفق ngrok للتطوير عند إسراء (Laravel).
  /// عند النشر يُستبدل بدومين الإنتاج، مثال:
  ///   'https://api.carhub.com/api/v1'
  ///
  /// يمكن تجاوزه وقت البناء دون تعديل الكود (رابط ngrok جديد مثلاً):
  ///   flutter run --dart-define=API_BASE_URL=https://xxxx.ngrok-free.app/api/v1
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue:
        'https://carlene-hygroscopic-recollectively.ngrok-free.dev/api/v1',
  );

  /// هل الخادم خلف نفق ngrok؟
  ///
  /// عند true يُضاف هيدر `ngrok-skip-browser-warning` لكل طلب، وإلا اعترضت
  /// ngrok الطلب بصفحة تحذير HTML بدل استجابة JSON.
  /// اجعله false عند الانتقال لدومين حقيقي.
  static const bool isNgrokTunnel = true;

  /// طباعة تفاصيل كل طلب/استجابة في الطرفية أثناء التطوير.
  /// يعمل في وضع debug فقط (محمي بـ kDebugMode داخل DioClient).
  static const bool enableNetworkLogs = true;

  // ── المهلات ──
  // أطول من المعتاد لأن ngrok يضيف زمناً، والاتصال هنا غير مستقر.
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  /// مهلة أطول للإرسال لأنها تشمل رفع الصور (avatar / attachments).
  static const Duration sendTimeout = Duration(seconds: 60);

  /// مهلة انتظار ردّ المساعد الذكي (POST /ai/ask)، تُطبَّق على هذا الطلب وحده.
  /// سلسلة المهل: النموذج 25 ث ← Laravel 30 ث ← التطبيق 40 ث، فيصل الردّ
  /// الصحيح أو 503 من الخادم قبل أن تنتهي مهلة التطبيق.
  static const Duration aiReceiveTimeout = Duration(seconds: 40);

  // ملاحظة: لم يعد هناك مفتاح useMock ولا أي repository وهمي في المشروع.
  // كل نداء — بما فيه تسجيل الدخول — يمرّ عبر الخادم الحقيقي فعلياً.
}
