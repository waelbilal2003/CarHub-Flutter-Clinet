import '../../../../core/network/api_response.dart';
import '../entities/product.dart';
import '../entities/review.dart';

abstract class ProductRepository {
  /// الفلترة تُنفَّذ على الخادم (search / category_id / brand_id /
  /// min_price / max_price) لا محلياً.
  Future<PaginatedList<Product>> list({
    int page,
    String? search,
    int? categoryId,
    int? brandId,
    double? minPrice,
    double? maxPrice,
  });

  Future<Product> show(int id);

  Future<Review> addReview({
    required int productId,
    required int rating,
    String? comment,
  });
}
