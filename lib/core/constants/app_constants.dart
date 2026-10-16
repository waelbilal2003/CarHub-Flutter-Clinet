/// ثوابت عامة للتطبيق (اسم التطبيق، مدة الأنيميشن... إلخ)
class AppConstants {
  AppConstants._(); // منع إنشاء نسخة

  static const String appName = 'CarHub';
  static const String appTagline = 'كل ما تحتاجه لسيارتك في مكان واحد';

  // مدة شاشة البداية قبل الانتقال
  static const Duration splashDelay = Duration(seconds: 2);

  // مهلة اتصال الشبكة
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
