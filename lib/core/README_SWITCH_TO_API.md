# تبديل Mock بالـ API الحقيقي

عند جاهزية الـ Backend، اتبع 3 خطوات فقط:

1. افتح `lib/core/config/app_config.dart`.
2. غيّر `useMock` إلى `false`.
3. اضبط `apiBaseUrl` على عنوان خادم زميلك.

لن تحتاج لتعديل أي شاشة أو منطق. طبقتا `authRepositoryProvider`
و `profileRepositoryProvider` ستختاران التطبيق الحقيقي تلقائياً.

## إن اختلف شكل استجابة الـ Backend
- أسماء حقول المستخدم: عدّل `UserModel.fromJson` فقط.
- شكل رسالة الخطأ: عدّل `DioClient._extractMessage` فقط.
- مسارات الـ endpoints: عدّلها في `auth_remote_datasource.dart`
  و `profile_remote_datasource.dart`.
