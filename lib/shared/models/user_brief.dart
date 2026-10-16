import 'json_utils.dart';

/// تمثيل مختصر للمستخدم كما يعود داخل الكائنات الأخرى في الـ API:
/// ```json
/// "contractor": { "id": 4, "name": "contractor", "avatar_url": null }
/// ```
/// يظهر بنفس الشكل في: tender.contractor، bid.merchant،
/// conversation.sender / conversation.receiver، message.sender.
///
/// في مسارات المرحلة 3 (المنتجات والطلبات) يعود الكائن نفسه لكن أوسع:
/// ```json
/// "merchant": { "id": 2, "name": "...", "email": "...", "phone": "0954652404",
///   "type": "merchant", "status": null, "avatar_url": "...",
///   "avatar_thumb_url": "...", "created_at": "..." }
/// ```
/// لذلك [phone] و[type] اختياريان: موجودان في استجابات المرحلة 3،
/// وغائبان في استجابات المناقصات والعروض من المراحل السابقة.
class UserBrief {
  final int id;
  final String name;
  final String? avatarUrl;
  final String? phone;
  final String? type;

  const UserBrief({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.phone,
    this.type,
  });

  factory UserBrief.fromJson(Map<String, dynamic> json) => UserBrief(
        id: asInt(json['id']),
        name: asString(json['name']),
        // avatar_thumb_url أخفّ للقوائم، ونرجع لـ avatar_url عند غيابه.
        avatarUrl: asStringOrNull(json['avatar_thumb_url']) ??
            asStringOrNull(json['avatar_url']),
        phone: asStringOrNull(json['phone']),
        type: asStringOrNull(json['type']),
      );

  /// يقرأ كائن مستخدم مضمَّناً داخل حقل آخر (merchant / buyer / user)
  /// ويعيد null إذا كان الحقل غائباً أو ليس كائناً.
  static UserBrief? fromNullable(dynamic value) {
    if (value is! Map) return null;
    return UserBrief.fromJson(Map<String, dynamic>.from(value));
  }

  /// أول حرف من الاسم — للصورة البديلة عند غياب avatar_url.
  String get initial => name.isEmpty ? '؟' : name.characters.first;
}

extension on String {
  Iterable<String> get characters => split('');
}
