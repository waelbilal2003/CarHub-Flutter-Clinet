import '../../../../shared/models/json_utils.dart';
import '../../domain/entities/user.dart';

/// نموذج المستخدم — أسماء الحقول مطابقة تماماً لاستجابة الـ API.
/// المرجع: ملف Postman «CarHub Laravel API» → /auth/login، /auth/me.
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    super.phone,
    super.type,
    super.status,
    super.avatarUrl,
    super.avatarThumbUrl,
    super.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: asInt(json['id']),
      name: asString(json['name']),
      email: asString(json['email']),
      phone: asStringOrNull(json['phone']),
      type: asStringOrNull(json['type']),
      status: asStringOrNull(json['status']),
      avatarUrl: asStringOrNull(json['avatar_url']),
      avatarThumbUrl: asStringOrNull(json['avatar_thumb_url']),
      createdAt: asDateOrNull(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'type': type,
        'status': status,
        'avatar_url': avatarUrl,
        'avatar_thumb_url': avatarThumbUrl,
        'created_at': createdAt?.toIso8601String(),
      };
}
