import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';
import '../datasources/order_remote_datasource.dart';

class ApiOrderRepository implements OrderRepository {
  final OrderRemoteDataSource _remote;
  ApiOrderRepository(this._remote);

  @override
  Future<List<Order>> checkout({required int addressId, String? notes}) async {
    try {
      return await _remote.checkout(addressId: addressId, notes: notes);
    } catch (e) {
      throw DioClient.mapError(e);
    }
  }

  @override
  Future<PaginatedList<Order>> myOrders({int page = 1}) async {
    try {
      return await _remote.myOrders(page: page);
    } catch (e) {
      throw DioClient.mapError(e);
    }
  }
}
