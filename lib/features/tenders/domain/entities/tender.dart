import '../../../../shared/models/json_utils.dart';
import '../../../../shared/models/user_brief.dart';

/// مناقصة — الحقول مطابقة لاستجابة /tenders:
/// ```json
/// { "id": 2, "title": "...", "description": "...", "budget": "50000.00",
///   "deadline": "2026-12-31T23:59:59+00:00", "status": "open",
///   "attachments": [], "contractor": { "id": 4, "name": "...",
///   "avatar_url": null }, "created_at": "..." }
/// ```
/// ملاحظة: [status] يعود null عند الإنشاء و "open" عند القراءة،
/// و[budget] يعود نصاً لا رقماً.
class Tender {
  final int id;
  final String title;
  final String description;
  final double budget;
  final DateTime? deadline;
  final String? status;
  final List<String> attachments;
  final UserBrief? contractor;
  final DateTime? createdAt;

  const Tender({
    required this.id,
    required this.title,
    required this.description,
    required this.budget,
    this.deadline,
    this.status,
    this.attachments = const [],
    this.contractor,
    this.createdAt,
  });

  factory Tender.fromJson(Map<String, dynamic> json) => Tender(
        id: asInt(json['id']),
        title: asString(json['title']),
        description: asString(json['description']),
        budget: asDouble(json['budget']),
        deadline: asDateOrNull(json['deadline']),
        status: asStringOrNull(json['status']),
        attachments: asStringList(json['attachments']),
        contractor: json['contractor'] is Map
            ? UserBrief.fromJson(
                Map<String, dynamic>.from(json['contractor'] as Map))
            : null,
        createdAt: asDateOrNull(json['created_at']),
      );

  /// مفتوحة للعروض؟ (بعد قبول عرض يغلقها الخادم تلقائياً)
  bool get isOpen => status == null || status == 'open';

  String get statusLabel => switch (status) {
        'open' => 'مفتوحة',
        'closed' => 'مغلقة',
        'awarded' => 'تم الترسية',
        'cancelled' => 'ملغاة',
        _ => 'مفتوحة',
      };
}
