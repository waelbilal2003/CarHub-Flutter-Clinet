import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../../../orders/domain/entities/order.dart';
import '../../../products/domain/entities/product.dart';
import '../../domain/repositories/merchant_repository.dart';
import '../datasources/merchant_remote_datasource.dart';

class ApiMerchantRepository implements MerchantRepository {
  final MerchantRemoteDataSource _remote;
  ApiMerchantRepository(this._remote);

  @override
  Future<PaginatedList<Product>> products({int page = 1}) async {
    try {
      return await _remote.products(page: page);
    } catch (e) {
      throw DioClient.mapError(e);
    }
  }

  @override
  Future<Product> addProduct({
    required String title,
    required String description,
    required double price,
    required int stock,
    required List<String> imagePaths,
    int primaryImageIndex = 0,
    int? categoryId,
    int? brandId,
  }) async {
    try {
      return await _remote.addProduct(
        title: title,
        description: description,
        price: price,
        stock: stock,
        imagePaths: imagePaths,
        primaryImageIndex: primaryImageIndex,
        categoryId: categoryId,
        brandId: brandId,
      );
    } catch (e) {
      throw DioClient.mapError(e);
    }
  }

  @override
  Future<Product> updateProduct({
    required int id,
    String? title,
    String? description,
    double? price,
    int? stock,
    List<String> newImagePaths = const [],
  }) async {
    try {
      return await _remote.updateProduct(
        id: id,
        title: title,
        description: description,
        price: price,
        stock: stock,
        newImagePaths: newImagePaths,
      );
    } catch (e) {
      throw DioClient.mapError(e);
    }
  }

  @override
  Future<void> deleteProduct(int id) async {
    try {
      await _remote.deleteProduct(id);
    } catch (e) {
      throw DioClient.mapError(e);
    }
  }

  @override
  Future<PaginatedList<Order>> orders({int page = 1}) async {
    try {
      return await _remote.orders(page: page);
    } catch (e) {
      throw DioClient.mapError(e);
    }
  }

  @override
  Future<Order> updateOrderStatus({
    required int orderId,
    required String status,
  }) async {
    try {
      return await _remote.updateOrderStatus(orderId: orderId, status: status);
    } catch (e) {
      throw DioClient.mapError(e);
    }
  }
}
