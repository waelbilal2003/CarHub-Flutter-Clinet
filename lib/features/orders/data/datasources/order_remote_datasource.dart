import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/order.dart';

/// مصدر بيانات الطلبات (جانب العميل).
///
/// من ملف Postman:
///   POST /checkout → data = **مصفوفة طلبات** (تقسيم تلقائي حسب التاجر)
///   GET  /orders   → data.data[] + data.meta (مصفّحة)
class OrderRemoteDataSource {
  final DioClient _client;
  OrderRemoteDataSource(this._client);

  /// إتمام الشراء.
  ///
  /// ⚠️ نقطة جوهرية: الخادم يقسّم محتوى السلة إلى **طلب مستقل لكل تاجر**
  /// (Order Splitting) ويعيدها كمصفوفة داخل `data`. لذلك لا نستخدم
  /// [ApiEnvelope.object] هنا — نقرأ المصفوفة مباشرة، وشاشة النجاح
  /// تعرض للعميل أن طلبه صار عدة طلبات بأرقامها.
  Future<List<Order>> checkout({
    required int addressId,
    String? notes,
  }) async {
    final res = await _client.dio.post(
      ApiEndpoints.checkout,
      data: {
        'address_id': addressId,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      },
    );

    final envelope = ApiEnvelope.from(res.data);
    final raw = envelope.data;
    if (raw is! List) {
      throw const ServerFailure(
        'استجابة إتمام الشراء غير متوقّعة: الحقل data ليس مصفوفة طلبات.',
      );
    }

    return raw
        .whereType<Map>()
        .map((e) => Order.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<PaginatedList<Order>> myOrders({int page = 1}) async {
    final res = await _client.dio.get(
      ApiEndpoints.orders,
      queryParameters: {'page': page},
    );
    final envelope = ApiEnvelope.from(res.data);
    return envelope.paginated(Order.fromJson);
  }
}
