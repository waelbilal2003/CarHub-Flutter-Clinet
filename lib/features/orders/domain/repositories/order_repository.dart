import '../../../../core/network/api_response.dart';
import '../entities/order.dart';

abstract class OrderRepository {
  /// يعيد **قائمة** طلبات لأن الخادم يقسّم الشراء حسب كل تاجر.
  Future<List<Order>> checkout({required int addressId, String? notes});

  Future<PaginatedList<Order>> myOrders({int page});
}
