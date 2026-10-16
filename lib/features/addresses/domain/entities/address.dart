import '../../../../shared/models/json_utils.dart';

/// عنوان شحن — الحقول مطابقة تماماً لاستجابة /addresses:
/// ```json
/// { "id": 3, "title": "home", "recipient_name": "...", "phone": "...",
///   "city": "دبي", "address_line": "...", "is_default": true,
///   "created_at": "2026-09-03T14:57:10+00:00" }
/// ```
/// ملاحظة: استجابة "عرض عنوان محدد" تضيف user_id و updated_at.
class Address {
  final int id;
  final String title;
  final String recipientName;
  final String phone;
  final String city;
  final String addressLine;
  final bool isDefault;
  final DateTime? createdAt;

  const Address({
    required this.id,
    required this.title,
    required this.recipientName,
    required this.phone,
    required this.city,
    required this.addressLine,
    required this.isDefault,
    this.createdAt,
  });

  factory Address.fromJson(Map<String, dynamic> json) => Address(
        id: asInt(json['id']),
        title: asString(json['title']),
        recipientName: asString(json['recipient_name']),
        phone: asString(json['phone']),
        city: asString(json['city']),
        addressLine: asString(json['address_line']),
        isDefault: asBool(json['is_default']),
        createdAt: asDateOrNull(json['created_at']),
      );

  /// جسم الطلب عند الإنشاء/التعديل — أسماء الحقول كما يتوقّعها الـ Backend.
  Map<String, dynamic> toRequestJson() => {
        'title': title,
        'recipient_name': recipientName,
        'phone': phone,
        'city': city,
        'address_line': addressLine,
        'is_default': isDefault,
      };
}
