/// كيان المستخدم — يطابق حقول الـ API حرفياً كما في استجابة /auth/me:
/// ```json
/// { "id": 3, "name": "...", "email": "...", "phone": "...",
///   "type": "merchant", "status": null, "avatar_url": null,
///   "avatar_thumb_url": null, "created_at": "2026-09-03T14:35:06+00:00" }
/// ```
///
/// ملاحظة: لا يوجد حقل `city` ولا `role` في الـ Backend، لذلك أُزيلا.
class User {
  final int id;
  final String name;
  final String email;
  final String? phone;

  /// نوع الحساب كما في `App\Enums\UserType`:
  /// client (عميل) · contractor (مقاول) · merchant (تاجر) · admin.
  ///
  /// كل من يُنشئ حساباً من تطبيق CarHub هذا يكون `client`؛ الأدوار
  /// الأخرى تأتي من تطبيق الأعمال أو لوحة الإدارة. لذلك لا تعرض
  /// الشاشات هنا نوع الحساب — فهو `client` دائماً ولا معنى لإظهاره.
  final String? type;

  /// حالة الحساب — تعود null في كل أمثلة الـ API حتى الآن.
  final String? status;

  final String? avatarUrl;
  final String? avatarThumbUrl;
  final DateTime? createdAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.type,
    this.status,
    this.avatarUrl,
    this.avatarThumbUrl,
    this.createdAt,
  });

  bool get isClient => type == 'client';
  bool get isContractor => type == 'contractor';
  bool get isMerchant => type == 'merchant';

  User copyWith({
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    String? avatarThumbUrl,
  }) {
    return User(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      type: type,
      status: status,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      avatarThumbUrl: avatarThumbUrl ?? this.avatarThumbUrl,
      createdAt: createdAt,
    );
  }
}
