# tender_app — تطبيق العميل (Flutter)

المرحلة الأولى: الأساس + المصادقة + الملف الشخصي، بمعمارية Feature-First.

## التشغيل
```bash
flutter pub get
flutter run
```

## تبديل Mock / API الحقيقي
افتح `lib/core/config/app_config.dart`:
- `useMock = true`  ← بيانات وهمية (الوضع الحالي، يعمل بدون Backend).
- `useMock = false` ← الاتصال بالـ API الحقيقي. عدّل `apiBaseUrl` لعنوان الخادم.

## بيانات تجربة الـ Mock
- الدخول: أي بريد صحيح الصيغة + كلمة مرور 6 أحرف فأكثر.
- `fail@test.com` ← يحاكي خطأ بيانات الدخول.
- `exists@test.com` ← يحاكي بريد مسجّل مسبقاً عند التسجيل.

## البنية
```
lib/
  core/      → إعدادات، ثيم، شبكة، تخزين، راوتر، أدوات، مكوّنات مشتركة
  features/
    auth/    → المصادقة (data / domain / presentation)
    profile/ → الملف الشخصي
    home/    → الشاشة الرئيسية
    splash/  → شاشة البداية
```
