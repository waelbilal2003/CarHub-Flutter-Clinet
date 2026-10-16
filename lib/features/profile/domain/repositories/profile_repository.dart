import '../../../auth/domain/entities/user.dart';

/// عقد الملف الشخصي.
///
/// ملاحظة عن الـ Backend: لا يوجد مسار منفصل لرفع الصورة —
/// المسار الوحيد هو POST /auth/profile بصيغة multipart، ويقبل
/// name / email / phone / avatar معاً. لذلك [updateProfile] تغطّي الحالتين.
/// كما أنه لا يقبل حقل `city`.
abstract interface class ProfileRepository {
  /// يقرأ الملف الشخصي عبر GET /auth/me.
  Future<User> getProfile();

  /// يحدّث البيانات و/أو الصورة في نداء واحد.
  /// [avatarPath] مسار ملف محلي اختياري.
  Future<User> updateProfile({
    required String name,
    String? email,
    String? phone,
    String? avatarPath,
  });
}
