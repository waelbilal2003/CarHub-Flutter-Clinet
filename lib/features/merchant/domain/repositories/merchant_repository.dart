import '../../../../core/network/api_response.dart';
import '../../../orders/domain/entities/order.dart';
import '../../../products/domain/entities/product.dart';

abstract class MerchantRepository {
  /// مخزون التاجر — GET /merchant/products (مصفّح).
  Future<PaginatedList<Product>> products({int page});

  /// ⚠️ [imagePaths] إجباري: الخادم يشترط صورة واحدة على الأقل.
  Future<Product> addProduct({
    required String title,
    required String description,
    required double price,
    required int stock,
    required List<String> imagePaths,
    int primaryImageIndex,
    int? categoryId,
    int? brandId,
  });

  Future<Product> updateProduct({
    required int id,
    String? title,
    String? description,
    double? price,
    int? stock,
    List<String> newImagePaths,
  });

  Future<void> deleteProduct(int id);

  Future<PaginatedList<Order>> orders({int page});

  Future<Order> updateOrderStatus({
    required int orderId,
    required String status,
  });
}
