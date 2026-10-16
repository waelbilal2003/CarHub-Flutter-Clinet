import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/product.dart';

/// مصدر بيانات المفضّلة — غير موثّق في مجموعة Postman إطلاقاً رغم أن
/// مجلدها اسمه «Shopping Cart & Wishlist». مأخوذ من `WishlistController`:
///   GET    /wishlists              → data = **مصفوفة** (لا مصفّحة)
///   POST   /wishlists              → { product_id } — firstOrCreate
///   DELETE /wishlists/{productId}  → ⚠️ بمعرّف **المنتج** لا معرّف السطر
class WishlistRemoteDataSource {
  final DioClient _client;
  WishlistRemoteDataSource(this._client);

  /// يعيد المنتجات المفضّلة. كل عنصر هو WishlistResource يحوي `product`،
  /// فنستخرج المنتج منه ونتجاهل غلاف السطر.
  Future<List<Product>> list() async {
    final res = await _client.dio.get(ApiEndpoints.wishlists);
    final envelope = ApiEnvelope.from(res.data);

    final raw = envelope.data;
    if (raw is! List) {
      throw const ServerFailure('استجابة المفضّلة غير متوقّعة (data ليست مصفوفة).');
    }

    return raw.whereType<Map>().map((e) {
      final row = Map<String, dynamic>.from(e);
      final product = row['product'];
      return Product.fromJson(
        product is Map ? Map<String, dynamic>.from(product) : row,
      );
    }).toList();
  }

  Future<void> add(int productId) async {
    final res = await _client.dio.post(
      ApiEndpoints.wishlists,
      data: {'product_id': productId},
    );
    ApiEnvelope.from(res.data);
  }

  /// ⚠️ المعرّف هنا هو `product_id` لا معرّف سطر المفضّلة.
  Future<void> remove(int productId) async {
    final res = await _client.dio.delete(ApiEndpoints.wishlist(productId));
    ApiEnvelope.from(res.data);
  }
}
