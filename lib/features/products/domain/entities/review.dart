import '../../../../shared/models/json_utils.dart';
import '../../../../shared/models/user_brief.dart';

/// تقييم منتج — الحقول مطابقة لاستجابة POST /products/{id}/reviews
/// ولعناصر `product.reviews[]` في GET /products/{id}:
/// ```json
/// { "id": 1, "rating": 5, "comment": "منتج ممتاز جداً",
///   "user": { "id": 2, "name": "...", "avatar_url": "..." },
///   "created_at": "2026-09-12T14:27:49.000000Z" }
/// ```
class Review {
  final int id;
  final int rating;
  final String? comment;
  final UserBrief? user;
  final DateTime? createdAt;

  const Review({
    required this.id,
    required this.rating,
    this.comment,
    this.user,
    this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: asInt(json['id']),
        rating: asInt(json['rating']),
        comment: asStringOrNull(json['comment']),
        user: UserBrief.fromNullable(json['user']),
        createdAt: asDateOrNull(json['created_at']),
      );
}
