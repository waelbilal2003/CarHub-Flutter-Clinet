import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/review.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_remote_datasource.dart';

class ApiProductRepository implements ProductRepository {
  final ProductRemoteDataSource _remote;
  ApiProductRepository(this._remote);

  @override
  Future<PaginatedList<Product>> list({
    int page = 1,
    String? search,
    int? categoryId,
    int? brandId,
    double? minPrice,
    double? maxPrice,
    String? carMake,
    String? carModel,
    int? year,
  }) async {
    try {
      return await _remote.list(
        page: page,
        search: search,
        categoryId: categoryId,
        brandId: brandId,
        minPrice: minPrice,
        maxPrice: maxPrice,
        carMake: carMake,
        carModel: carModel,
        year: year,
      );
    } catch (e) {
      throw DioClient.mapError(e);
    }
  }

  @override
  Future<Product> show(int id) async {
    try {
      return await _remote.show(id);
    } catch (e) {
      throw DioClient.mapError(e);
    }
  }

  @override
  Future<Review> addReview({
    required int productId,
    required int rating,
    String? comment,
  }) async {
    try {
      return await _remote.addReview(
        productId: productId,
        rating: rating,
        comment: comment,
      );
    } catch (e) {
      throw DioClient.mapError(e);
    }
  }
}
