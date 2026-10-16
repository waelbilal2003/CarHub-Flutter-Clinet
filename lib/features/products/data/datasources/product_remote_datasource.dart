import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/review.dart';

/// مصدر بيانات المنتجات والتقييمات.
///
/// مصدر الحقيقة: `ProductController` في الـ Backend.
///   GET  /products                 → data.data[] + data.links + data.meta
///        يدعم: search, category_id, brand_id, min_price, max_price
///        ويعيد المنتجات النشطة فقط (status = active).
///   GET  /products/{id}            → الكائن مباشرة داخل data (+ reviews[])
///   POST /products/{id}/reviews    → كائن التقييم مباشرة داخل data
class ProductRemoteDataSource {
  final DioClient _client;
  ProductRemoteDataSource(this._client);

  /// قائمة السوق مع فلترة اختيارية تُنفَّذ **على الخادم**.
  /// نرسل المعاملات الفارغة أبداً — `filled()` في Laravel يتجاهل الفارغ،
  /// لكن حذفها يبقي الرابط نظيفاً وقابلاً للقراءة في السجلّات.
  Future<PaginatedList<Product>> list({
    int page = 1,
    String? search,
    int? categoryId,
    int? brandId,
    double? minPrice,
    double? maxPrice,
  }) async {
    final res = await _client.dio.get(
      ApiEndpoints.products,
      queryParameters: {
        'page': page,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (categoryId != null) 'category_id': categoryId,
        if (brandId != null) 'brand_id': brandId,
        if (minPrice != null) 'min_price': minPrice,
        if (maxPrice != null) 'max_price': maxPrice,
      },
    );
    final envelope = ApiEnvelope.from(res.data);
    return envelope.paginated(Product.fromJson);
  }

  Future<Product> show(int id) async {
    final res = await _client.dio.get(ApiEndpoints.product(id));
    final envelope = ApiEnvelope.from(res.data);
    return Product.fromJson(envelope.object);
  }

  /// إضافة تقييم.
  ///
  /// ملاحظة على السلوك: الخادم يستخدم `updateOrCreate` على
  /// (product_id, user_id)، فإعادة التقييم من نفس المستخدم **تُحدّث**
  /// تقييمه السابق ولا تضيف سطراً جديداً.
  Future<Review> addReview({
    required int productId,
    required int rating,
    String? comment,
  }) async {
    final res = await _client.dio.post(
      ApiEndpoints.productReviews(productId),
      data: {
        'rating': rating,
        if (comment != null && comment.trim().isNotEmpty)
          'comment': comment.trim(),
      },
    );
    final envelope = ApiEnvelope.from(res.data);
    return Review.fromJson(envelope.object);
  }
}
