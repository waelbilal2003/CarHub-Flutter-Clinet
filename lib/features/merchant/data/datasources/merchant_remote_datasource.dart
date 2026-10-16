import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../../../orders/domain/entities/order.dart';
import '../../../products/domain/entities/product.dart';

/// مصدر بيانات لوحة التاجر.
///
/// مصدر الحقيقة: `routes/api.php` (سطر `apiResource('products', ...)`)
/// و`Merchant\ProductController` — لا مجموعة Postman التي توثّق ثلاثة
/// مسارات فقط من أصل ثمانية:
///   GET    /merchant/products            ← غير موثّق
///   POST   /merchant/products            (multipart، images مطلوبة)
///   GET    /merchant/products/{id}       ← غير موثّق
///   PUT    /merchant/products/{id}       ← غير موثّق
///   DELETE /merchant/products/{id}       ← غير موثّق
///   GET    /merchant/orders
///   GET    /merchant/orders/{id}         ← غير موثّق
///   PATCH  /merchant/orders/{id}/status
class MerchantRemoteDataSource {
  final DioClient _client;
  MerchantRemoteDataSource(this._client);

  /// مخزون التاجر — منتجاته هو فقط، مصفّحة، بكل الحالات (لا active فقط).
  Future<PaginatedList<Product>> products({int page = 1}) async {
    final res = await _client.dio.get(
      ApiEndpoints.merchantProducts,
      queryParameters: {'page': page},
    );
    final envelope = ApiEnvelope.from(res.data);
    return envelope.paginated(Product.fromJson);
  }

  /// إضافة منتج.
  ///
  /// ⚠️ الحقل `images` **مطلوب** في `StoreProductRequest`
  /// (`required|array|min:1`, كل صورة `image|mimes:jpeg,png,jpg,gif,webp|max:2048`).
  /// لذلك لا يمكن إنشاء منتج بلا صورة واحدة على الأقل — ومثال Postman
  /// الذي لا يرسل صوراً يفشل بـ 422.
  ///
  /// [imagePaths] مسارات ملفات محلية من معرض الصور/الكاميرا.
  /// [primaryImageIndex] يحدّد أي صورة تكون الأساسية (الافتراضي الأولى).
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
    final formData = FormData.fromMap({
      'title': title,
      'description': description,
      // نرسل السعر نصاً كما في المجموعة ("1200") لا رقماً عشرياً.
      'price': _priceField(price),
      'stock': stock.toString(),
      'primary_image_index': primaryImageIndex.toString(),
      if (categoryId != null) 'category_id': categoryId.toString(),
      if (brandId != null) 'brand_id': brandId.toString(),
    });

    // Laravel يتوقّع مصفوفة، فالمفتاح يتكرّر باسم images[] لكل ملف.
    for (final path in imagePaths) {
      formData.files.add(
        MapEntry('images[]', await MultipartFile.fromFile(path)),
      );
    }

    final res = await _client.dio.post(
      ApiEndpoints.merchantProducts,
      data: formData,
    );
    final envelope = ApiEnvelope.from(res.data);
    return Product.fromJson(envelope.object);
  }

  /// تعديل منتج — `UpdateProductRequest` يقبل الحقول النصية بالإضافة إلى
  /// `new_images[]` و`delete_images[]` و`primary_image_id`.
  ///
  /// نرسله بـ POST مع `_method=PUT` لأن PHP لا يقرأ multipart من طلب
  /// PUT مباشرة (قيد معروف في Laravel عند رفع ملفات).
  Future<Product> updateProduct({
    required int id,
    String? title,
    String? description,
    double? price,
    int? stock,
    List<String> newImagePaths = const [],
  }) async {
    final formData = FormData.fromMap({
      '_method': 'PUT',
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (price != null) 'price': _priceField(price),
      if (stock != null) 'stock': stock.toString(),
    });

    for (final path in newImagePaths) {
      formData.files.add(
        MapEntry('new_images[]', await MultipartFile.fromFile(path)),
      );
    }

    final res = await _client.dio.post(
      ApiEndpoints.merchantProduct(id),
      data: formData,
    );
    final envelope = ApiEnvelope.from(res.data);
    return Product.fromJson(envelope.object);
  }

  /// حذف منتج. الخادم يحذف ملفات الصور أيضاً ولا يعيد `data`.
  Future<void> deleteProduct(int id) async {
    final res = await _client.dio.delete(ApiEndpoints.merchantProduct(id));
    ApiEnvelope.from(res.data);
  }

  Future<PaginatedList<Order>> orders({int page = 1}) async {
    final res = await _client.dio.get(
      ApiEndpoints.merchantOrders,
      queryParameters: {'page': page},
    );
    final envelope = ApiEnvelope.from(res.data);
    return envelope.paginated(Order.fromJson);
  }

  /// [status] قيمة من `App\Enums\OrderStatus` حصراً؛ أي قيمة أخرى
  /// يرفضها `Rule::enum` بـ 422. الخادم يردّ بالطلب المحدَّث ومعه
  /// `status_label` عربي نعرضه كما هو.
  Future<Order> updateOrderStatus({
    required int orderId,
    required String status,
  }) async {
    final res = await _client.dio.patch(
      ApiEndpoints.merchantOrderStatus(orderId),
      data: {'status': status},
    );
    final envelope = ApiEnvelope.from(res.data);
    return Order.fromJson(envelope.object);
  }

  /// السعر يُرسل بلا كسور عندما يكون صحيحاً ("1200" لا "1200.0").
  static String _priceField(double price) =>
      price == price.roundToDouble() ? price.toInt().toString() : price.toString();
}
