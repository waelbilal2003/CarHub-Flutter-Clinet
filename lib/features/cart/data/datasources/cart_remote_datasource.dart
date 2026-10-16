import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/cart.dart';

/// مصدر بيانات السلة.
///
/// مصدر الحقيقة هنا هو `routes/api.php` و `CartController` في الـ Backend،
/// لا مجموعة Postman — فالمجموعة توثّق مسارين فقط من أصل خمسة:
///   GET    /cart              → كائن السلة مباشرة داخل data
///   POST   /cart/items        → **عنصر السلة** المضاف (لا السلة)
///   PUT    /cart/items/{id}   → السلة كاملة بعد التعديل   ← غير موثّق
///   DELETE /cart/items/{id}   → السلة كاملة بعد الحذف     ← غير موثّق
///   DELETE /cart              → رسالة فقط بلا data        ← غير موثّق
class CartRemoteDataSource {
  final DioClient _client;
  CartRemoteDataSource(this._client);

  Future<Cart> fetch() async {
    final res = await _client.dio.get(ApiEndpoints.cart);
    final envelope = ApiEnvelope.from(res.data);
    return Cart.fromJson(envelope.object);
  }

  /// يضيف [quantity] من المنتج للسلة.
  ///
  /// ⚠️ الخادم **يجمع** على الكمية الموجودة (`increment`) ولا يستبدلها،
  /// لذلك إضافة 2 لسطر كميته 2 تجعلها 4. ولأنه يعيد عنصر السلة فقط
  /// (بلا `total_amount`)، تتكفّل طبقة الحالة بإعادة جلب السلة.
  Future<CartItem> addItem({
    required int productId,
    required int quantity,
  }) async {
    final res = await _client.dio.post(
      ApiEndpoints.cartItems,
      data: {'product_id': productId, 'quantity': quantity},
    );
    final envelope = ApiEnvelope.from(res.data);
    return CartItem.fromJson(envelope.object);
  }

  /// يضبط كمية سطر إلى [quantity] بالضبط (تعيين لا جمع).
  /// يعيد السلة كاملة، فلا حاجة لنداء إضافي بعده.
  Future<Cart> updateItem({
    required int itemId,
    required int quantity,
  }) async {
    final res = await _client.dio.put(
      ApiEndpoints.cartItem(itemId),
      data: {'quantity': quantity},
    );
    final envelope = ApiEnvelope.from(res.data);
    return Cart.fromJson(envelope.object);
  }

  /// يحذف سطراً من السلة ويعيد السلة كاملة بعد الحذف.
  Future<Cart> removeItem(int itemId) async {
    final res = await _client.dio.delete(ApiEndpoints.cartItem(itemId));
    final envelope = ApiEnvelope.from(res.data);
    return Cart.fromJson(envelope.object);
  }

  /// يفرّغ السلة. الخادم لا يعيد `data` هنا (رسالة نجاح فقط)، لذلك
  /// نعيد جلب السلة لنحصل على كائن صالح للعرض.
  Future<Cart> clear() async {
    final res = await _client.dio.delete(ApiEndpoints.clearCart);
    // نتحقّق من success فقط؛ لا يوجد data لنفكّها.
    ApiEnvelope.from(res.data);
    return fetch();
  }
}
