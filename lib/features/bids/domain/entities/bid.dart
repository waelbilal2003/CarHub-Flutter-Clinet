import '../../../../shared/models/json_utils.dart';
import '../../../../shared/models/user_brief.dart';

/// عرض سعر على مناقصة — مطابق لاستجابة /bids:
/// ```json
/// { "id": 2, "tender_id": 2, "price": "69000.00", "proposal": null,
///   "technical_offer": null, "financial_offer": null, "status": "submitted",
///   "admin_notes": null, "submitted_at": "...", "attachments": [],
///   "merchant": { "id": 2, "name": "...", "avatar_url": "..." },
///   "created_at": "..." }
/// ```
/// انتبه: عند الإنشاء يعود tender_id نصاً ("1") و status يعود null.
class Bid {
  final int id;
  final int tenderId;
  final double price;
  final String? proposal;
  final String? technicalOffer;
  final String? financialOffer;
  final String? status;
  final String? adminNotes;
  final DateTime? submittedAt;
  final List<String> attachments;
  final UserBrief? merchant;
  final DateTime? createdAt;

  const Bid({
    required this.id,
    required this.tenderId,
    required this.price,
    this.proposal,
    this.technicalOffer,
    this.financialOffer,
    this.status,
    this.adminNotes,
    this.submittedAt,
    this.attachments = const [],
    this.merchant,
    this.createdAt,
  });

  factory Bid.fromJson(Map<String, dynamic> json) => Bid(
        id: asInt(json['id']),
        tenderId: asInt(json['tender_id']),
        price: asDouble(json['price']),
        proposal: asStringOrNull(json['proposal']),
        technicalOffer: asStringOrNull(json['technical_offer']),
        financialOffer: asStringOrNull(json['financial_offer']),
        status: asStringOrNull(json['status']),
        adminNotes: asStringOrNull(json['admin_notes']),
        submittedAt: asDateOrNull(json['submitted_at']),
        attachments: asStringList(json['attachments']),
        merchant: json['merchant'] is Map
            ? UserBrief.fromJson(
                Map<String, dynamic>.from(json['merchant'] as Map))
            : null,
        createdAt: asDateOrNull(json['created_at']),
      );

  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';

  String get statusLabel => switch (status) {
        'accepted' => 'مقبول',
        'rejected' => 'مرفوض',
        'submitted' => 'قيد المراجعة',
        _ => 'قيد المراجعة',
      };
}
