import '../../../../core/network/dio_client.dart';
import '../../domain/entities/cart.dart';
import '../../domain/repositories/cart_repository.dart';
import '../datasources/cart_remote_datasource.dart';

class ApiCartRepository implements CartRepository {
  final CartRemoteDataSource _remote;
  ApiCartRepository(this._remote);

  @override
  Future<Cart> fetch() async {
    try {
      return await _remote.fetch();
    } catch (e) {
      throw DioClient.mapError(e);
    }
  }

  @override
  Future<CartItem> addItem({
    required int productId,
    required int quantity,
  }) async {
    try {
      return await _remote.addItem(productId: productId, quantity: quantity);
    } catch (e) {
      throw DioClient.mapError(e);
    }
  }

  @override
  Future<Cart> updateItem({
    required int itemId,
    required int quantity,
  }) async {
    try {
      return await _remote.updateItem(itemId: itemId, quantity: quantity);
    } catch (e) {
      throw DioClient.mapError(e);
    }
  }

  @override
  Future<Cart> removeItem(int itemId) async {
    try {
      return await _remote.removeItem(itemId);
    } catch (e) {
      throw DioClient.mapError(e);
    }
  }

  @override
  Future<Cart> clear() async {
    try {
      return await _remote.clear();
    } catch (e) {
      throw DioClient.mapError(e);
    }
  }
}
